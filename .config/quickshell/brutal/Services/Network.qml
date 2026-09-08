pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import qs.Config

/// Network and bluetooth status, reduced to the handful of facts the bar needs.
Singleton {
    id: root

    readonly property var devices: Networking.devices?.values ?? []

    readonly property var wifiDevice:
        root.devices.find(d => d.type === DeviceType.Wifi) ?? null

    /// The wifi network currently associated, if any.
    readonly property var activeWifi:
        root.wifiDevice?.networks?.values?.find(n => n.connected) ?? null

    readonly property bool wifiEnabled: Networking.wifiEnabled ?? false
    readonly property bool connected: root.devices.some(d => d.connected)
    /// True when something other than wifi carries the connection.
    readonly property bool wired:
        root.devices.some(d => d.connected && d.type !== DeviceType.Wifi)

    readonly property string ssid: root.activeWifi?.name ?? ""
    /// 0.0 - 1.0
    readonly property real strength: root.activeWifi?.signalStrength ?? 0

    readonly property string icon: root.wired ? Icons.ethernet
        : !root.wifiEnabled || !root.connected ? Icons.wifiOff
        : Icons.wifi

    readonly property string label: root.wired ? "Wired"
        : root.ssid !== "" ? root.ssid
        : root.wifiEnabled ? "Disconnected"
        : "Wi-Fi off"

    function toggleWifi(): void {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    /// False when an rfkill switch has the radio off. Nothing in software can
    /// turn it back on, so the menu says so rather than offering a dead toggle.
    readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled ?? true

    readonly property var wifiNetworks: root.wifiDevice?.networks?.values ?? []

    /// Connected first, then saved networks, then everything else — each group
    /// by descending signal. Sorting by signal alone would let the row you are
    /// reaching for swap places with its neighbour as the numbers wobble.
    readonly property var sortedWifi: {
        const rank = n => n.connected ? 0 : (n.known ? 1 : 2);
        return [...root.wifiNetworks].sort((a, b) => {
            const ra = rank(a), rb = rank(b);
            if (ra !== rb) return ra - rb;
            const d = (b.signalStrength ?? 0) - (a.signalStrength ?? 0);
            if (Math.abs(d) > 0.001) return d;
            return (a.name ?? "").localeCompare(b.name ?? "");
        });
    }

    readonly property bool wifiScanning: root.wifiDevice?.scannerEnabled ?? false

    function setWifiScanning(on: bool): void {
        if (root.wifiDevice) root.wifiDevice.scannerEnabled = on;
    }

    /// One of `Icons.wifiBars`, picked from signal strength. `secured` swaps in
    /// the padlocked variant of the same bar count.
    function wifiIcon(strength: real, secured: bool): string {
        const bars = secured ? Icons.wifiBarsLock : Icons.wifiBars;
        const i = Math.max(0, Math.min(bars.length - 1,
            Math.floor((strength ?? 0) * bars.length)));
        return bars[i];
    }

    /// True when the network is encrypted. Owe (Enhanced Open) encrypts without
    /// a passphrase, so it counts as secured but never prompts.
    function wifiSecured(net: var): bool {
        if (!net) return false;
        return net.security !== WifiSecurityType.Open;
    }

    /// True when the network needs a passphrase we do not already hold.
    function wifiNeedsPassword(net: var): bool {
        if (!net) return false;
        return !net.known
            && net.security !== WifiSecurityType.Open
            && net.security !== WifiSecurityType.Owe;
    }

    /// Join a network we can join unattended: one already saved, or an open
    /// one. Anything else has to come through `connectWifiWithPassword`.
    function connectWifi(net: var): void {
        if (!net || root.wifiNeedsPassword(net)) return;
        net.connect();
    }

    function disconnectWifi(net: var): void { if (net) net.disconnect(); }

    function forgetWifi(net: var): void { if (net) net.forget(); }

    // ── Joining a new secured network ──────────────────────────────────────
    // WifiNetwork.connect() takes no arguments, so there is no way to hand a
    // passphrase to it from QML. nmcli is the fallback, and it is driven with
    // --ask so the passphrase arrives on stdin: a password in argv is readable
    // by any process on the machine for as long as the command runs.
    property string wifiBusySsid: ""
    property string wifiError: ""

    function connectWifiWithPassword(ssid: string, password: string): void {
        if (ssid === "" || wifiJoin.running) return;
        root.wifiError = "";
        root.wifiBusySsid = ssid;
        root.pendingWifiPassword = password;
        wifiJoin.command = ["nmcli", "--ask", "device", "wifi", "connect", ssid];
        wifiJoin.running = true;
    }

    Process {
        id: wifiJoin

        stdinEnabled: true
        onStarted: {
            // nmcli prompts once for the passphrase; the newline submits it.
            wifiJoin.write(root.pendingWifiPassword + "\n");
            root.pendingWifiPassword = "";
        }
        stderr: StdioCollector { id: joinErr }
        onExited: (code) => {
            root.wifiBusySsid = "";
            root.wifiError = code === 0 ? "" : (joinErr.text.trim() || "Could not connect.");
        }
    }

    /// Held only between the click and nmcli asking for it, then cleared.
    property string pendingWifiPassword: ""

    // ── Bluetooth ──────────────────────────────────────────────────────────
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothEnabled: root.adapter?.enabled ?? false
    readonly property var bluetoothDevices: Bluetooth.devices?.values ?? []
    readonly property var connectedBluetooth:
        root.bluetoothDevices.filter(d => d.connected)

    function toggleBluetooth(): void {
        if (root.adapter) root.adapter.enabled = !root.adapter.enabled;
    }

    /// Devices in the order the menu wants them: connected first, then paired,
    /// then whatever the adapter has merely seen — each group alphabetical, so
    /// a scan finding new devices never reshuffles the ones above.
    readonly property var sortedBluetooth: {
        const rank = d => d.connected ? 0 : (d.paired || d.bonded ? 1 : 2);
        return [...root.bluetoothDevices].sort((a, b) => {
            const ra = rank(a), rb = rank(b);
            if (ra !== rb) return ra - rb;
            return (a.name ?? "").localeCompare(b.name ?? "");
        });
    }

    readonly property bool scanning: root.adapter?.discovering ?? false

    function setScanning(on: bool): void {
        if (root.adapter) root.adapter.discovering = on;
    }

    /// Connect or disconnect, whichever the device is not. An unpaired device
    /// has to be paired first; BlueZ will not connect to a stranger.
    function toggleDevice(device: var): void {
        if (!device) return;
        if (device.connected) device.disconnect();
        else if (device.paired || device.bonded) device.connect();
        else device.pair();
    }
}

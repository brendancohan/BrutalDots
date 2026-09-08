pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.Config

/**
 * Colour temperature, via hyprsunset's hyprctl interface.
 *
 * hyprsunset is started from hyprland/execs.lua when it is installed; this
 * service only talks to it. `enabled` is the shell's own state rather than a
 * read-back, because "identity" and "6000K" are indistinguishable over IPC.
 */
Singleton {
    id: root

    property bool enabled: false

    readonly property int temperature: Settings.data.nightLight.temperature
    readonly property bool available: probe.found

    function apply(): void {
        Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature",
            `${root.temperature}`]);
    }

    function enable(): void {
        if (!root.available) return;
        root.enabled = true;
        root.apply();
    }

    function disable(): void {
        root.enabled = false;
        Quickshell.execDetached(["hyprctl", "hyprsunset", "identity"]);
    }

    function toggle(): void {
        if (root.enabled) root.disable();
        else root.enable();
    }

    // Re-apply when the temperature is edited in settings.json while on.
    onTemperatureChanged: {
        if (root.enabled) root.apply();
    }

    Process {
        id: probe

        property bool found: false

        running: true
        command: ["sh", "-c", "command -v hyprsunset >/dev/null"]
        onExited: code => probe.found = code === 0
    }
}

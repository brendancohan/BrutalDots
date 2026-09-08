pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.UPower
import QtQuick
import qs.Config

/**
 * Laptop battery, via UPower.
 *
 * `available` is false on a desktop, and every consumer is expected to check
 * it: the bar hides its battery pill entirely rather than showing a full
 * charge that never moves.
 */
Singleton {
    id: root

    readonly property var device: UPower.displayDevice

    readonly property bool available:
        (root.device?.isLaptopBattery ?? false) && (root.device?.isPresent ?? false)

    /// 0.0 - 1.0
    readonly property real level: root.device?.percentage ?? 0
    readonly property int percent: Math.round(root.level * 100)

    readonly property int state: root.device?.state ?? UPowerDeviceState.Unknown
    readonly property bool charging:
        root.state === UPowerDeviceState.Charging
        || root.state === UPowerDeviceState.PendingCharge
    readonly property bool full: root.state === UPowerDeviceState.FullyCharged

    readonly property bool low: root.available && !root.charging && root.level <= 0.20
    readonly property bool critical: root.available && !root.charging && root.level <= 0.10

    readonly property color tint: root.critical ? Theme.color.red
        : root.low ? Theme.color.peach
        : root.charging ? Theme.color.mint
        : Theme.color.green

    /// Ten discrete glyphs, plus a separate charging set, matching how the
    /// nf-md battery icons are laid out.
    readonly property string icon: root.charging
        ? Icons.batteryCharging[Math.min(10, Math.max(0, Math.round(root.level * 10)))]
        : Icons.batteryLevel[Math.min(10, Math.max(0, Math.round(root.level * 10)))]

    /// "2h 14m left" / "1h 03m to full", or "" when UPower has no estimate.
    readonly property string estimate: {
        const seconds = root.charging
            ? (root.device?.timeToFull ?? 0)
            : (root.device?.timeToEmpty ?? 0);
        if (!root.available || seconds <= 0) return "";

        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const clock = hours > 0
            ? `${hours}h ${minutes.toString().padStart(2, "0")}m`
            : `${minutes}m`;
        return root.charging ? `${clock} to full` : `${clock} left`;
    }
}

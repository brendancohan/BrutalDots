pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.Config

/**
 * Backlight control via brightnessctl.
 *
 * `available` stays false on desktops with no backlight device, which lets the
 * UI hide the slider rather than showing a dead control.
 */
Singleton {
    id: root

    property real value: 1.0        // 0.0 - 1.0
    property int _max: 0
    readonly property bool available: root._max > 0

    readonly property string icon: root.value < 0.34 ? Icons.brightnessLow
        : root.value < 0.67 ? Icons.brightnessMed
        : Icons.brightnessHigh

    function setValue(v: real): void {
        if (!root.available) return;
        root.value = Math.max(0.01, Math.min(1, v));
        setProc.command = ["brightnessctl", "-m", "set", `${Math.round(root.value * 100)}%`];
        setProc.running = true;
    }

    function refresh(): void {
        readProc.running = true;
    }

    Process { id: setProc }

    Process {
        id: readProc
        running: true
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                // device,class,current,percent%,max
                const f = text.trim().split(",");
                if (f.length < 5) return;
                const cur = parseInt(f[2], 10);
                const max = parseInt(f[4], 10);
                if (!max) return;
                root._max = max;
                root.value = cur / max;
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.Config

/**
 * Points the SDDM login screen at the palette the session is wearing.
 *
 * Writes one line of the greeter's own theme.conf, which the installer makes
 * writable. Silently does nothing if the greeter is not installed. See
 * AGENTS.md "Dark mode follows the session".
 */
Singleton {
    id: root

    /// The greeter's own config, which the installer makes writable by you.
    readonly property string statePath: "/var/lib/brutaldots/theme.conf"

    /// Point the login screen at the palette the session is currently wearing.
    function sync(): void {
        if (write.running) return;
        write.mode = Theme.dark ? "true" : "false";
        write.running = true;
    }

    Process {
        id: write

        property string mode: "false"

        // Only the one line is rewritten. `message` and `label` in that file
        // are yours, and a palette toggle has no business touching them.
        command: ["sh", "-c",
            `f='${root.statePath}'; test -w "$f" || exit 0; `
            + `sed -i 's/^dark=.*/dark=${write.mode}/' "$f"`]

        stderr: StdioCollector { id: writeErr }
        onExited: code => {
            if (code !== 0) {
                console.warn("Greeter: could not update the login screen palette -",
                    writeErr.text.trim() || `exit ${code}`);
            }
        }
    }
}

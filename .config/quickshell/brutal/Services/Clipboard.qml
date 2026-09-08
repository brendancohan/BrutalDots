pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.Config

/**
 * Clipboard history, backed by cliphist.
 *
 * The store is filled by the `wl-paste --watch` processes started in
 * hyprland/execs.lua; this service only reads and edits it. The list is
 * re-read when the picker opens rather than polled, because cliphist has no
 * change signal and a timer would spawn a process every few seconds forever.
 */
Singleton {
    id: root

    /// [{ id, preview, raw, isBinary }]
    property list<var> entries: []
    property bool available: true
    property bool loading: false

    readonly property int count: root.entries.length

    function refresh(): void {
        if (!root.available) return;
        root.loading = true;
        list.running = false;
        list.running = true;
    }

    function copy(entry: var): void {
        if (!entry) return;
        Quickshell.execDetached(["sh", "-c", `cliphist decode ${entry.id} | wl-copy`]);
    }

    function remove(entry: var): void {
        if (!entry) return;
        removal.line = entry.raw;
        removal.running = false;
        removal.running = true;
    }

    function wipe(): void {
        Quickshell.execDetached(["cliphist", "wipe"]);
        root.entries = [];
    }

    Process {
        id: probe

        running: true
        command: ["sh", "-c", "command -v cliphist >/dev/null"]
        onExited: code => {
            root.available = code === 0;
            if (root.available) root.refresh();
        }
    }

    Process {
        id: list

        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = [];
                for (const line of this.text.split("\n")) {
                    if (line === "") continue;
                    const tab = line.indexOf("\t");
                    if (tab === -1) continue;

                    const preview = line.slice(tab + 1);
                    parsed.push({
                        id: line.slice(0, tab),
                        preview: preview,
                        raw: line,
                        // cliphist renders non-text as "[[ binary data … ]]".
                        isBinary: preview.startsWith("[[ binary data")
                    });
                }
                root.entries = parsed;
                root.loading = false;
            }
        }

        onExited: code => {
            if (code !== 0) root.loading = false;
        }
    }

    // cliphist deletes by being handed the whole list line on stdin, so the
    // stream has to be closed once written or the process never exits.
    Process {
        id: removal

        property string line: ""

        command: ["cliphist", "delete"]
        stdinEnabled: true

        onStarted: {
            this.write(`${removal.line}\n`);
            this.stdinEnabled = false;
        }

        onExited: root.refresh()
    }
}

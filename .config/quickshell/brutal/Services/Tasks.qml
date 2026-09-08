pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.Config

/// Todo list, persisted next to the shell's settings.
Singleton {
    id: root

    readonly property var list: adapter.items
    readonly property int activeCount: root.list.filter(t => !t.done).length

    function add(text: string): void {
        const trimmed = text.trim();
        if (trimmed === "") return;
        adapter.items = [...adapter.items, {
            id: Date.now(),
            text: trimmed,
            done: false
        }];
        file.writeAdapter();
    }

    function toggle(id): void {
        adapter.items = adapter.items.map(t =>
            t.id === id ? { id: t.id, text: t.text, done: !t.done } : t);
        file.writeAdapter();
    }

    function remove(id): void {
        adapter.items = adapter.items.filter(t => t.id !== id);
        file.writeAdapter();
    }

    function clearDone(): void {
        adapter.items = adapter.items.filter(t => !t.done);
        file.writeAdapter();
    }

    FileView {
        id: file

        path: `${Settings.configDir}/tasks.json`
        watchChanges: true
        preload: true
        printErrors: false

        onFileChanged: this.reload()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) this.writeAdapter();
            else console.warn("Tasks: could not read", this.path, "-",
                FileViewError.toString(error));
        }

        adapter: JsonAdapter {
            id: adapter
            property list<var> items: []
        }
    }
}

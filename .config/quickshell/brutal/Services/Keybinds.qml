pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

/**
 * The keybind index behind the dashboard's Keybinds tab, and the capture flow
 * for rebinding one.
 *
 * Reads what Hyprland actually has bound rather than what the config says, so
 * an override in custom/ shows up. See AGENTS.md for the submap dispatch quirk.
 */
Singleton {
    id: root

    readonly property string stateDir:
        (Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`)
        + "/brutaldots"
    readonly property string hyprDir:
        (Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`)
        + "/hypr"

    /// The markers the Lua side scrapes for. Changing either breaks the pair.
    readonly property string blockBegin: ">>> BrutalDots keybinds"
    readonly property string blockEnd: "<<< BrutalDots keybinds"

    /// [{ id, group, description, default, fixed }], in the order Lua declared
    /// them — which is the order they read best in.
    property var catalogue: []
    /// { id: "SUPER + D" }. An empty string means the user cleared the bind.
    property var overrides: ({})

    property bool catalogueLoaded: false
    property bool overridesLoaded: false

    /// Both files have settled. Writing before the overrides file has been read
    /// would splice an empty block over whatever is already in it, so nothing
    /// may be edited until this is true.
    readonly property bool ready: root.catalogueLoaded && root.overridesLoaded

    /// Group names, in first-seen order.
    readonly property var groups: {
        const seen = [];
        for (const e of root.catalogue) {
            if (!seen.includes(e.group)) seen.push(e.group);
        }
        return seen;
    }

    function comboFor(entry): string {
        const o = root.overrides[entry.id];
        return o === undefined ? entry.default : o;
    }

    function isOverridden(entry): bool {
        return root.overrides[entry.id] !== undefined;
    }

    /// Modifier order and case differ between what a user typed into the Lua
    /// and what the capture emits, and neither matters to Hyprland — so compare
    /// on a normalised form rather than on the string as written.
    function normalise(combo: string): string {
        if (!combo) return "";
        const parts = combo.split("+").map(p => p.trim().toUpperCase()).filter(p => p !== "");
        const order = ["SUPER", "CTRL", "ALT", "SHIFT"];
        const mods = order.filter(m => parts.includes(m));
        const keys = parts.filter(p => !order.includes(p));
        return mods.concat(keys).join("+");
    }

    /// The catalogue entry already using `combo`, or null. `exceptId` is the row
    /// being edited, which is never a conflict with itself.
    function conflict(combo: string, exceptId: string): var {
        const want = root.normalise(combo);
        if (want === "") return null;
        for (const e of root.catalogue) {
            if (e.id === exceptId) continue;
            if (root.normalise(root.comboFor(e)) === want) return e;
        }
        return null;
    }

    /// Binds Hyprland knows about that this catalogue does not — anything in
    /// custom/keybinds.lua. Caught separately so a rebind cannot silently
    /// shadow something the user added by hand.
    property var foreign: []

    function foreignConflict(combo: string): var {
        const want = root.normalise(combo);
        if (want === "") return null;
        for (const b of root.foreign) {
            if (root.normalise(b.combo) === want) return b;
        }
        return null;
    }

    // ── Reading and writing the block ──────────────────────────────────────
    property bool applying: false

    /// Overrides out of the marked block, ignoring the rest of the file.
    function parseBlock(text: string): var {
        const b = text.indexOf(root.blockBegin);
        const e = text.indexOf(root.blockEnd);
        if (b === -1 || e === -1 || e < b) return ({});

        const block = text.slice(b, e);
        const out = ({});
        const re = /\[\s*"([\w.\-]+)"\s*\]\s*=\s*"([^"]*)"/g;
        let m;
        while ((m = re.exec(block)) !== null) out[m[1]] = m[2];
        return out;
    }

    function renderBlock(): string {
        const ids = Object.keys(root.overrides).sort();
        const rows = ids.map(id => `    ["${id}"] = "${root.overrides[id]}",`);

        return `-- ${root.blockBegin} (managed by the dashboard) >>>\n`
            + "-- Rebinding in the Keybinds tab rewrites this block. Editing it by hand\n"
            + "-- works too; delete the block to restore every default.\n"
            + "BRUTALDOTS_KEYBINDS = {\n"
            + (rows.length > 0 ? rows.join("\n") + "\n" : "")
            + "}\n"
            + `-- ${root.blockEnd} <<<`;
    }

    /// Splice the block into the file, leaving everything around it alone. A
    /// file with no block yet gets one at the top, above whatever is there; a
    /// file whose last override was just removed loses the block entirely,
    /// rather than keeping an empty one nobody asked for.
    function spliceBlock(text: string): string {
        const empty = Object.keys(root.overrides).length === 0;
        const block = empty ? "" : root.renderBlock();
        const b = text.indexOf(root.blockBegin);
        const e = text.indexOf(root.blockEnd);

        if (b === -1 || e === -1 || e < b) {
            if (empty) return text;
            const rest = text.replace(/^\n+/, "");
            return rest.trim() === "" ? block + "\n" : `${block}\n\n${rest}`;
        }

        // Widen to whole lines, so the `--` in front of each marker goes too.
        const start = text.lastIndexOf("\n", b) + 1;
        let stop = text.indexOf("\n", e);
        stop = stop === -1 ? text.length : stop + 1;

        const head = text.slice(0, start);
        const tail = text.slice(stop);
        if (empty) return (head + tail).replace(/^\n+/, "");
        return head + block + "\n" + tail;
    }

    /// Combos come from this catalogue or from a key capture, so neither can
    /// carry a quote or a newline — but this is written into a file Hyprland
    /// executes, so it is checked rather than assumed.
    function isWritable(combo: string): bool {
        return !/["\\\n\r]/.test(combo);
    }

    function write(): void {
        if (!root.ready) {
            console.warn("Keybinds: refusing to write before the files have loaded");
            return;
        }
        root.applying = true;
        // A file that has never existed reads back as nothing, which splices
        // into a file containing only the block — which is correct.
        let current = "";
        try {
            current = overridesFile.text() || "";
        } catch (e) {
            current = "";
        }
        overridesFile.setText(root.spliceBlock(current));
    }

    function assign(id: string, combo: string): void {
        if (!root.isWritable(combo)) {
            console.warn("Keybinds: refusing to write combo", combo);
            return;
        }
        const next = Object.assign({}, root.overrides);
        next[id] = combo;
        root.overrides = next;
        root.write();
    }

    /// Back to whatever the Lua declares.
    function reset(id: string): void {
        const next = Object.assign({}, root.overrides);
        delete next[id];
        root.overrides = next;
        root.write();
    }

    /// Bound to nothing at all, without losing the row.
    function clear(id: string): void { root.assign(id, ""); }

    function resetAll(): void {
        root.overrides = ({});
        root.write();
    }

    // ── Turning a key event into a Hyprland combo ──────────────────────────
    /// Hyprland names keys by X keysym. Letters and function keys map straight
    /// across; the rest need spelling out.
    function keyName(key: int): string {
        if (key >= Qt.Key_A && key <= Qt.Key_Z)
            return String.fromCharCode(65 + key - Qt.Key_A);
        if (key >= Qt.Key_0 && key <= Qt.Key_9)
            return String.fromCharCode(48 + key - Qt.Key_0);
        if (key >= Qt.Key_F1 && key <= Qt.Key_F12)
            return "F" + (1 + key - Qt.Key_F1);

        switch (key) {
        case Qt.Key_Space: return "Space";
        case Qt.Key_Return:
        case Qt.Key_Enter: return "Return";
        case Qt.Key_Tab: return "Tab";
        case Qt.Key_Backspace: return "BackSpace";
        case Qt.Key_Delete: return "Delete";
        case Qt.Key_Insert: return "Insert";
        case Qt.Key_Home: return "Home";
        case Qt.Key_End: return "End";
        case Qt.Key_PageUp: return "Prior";
        case Qt.Key_PageDown: return "Next";
        case Qt.Key_Left: return "Left";
        case Qt.Key_Right: return "Right";
        case Qt.Key_Up: return "Up";
        case Qt.Key_Down: return "Down";
        case Qt.Key_Print: return "Print";
        case Qt.Key_Pause: return "Pause";
        case Qt.Key_Minus: return "minus";
        case Qt.Key_Equal: return "equal";
        case Qt.Key_BracketLeft: return "bracketleft";
        case Qt.Key_BracketRight: return "bracketright";
        case Qt.Key_Semicolon: return "semicolon";
        case Qt.Key_Apostrophe: return "apostrophe";
        case Qt.Key_Comma: return "comma";
        case Qt.Key_Period: return "period";
        case Qt.Key_Slash: return "slash";
        case Qt.Key_Backslash: return "backslash";
        case Qt.Key_QuoteLeft: return "grave";
        default: return "";
        }
    }

    /// Modifier keys on their own are not a combo — they are the user still
    /// holding the chord down.
    function isModifierKey(key: int): bool {
        return key === Qt.Key_Shift || key === Qt.Key_Control
            || key === Qt.Key_Alt || key === Qt.Key_AltGr
            || key === Qt.Key_Meta || key === Qt.Key_Super_L
            || key === Qt.Key_Super_R || key === Qt.Key_CapsLock
            || key === Qt.Key_NumLock || key === Qt.Key_unknown;
    }

    /**
     * "" when the press is not a usable combo yet.
     *
     * Qt reports the *shifted* keysym for digits and punctuation — SHIFT + 1
     * arrives as Key_Exclam, which Hyprland would not match against `1`. Those
     * fall back to `code:NN`, the evdev scancode, which is layout-independent
     * and binds exactly what was pressed. `nativeScanCode` is the evdev code
     * plus 8 on both X and Wayland.
     */
    function comboFromEvent(event): string {
        if (root.isModifierKey(event.key)) return "";

        const parts = [];
        if (event.modifiers & Qt.MetaModifier) parts.push("SUPER");
        if (event.modifiers & Qt.ControlModifier) parts.push("CTRL");
        if (event.modifiers & Qt.AltModifier) parts.push("ALT");
        if (event.modifiers & Qt.ShiftModifier) parts.push("SHIFT");

        let name = root.keyName(event.key);
        if (name === "") {
            const code = event.nativeScanCode - 8;
            if (code <= 0) return "";
            name = `code:${code}`;
        }

        parts.push(name);
        return parts.join(" + ");
    }

    // ── Capture ────────────────────────────────────────────────────────────
    /// The row currently listening for a combo, or "".
    property string capturingId: ""
    readonly property bool capturing: root.capturingId !== ""

    /**
     * Hyprland binds fire whatever the focused surface is, so listening for a
     * new combo with the normal map active would run the bind instead of
     * recording it — pressing SUPER + Q to assign it would close a window.
     * `brutaldots_capture` is an empty submap, so for as long as it is active
     * every key falls through to this shell instead.
     */
    /// Hyprland's Lua config takes a dispatcher expression, not a bare name:
    /// `hyprctl dispatch submap reset` is rejected outright (it exits 7). The
    /// plain form is kept as a fallback for a .conf-based Hyprland, the same
    /// way Idle does it for dpms.
    function submap(name: string): void {
        Quickshell.execDetached(["sh", "-c",
            `hyprctl dispatch 'hl.dsp.submap("${name}")' >/dev/null 2>&1 `
            + `|| hyprctl dispatch submap ${name}`]);
    }

    function beginCapture(id: string): void {
        if (root.capturing) root.endCapture();
        root.capturingId = id;
        root.submap("brutaldots_capture");
        captureTimeout.restart();
    }

    function endCapture(): void {
        captureTimeout.stop();
        root.capturingId = "";
        root.submap("reset");
    }

    Timer {
        id: refreshBinds
        interval: 600
        onTriggered: liveBinds.running = true
    }

    Timer {
        id: captureTimeout
        // A stuck submap is a session with no working keys, so capture always
        // gives itself back rather than waiting on a click that may not come.
        interval: 10000
        onTriggered: root.endCapture()
    }

    Connections {
        target: Hyprland

        // Escape is bound inside the submap to reset it — that keypress never
        // reaches this shell, so the submap ending is how a cancel is heard.
        function onRawEvent(event): void {
            if (event.name !== "submap") return;
            if (event.data !== "brutaldots_capture") {
                captureTimeout.stop();
                root.capturingId = "";
            }
        }
    }

    // ── Files ──────────────────────────────────────────────────────────────
    FileView {
        id: catalogueFile

        path: `${root.stateDir}/keybinds-catalogue.json`
        watchChanges: true
        printErrors: false
        // Read up front rather than on first access: both files gate editing,
        // and a lazy read leaves the tab inert for as long as it takes.
        preload: true

        onLoaded: {
            try {
                root.catalogue = JSON.parse(this.text());
                root.catalogueLoaded = true;
            } catch (e) {
                console.warn("Keybinds: catalogue is not valid JSON -", e);
            }
        }
        onFileChanged: this.reload()
        onLoadFailed: {
            // Written by Hyprland on config load. Missing means the config in
            // use predates the catalogue, not that anything is broken.
            console.warn("Keybinds: no catalogue at", this.path,
                "- reload your Hyprland config to generate it");
        }
    }

    FileView {
        id: overridesFile

        path: `${root.hyprDir}/custom/keybinds.lua`
        watchChanges: true
        printErrors: false
        atomicWrites: true
        preload: true

        onLoaded: {
            // Ignore the echo of our own write; `overrides` is already current
            // and re-parsing would fight an in-flight edit.
            root.overridesLoaded = true;
            if (root.applying) return;
            root.overrides = root.parseBlock(this.text());
        }
        onFileChanged: this.reload()
        // No custom/keybinds.lua yet is the normal state, not a problem — and
        // it still counts as settled, or nothing could ever be written.
        onLoadFailed: {
            root.overrides = ({});
            root.overridesLoaded = true;
        }

        onSaved: {
            root.applying = false;
            // Hyprland re-reads the overrides and rewrites the catalogue.
            Quickshell.execDetached(["hyprctl", "reload"]);
            // The reload is asynchronous; reading the bind list straight away
            // would describe the config we just replaced.
            refreshBinds.restart();
        }
        onSaveFailed: {
            root.applying = false;
            console.warn("Keybinds: could not write", this.path);
        }
    }

    // ── What Hyprland actually has bound ───────────────────────────────────
    Process {
        id: liveBinds

        command: ["hyprctl", "binds", "-j"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let parsed;
                try {
                    parsed = JSON.parse(this.text);
                } catch (e) {
                    return;
                }

                // 1 SHIFT, 4 CTRL, 8 ALT, 64 SUPER — Hyprland's modmask bits.
                const mods = [[64, "SUPER"], [4, "CTRL"], [8, "ALT"], [1, "SHIFT"]];
                const known = root.catalogue.map(e => root.normalise(root.comboFor(e)));
                const out = [];

                for (const b of parsed) {
                    if (b.submap) continue;
                    const parts = mods.filter(m => (b.modmask & m[0]) !== 0).map(m => m[1]);
                    parts.push(b.key);
                    const combo = parts.join(" + ");
                    if (known.includes(root.normalise(combo))) continue;
                    out.push({ combo: combo, description: b.description || "an unnamed bind" });
                }

                root.foreign = out;
            }
        }
    }
}

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.Config

/**
 * Live Hyprland settings: reads what the compositor currently has, previews a
 * change through `hyprctl eval`, and persists it to a managed block in
 * custom/general.lua.
 *
 * Also pushes the palette, since a Lua config is executed once at load and
 * cannot notice settings.json changing underneath it. See AGENTS.md.
 */
Singleton {
    id: root

    readonly property string hyprDir:
        (Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`)
        + "/hypr"

    readonly property string blockBegin: ">>> BrutalDots appearance"
    readonly property string blockEnd: "<<< BrutalDots appearance"

    /// `option` is what `hyprctl getoption` answers to; `path` is where the
    /// same setting sits inside an `hl.config` table.
    readonly property var settings: [
        {
            id: "rounding", group: "Windows", label: "Corner rounding",
            description: "Radius of a window's corners, in pixels",
            option: "decoration:rounding", path: ["decoration", "rounding"],
            type: "int", min: 0, max: 24
        },
        {
            id: "borderSize", group: "Windows", label: "Border width",
            description: "The ink outline around every window",
            option: "general:border_size", path: ["general", "border_size"],
            type: "int", min: 0, max: 8
        },
        {
            id: "gapsIn", group: "Windows", label: "Gaps between windows",
            description: "Space between tiled neighbours",
            option: "general:gaps_in", path: ["general", "gaps_in"],
            type: "int", min: 0, max: 40
        },
        {
            id: "gapsOut", group: "Windows", label: "Gaps at the screen edge",
            description: "Space between the tiling area and the monitor",
            option: "general:gaps_out", path: ["general", "gaps_out"],
            type: "int", min: 0, max: 80
        },

        {
            id: "activeOpacity", group: "Transparency", label: "Active window",
            description: "Opacity of the window you are working in",
            option: "decoration:active_opacity", path: ["decoration", "active_opacity"],
            type: "real", min: 0.4, max: 1
        },
        {
            id: "inactiveOpacity", group: "Transparency", label: "Inactive windows",
            description: "Opacity of everything behind it",
            option: "decoration:inactive_opacity", path: ["decoration", "inactive_opacity"],
            type: "real", min: 0.4, max: 1
        },
        {
            id: "dimInactive", group: "Transparency", label: "Dim inactive windows",
            description: "Darken unfocused windows instead of fading them",
            option: "decoration:dim_inactive", path: ["decoration", "dim_inactive"],
            type: "bool"
        },
        {
            id: "dimStrength", group: "Transparency", label: "Dim strength",
            description: "How far the dim goes, when it is on",
            option: "decoration:dim_strength", path: ["decoration", "dim_strength"],
            type: "real", min: 0, max: 1
        },

        {
            id: "shadowEnabled", group: "Effects", label: "Window shadows",
            description: "The hard offset block of ink the whole theme is built on",
            option: "decoration:shadow:enabled", path: ["decoration", "shadow", "enabled"],
            type: "bool"
        },
        {
            id: "shadowRange", group: "Effects", label: "Shadow size",
            description: "How far the shadow reaches past the window",
            option: "decoration:shadow:range", path: ["decoration", "shadow", "range"],
            type: "int", min: 0, max: 30
        },
        {
            id: "blurEnabled", group: "Effects", label: "Blur behind windows",
            description: "Off by design — brutalism is opaque, and blur softens every edge",
            option: "decoration:blur:enabled", path: ["decoration", "blur", "enabled"],
            type: "bool"
        },
        {
            id: "blurSize", group: "Effects", label: "Blur size",
            description: "Radius of the blur, when it is on",
            option: "decoration:blur:size", path: ["decoration", "blur", "size"],
            type: "int", min: 1, max: 20
        },
        {
            id: "animations", group: "Effects", label: "Animations",
            description: "Window and workspace motion",
            option: "animations:enabled", path: ["animations", "enabled"],
            type: "bool"
        }
    ]

    readonly property var groups: {
        const seen = [];
        for (const s of root.settings) {
            if (!seen.includes(s.group)) seen.push(s.group);
        }
        return seen;
    }

    /// { id: value } as Hyprland currently has them.
    property var values: ({})
    /// { id: value } this shell has written into the block.
    property var overrides: ({})

    property bool valuesLoaded: false
    property bool overridesLoaded: false
    readonly property bool ready: root.valuesLoaded && root.overridesLoaded

    function find(id: string): var {
        return root.settings.find(s => s.id === id) ?? null;
    }

    function value(id: string): var {
        const v = root.values[id];
        if (v !== undefined) return v;
        const s = root.find(id);
        return s && s.type === "bool" ? false : 0;
    }

    function isOverridden(id: string): bool {
        return root.overrides[id] !== undefined;
    }

    // ── Applying ───────────────────────────────────────────────────────────
    /// Lua literal for a value, typed the way `hl.config` expects it.
    function literal(setting, value): string {
        if (setting.type === "bool") return value ? "true" : "false";
        if (setting.type === "int") return String(Math.round(value));
        // Hyprland's parser wants a decimal point on a float, or 1 reads as int.
        return Number(value).toFixed(2);
    }

    /// One `hl.config` call covering every setting passed in, nested the way
    /// the paths say. Shared by the live eval and the file block.
    function configCall(ids, indent: string): string {
        const tree = ({});
        let count = 0;
        for (const id of ids) {
            const s = root.find(id);
            // An id with nothing recorded against it would serialise as NaN,
            // straight into a config Hyprland executes.
            if (!s || root.overrides[id] === undefined) continue;
            let node = tree;
            for (let i = 0; i < s.path.length - 1; i++) {
                const key = s.path[i];
                if (node[key] === undefined) node[key] = ({});
                node = node[key];
            }
            node[s.path[s.path.length - 1]] = root.literal(s, root.overrides[id]);
            count++;
        }

        if (count === 0) return "";

        function render(node, depth) {
            const pad = indent + "    ".repeat(depth);
            const rows = Object.keys(node).sort().map(k => {
                const v = node[k];
                return typeof v === "string"
                    ? `${pad}    ${k} = ${v}`
                    : `${pad}    ${k} = {\n${render(v, depth + 1)}\n${pad}    }`;
            });
            return rows.join(",\n");
        }

        return `${indent}hl.config({\n${render(tree, 0)}\n${indent}})`;
    }

    /// `hyprctl keyword` refuses to work against a Lua config ("keyword can't
    /// work with non-legacy parsers. Use eval."), so live preview goes through
    /// eval with the same call the block will hold.
    /// Ids whose live preview has not reached the compositor yet.
    property var applyQueue: ({})

    function apply(id: string): void {
        root.applyQueue[id] = true;
        // Leading edge, so the first movement of a drag is immediate...
        if (applyThrottle.running) return;
        root.flushApply();
        applyThrottle.start();
    }

    /// One eval for everything queued since the last one.
    function flushApply(): void {
        const ids = Object.keys(root.applyQueue);
        if (ids.length === 0) return;
        root.applyQueue = ({});
        Quickshell.execDetached(["hyprctl", "eval", root.configCall(ids, "")]);
        refresh.restart();
    }

    // ...and then at most one eval per interval while it continues. The
    // trailing flush guarantees the value you release on is the one that lands.
    Timer {
        id: applyThrottle
        interval: 50
        onTriggered: {
            if (Object.keys(root.applyQueue).length === 0) return;
            root.flushApply();
            applyThrottle.start();
        }
    }

    // ── Palette ────────────────────────────────────────────────────────────
    /// Hyprland's border and shadow are drawn in the same ink the shell draws
    /// with, so they have to flip when it does. general.lua holds the light
    /// values; this pushes whatever is current over the top, through the same
    /// `eval` the settings above use.
    ///
    /// It is a push rather than something Hyprland reads because a Lua config
    /// is executed once at load and has no way to notice a JSON file changing
    /// underneath it. `hyprctl reload` therefore drops this — shell.qml calls
    /// it again at startup, which is when a reload lands anyway, and on every
    /// change after that.
    function syncPalette(): void {
        // Borders take the ink; shadows take the shadow colour. They are not
        // the same value — see AGENTS.md "Shadows do not follow the ink".
        const ink = String(Theme.color.ink).replace("#", "");
        const shadow = String(Theme.shadow.color).replace("#", "");
        Quickshell.execDetached(["hyprctl", "eval",
            "hl.config({ general = { col = { "
            + `active_border = "rgba(${ink}ff)", inactive_border = "rgba(${ink}66)" `
            + "} }, decoration = { shadow = { "
            + `color = "rgba(${shadow}ff)", color_inactive = "rgba(${shadow}55)" `
            + "} } })"]);
    }


    function set(id: string, value): void {
        const next = Object.assign({}, root.overrides);
        next[id] = value;
        root.overrides = next;

        // Show the new value at once, rather than waiting for `probe` to read
        // it back from the compositor 400ms later. The probe still wins; this
        // only fills the gap. See AGENTS.md "Live-preview cost".
        const shown = Object.assign({}, root.values);
        shown[id] = value;
        root.values = shown;

        root.apply(id);
        writeDebounce.restart();
    }

    function reset(id: string): void {
        const next = Object.assign({}, root.overrides);
        delete next[id];
        root.overrides = next;
        root.write();
        // Nothing to eval back to: only re-reading the config restores what the
        // files actually say.
        reloadDebounce.restart();
    }

    function resetAll(): void {
        root.overrides = ({});
        root.write();
        reloadDebounce.restart();
    }

    Timer {
        id: writeDebounce
        // Dragging a slider evals on every step but must not rewrite the file
        // on every step.
        interval: 500
        onTriggered: root.write()
    }

    Timer {
        id: reloadDebounce
        interval: 250
        onTriggered: {
            Quickshell.execDetached(["hyprctl", "reload"]);
            // The reload is what restores a reset value, so the cached reading
            // is stale until it has happened — re-probe once it has.
            refresh.restart();
        }
    }

    Timer {
        id: refresh
        interval: 400
        onTriggered: probe.running = true
    }

    // ── The block in custom/general.lua ────────────────────────────────────
    property bool applying: false

    function parseBlock(text: string): var {
        const b = text.indexOf(root.blockBegin);
        const e = text.indexOf(root.blockEnd);
        if (b === -1 || e === -1 || e < b) return ({});

        const block = text.slice(b, e);
        const out = ({});
        // The ids are recorded in a comment line, because the nested hl.config
        // below cannot be read back unambiguously by pattern alone.
        const re = /--\s*@([\w]+)\s*=\s*(\S+)/g;
        let m;
        while ((m = re.exec(block)) !== null) {
            const s = root.find(m[1]);
            if (!s) continue;
            out[m[1]] = s.type === "bool" ? m[2] === "true" : Number(m[2]);
        }
        return out;
    }

    function renderBlock(): string {
        const ids = Object.keys(root.overrides).sort();
        const manifest = ids.map(id => `-- @${id} = ${root.overrides[id]}`).join("\n");

        return `-- ${root.blockBegin} (managed by the dashboard) >>>\n`
            + "-- Written last on purpose, so it wins over anything above it.\n"
            + "-- The @lines are how the Settings tab reads these back; keep them\n"
            + "-- with the values they describe, or delete the whole block to\n"
            + "-- hand every one of these settings back to your own config.\n"
            + manifest + "\n"
            + root.configCall(ids, "") + "\n"
            + `-- ${root.blockEnd} <<<`;
    }

    function spliceBlock(text: string): string {
        const empty = Object.keys(root.overrides).length === 0;
        const block = empty ? "" : root.renderBlock();
        const b = text.indexOf(root.blockBegin);
        const e = text.indexOf(root.blockEnd);

        if (b === -1 || e === -1 || e < b) {
            if (empty) return text;
            const rest = text.replace(/\n+$/, "");
            return rest.trim() === "" ? block + "\n" : `${rest}\n\n${block}\n`;
        }

        const start = text.lastIndexOf("\n", b) + 1;
        let stop = text.indexOf("\n", e);
        stop = stop === -1 ? text.length : stop + 1;

        const head = text.slice(0, start);
        const tail = text.slice(stop);
        if (empty) {
            return (head + tail).replace(/\n{3,}/g, "\n\n").replace(/\n+$/, "\n");
        }
        return head + block + "\n" + tail;
    }

    function write(): void {
        if (!root.ready) {
            console.warn("Appearance: refusing to write before the files have loaded");
            return;
        }
        root.applying = true;
        let current = "";
        try {
            current = file.text() || "";
        } catch (e) {
            current = "";
        }
        file.setText(root.spliceBlock(current));
    }

    FileView {
        id: file

        path: `${root.hyprDir}/custom/general.lua`
        watchChanges: true
        printErrors: false
        atomicWrites: true
        preload: true

        onLoaded: {
            root.overridesLoaded = true;
            if (root.applying) return;
            root.overrides = root.parseBlock(this.text());
        }
        onFileChanged: this.reload()
        onLoadFailed: {
            root.overrides = ({});
            root.overridesLoaded = true;
        }
        onSaved: root.applying = false
        onSaveFailed: {
            root.applying = false;
            console.warn("Appearance: could not write", this.path);
        }
    }

    // ── What Hyprland actually has ─────────────────────────────────────────
    Process {
        id: probe

        // One shell, one pass: a Process per setting would be thirteen spawns
        // every time the tab is opened.
        command: ["sh", "-c",
            "for o in " + root.settings.map(s => s.option).join(" ")
            + "; do printf '%s\\t' \"$o\"; hyprctl getoption \"$o\" -j; echo; done"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const out = ({});
                for (const line of this.text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab === -1) continue;

                    const option = line.slice(0, tab).trim();
                    const setting = root.settings.find(s => s.option === option);
                    if (!setting) continue;

                    let parsed;
                    try {
                        parsed = JSON.parse(line.slice(tab + 1));
                    } catch (e) {
                        continue;
                    }

                    if (setting.type === "bool") {
                        out[setting.id] = parsed.bool === true;
                    } else if (parsed.css !== undefined) {
                        // Gaps answer as a CSS box ("10 10 10 10"); the panel
                        // sets all four together, so the first is the value.
                        out[setting.id] = Number(String(parsed.css).split(/\s+/)[0]);
                    } else {
                        const v = parsed.int !== undefined ? parsed.int : parsed.float;
                        if (v !== undefined) out[setting.id] = Number(v);
                    }
                }

                root.values = out;
                root.valuesLoaded = true;
            }
        }
    }
}

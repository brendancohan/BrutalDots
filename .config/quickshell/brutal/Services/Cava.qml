pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.Config

/**
 * Live audio levels from `cava`, for the mini player's visualiser.
 *
 * cava reads the output device directly rather than the player, so the bars
 * follow whatever is actually audible — including a video in a browser tab
 * that publishes no MPRIS metadata at all.
 *
 * It is refcounted and only runs while something is on screen to show it:
 * a 60fps process polling the audio device is not worth its battery cost for
 * a panel nobody has open. Call `subscribe()` when a surface appears and
 * `release()` when it goes.
 */
Singleton {
    id: root

    readonly property int bars: Math.max(4, Settings.data.media.visualizerBars)

    /// Levels, 0.0 - 1.0, `bars` of them. Empty when cava is not running.
    property list<real> values: []

    property int subscribers: 0
    readonly property bool active: root.subscribers > 0

    function subscribe(): void { root.subscribers++; }
    function release(): void { root.subscribers = Math.max(0, root.subscribers - 1); }

    /// Whether cava is actually producing frames. False also covers "cava is
    /// not installed", which is a normal state, not a fault.
    readonly property bool running: proc.running && root.values.length > 0

    onActiveChanged: {
        if (!root.active) root.values = [];
    }

    // ── Config ──────────────────────────────────────────────────────────────
    // cava only takes settings from a file, so one gets written next to the
    // rest of our state. Rewritten whenever the bar count changes.

    readonly property string configPath:
        `${Quickshell.env("HOME")}/.local/state/brutaldots/cava.conf`

    readonly property string configText: `[general]
mode = normal
framerate = 60
autosens = 1
bars = ${root.bars}

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = ${root.scale}
channels = mono
mono_option = average

[smoothing]
noise_reduction = ${Settings.data.media.visualizerSmoothing}
`

    readonly property int scale: 100

    property bool configReady: false

    FileView {
        id: config
        path: root.configPath
        printErrors: false
        onSaved: root.configReady = true
        onSaveFailed: error => {
            console.warn("Cava: could not write", root.configPath, error);
            root.configReady = false;
        }
    }

    function writeConfig(): void {
        root.configReady = false;
        config.setText(root.configText);
    }

    onConfigTextChanged: root.writeConfig()
    Component.onCompleted: root.writeConfig()

    // ── The process ─────────────────────────────────────────────────────────

    Process {
        id: proc

        // Waiting on configReady matters: cava reads the file once at startup,
        // so starting it against a half-written config gives the wrong bar
        // count for the life of the process.
        running: root.active && root.configReady
        command: ["cava", "-p", root.configPath]

        onExited: code => {
            root.values = [];
            // 127 is "not installed", which the UI already handles by drawing a
            // flat baseline; anything else is worth a line in the log.
            if (code !== 0 && code !== 127 && root.active)
                console.warn("Cava: exited with", code);
        }

        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(";");
                const out = [];
                for (const p of parts) {
                    if (p === "") continue;
                    const n = parseFloat(p);
                    if (!isNaN(n)) out.push(Math.min(1, n / root.scale));
                }
                if (out.length > 0) root.values = out;
            }
        }
    }
}

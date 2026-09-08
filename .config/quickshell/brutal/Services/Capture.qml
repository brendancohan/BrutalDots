pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.Config

/**
 * Screenshots and screen recording.
 *
 * The region picker is a separate Process from the encoder. See AGENTS.md
 * "Quickshell" — running them as one shell makes the tracked pid the wrong
 * process, and the stop signal then goes nowhere.
 */
Singleton {
    id: root

    readonly property string directory: Settings.data.capture.directory !== ""
        ? Settings.data.capture.directory
        : `${Quickshell.env("HOME")}/Pictures/Screenshots`

    readonly property bool recording: recorder.running

    function stamp(): string {
        return Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
    }

    function shell(script: string): void {
        Quickshell.execDetached(["sh", "-c", script]);
    }

    /// Everything a shot needs, once a geometry is known. An empty geometry
    /// means the whole focused output.
    function capture(geometry: string): void {
        const file = `${root.directory}/shot-${root.stamp()}.png`;
        const area = geometry === "" ? "" : `-g '${geometry}' `;
        const editor = Settings.data.capture.annotate ? root.annotator() : "";

        let script = `mkdir -p '${root.directory}' && grim ${area}'${file}'`;

        if (editor !== "") {
            script += ` && ${editor} '${file}'`;
        } else {
            script += ` && wl-copy < '${file}'`;
        }

        script += ` && notify-send -a BrutalDots -i '${file}' 'Screenshot' '${file}'`;
        root.shell(script);
    }

    /// satty if it is installed, else swappy, else nothing and the shot is
    /// simply saved.
    function annotator(): string {
        return "sh -c 'if command -v satty >/dev/null; then "
            + "satty --filename \"$1\" --output-filename \"$1\" --early-exit --copy-command wl-copy; "
            + "elif command -v swappy >/dev/null; then swappy -f \"$1\" -o \"$1\"; "
            + "else wl-copy < \"$1\"; fi' _";
    }

    function region(): void {
        const file = `${root.directory}/shot-${root.stamp()}.png`;
        // slurp has to run before grim, and its cancellation must abort the
        // whole thing rather than shooting the full screen.
        root.shell(
            `mkdir -p '${root.directory}'; geom=$(slurp -d) || exit 0; `
            + `[ -n "$geom" ] || exit 0; grim -g "$geom" '${file}' && `
            + (Settings.data.capture.annotate
                ? `${root.annotator()} '${file}'`
                : `wl-copy < '${file}'`)
            + ` && notify-send -a BrutalDots -i '${file}' 'Screenshot' '${file}'`);
    }

    function screen(): void {
        const output = Hyprland.focusedMonitor?.name ?? "";
        const file = `${root.directory}/shot-${root.stamp()}.png`;
        const target = output === "" ? "" : `-o '${output}' `;
        root.shell(
            `mkdir -p '${root.directory}' && grim ${target}'${file}' && `
            + (Settings.data.capture.annotate
                ? `${root.annotator()} '${file}'`
                : `wl-copy < '${file}'`)
            + ` && notify-send -a BrutalDots -i '${file}' 'Screenshot' '${file}'`);
    }

    function window(): void {
        activeWindow.running = false;
        activeWindow.running = true;
    }

    function pickColour(): void {
        // -a copies straight to the clipboard; the notification is the only
        // confirmation the user gets, since there is no picker UI.
        root.shell("hyprpicker -a -f hex "
            + "&& notify-send -a BrutalDots 'Colour picked' \"$(wl-paste)\"");
    }

    function toggleRecording(selectRegion: bool): void {
        // Cancelling the picker counts as stopping. It is the same key that
        // opened it, and from the outside "choose what to record" and
        // "recording" are one action — pressing it again has to end whichever
        // of the two you are in.
        if (regionPicker.running) {
            regionPicker.signal(15);
            return;
        }

        if (recorder.running) {
            // wf-recorder finalises the container on SIGINT; killing it
            // outright leaves an unplayable file.
            recorder.signal(2);
            return;
        }

        if (selectRegion) regionPicker.running = true;
        else root.startRecording("");
    }

    /// Start the encoder. An empty geometry records the focused output whole.
    function startRecording(geometry: string): void {
        const file = `${root.directory}/rec-${root.stamp()}.mp4`;
        const output = Hyprland.focusedMonitor?.name ?? "";

        // Name the output. Handed more than one and no -o, wf-recorder prints a
        // numbered list and blocks reading the choice from stdin — which on a
        // tracked process is a pipe nobody is ever going to write to. Nothing is
        // recorded, the shell shows a recording light because the process is
        // alive, and the stop signal then kills it mid-read rather than closing
        // a capture. A -g carries its own output, so this is only about the
        // whole-screen case. The screenshot path has always passed -o; this is
        // the same call.
        const target = geometry !== ""
            ? `-g '${geometry}' `
            : (output !== "" ? `-o '${output}' ` : "");

        recorder.outputFile = file;
        // `exec` so the tracked pid *is* wf-recorder and the stop signal has
        // nothing to pass through; `< /dev/null` so that if it ever does ask
        // something, EOF makes it exit loudly instead of hanging on the answer.
        recorder.command = ["sh", "-c",
            `mkdir -p '${root.directory}'; `
            + `exec wf-recorder ${target}-f '${file}' < /dev/null`];
        recorder.running = true;
    }

    Process {
        id: activeWindow

        command: ["hyprctl", "activewindow", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const info = JSON.parse(this.text);
                    if (!info.at || !info.size) return;
                    root.capture(`${info.at[0]},${info.at[1]} ${info.size[0]}x${info.size[1]}`);
                } catch (e) {
                    console.warn("Capture: could not read the active window -", e);
                }
            }
        }
    }

    Process {
        id: regionPicker

        // `< /dev/null`, and it is not optional. slurp reads a list of
        // predefined rectangles from standard input whenever that input is not
        // a TTY, and Quickshell hands every tracked process a pipe — so a bare
        // ["slurp"] blocks forever on a pipe nobody writes to or closes, never
        // maps its surface, and looks from the outside like the key did
        // nothing. /dev/null is an immediate EOF: no predefined rectangles,
        // straight to the selector.
        //
        // The screenshot pickers avoid this by accident rather than by design —
        // they go through `execDetached`, which gives the child /dev/null
        // already. This is the only slurp the shell keeps a handle on.
        //
        // `exec` so the tracked pid is slurp itself and cancelling reaches it.
        command: ["sh", "-c", "exec slurp < /dev/null"]

        // A cancelled pick — Escape, or the keybind pressed again — leaves this
        // empty, and an empty geometry must not fall through to recording the
        // whole screen. There is no `onExited` for the same reason: the only
        // thing that starts an encoder is a geometry that actually arrived.
        stdout: StdioCollector {
            onStreamFinished: {
                const geometry = this.text.trim();
                if (geometry !== "") root.startRecording(geometry);
            }
        }
    }

    Process {
        id: recorder

        property string outputFile: ""

        // Both streams: wf-recorder puts its refusals on stdout, not stderr —
        // "Failed to select output, exiting" arrives there — so collecting only
        // stderr leaves a failure with nothing to say but its exit code.
        stdout: StdioCollector { id: recorderOut }
        stderr: StdioCollector { id: recorderErr }

        // wf-recorder traps SIGINT, finalises the container and exits 0, so a
        // clean stop is a zero and nothing else needs special-casing. In
        // particular there is no 128+n here: a process Quickshell sees killed by
        // a signal reports the raw signal number as its exit code, so the shell
        // convention 130 would never have matched anything.
        onExited: code => {
            if (code === 0) {
                Quickshell.execDetached(["notify-send", "-a", "BrutalDots",
                    "Recording saved", recorder.outputFile]);
                return;
            }
            // Saying nothing here is how "the key does nothing" happens: the
            // light goes out and there is no file, with no way to tell whether
            // it recorded and failed to save or never started at all.
            const said = (recorderErr.text.trim() || recorderOut.text.trim())
                .split("\n").pop().trim();
            const why = code === 127
                ? "wf-recorder is not installed"
                : (said || `exited ${code}`);
            console.warn("Capture: recording failed -", why);
            Quickshell.execDetached(["notify-send", "-a", "BrutalDots", "-u", "critical",
                "Recording failed", why]);
        }
    }
}

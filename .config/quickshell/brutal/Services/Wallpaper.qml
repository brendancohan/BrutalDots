pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.Config

/**
 * Resolves which image the desktop shows, and lists what else is available.
 *
 * Never launches anything — Modules/Wallpaper/Backdrop draws it. The
 * existence check lives here so it runs once rather than once per monitor.
 */
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME") ?? ""

    /// Hand-written settings say `~/Pictures/…`; nothing downstream expands
    /// that, and a file:// URL with a tilde in it simply fails to load.
    function expand(path: string): string {
        if (path === "~") return root.home;
        if (path.startsWith("~/")) return root.home + path.slice(1);
        if (path.startsWith("$HOME/")) return root.home + path.slice(5);
        return path;
    }

    // ── The current wallpaper ───────────────────────────────────────────────

    /// An explicit setting wins, then the environment variable the Hyprland
    /// config reads, then the conventional drop-in location.
    readonly property string candidate: {
        const configured = Settings.data.wallpaper.path;
        if (configured !== "") return root.expand(configured);

        const fromEnv = Quickshell.env("BRUTALDOTS_WALLPAPER");
        if (fromEnv) return root.expand(fromEnv);

        return `${root.home}/.config/brutaldots/wallpaper`;
    }

    /// The candidate, but only once it is known to exist. Empty means "draw
    /// the generated backdrop instead".
    property string path: ""

    /// Set while a probe is in flight and the candidate has moved on again.
    property bool pending: false

    /// Restarting the Process mid-flight would let the *previous* run's exit
    /// code land on the *new* candidate — which is how a file that does not
    /// exist ends up in `path`, and how the backdrop ends up asking QML to
    /// open it. One probe at a time, and its result belongs to the path it
    /// actually tested.
    function recheck(): void {
        if (probe.running) {
            root.pending = true;
            return;
        }
        probe.target = root.candidate;
        probe.running = true;
    }

    onCandidateChanged: root.recheck()

    Process {
        id: probe

        /// Deliberately not bound to `candidate`: this has to stay pinned to
        /// what the running `test` was given.
        property string target: ""

        command: ["test", "-f", probe.target]
        onExited: code => {
            root.path = code === 0 ? probe.target : "";
            if (!root.pending) return;
            root.pending = false;
            root.recheck();
        }
    }

    // The wallpaper directory is usually on disk before the shell starts, but
    // a fresh install may not have one; scanning at startup means the picker is
    // populated the first time it is opened rather than after it.
    Component.onCompleted: {
        root.recheck();
        root.rescan();
    }

    /// Persist a choice. Settings writes through to disk, so the change
    /// survives a restart, and the binding above repaints every monitor.
    function select(file: string): void {
        Settings.data.wallpaper.path = file;
    }

    /// Go back to the generated pattern.
    function clear(): void {
        Settings.data.wallpaper.path = "";
    }

    // ── What the picker can offer ───────────────────────────────────────────

    readonly property string directory: root.expand(Settings.data.wallpaper.directory)

    /// Absolute paths, sorted by name. Empty until the first scan finishes.
    property list<string> available: []
    property bool scanning: false

    /// Formats QML's Image can decode. Videos are deliberately absent: the
    /// backdrop is an Image, so a video here would be a black rectangle.
    readonly property var extensions: ["png", "jpg", "jpeg", "webp", "bmp", "gif", "avif"]

    function basename(file: string): string {
        return file.slice(file.lastIndexOf("/") + 1);
    }

    /// Filename without the extension, which is what the picker labels tiles
    /// with — the extension is noise when every tile is an image.
    function title(file: string): string {
        const name = root.basename(file);
        const dot = name.lastIndexOf(".");
        return dot > 0 ? name.slice(0, dot) : name;
    }

    function rescan(): void {
        if (scan.running) scan.running = false;
        scan.running = true;
    }

    onDirectoryChanged: root.rescan()

    Process {
        id: scan

        // -maxdepth 2 so one level of subfolders is picked up without walking
        // a whole photo library. `sort -z` keeps newlines in filenames safe.
        command: ["sh", "-c",
            `find "$1" -maxdepth 2 -type f \\( `
            + root.extensions.map(e => `-iname "*.${e}"`).join(" -o ")
            + ` \\) -print0 2>/dev/null | sort -z`,
            "sh", root.directory]

        onRunningChanged: root.scanning = scan.running

        stdout: StdioCollector {
            onStreamFinished: {
                const found = text.split("\0").filter(f => f !== "");
                root.available = found;
            }
        }
    }

}

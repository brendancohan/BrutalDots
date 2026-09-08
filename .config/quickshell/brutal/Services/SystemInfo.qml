pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * System telemetry for the bar and dashboard.
 *
 * Fast-moving values (CPU, memory) are read straight out of /proc on a short
 * timer — no subprocess per tick. Slow, expensive facts (disk, package count,
 * distro name) are shelled out for far less often, or only once at startup.
 */
Singleton {
    id: root

    // ── Live metrics ───────────────────────────────────────────────────────
    property real cpuUsage: 0        // 0.0 - 1.0
    property real memoryUsage: 0     // 0.0 - 1.0
    property real diskUsage: 0       // 0.0 - 1.0
    property real memoryUsedGb: 0
    property real memoryTotalGb: 0
    property string diskUsedText: ""

    // ── Static-ish facts ───────────────────────────────────────────────────
    property string osName: "Linux"
    property string kernel: ""
    property string wm: "Hyprland"
    property string wmVersion: ""
    property string shell: ""
    property string host: "localhost"
    property string packages: "0"
    property string uptime: ""

    // Previous /proc/stat totals, for the usage delta.
    property real _lastIdle: 0
    property real _lastTotal: 0

    // ── CPU ────────────────────────────────────────────────────────────────
    FileView {
        id: procStat
        path: "/proc/stat"
        onLoaded: {
            const line = text().split("\n")[0];          // aggregate "cpu" row
            const f = line.split(/\s+/).slice(1).map(Number);
            if (f.length < 4) return;

            const idle = f[3] + (f[4] ?? 0);             // idle + iowait
            const total = f.reduce((a, b) => a + b, 0);
            const dIdle = idle - root._lastIdle;
            const dTotal = total - root._lastTotal;

            if (root._lastTotal > 0 && dTotal > 0) {
                root.cpuUsage = Math.max(0, Math.min(1, 1 - dIdle / dTotal));
            }
            root._lastIdle = idle;
            root._lastTotal = total;
        }
    }

    // ── Memory ─────────────────────────────────────────────────────────────
    FileView {
        id: procMem
        path: "/proc/meminfo"
        onLoaded: {
            const kv = {};
            for (const line of text().split("\n")) {
                const m = line.match(/^(\w+):\s+(\d+)/);
                if (m) kv[m[1]] = parseInt(m[2], 10);
            }
            const total = kv.MemTotal ?? 0;
            const avail = kv.MemAvailable ?? kv.MemFree ?? 0;
            if (total <= 0) return;

            root.memoryTotalGb = total / 1048576;
            root.memoryUsedGb = (total - avail) / 1048576;
            root.memoryUsage = (total - avail) / total;
        }
    }

    // ── Uptime ─────────────────────────────────────────────────────────────
    FileView {
        id: procUptime
        path: "/proc/uptime"
        onLoaded: {
            const secs = parseFloat(text().split(" ")[0]);
            if (isNaN(secs)) return;
            const h = Math.floor(secs / 3600);
            const m = Math.floor((secs % 3600) / 60);
            root.uptime = h > 0 ? `${h}H ${m}M` : `${m}M`;
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            procStat.reload();
            procMem.reload();
            procUptime.reload();
        }
    }

    // ── Disk ───────────────────────────────────────────────────────────────
    Process {
        id: dfProc
        command: ["sh", "-c", "df -B1 --output=used,size / | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(/\s+/).map(Number);
                if (p.length < 2 || !p[1]) return;
                root.diskUsage = p[0] / p[1];
                const gb = v => (v / 1073741824).toFixed(0);
                root.diskUsedText = `${gb(p[0])}G / ${gb(p[1])}G`;
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: dfProc.running = true
    }

    // ── Package count ──────────────────────────────────────────────────────
    // Covers the common package managers; first one that exists wins.
    Process {
        id: pkgProc
        command: ["sh", "-c",
            "if command -v pacman >/dev/null; then pacman -Qq | wc -l;" +
            "elif command -v dpkg-query >/dev/null; then dpkg-query -f '.\\n' -W | wc -l;" +
            "elif command -v rpm >/dev/null; then rpm -qa | wc -l;" +
            "elif command -v xbps-query >/dev/null; then xbps-query -l | wc -l;" +
            "else echo 0; fi"]
        stdout: StdioCollector {
            onStreamFinished: root.packages = text.trim() || "0"
        }
    }

    Timer {
        interval: 600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: pkgProc.running = true
    }

    // ── One-shot identity ──────────────────────────────────────────────────
    Process {
        running: true
        command: ["sh", "-c",
            ". /etc/os-release 2>/dev/null; echo \"${NAME:-Linux}\"; " +
            "uname -r; uname -n; basename \"${SHELL:-sh}\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                root.osName = l[0] ?? "Linux";
                root.kernel = l[1] ?? "";
                root.host = l[2] ?? "localhost";
                root.shell = l[3] ?? "";
            }
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "hyprctl version -j 2>/dev/null | sed -n 's/.*\"tag\": *\"\\([^\"]*\\)\".*/\\1/p' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wmVersion = text.trim().replace(/^v/, "");
            }
        }
    }
}

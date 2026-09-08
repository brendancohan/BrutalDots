pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.Config

/**
 * Pomodoro timer and stopwatch.
 *
 * Durations come from settings.json. Completing a focus round advances to a
 * break automatically, and every fourth round takes the long break.
 */
Singleton {
    id: root

    enum Phase { Focus, ShortBreak, LongBreak }

    property int phase: Pomodoro.Phase.Focus
    property bool running: false
    property int remaining: root.duration(root.phase) * 60
    property int completedRounds: 0

    /// Stopwatch, kept independent of the pomodoro state.
    property bool stopwatchRunning: false
    property int stopwatchElapsed: 0

    readonly property int total: root.duration(root.phase) * 60
    readonly property real progress:
        root.total > 0 ? 1 - (root.remaining / root.total) : 0

    readonly property string phaseLabel: {
        switch (root.phase) {
            case Pomodoro.Phase.Focus: return "FOCUS SESSION";
            case Pomodoro.Phase.ShortBreak: return "SHORT BREAK";
            default: return "LONG BREAK";
        }
    }

    readonly property color phaseColor: {
        switch (root.phase) {
            case Pomodoro.Phase.Focus: return Theme.color.pink;
            case Pomodoro.Phase.ShortBreak: return Theme.color.green;
            default: return Theme.color.blue;
        }
    }

    function duration(phase: int): int {
        const p = Settings.data.pomodoro;
        switch (phase) {
            case Pomodoro.Phase.Focus: return p.focus;
            case Pomodoro.Phase.ShortBreak: return p.shortBreak;
            default: return p.longBreak;
        }
    }

    function format(seconds: int): string {
        const m = Math.floor(Math.max(0, seconds) / 60);
        const s = Math.max(0, seconds) % 60;
        return `${m.toString().padStart(2, "0")}:${s.toString().padStart(2, "0")}`;
    }

    readonly property string display: root.format(root.remaining)
    readonly property string stopwatchDisplay: root.format(root.stopwatchElapsed)

    function start(): void { root.running = true; }
    function pause(): void { root.running = false; }
    function toggle(): void { root.running = !root.running; }

    function reset(): void {
        root.running = false;
        root.remaining = root.duration(root.phase) * 60;
    }

    function setPhase(phase: int): void {
        root.phase = phase;
        root.reset();
    }

    /// Move to whatever should come next, without starting it.
    function advance(): void {
        if (root.phase === Pomodoro.Phase.Focus) {
            root.completedRounds++;
            const long = root.completedRounds % Settings.data.pomodoro.roundsBeforeLong === 0;
            root.setPhase(long ? Pomodoro.Phase.LongBreak : Pomodoro.Phase.ShortBreak);
        } else {
            root.setPhase(Pomodoro.Phase.Focus);
        }
    }

    function toggleStopwatch(): void { root.stopwatchRunning = !root.stopwatchRunning; }
    function resetStopwatch(): void {
        root.stopwatchRunning = false;
        root.stopwatchElapsed = 0;
    }

    Timer {
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: {
            if (root.remaining > 0) {
                root.remaining--;
            } else {
                root.advance();
            }
        }
    }

    Timer {
        interval: 1000
        running: root.stopwatchRunning
        repeat: true
        onTriggered: root.stopwatchElapsed++
    }

    // Picking up an edited settings.json should refresh an idle timer.
    Connections {
        target: Settings.data.pomodoro
        function onFocusChanged(): void { if (!root.running) root.reset(); }
    }
}

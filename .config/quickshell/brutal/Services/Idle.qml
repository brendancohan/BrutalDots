pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.Config

/**
 * Idle handling, done in the shell rather than by hypridle — one config, and
 * the same lock screen the power menu uses.
 *
 * Each step is an independent monitor: dim, lock, screen off, suspend. A
 * timeout of 0 is off. `respectInhibitors` honours a video player's idle
 * inhibitor; `inhibited` is the bar's coffee button. Preview mode disables
 * the lot.
 */
Singleton {
    id: root

    property bool inhibited: false

    readonly property var config: Settings.data.idle
    readonly property bool dimmed: dim.isIdle

    /// A fullscreen window is nearly always a game or a video. Games in
    /// particular are read over evdev — the compositor never sees a gamepad,
    /// so its idle timer runs to completion in the middle of play, and the
    /// session dims at `dimAfter` and locks at `lockAfter` while you are
    /// actively using it. Video players take a real idle inhibitor and are
    /// already covered by `respectInhibitors`; games almost never do.
    ///
    /// Scoped to the *focused* workspace on purpose: a fullscreen game left
    /// running on another workspace should not keep the machine awake once you
    /// have moved on from it.
    readonly property bool fullscreenInhibited:
        root.config.inhibitFullscreen
        && (Hyprland.focusedWorkspace?.hasFullscreen ?? false)

    /// Every step is gated on this, so there is one place to look when idle
    /// handling is not firing.
    readonly property bool active:
        !root.inhibited && !root.fullscreenInhibited && !Env.preview

    function toggleInhibit(): void { root.inhibited = !root.inhibited; }

    function lockNow(): void { ShellState.locked = true; }

    /// Hyprland's Lua config format takes a dispatcher expression rather than
    /// a bare name, so `hyprctl dispatch dpms off` is rejected outright (it
    /// exits 7). The plain form is kept as a fallback for anyone running this
    /// shell against a .conf-based Hyprland.
    function dpms(state: string): void {
        Quickshell.execDetached(["sh", "-c",
            `hyprctl dispatch 'hl.dsp.dpms("${state}")' >/dev/null 2>&1 `
            + `|| hyprctl dispatch dpms ${state}`]);
    }

    IdleMonitor {
        id: dim

        enabled: root.active && root.config.dimAfter > 0
        timeout: root.config.dimAfter
        respectInhibitors: true
    }

    IdleMonitor {
        enabled: root.active && root.config.lockAfter > 0
        timeout: root.config.lockAfter
        respectInhibitors: true
        onIsIdleChanged: {
            if (this.isIdle) root.lockNow();
        }
    }

    // DPMS is toggled rather than latched: coming back from idle has to turn
    // the panels on again, or the session looks dead until a mode switch.
    IdleMonitor {
        enabled: root.active && root.config.screenOffAfter > 0
        timeout: root.config.screenOffAfter
        respectInhibitors: true
        onIsIdleChanged: root.dpms(this.isIdle ? "off" : "on")
    }

    IdleMonitor {
        enabled: root.active && root.config.suspendAfter > 0
        timeout: root.config.suspendAfter
        respectInhibitors: true
        onIsIdleChanged: {
            if (this.isIdle) Quickshell.execDetached(["systemctl", "suspend"]);
        }
    }
}

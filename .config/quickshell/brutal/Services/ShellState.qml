pragma Singleton

import Quickshell
import QtQuick

/// Cross-module UI state: which overlays are open, and how they toggle.
Singleton {
    id: root

    property bool dashboardOpen: false

    /// Which pane the dashboard is showing: "overview" | "settings" |
    /// "keybinds". Reset on
    /// close, so reopening always lands on the overview rather than wherever
    /// you happened to leave it.
    property string dashboardTab: "overview"
    property bool widgetsOpen: false
    property bool powerMenuOpen: false
    property bool notificationsOpen: false

    /// "apps" | "run" | "clipboard"
    property string launcherMode: "apps"
    property bool launcherOpen: false

    property bool wallpaperPickerOpen: false
    property bool mediaOpen: false
    property bool bluetoothOpen: false
    property bool audioOpen: false
    property bool wifiOpen: false

    /// How far down the screen the bar reaches, shadow included — what the
    /// mini player anchors under. Written by Bar, which is the only thing that
    /// knows the islands' measured height. Every monitor's bar computes the
    /// identical number (it depends only on settings and theme), so them all
    /// writing it is harmless.
    property int barBottom: 0

    /// Set by the lock module; read by anything that must stay quiet while the
    /// session is locked (toasts, the OSD).
    property bool locked: false

    // Every close path assigns `dashboardOpen` directly — Escape, the scrim,
    // closeAll — so the reset hangs off the property rather than off toggle().
    onDashboardOpenChanged: {
        if (!root.dashboardOpen) root.dashboardTab = "overview";
    }

    function toggleDashboard(): void {
        root.dashboardOpen = !root.dashboardOpen;
    }

    function toggleWidgets(): void { root.widgetsOpen = !root.widgetsOpen; }
    function togglePowerMenu(): void { root.powerMenuOpen = !root.powerMenuOpen; }
    function toggleNotifications(): void { root.notificationsOpen = !root.notificationsOpen; }

    /// Opening in a mode that is already showing closes the launcher, so the
    /// same key both summons and dismisses it.
    function openLauncher(mode: string): void {
        if (root.launcherOpen && root.launcherMode === mode) {
            root.launcherOpen = false;
            return;
        }
        root.launcherMode = mode;
        root.launcherOpen = true;
    }

    function closeLauncher(): void { root.launcherOpen = false; }

    function toggleWallpaperPicker(): void {
        root.wallpaperPickerOpen = !root.wallpaperPickerOpen;
    }

    function closeWallpaperPicker(): void { root.wallpaperPickerOpen = false; }

    function toggleMedia(): void { root.mediaOpen = !root.mediaOpen; }
    function closeMedia(): void { root.mediaOpen = false; }

    function toggleBluetooth(): void { root.bluetoothOpen = !root.bluetoothOpen; }
    function closeBluetooth(): void { root.bluetoothOpen = false; }

    function toggleAudio(): void { root.audioOpen = !root.audioOpen; }
    function closeAudio(): void { root.audioOpen = false; }

    function toggleWifi(): void { root.wifiOpen = !root.wifiOpen; }
    function closeWifi(): void { root.wifiOpen = false; }

    function closeAll(): void {
        root.dashboardOpen = false;
        root.widgetsOpen = false;
        root.powerMenuOpen = false;
        root.notificationsOpen = false;
        root.launcherOpen = false;
        root.wallpaperPickerOpen = false;
        root.mediaOpen = false;
        root.bluetoothOpen = false;
        root.audioOpen = false;
        root.wifiOpen = false;
    }
}

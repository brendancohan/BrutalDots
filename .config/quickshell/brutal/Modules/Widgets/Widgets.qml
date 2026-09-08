import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Config
import qs.Components
import qs.Services
import qs.Modules.Common

/**
 * The desktop widget layer.
 *
 * Defaults to the top layer so toggling it from the bar is actually visible.
 * Set `widgets.layer` to "bottom" in settings.json for true desktop widgets
 * that sit beneath every window.
 * Toggled from the bar's Tasks button, or `ipc call shell widgets`.
 */
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData

        readonly property bool onFocusedMonitor: Hyprland.focusedMonitor
            ? Hyprland.focusedMonitor.name === win.modelData.name
            : true

        /// True desktop widgets, sitting under every window, rather than a
        /// panel you toggle on top of your work.
        readonly property bool desktopLayer: Settings.data.widgets.layer === "bottom"

        screen: win.modelData
        visible: ShellState.widgetsOpen && !ShellState.locked && win.onFocusedMonitor
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // exclusiveZone 0 with Normal mode means: reserve nothing, but stay
        // clear of surfaces that do reserve space (the bar).
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        WlrLayershell.layer: win.desktopLayer ? WlrLayer.Bottom : WlrLayer.Top
        WlrLayershell.keyboardFocus: win.desktopLayer
            ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "brutaldots-widgets"

        readonly property int edge: Theme.space.xl
        readonly property int columnWidth: Math.min(390, win.width * 0.26)

        // PanelWindow is a window, not an Item, so the fade lives on a content
        // wrapper rather than on the surface itself.
        FocusScope {
            id: layer

            anchors.fill: parent
            // Nothing to focus on the desktop layer: it never holds the
            // keyboard, so it must not claim focus away from a real window.
            focus: !win.desktopLayer
            Keys.onEscapePressed: ShellState.widgetsOpen = false

            opacity: ShellState.widgetsOpen ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: Theme.anim.normal } }

            // ── Left column: tasks and timer ───────────────────────────────────
            ColumnLayout {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: win.edge
                    topMargin: win.edge
                    bottomMargin: win.edge
                }
                width: win.columnWidth
                spacing: Theme.space.lg

                TasksWidget {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 260
                }

                PomodoroWidget {
                    Layout.fillWidth: true
                }

                Item { Layout.fillHeight: true }
            }

            // ── Centre: now playing ────────────────────────────────────────────
            MediaPlayer {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: win.edge
                }
                width: Math.min(430, win.width * 0.3)
                visible: Players.hasPlayer
            }

            // ── Right column: clock, calendar, weather ─────────────────────────
            ColumnLayout {
                anchors {
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    // Inset by the shadow too; it only extends right.
                    rightMargin: win.edge + Theme.shadow.md
                    topMargin: win.edge
                    bottomMargin: win.edge
                }
                width: win.columnWidth
                spacing: Theme.space.lg

                GreetingCard { Layout.fillWidth: true }
                CalendarWidget { Layout.fillWidth: true }
                WeatherWidget { Layout.fillWidth: true }

                Item { Layout.fillHeight: true }
            }
        }
    }
}

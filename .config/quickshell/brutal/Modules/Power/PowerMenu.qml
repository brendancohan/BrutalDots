import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Config
import qs.Components
import qs.Services

/// Session actions, opened from the bar's power button.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData

        readonly property bool onFocusedMonitor: Hyprland.focusedMonitor
            ? Hyprland.focusedMonitor.name === win.modelData.name
            : true

        screen: win.modelData
        visible: ShellState.powerMenuOpen && win.onFocusedMonitor
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "brutaldots-power"

        readonly property var actions: [
            // Lock does both: the shell's own surface goes up immediately,
            // and logind is told so LockedHint and `loginctl` agree with it.
            { label: "Lock",     glyph: Icons.lock,    tint: Theme.color.blue,     cmd: "loginctl lock-session", lock: true },
            { label: "Suspend",  glyph: Icons.sleep,   tint: Theme.color.lavender, cmd: "systemctl suspend" },
            { label: "Log out",  glyph: Icons.logout,  tint: Theme.color.peach,    cmd: "hyprctl dispatch 'hl.dsp.exit()' || hyprctl dispatch exit" },
            { label: "Reboot",   glyph: Icons.restart, tint: Theme.color.coral,    cmd: "systemctl reboot" },
            { label: "Shutdown", glyph: Icons.power,   tint: Theme.color.red,      cmd: "systemctl poweroff" }
        ]

        Rectangle {
            anchors.fill: parent
            color: Theme.color.overlay

            MouseArea {
                anchors.fill: parent
                onClicked: ShellState.powerMenuOpen = false
            }
        }

        FocusScope {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: ShellState.powerMenuOpen = false

            BrutalBox {
                anchors.centerIn: parent
                // Offset by half the shadow so the panel reads as centred
                // rather than sitting half a shadow to the left.
                anchors.horizontalCenterOffset: -Theme.shadow.lg / 2
                anchors.verticalCenterOffset: -Theme.shadow.lg / 2
                implicitWidth: row.implicitWidth + Theme.space.xl * 2
                implicitHeight: row.implicitHeight + Theme.space.xl * 2
                color: Theme.color.mantle
                radius: Theme.radius.xl
                shadowOffset: Theme.shadow.lg

                scale: ShellState.powerMenuOpen ? 1 : 0.97
                Behavior on scale { NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.curve } }

                MouseArea { anchors.fill: parent }

                RowLayout {
                    id: row
                    anchors.centerIn: parent
                    spacing: Theme.space.lg

                    Repeater {
                        model: win.actions

                        delegate: BrutalButton {
                            id: action

                            required property var modelData

                            implicitWidth: 104
                            implicitHeight: 104
                            radius: Theme.radius.lg
                            baseColor: Theme.color.base
                            hoverColor: action.modelData.tint

                            onClicked: {
                                ShellState.powerMenuOpen = false;
                                if (action.modelData.lock === true) ShellState.locked = true;
                                Quickshell.execDetached(["sh", "-c", action.modelData.cmd]);
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: Theme.space.sm

                                BrutalIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: action.modelData.glyph
                                    font.pixelSize: 34
                                }

                                BrutalText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: action.modelData.label
                                    font.pixelSize: Theme.font.size.sm
                                    font.weight: Theme.font.weight.bold
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

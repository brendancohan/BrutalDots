import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.Config
import qs.Components
import qs.Services

/**
 * Audio devices, hanging under the right island.
 *
 * Output and input are listed separately — picking a headset to listen through
 * and picking its microphone are two different decisions, and PipeWire treats
 * them as two nodes. Application streams are deliberately absent: they are not
 * devices, and routing individual streams belongs in a mixer, not a bar menu.
 */
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData

        readonly property bool onFocusedMonitor: Hyprland.focusedMonitor
            ? Hyprland.focusedMonitor.name === win.modelData.name
            : true

        screen: win.modelData
        visible: ShellState.audioOpen && !ShellState.locked && win.onFocusedMonitor
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
        WlrLayershell.namespace: "brutaldots-audio"

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.closeAudio()
        }

        FocusScope {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: ShellState.closeAudio()

            BrutalBox {
                id: panel

                anchors.top: parent.top
                anchors.topMargin: ShellState.barBottom + Theme.space.sm
                anchors.right: parent.right
                anchors.rightMargin: Settings.data.bar.sideMargin + Theme.shadow.md

                implicitWidth: 340
                implicitHeight: layout.implicitHeight + Theme.space.lg * 2

                color: Theme.color.surface
                radius: Theme.radius.lg
                shadowOffset: Theme.shadow.md

                scale: win.visible ? 1 : 0.96
                Behavior on scale {
                    NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.curve }
                }

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: layout

                    anchors.fill: parent
                    anchors.margins: Theme.space.lg
                    spacing: Theme.space.md

                    // ── Output level ───────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space.sm

                        BrutalBox {
                            implicitWidth: 34
                            implicitHeight: 34
                            radius: Theme.radius.sm
                            shadowOffset: Theme.shadow.sm
                            color: Audio.muted ? Theme.color.base : Theme.color.blue

                            BrutalIcon {
                                anchors.centerIn: parent
                                text: Audio.icon
                                font.pixelSize: Theme.font.size.lg
                                dim: Audio.muted
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Audio.toggleMute()
                            }
                        }

                        BrutalSlider {
                            Layout.fillWidth: true
                            vertical: false
                            value: Audio.volume
                            fillColor: Audio.muted ? Theme.color.subtext : Theme.color.salmon
                            onMoved: v => Audio.setVolume(v)
                        }

                        BrutalText {
                            Layout.preferredWidth: 38
                            horizontalAlignment: Text.AlignRight
                            font.pixelSize: Theme.font.size.xs
                            font.weight: Theme.font.weight.bold
                            text: `${Math.round(Audio.volume * 100)}%`
                        }
                    }

                    // ── Input level ────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space.sm
                        visible: Audio.source !== null

                        BrutalBox {
                            implicitWidth: 34
                            implicitHeight: 34
                            radius: Theme.radius.sm
                            shadowOffset: Theme.shadow.sm
                            color: Audio.micMuted ? Theme.color.base : Theme.color.mint

                            BrutalIcon {
                                anchors.centerIn: parent
                                text: Audio.micMuted ? Icons.micOff : Icons.micOn
                                font.pixelSize: Theme.font.size.lg
                                dim: Audio.micMuted
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Audio.toggleMicMute()
                            }
                        }

                        BrutalSlider {
                            Layout.fillWidth: true
                            vertical: false
                            value: Audio.micVolume
                            fillColor: Audio.micMuted ? Theme.color.subtext : Theme.color.teal
                            onMoved: v => Audio.setMicVolume(v)
                        }

                        BrutalText {
                            Layout.preferredWidth: 38
                            horizontalAlignment: Text.AlignRight
                            font.pixelSize: Theme.font.size.xs
                            font.weight: Theme.font.weight.bold
                            text: `${Math.round(Audio.micVolume * 100)}%`
                        }
                    }

                    BrutalDivider { Layout.fillWidth: true }

                    // ── Devices ────────────────────────────────────────────
                    // A desktop can easily have a dozen sinks and sources
                    // between HDMI, USB and every headset ever plugged in, so
                    // the list scrolls rather than growing the panel off the
                    // bottom of the screen.
                    ClippingRectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(devices.implicitHeight, win.height * 0.45)
                        color: "transparent"
                        radius: Theme.radius.sm

                        Flickable {
                            anchors.fill: parent
                            contentHeight: devices.implicitHeight
                            contentWidth: width
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            flickDeceleration: 6000

                            ColumnLayout {
                                id: devices

                                width: parent.width
                                spacing: Theme.space.md

                                DeviceGroup {
                                    Layout.fillWidth: true
                                    title: "Output"
                                    devices: Audio.sinks
                                    current: Audio.sink
                                    accent: Theme.color.blue
                                    onPicked: node => Audio.setSink(node)
                                }

                                DeviceGroup {
                                    Layout.fillWidth: true
                                    title: "Input"
                                    devices: Audio.sources
                                    current: Audio.source
                                    accent: Theme.color.mint
                                    onPicked: node => Audio.setSource(node)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

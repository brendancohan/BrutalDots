import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Config
import qs.Components
import qs.Services

/**
 * Volume and brightness overlay.
 *
 * Shows only in response to a change, then hides itself. The first value seen
 * after startup is ignored so the OSD doesn't flash on login.
 */
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData

        property string mode: "volume"
        property bool primed: false

        screen: win.modelData
        visible: hideTimer.running && !ShellState.locked
        color: "transparent"

        anchors {
            bottom: true
            left: true
            right: true
        }

        implicitHeight: 110
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "brutaldots-osd"

        function show(mode: string): void {
            if (!win.primed) return;
            win.mode = mode;
            hideTimer.restart();
        }

        Timer {
            id: hideTimer
            interval: 1800
            repeat: false
        }

        // Ignore the initial property settle so nothing pops up at startup.
        Timer {
            interval: 1500
            running: true
            repeat: false
            onTriggered: win.primed = true
        }

        Connections {
            target: Audio
            function onVolumeChanged(): void { win.show("volume"); }
            function onMutedChanged(): void { win.show("volume"); }
        }

        Connections {
            target: Brightness
            function onValueChanged(): void { win.show("brightness"); }
        }

        BrutalBox {
            id: panel

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.space.xl

            implicitWidth: 280
            implicitHeight: 56
            radius: Theme.radius.lg
            color: Theme.color.crust
            shadowOffset: Theme.shadow.md

            readonly property bool isVolume: win.mode === "volume"
            readonly property real value: isVolume ? Audio.volume : Brightness.value
            readonly property color tint: isVolume ? Theme.color.salmon : Theme.color.green

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.space.md
                spacing: Theme.space.md

                BrutalBox {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: Theme.radius.sm
                    color: panel.tint
                    shadowOffset: Theme.shadow.sm

                    BrutalIcon {
                        anchors.centerIn: parent
                        text: panel.isVolume ? Audio.icon : Brightness.icon
                        font.pixelSize: Theme.font.size.lg
                    }
                }

                BrutalProgress {
                    Layout.fillWidth: true
                    value: panel.value
                    fillColor: panel.tint
                    thickness: 16
                }

                BrutalText {
                    text: `${Math.round(panel.value * 100)}%`
                    font.pixelSize: Theme.font.size.sm
                    font.weight: Theme.font.weight.bold
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 38
                }
            }
        }
    }
}

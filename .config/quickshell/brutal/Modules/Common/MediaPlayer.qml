import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import qs.Config
import qs.Components
import qs.Services

/// Now playing: art, track, dotted seek bar, transport.
/// Shared by the dashboard and the desktop widget layer.
BrutalCard {
    id: root

    padding: Theme.space.lg

    /// Side of the cover square. The dashboard gives it a great deal more room
    /// than the desktop widget does, so the caller picks.
    property int artSize: 104

    // The cover, blown up and blurred, washed out enough that the text on top
    // of it still reads. Cards with no art fall back to the flat card fill.
    backdrop: Component {
        Item {
            Image {
                id: wash
                anchors.fill: parent
                source: Players.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: wash
                visible: wash.status === Image.Ready
                autoPaddingEnabled: false
                blurEnabled: true
                blur: 1
                blurMax: 48
                // Desaturated and lifted: a tint under the text, not a picture
                // competing with it. A dark cover still has to leave the
                // artist line readable.
                saturation: -0.35
                brightness: 0.15
                opacity: 0.3
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Theme.space.lg

        // ── Album art ──────────────────────────────────────────────────────
        BrutalBox {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: root.artSize
            implicitHeight: root.artSize
            radius: Theme.radius.md
            color: Theme.color.lavender

            // A plain `clip` is rectangular, so the cover would square off the
            // card's rounded corners. Clip to the same curve instead.
            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: Theme.border.width
                radius: Math.max(0, Theme.radius.md - Theme.border.width)
                color: "transparent"

                Image {
                    anchors.fill: parent
                    source: Players.artUrl
                    visible: Players.artUrl !== "" && status === Image.Ready
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            BrutalIcon {
                anchors.centerIn: parent
                visible: Players.artUrl === ""
                text: Icons.music
                font.pixelSize: Math.round(root.artSize * 0.38)
            }
        }

        // ── Track + transport ──────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.space.xs

            BrutalText {
                text: Players.title || "Nothing playing"
                font.pixelSize: Theme.font.size.xxl
                font.weight: Theme.font.weight.bold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            BrutalText {
                text: Players.artist || "—"
                dim: true
                font.pixelSize: Theme.font.size.lg
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            BrutalWave {
                Layout.fillWidth: true
                Layout.topMargin: Theme.space.sm
                Layout.bottomMargin: Theme.space.xs
                dotSize: 13
                progress: Players.progress
                onSeeked: f => Players.seek(f)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.md

                BrutalText {
                    text: Players.formatTime(Players.position)
                    font.pixelSize: Theme.font.size.md
                    font.weight: Theme.font.weight.bold
                    Layout.preferredWidth: 46
                }

                Item { Layout.fillWidth: true }

                BrutalIconButton {
                    icon: Icons.previous
                    size: 36
                    radius: Theme.radius.sm
                    iconSize: Theme.font.size.lg
                    onClicked: Players.previous()
                }

                BrutalIconButton {
                    icon: Players.isPlaying ? Icons.pause : Icons.play
                    baseColor: Theme.color.salmon
                    hoverColor: Theme.color.coral
                    size: 44
                    radius: Theme.radius.sm
                    iconSize: Theme.font.size.xxl
                    onClicked: Players.playPause()
                }

                BrutalIconButton {
                    icon: Icons.next
                    size: 36
                    radius: Theme.radius.sm
                    iconSize: Theme.font.size.lg
                    onClicked: Players.next()
                }

                Item { Layout.fillWidth: true }

                BrutalText {
                    text: Players.formatTime(Players.length)
                    font.pixelSize: Theme.font.size.md
                    font.weight: Theme.font.weight.bold
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 46
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Config
import qs.Components
import qs.Services

/// Compact now-playing capsule. Hides itself entirely when nothing is playing.
Island {
    id: root

    visible: Players.hasPlayer && Settings.data.bar.showMedia
    hPadding: Theme.space.lg

    // Art tile, text, divider and glyphs — none of them cast a shadow, so the
    // island keeps the reserved height but skips the nudge that goes with it.
    contentShadowed: false

    // Clicking the capsule expands it into the mini player.
    clickable: true
    onClicked: ShellState.toggleMedia()

    // Album art, falling back to a flat accent tile with a note glyph.
    BrutalBox {
        implicitWidth: Theme.bar.control
        implicitHeight: Theme.bar.control
        radius: Theme.radius.xs
        shadowed: false
        color: Theme.color.lavender
        clip: true

        Image {
            anchors.fill: parent
            anchors.margins: Theme.border.width
            source: Players.artUrl
            visible: Players.artUrl !== "" && status === Image.Ready
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }

        BrutalIcon {
            anchors.centerIn: parent
            text: Icons.music
            font.pixelSize: Theme.font.icon.sm
            visible: Players.artUrl === ""
        }
    }

    BrutalText {
        text: Players.title || "Nothing playing"
        font.pixelSize: Theme.font.barSize.sm
        font.weight: Theme.font.weight.bold
        elide: Text.ElideRight
        Layout.maximumWidth: 180
        Layout.leftMargin: Theme.space.xs
    }

    BrutalDivider {
        vertical: true
        length: 20
        Layout.leftMargin: Theme.space.xs
        Layout.rightMargin: Theme.space.xs
    }

    // Spread the transport out a touch: at this glyph size they read as one
    // smear otherwise.
    Item { implicitWidth: Theme.space.xs; implicitHeight: 1 }

    Repeater {
        model: [
            { glyph: Icons.previous, action: () => Players.previous() },
            { glyph: Players.isPlaying ? Icons.pause : Icons.play, action: () => Players.playPause() },
            { glyph: Icons.next, action: () => Players.next() }
        ]

        delegate: BrutalIcon {
            required property var modelData

            text: modelData.glyph
            font.pixelSize: Theme.font.barSize.xl
            opacity: hover.containsMouse ? 1 : 0.65

            Behavior on opacity { NumberAnimation { duration: Theme.anim.fast } }

            MouseArea {
                id: hover
                anchors.fill: parent
                // Transport glyphs are narrow, and a near-miss that opens the
                // mini player instead of skipping a track is a bad surprise —
                // so the hit area is deliberately wider than the glyph.
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: parent.modelData.action()
            }
        }
    }
}

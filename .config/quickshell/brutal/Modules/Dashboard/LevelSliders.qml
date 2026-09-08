import QtQuick
import QtQuick.Layouts
import qs.Config
import qs.Components
import qs.Services

/// Vertical volume and brightness controls with percentage chips beneath.
BrutalCard {
    id: root

    padding: Theme.space.lg

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Theme.space.md

        component Level: ColumnLayout {
            id: level

            property string icon: ""
            property color tint: Theme.color.salmon
            property real value: 0
            property bool active: true

            signal moved(real value)
            signal toggled()

            spacing: Theme.space.sm
            Layout.fillHeight: true

            BrutalIconButton {
                Layout.alignment: Qt.AlignHCenter
                icon: level.icon
                baseColor: level.active ? level.tint : Theme.color.base
                size: 38
                radius: Theme.radius.sm
                iconSize: Theme.font.icon.lg
                onClicked: level.toggled()
            }

            BrutalSlider {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: true
                implicitWidth: 40
                value: level.value
                fillColor: level.tint
                onMoved: v => level.moved(v)
            }

            // A rounded square, not a pill — the same call the bar's right
            // island makes, so the two read as the same family of control.
            BrutalPill {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                text: `${Math.round(level.value * 100)}%`
                color: level.tint
                radius: Theme.radius.sm
                fontSize: Theme.font.size.sm
                hPadding: Theme.space.sm
                vPadding: Theme.space.sm
            }
        }

        Level {
            icon: Audio.icon
            tint: Theme.color.salmon
            value: Audio.volume
            active: !Audio.muted
            onMoved: v => Audio.setVolume(v)
            onToggled: Audio.toggleMute()
        }

        Level {
            visible: Brightness.available
            icon: Brightness.icon
            tint: Theme.color.green
            value: Brightness.value
            onMoved: v => Brightness.setValue(v)
        }
    }
}

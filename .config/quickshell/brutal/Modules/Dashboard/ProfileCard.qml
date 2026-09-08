import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Config
import qs.Components
import qs.Services

/// Avatar, name, user@host, and an online chip.
BrutalCard {
    id: root

    padding: Theme.space.xxl

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        spacing: Theme.space.lg

        // Avatar, or the user's initial if no image is configured.
        BrutalBox {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 104
            implicitHeight: 104
            radius: Theme.radius.lg
            color: Theme.color.peach

            // Rounded clip, not the rectangular one `clip: true` gives — a
            // square-cornered photo inside a rounded box is very visible.
            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: Theme.border.width
                radius: Math.max(0, Theme.radius.lg - Theme.border.width)
                color: "transparent"

                Image {
                    id: avatar
                    anchors.fill: parent
                    source: Settings.data.avatar
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }
            }

            BrutalText {
                anchors.centerIn: parent
                visible: avatar.status !== Image.Ready
                text: (Settings.data.userName[0] ?? "?").toUpperCase()
                font.pixelSize: 46
                font.weight: Theme.font.weight.black
            }
        }

        BrutalText {
            Layout.alignment: Qt.AlignHCenter
            text: Settings.data.userName
            font.pixelSize: Theme.font.size.xxl
            font.weight: Theme.font.weight.bold
        }

        BrutalText {
            Layout.alignment: Qt.AlignHCenter
            text: `${Settings.data.userName}@${SystemInfo.host}`
            dim: true
            font.pixelSize: Theme.font.size.sm
        }

        BrutalPill {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Theme.space.xs
            color: Theme.color.green
            hPadding: Theme.space.lg
            dotColor: Theme.color.ink
            text: Settings.data.statusText
            fontSize: Theme.font.size.sm
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Config
import qs.Components
import qs.Services

/// One notification card. Shared by the toast stack and the history panel.
BrutalBox {
    id: root

    required property var notification
    /// Toasts dismiss the notification outright; the panel only closes it.
    property bool compact: false

    signal dismissed()

    implicitHeight: body.implicitHeight + Theme.space.md * 2
    radius: Theme.radius.lg
    color: Theme.color.surface
    shadowOffset: Theme.shadow.md

    readonly property string iconSource: {
        if (root.notification.image !== "") return root.notification.image;
        return Quickshell.iconPath(root.notification.appIcon, true);
    }

    // Urgency stripe down the left edge.
    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            margins: Theme.border.width
        }
        width: 6
        color: Notifications.urgencyColor(root.notification)
    }

    RowLayout {
        id: body

        anchors {
            fill: parent
            margins: Theme.space.md
            leftMargin: Theme.space.md + 6
        }
        spacing: Theme.space.md

        BrutalBox {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 36
            implicitHeight: 36
            radius: Theme.radius.sm
            color: Theme.color.base
            shadowed: false
            clip: true

            IconImage {
                anchors.centerIn: parent
                implicitSize: 22
                source: root.iconSource
                visible: root.iconSource !== ""
            }

            BrutalIcon {
                anchors.centerIn: parent
                text: Icons.bell
                visible: root.iconSource === ""
                font.pixelSize: Theme.font.size.md
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.sm

                BrutalText {
                    text: root.notification.appName
                    dim: true
                    font.pixelSize: Theme.font.size.xs
                    font.weight: Theme.font.weight.bold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                BrutalIcon {
                    text: Icons.close
                    font.pixelSize: Theme.font.size.sm
                    opacity: close.containsMouse ? 1 : 0.4

                    Behavior on opacity { NumberAnimation { duration: Theme.anim.fast } }

                    MouseArea {
                        id: close
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismissed()
                    }
                }
            }

            BrutalText {
                text: root.notification.summary
                font.pixelSize: Theme.font.size.sm
                font.weight: Theme.font.weight.bold
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            BrutalText {
                visible: root.notification.body !== ""
                text: root.notification.body
                dim: true
                font.pixelSize: Theme.font.size.xs
                wrapMode: Text.WordWrap
                maximumLineCount: root.compact ? 2 : 4
                elide: Text.ElideRight
                textFormat: Text.PlainText
                Layout.fillWidth: true
            }

            RowLayout {
                visible: root.notification.actions.length > 0
                Layout.topMargin: Theme.space.xs
                spacing: Theme.space.sm

                Repeater {
                    model: root.notification.actions

                    delegate: BrutalButton {
                        id: action

                        required property var modelData

                        implicitWidth: label.implicitWidth + Theme.space.md * 2
                        implicitHeight: 24
                        radius: Theme.radius.pill
                        shadowOffset: Theme.shadow.sm
                        baseColor: Theme.color.lavender
                        onClicked: action.modelData.invoke()

                        BrutalText {
                            id: label
                            anchors.centerIn: parent
                            text: action.modelData.text
                            font.pixelSize: Theme.font.size.xs
                            font.weight: Theme.font.weight.bold
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: root.dismissed()
        z: -1
    }
}

import QtQuick
import QtQuick.Layouts
import qs.Config
import qs.Components
import qs.Services

/// One titled list of audio devices — outputs or inputs — with the active one
/// marked. Picking is the whole interaction, so the rows are plain buttons.
ColumnLayout {
    id: root

    property string title: ""
    property var devices: []
    property var current: null
    property color accent: Theme.color.blue

    signal picked(var node)

    spacing: Theme.space.xs

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space.sm

        BrutalText {
            text: root.title
            dim: true
            font.pixelSize: Theme.font.size.xs
            font.weight: Theme.font.weight.bold
        }

        BrutalDivider { Layout.fillWidth: true }
    }

    Repeater {
        model: root.devices

        delegate: BrutalButton {
            id: deviceRow

            required property var modelData

            // Comparing by id rather than by object: PipeWire hands out fresh
            // wrappers, so the default and the list entry can be equal devices
            // and still fail an identity check.
            readonly property bool active:
                root.current && modelData && root.current.id === modelData.id

            Layout.fillWidth: true
            implicitHeight: 38
            radius: Theme.radius.sm
            shadowOffset: Theme.shadow.sm
            baseColor: deviceRow.active ? root.accent : Theme.color.base
            hoverColor: deviceRow.active ? root.accent : Theme.color.crust
            onClicked: root.picked(deviceRow.modelData)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.space.md
                anchors.rightMargin: Theme.space.md
                spacing: Theme.space.sm

                BrutalIcon {
                    // A tick only on the active one: every row having a glyph
                    // makes the list harder to scan, not easier.
                    text: deviceRow.active ? Icons.check : ""
                    visible: deviceRow.active
                    font.pixelSize: Theme.font.size.md
                }

                BrutalText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: Audio.label(deviceRow.modelData)
                    font.pixelSize: Theme.font.size.sm
                    font.weight: deviceRow.active
                        ? Theme.font.weight.bold : Theme.font.weight.normal
                }
            }
        }
    }

    BrutalText {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        dim: true
        font.pixelSize: Theme.font.size.xs
        visible: root.devices.length === 0
        text: "Nothing available"
    }
}

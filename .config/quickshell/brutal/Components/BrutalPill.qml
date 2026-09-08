import QtQuick
import QtQuick.Layouts
import qs.Config

/// A fully-rounded label chip: optional glyph, text, flat pastel fill.
BrutalBox {
    id: root

    property string icon: ""
    property string text: ""
    /// Optional status dot before the label. Transparent — the default — leaves
    /// it out entirely; it belongs in the row so the text makes room for it.
    property color dotColor: "transparent"
    property int fontSize: Theme.font.size.sm
    property int iconSize: Theme.font.size.md
    property int hPadding: Theme.space.md
    property int vPadding: Theme.space.xs

    radius: Theme.radius.pill
    color: Theme.color.base
    shadowOffset: Theme.shadow.sm
    implicitWidth: row.implicitWidth + root.hPadding * 2
    implicitHeight: row.implicitHeight + root.vPadding * 2

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.space.sm

        Rectangle {
            visible: root.dotColor.a > 0
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 7
            implicitHeight: 7
            radius: 3.5
            color: root.dotColor
            antialiasing: true
        }

        BrutalIcon {
            visible: root.icon !== ""
            text: root.icon
            color: root.onColor
            font.pixelSize: root.iconSize
        }

        BrutalText {
            visible: root.text !== ""
            text: root.text
            color: root.onColor
            font.pixelSize: root.fontSize
            font.weight: Theme.font.weight.bold
        }
    }
}

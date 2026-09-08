import QtQuick
import qs.Config

/// Compact square/round button holding a single Nerd Font glyph.
BrutalButton {
    id: root

    property string icon: ""
    property int iconSize: Theme.font.icon.md
    /// Follows the button's own fill, hover state included — a pastel accent
    /// takes dark ink, a near-black surface takes cream.
    property color iconColor: root.onColor
    property int size: 30

    implicitWidth: root.size
    implicitHeight: root.size
    radius: Theme.radius.sm
    shadowOffset: Theme.shadow.sm

    BrutalIcon {
        anchors.centerIn: parent
        text: root.icon
        color: root.iconColor
        font.pixelSize: root.iconSize
    }
}

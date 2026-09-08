import QtQuick
import qs.Config

/// Horizontal meter: bordered track, flat pastel fill, no gradient.
BrutalBox {
    id: root

    /// 0.0 - 1.0
    property real value: 0
    property color fillColor: Theme.color.salmon
    property int thickness: 14

    radius: Theme.radius.pill
    color: Theme.color.base
    shadowed: false
    implicitHeight: root.thickness
    clip: true

    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            margins: Theme.border.width
        }
        width: Math.max(0, (parent.width - Theme.border.width * 2) * Math.max(0, Math.min(1, root.value)))
        radius: Theme.radius.pill
        color: root.fillColor
        antialiasing: true

        Behavior on width { NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.curve } }
    }
}

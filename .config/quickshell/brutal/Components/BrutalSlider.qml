import QtQuick
import qs.Config

/**
 * Draggable level control. Vertical by default (as used for volume and
 * brightness in the dashboard); set `vertical: false` for a horizontal one.
 */
BrutalBox {
    id: root

    /// 0.0 - 1.0
    property real value: 0.5
    property color fillColor: Theme.color.salmon
    property bool vertical: true

    signal moved(real value)

    radius: Theme.radius.pill
    color: Theme.color.base
    shadowOffset: Theme.shadow.sm
    clip: true

    // A bare Rectangle has no implicit size, so a slider dropped into a layout
    // without an explicit one collapsed to nothing. Give the track a sensible
    // thickness on its short axis and let the layout stretch the long one.
    implicitWidth: root.vertical ? 26 : 120
    implicitHeight: root.vertical ? 120 : 18

    Rectangle {
        id: fill

        // Anchor only the edges the fill is pinned to and size the other axis
        // explicitly. Anchoring both ends of the axis that is supposed to grow
        // makes the anchors win and the fill span the whole track whatever the
        // value is — which is what horizontal sliders used to do.
        anchors {
            left: parent.left
            right: root.vertical ? parent.right : undefined
            bottom: parent.bottom
            top: root.vertical ? undefined : parent.top
            margins: Theme.border.width
        }
        width: root.vertical
            ? undefined
            : Math.max(0, (root.width - Theme.border.width * 2) * root.value)
        height: root.vertical
            ? Math.max(0, (root.height - Theme.border.width * 2) * root.value)
            : undefined
        radius: Theme.radius.pill
        color: root.fillColor
        antialiasing: true

        Behavior on height { enabled: !drag.pressed; NumberAnimation { duration: Theme.anim.normal } }
        Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: Theme.anim.normal } }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        function apply(mouse) {
            const v = root.vertical
                ? 1 - (mouse.y / root.height)
                : mouse.x / root.width;
            root.moved(Math.max(0, Math.min(1, v)));
        }

        onPressed: mouse => apply(mouse)
        onPositionChanged: mouse => { if (pressed) apply(mouse); }
        onWheel: wheel => {
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.moved(Math.max(0, Math.min(1, root.value + step)));
        }
    }
}

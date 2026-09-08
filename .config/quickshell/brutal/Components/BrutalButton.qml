import QtQuick
import qs.Config

/**
 * A BrutalBox that physically presses into its own shadow when clicked —
 * the box slides down-right by exactly the shadow offset and the shadow
 * vanishes, so the surface reads as pushed flat against the page.
 */
BrutalBox {
    id: root

    signal clicked()
    signal rightClicked()

    property bool hoverEnabled: true
    /// Fill used while the cursor is over the button. Which direction that
    /// moves in depends on the palette, so the step comes from the theme.
    property color hoverColor: Theme.hover(root.baseColor)
    property color baseColor: Theme.color.base

    readonly property bool hovered: mouse.containsMouse
    readonly property bool down: mouse.containsPress

    color: root.hovered && root.enabled ? root.hoverColor : root.baseColor
    shadowed: !root.down
    opacity: root.enabled ? 1 : 0.5

    Behavior on color { ColorAnimation { duration: Theme.anim.fast } }

    transform: Translate {
        x: root.down ? root.shadowOffset : 0
        y: root.down ? root.shadowOffset : 0
        Behavior on x { NumberAnimation { duration: Theme.anim.fast; easing.type: Theme.anim.curve } }
        Behavior on y { NumberAnimation { duration: Theme.anim.fast; easing.type: Theme.anim.curve } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: root.hoverEnabled
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton) root.rightClicked();
            else root.clicked();
        }
    }
}

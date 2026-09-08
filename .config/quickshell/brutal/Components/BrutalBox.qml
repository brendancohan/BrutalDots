import QtQuick
import qs.Config

/**
 * The one shape this entire shell is built out of: an opaque cream panel with
 * a hard black border and a solid, un-blurred shadow offset down and right.
 *
 * It subclasses Rectangle rather than wrapping one so it drops straight into
 * anchors and Layouts with no extra indirection.
 */
Rectangle {
    id: root

    /// The ink that reads on this box's own fill. Anything drawn on the box
    /// wants this rather than `Theme.color.ink`, which is only correct while
    /// the fill is a neutral.
    ///
    /// A see-through fill defines nothing — whatever is behind it does — and
    /// measuring one would read `transparent` as pure black and answer cream.
    readonly property color onColor: root.color.a > 0.5
        ? Theme.inkOn(root.color)
        : Theme.color.ink

    /// Distance the shadow is offset down and to the right. 0 disables it.
    property int shadowOffset: Theme.shadow.md
    property color shadowColor: Theme.shadow.color
    property bool shadowed: true

    color: Theme.color.surface
    radius: Theme.radius.md
    border.width: Theme.border.width
    border.color: Theme.border.color
    antialiasing: true

    // Negative z puts this behind the parent's own background fill.
    Rectangle {
        z: -1
        x: root.shadowOffset
        y: root.shadowOffset
        width: root.width
        height: root.height
        radius: root.radius
        color: root.shadowColor
        antialiasing: true
        visible: root.shadowed && root.shadowOffset > 0

        Behavior on x { NumberAnimation { duration: Theme.anim.fast; easing.type: Theme.anim.curve } }
        Behavior on y { NumberAnimation { duration: Theme.anim.fast; easing.type: Theme.anim.curve } }
    }
}

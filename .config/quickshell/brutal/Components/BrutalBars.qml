import QtQuick
import qs.Config

/**
 * A live level meter: flat, hard-edged columns on a baseline.
 *
 * No gradients and no rounded caps — the bars are the same blunt rectangles
 * everything else in this shell is made of. Silence still draws a row of stubs
 * rather than nothing, so the widget keeps its shape when the music stops.
 */
Item {
    id: root

    /// Levels, 0.0 - 1.0. Shorter or longer than `count` is fine: missing
    /// entries read as silence, extra ones are ignored.
    property var values: []
    property int count: 28

    property color barColor: Theme.color.ink
    property int gap: 3
    /// Height of a bar at zero, as a fraction of the widget.
    property real floorHeight: 0.06

    implicitHeight: 44

    function level(i: int): real {
        const v = root.values[i];
        return (v === undefined || isNaN(v)) ? 0 : Math.max(0, Math.min(1, v));
    }

    Row {
        anchors.fill: parent
        spacing: root.gap

        Repeater {
            model: root.count

            Rectangle {
                required property int index

                // Share the leftover pixels out rather than letting the last
                // bar absorb the rounding error and come out visibly wider.
                readonly property real slot:
                    (root.width - root.gap * (root.count - 1)) / root.count

                width: Math.max(1, Math.floor(slot))
                height: Math.max(2, root.height
                    * (root.floorHeight + (1 - root.floorHeight) * root.level(index)))
                // Grown from the baseline. Set directly rather than anchored:
                // a Row owns its children's x, and mixing the two earns a
                // warning per bar per frame.
                y: root.height - height
                color: root.barColor
                antialiasing: false
            }
        }
    }
}

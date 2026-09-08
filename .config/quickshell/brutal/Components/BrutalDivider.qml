import QtQuick
import qs.Config

/// A plain ink rule. Horizontal by default; set `vertical` for a column split.
Rectangle {
    id: root

    property bool vertical: false
    property int thickness: 2
    property int length: 0

    color: Theme.color.ink
    opacity: 0.15
    radius: 1
    implicitWidth: root.vertical ? root.thickness : root.length
    implicitHeight: root.vertical ? root.length : root.thickness
}

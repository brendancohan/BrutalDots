import QtQuick
import qs.Config

/**
 * The dotted seek bar from the reference: a row of dots whose heights form a
 * fixed waveform, coloured through the accent list up to the play position and
 * greyed after it. Click anywhere to seek.
 */
Item {
    id: root

    /// 0.0 - 1.0
    property real progress: 0
    property int dotCount: 28
    /// Widest a dot is allowed to get. The row is laid out to the width it is
    /// actually given, so a narrow one thins its dots rather than running past
    /// its own edge — the same wave appears in a 630px card and a 430px widget.
    property int dotSize: 7
    property bool interactive: true

    signal seeked(real fraction)

    readonly property real slot: root.width / Math.max(1, root.dotCount)
    readonly property real dotWidth: Math.max(2, Math.min(root.dotSize, root.slot * 0.72))

    implicitWidth: root.dotSize * root.dotCount * 1.4
    implicitHeight: root.dotSize * 3

    /// Deterministic pseudo-waveform, so the shape is stable across redraws.
    function amplitude(i: int): real {
        const a = Math.sin(i * 0.9) * 0.5 + 0.5;
        const b = Math.sin(i * 0.37 + 1.3) * 0.5 + 0.5;
        return 0.35 + 0.65 * ((a * 0.6) + (b * 0.4));
    }

    Row {
        anchors.centerIn: parent
        spacing: Math.max(1, root.slot - root.dotWidth)

        Repeater {
            model: root.dotCount

            delegate: Rectangle {
                required property int index

                readonly property bool played:
                    (index + 0.5) / root.dotCount <= root.progress
                readonly property real amp: root.amplitude(index)

                width: root.dotWidth
                height: Math.round(root.dotWidth * (0.6 + amp * 1.9))
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                antialiasing: true
                color: played
                    ? Theme.accents[index % Theme.accents.length]
                    : Theme.color.grey

                Behavior on color { ColorAnimation { duration: Theme.anim.normal } }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => root.seeked(Math.max(0, Math.min(1, mouse.x / root.width)))
    }
}

import QtQuick
import qs.Config
import qs.Services

/// Analog clock: bordered face, twelve ticks, three hands. No gradients.
BrutalBox {
    id: root

    property int diameter: 110
    property bool showSeconds: true

    implicitWidth: root.diameter
    implicitHeight: root.diameter
    radius: root.diameter / 2
    color: Theme.color.base
    shadowOffset: Theme.shadow.sm

    // Hour ticks
    Repeater {
        model: 12

        delegate: Rectangle {
            required property int index

            readonly property bool major: index % 3 === 0

            width: major ? 3 : 2
            height: major ? 9 : 5
            radius: 1
            color: Theme.color.ink
            opacity: major ? 1 : 0.45
            x: root.width / 2 - width / 2
            y: Theme.space.sm

            transform: Rotation {
                origin.x: width / 2
                origin.y: root.height / 2 - Theme.space.sm
                angle: index * 30
            }
        }
    }

    component Hand: Rectangle {
        id: hand

        property real angle: 0
        property int length: 30

        // `height` is what actually draws the hand; `length` also positions it
        // and anchors the rotation origin at the centre of the face.
        height: hand.length
        radius: hand.width / 2
        color: Theme.color.ink
        antialiasing: true
        x: root.width / 2 - hand.width / 2
        y: root.height / 2 - hand.length

        transform: Rotation {
            origin.x: hand.width / 2
            origin.y: hand.length
            angle: hand.angle
        }
    }

    Hand {
        width: 4
        length: root.diameter * 0.26
        angle: (Time.now.getHours() % 12) * 30 + Time.now.getMinutes() * 0.5
    }

    Hand {
        width: 3
        length: root.diameter * 0.36
        angle: Time.now.getMinutes() * 6 + Time.now.getSeconds() * 0.1
    }

    Hand {
        visible: root.showSeconds
        width: 2
        length: root.diameter * 0.40
        color: Theme.mark.red
        angle: Time.now.getSeconds() * 6
    }

    // Centre pin
    Rectangle {
        anchors.centerIn: parent
        width: 7
        height: 7
        radius: 3.5
        color: Theme.color.ink
    }
}

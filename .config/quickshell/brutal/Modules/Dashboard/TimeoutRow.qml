import QtQuick
import QtQuick.Layouts
import qs.Config
import qs.Components

/**
 * One step of the idle ladder: a labelled row that steps through a fixed set of
 * timeouts with − and +.
 *
 * A ladder rather than free entry — the useful values for "dim the screen" are
 * a handful of round numbers, and a slider over 0-3600 seconds cannot be landed
 * on any of them reliably.
 */
RowLayout {
    id: root

    property string label: ""
    property string description: ""
    property string icon: ""
    property color tint: Theme.color.peach
    /// Seconds. 0 is "Off" and is always the first rung.
    property int value: 0

    signal changed(int value)

    readonly property var ladder:
        [0, 30, 60, 120, 300, 600, 900, 1200, 1800, 2700, 3600]

    /// The rung the current value sits on, or the nearest one below it — a
    /// value hand-edited into settings.json still steps sensibly from here.
    readonly property int rung: {
        let best = 0;
        for (let i = 0; i < root.ladder.length; i++) {
            if (root.ladder[i] <= root.value) best = i;
        }
        return best;
    }

    function format(seconds: int): string {
        if (seconds <= 0) return "Off";
        if (seconds < 60) return `${seconds}s`;
        if (seconds % 3600 === 0) return `${seconds / 3600}h`;
        if (seconds % 60 === 0) return `${seconds / 60}m`;
        return `${Math.floor(seconds / 60)}m ${seconds % 60}s`;
    }

    function step(delta: int): void {
        const l = root.ladder;
        // Down from a value that is not on a rung snaps to the rung itself
        // rather than skipping past it — a number hand-edited into
        // settings.json comes back onto the ladder in one press.
        const next = delta < 0
            ? (l[root.rung] < root.value ? l[root.rung] : l[Math.max(0, root.rung - 1)])
            : l[Math.min(l.length - 1, root.rung + 1)];
        if (next !== root.value) root.changed(next);
    }

    spacing: Theme.space.md

    BrutalBox {
        implicitWidth: 34
        implicitHeight: 34
        radius: Theme.radius.sm
        color: root.value > 0 ? root.tint : Theme.color.grey
        shadowed: false

        BrutalIcon {
            anchors.centerIn: parent
            text: root.icon
            font.pixelSize: Theme.font.icon.lg
            opacity: root.value > 0 ? 1 : 0.45
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: -1

        BrutalText {
            text: root.label
            font.pixelSize: Theme.font.size.lg
            font.weight: Theme.font.weight.bold
        }

        BrutalText {
            visible: root.description !== ""
            text: root.description
            dim: true
            font.pixelSize: Theme.font.size.sm
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    BrutalIconButton {
        icon: Icons.minus
        size: 32
        radius: Theme.radius.sm
        // Not `rung > 0`: a value below the first rung is still above Off.
        enabled: root.value > 0
        onClicked: root.step(-1)
    }

    BrutalPill {
        Layout.preferredWidth: 72
        radius: Theme.radius.sm
        color: root.value > 0 ? Theme.color.base : Theme.color.grey
        text: root.format(root.value)
        fontSize: Theme.font.size.md
        vPadding: Theme.space.sm
    }

    BrutalIconButton {
        icon: Icons.plus
        size: 32
        radius: Theme.radius.sm
        enabled: root.rung < root.ladder.length - 1
        onClicked: root.step(1)
    }
}

import QtQuick
import QtQuick.Layouts
import qs.Config
import qs.Components

/**
 * One labelled setting: what it is, what it does, and the control for it.
 *
 * Numeric rows get a slider and a value chip, boolean rows a checkbox. Both
 * shapes live here so a settings card is a list of these rather than a stack of
 * hand-built RowLayouts that drift apart.
 */
RowLayout {
    id: root

    property string label: ""
    property string description: ""
    /// "int" | "real" | "bool"
    property string type: "real"
    property real value: 0
    property bool checked: false
    property real minimum: 0
    property real maximum: 1
    property color tint: Theme.color.peach
    /// Shows the dot and enables the restore button.
    property bool overridden: false
    property bool resettable: false
    property var format: v => String(v)

    signal moved(real value)
    signal toggled(bool checked)
    signal restore()

    readonly property bool numeric: root.type !== "bool"

    spacing: Theme.space.md

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
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    // Marks a value this shell has taken ownership of, matching the Keybinds
    // tab's dot. Always present so the controls stay in one column.
    Rectangle {
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 7
        implicitHeight: 7
        radius: 3.5
        color: Theme.mark.orange
        opacity: root.overridden ? 1 : 0
        antialiasing: true
    }

    BrutalSlider {
        Layout.preferredWidth: 170
        Layout.alignment: Qt.AlignVCenter
        visible: root.numeric
        vertical: false
        implicitHeight: 22
        fillColor: root.tint
        value: root.maximum > root.minimum
            ? (root.value - root.minimum) / (root.maximum - root.minimum) : 0
        onMoved: f => {
            const raw = root.minimum + f * (root.maximum - root.minimum);
            root.moved(root.type === "int" ? Math.round(raw) : raw);
        }
    }

    BrutalPill {
        Layout.preferredWidth: 72
        Layout.alignment: Qt.AlignVCenter
        visible: root.numeric
        radius: Theme.radius.sm
        text: root.format(root.value)
        fontSize: Theme.font.size.md
        vPadding: Theme.space.sm
    }

    BrutalCheckbox {
        Layout.alignment: Qt.AlignVCenter
        visible: !root.numeric
        size: 26
        checkColor: root.tint
        checked: root.checked
        onToggled: on => root.toggled(on)
    }

    BrutalIconButton {
        Layout.alignment: Qt.AlignVCenter
        icon: Icons.restart
        size: 30
        radius: Theme.radius.sm
        visible: root.resettable
        opacity: root.overridden ? 1 : 0
        enabled: root.overridden
        onClicked: root.restore()
    }
}

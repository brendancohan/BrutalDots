import QtQuick
import QtQuick.Layouts
import qs.Config
import qs.Components
import qs.Services

/// One rebindable action: what it does, what it is bound to, and the controls
/// to change or restore that.
RowLayout {
    id: root

    // Not `required`: the list builds rows through a Loader, which can only
    // assign after creation.
    property var entry: null

    readonly property string combo: root.entry ? Keybinds.comboFor(root.entry) : ""
    readonly property bool overridden: root.entry ? Keybinds.isOverridden(root.entry) : false
    readonly property bool listening:
        root.entry ? Keybinds.capturingId === root.entry.id : false
    readonly property bool unbound: root.combo === ""

    spacing: Theme.space.md

    BrutalText {
        Layout.fillWidth: true
        text: root.entry ? root.entry.description : ""
        font.pixelSize: Theme.font.size.lg
        elide: Text.ElideRight
    }

    // A dot rather than a word: the row is already dense, and the only thing
    // worth saying is "this one is not the default".
    Rectangle {
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 7
        implicitHeight: 7
        radius: 3.5
        color: Theme.mark.orange
        opacity: root.overridden ? 1 : 0
        antialiasing: true
    }

    BrutalButton {
        id: chip

        Layout.preferredWidth: 230
        implicitHeight: 34
        radius: Theme.radius.sm
        enabled: Keybinds.ready && root.entry !== null && !root.entry.fixed
        baseColor: root.listening ? Theme.color.blue
            : root.unbound ? Theme.color.grey
            : Theme.color.base
        hoverColor: Theme.color.lavender

        onClicked: {
            if (root.listening) Keybinds.endCapture();
            else Keybinds.beginCapture(root.entry.id);
        }

        BrutalText {
            anchors.centerIn: parent
            width: parent.width - Theme.space.md * 2
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.listening ? "Press a combo…"
                : root.unbound ? "Not bound"
                : root.combo
            dim: root.unbound && !root.listening
            font.pixelSize: Theme.font.size.md
            font.weight: Theme.font.weight.bold
        }
    }

    // Clear, and restore. Both stay in the layout when they do not apply, so
    // the chips above them stay on one column down the whole list.
    BrutalIconButton {
        icon: Icons.close
        size: 30
        radius: Theme.radius.sm
        opacity: !root.entry || root.entry.fixed || root.unbound ? 0 : 1
        enabled: Keybinds.ready && root.entry !== null && !root.entry.fixed && !root.unbound
        onClicked: Keybinds.clear(root.entry.id)
    }

    BrutalIconButton {
        icon: Icons.restart
        size: 30
        radius: Theme.radius.sm
        opacity: root.overridden ? 1 : 0
        enabled: Keybinds.ready && root.overridden
        onClicked: Keybinds.reset(root.entry.id)
    }
}

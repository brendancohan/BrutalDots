import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Config
import qs.Components
import qs.Services

/// Power button, workspaces, and the widget-panel toggle.
Island {
    id: root

    required property var screenName

    BrutalIconButton {
        icon: Icons.power
        baseColor: Theme.color.orange
        hoverColor: Qt.lighter(Theme.color.orange, 1.08)
        size: Theme.bar.control
        iconSize: Theme.font.icon.md
        onClicked: ShellState.togglePowerMenu()
    }

    BrutalDivider {
        vertical: true
        length: 22
        Layout.leftMargin: Theme.space.xs
        Layout.rightMargin: Theme.space.xs
    }

    Workspaces {
        screenName: root.screenName
    }

    BrutalDivider {
        vertical: true
        length: 22
        Layout.leftMargin: Theme.space.xs
        Layout.rightMargin: Theme.space.xs
    }

    BrutalButton {
        implicitWidth: content.implicitWidth + Theme.space.lg * 2
        implicitHeight: Theme.bar.control
        radius: Theme.radius.sm
        shadowOffset: Theme.shadow.sm
        baseColor: ShellState.widgetsOpen ? Theme.color.mint : Theme.color.green
        hoverColor: Theme.color.mint
        onClicked: ShellState.toggleWidgets()

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: Theme.space.sm

            BrutalIcon {
                text: Icons.tasks
                font.pixelSize: Theme.font.icon.sm
            }

            BrutalText {
                text: "Tasks"
                font.pixelSize: Theme.font.barSize.sm
                font.weight: Theme.font.weight.bold
            }
        }
    }
}

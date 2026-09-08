import QtQuick
import QtQuick.Layouts
import qs.Config
import qs.Components
import qs.Services

/// Todo list with an inline composer.
BrutalCard {
    id: root

    padding: Theme.space.lg
    showDivider: true

    // Header is built by hand here so the active count can sit on the right.
    title: ""

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space.sm

        BrutalIcon {
            text: Icons.pencil
            font.pixelSize: Theme.font.size.md
        }

        BrutalText {
            text: "Tasks"
            font.pixelSize: Theme.font.size.lg
            font.weight: Theme.font.weight.bold
            Layout.fillWidth: true
        }

        BrutalText {
            text: `${Tasks.activeCount} active`
            dim: true
            font.pixelSize: Theme.font.size.xs
        }
    }

    BrutalDivider { Layout.fillWidth: true }

    // ── Composer ───────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space.sm

        BrutalTextField {
            id: input

            Layout.fillWidth: true
            placeholder: "What needs to be done?"
            onAccepted: text => {
                Tasks.add(text);
                clear();
            }
        }

        BrutalIconButton {
            icon: Icons.plus
            baseColor: Theme.color.lavender
            size: 32
            radius: Theme.radius.sm
            onClicked: {
                Tasks.add(input.text);
                input.clear();
            }
        }
    }

    // ── List ───────────────────────────────────────────────────────────────
    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 120
        clip: true
        spacing: Theme.space.sm
        model: Tasks.list
        boundsBehavior: Flickable.StopAtBounds

        delegate: RowLayout {
            id: row

            required property var modelData

            width: ListView.view.width
            spacing: Theme.space.md

            BrutalCheckbox {
                checked: row.modelData.done
                checkColor: Theme.color.green
                onToggled: Tasks.toggle(row.modelData.id)
            }

            BrutalText {
                text: row.modelData.text
                font.pixelSize: Theme.font.size.sm
                dim: row.modelData.done
                font.strikeout: row.modelData.done
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            BrutalIcon {
                text: Icons.close
                font.pixelSize: Theme.font.size.sm
                dim: true
                opacity: remove.containsMouse ? 1 : 0.4

                MouseArea {
                    id: remove
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Tasks.remove(row.modelData.id)
                }
            }
        }

        // Empty state
        BrutalText {
            anchors.centerIn: parent
            visible: Tasks.list.length === 0
            text: "Nothing to do."
            dim: true
            font.pixelSize: Theme.font.size.sm
        }
    }
}

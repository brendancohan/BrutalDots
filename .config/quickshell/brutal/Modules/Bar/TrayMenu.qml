import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Config
import qs.Components

/**
 * The menu an application exposes through its tray icon, redrawn in the
 * BrutalDots idiom instead of Qt's platform menu.
 *
 * Submenus are navigated in place rather than cascading: entering one pushes
 * it onto a stack and draws a back row. QsMenuEntry is itself a QsMenuHandle,
 * so a child entry can be handed straight back to the opener.
 */
PopupWindow {
    id: root

    property var trayItem: null
    property list<var> stack: []

    readonly property var currentMenu: root.stack.length > 0
        ? root.stack[root.stack.length - 1]
        : (root.trayItem?.menu ?? null)

    readonly property string heading: root.stack.length > 0
        ? (root.stack[root.stack.length - 1].text || "Menu")
        : (root.trayItem?.title || root.trayItem?.id || "Menu")

    function openFor(item: var, anchorTo: Item): void {
        root.stack = [];
        root.trayItem = item;
        root.anchor.item = anchorTo;
        root.visible = true;
    }

    function close(): void { root.visible = false; }

    color: "transparent"
    visible: false
    grabFocus: true

    implicitWidth: 250
    implicitHeight: panel.implicitHeight + Theme.shadow.md

    anchor {
        edges: Edges.Bottom
        gravity: Edges.Bottom | Edges.Left
        margins.top: Theme.space.sm
    }

    // grabFocus closes the window behind our back, so the reset hangs off
    // visibility rather than off close().
    onVisibleChanged: {
        if (!root.visible) {
            root.trayItem = null;
            root.stack = [];
        }
    }

    QsMenuOpener {
        id: opener
        menu: root.currentMenu
    }

    BrutalBox {
        id: panel

        anchors.left: parent.left
        anchors.top: parent.top
        implicitWidth: root.implicitWidth - Theme.shadow.md
        implicitHeight: column.implicitHeight + Theme.space.sm * 2

        color: Theme.color.base
        radius: Theme.radius.md
        shadowOffset: Theme.shadow.md

        ColumnLayout {
            id: column

            anchors.fill: parent
            anchors.margins: Theme.space.sm
            spacing: 2

            // ── Heading, doubling as the back control ──────────────────────
            BrutalButton {
                Layout.fillWidth: true
                implicitHeight: 24
                radius: Theme.radius.xs
                shadowed: false
                border.width: 0
                baseColor: "transparent"
                hoverColor: root.stack.length > 0 ? Theme.color.crust : "transparent"
                hoverEnabled: root.stack.length > 0
                onClicked: {
                    if (root.stack.length > 0) root.stack = root.stack.slice(0, -1);
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.space.sm
                    anchors.rightMargin: Theme.space.sm
                    spacing: Theme.space.sm

                    BrutalIcon {
                        visible: root.stack.length > 0
                        text: Icons.chevronLeft
                        font.pixelSize: Theme.font.icon.xs
                    }

                    BrutalText {
                        Layout.fillWidth: true
                        text: root.heading
                        elide: Text.ElideRight
                        font.pixelSize: Theme.font.size.xs
                        font.weight: Theme.font.weight.bold
                        font.letterSpacing: 1
                        font.capitalization: Font.AllUppercase
                        dim: true
                    }
                }
            }

            BrutalDivider { Layout.fillWidth: true }

            // ── Entries ────────────────────────────────────────────────────
            Repeater {
                model: opener.children ? opener.children.values : []

                delegate: Item {
                    id: entry

                    required property var modelData
                    readonly property bool separator: entry.modelData.isSeparator

                    Layout.fillWidth: true
                    implicitHeight: entry.separator ? 9 : 26

                    BrutalDivider {
                        visible: entry.separator
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                    }

                    BrutalButton {
                        visible: !entry.separator
                        enabled: entry.modelData.enabled
                        anchors.fill: parent
                        radius: Theme.radius.xs
                        shadowed: false
                        // Rows inside a panel, not cards on a page: the panel
                        // already has the border this look is built on.
                        border.width: 0
                        baseColor: "transparent"
                        hoverColor: Theme.color.peach

                        onClicked: {
                            if (entry.modelData.hasChildren) {
                                root.stack = root.stack.concat([entry.modelData]);
                            } else {
                                entry.modelData.triggered();
                                root.close();
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.space.sm
                            anchors.rightMargin: Theme.space.sm
                            spacing: Theme.space.sm

                            // Checkbox and radio entries get an ink marker;
                            // plain entries get the application's own icon.
                            Item {
                                implicitWidth: 14
                                implicitHeight: 14
                                visible: entry.modelData.buttonType !== QsMenuButtonType.None
                                    || entry.modelData.icon !== ""

                                Rectangle {
                                    anchors.fill: parent
                                    visible: entry.modelData.buttonType !== QsMenuButtonType.None
                                    radius: entry.modelData.buttonType === QsMenuButtonType.RadioButton
                                        ? width / 2 : Theme.radius.xs
                                    color: entry.modelData.checkState === Qt.Checked
                                        ? Theme.color.mint : "transparent"
                                    border.width: Theme.border.width
                                    border.color: Theme.color.ink
                                }

                                IconImage {
                                    anchors.fill: parent
                                    visible: entry.modelData.buttonType === QsMenuButtonType.None
                                    source: entry.modelData.icon
                                }
                            }

                            BrutalText {
                                Layout.fillWidth: true
                                text: entry.modelData.text
                                elide: Text.ElideRight
                                font.pixelSize: Theme.font.size.sm
                            }

                            BrutalIcon {
                                visible: entry.modelData.hasChildren
                                text: Icons.chevronRight
                                font.pixelSize: Theme.font.icon.xs
                            }
                        }
                    }
                }
            }

            BrutalText {
                Layout.fillWidth: true
                Layout.topMargin: Theme.space.xs
                visible: !opener.children || opener.children.values.length === 0
                text: "No menu"
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.font.size.sm
                dim: true
            }
        }
    }
}

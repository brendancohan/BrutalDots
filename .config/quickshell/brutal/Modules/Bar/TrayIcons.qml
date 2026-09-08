import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Config
import qs.Components
import qs.Services

/**
 * System tray pill.
 *
 * Left click activates the item (or opens its menu, for menu-only items),
 * middle click runs the secondary action, right click always opens the menu.
 * The whole pill disappears when nothing is registered, rather than sitting
 * in the bar as an empty stub.
 */
BrutalBox {
    id: root

    visible: Tray.count > 0
    implicitWidth: row.implicitWidth + Theme.space.md * 2
    implicitHeight: Theme.bar.control
    radius: Theme.radius.sm
    color: Theme.color.base
    shadowOffset: Theme.shadow.sm

    TrayMenu { id: trayMenu }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Theme.space.sm

        Repeater {
            model: Tray.items

            delegate: Item {
                id: entry

                required property var modelData

                implicitWidth: Theme.bar.glyph
                implicitHeight: Theme.bar.glyph

                IconImage {
                    anchors.fill: parent
                    source: entry.modelData.icon
                    asynchronous: true
                    mipmap: true
                    opacity: hover.containsMouse ? 0.65 : 1

                    Behavior on opacity { NumberAnimation { duration: Theme.anim.fast } }
                }

                MouseArea {
                    id: hover

                    anchors.fill: parent
                    anchors.margins: -Theme.space.xs
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                    onClicked: event => {
                        const item = entry.modelData;
                        if (event.button === Qt.MiddleButton) {
                            item.secondaryActivate();
                        } else if (event.button === Qt.RightButton || item.onlyMenu) {
                            if (item.hasMenu) trayMenu.openFor(item, entry);
                            else item.activate();
                        } else {
                            item.activate();
                        }
                    }

                    onWheel: wheel => {
                        entry.modelData.scroll(wheel.angleDelta.y, false);
                    }
                }
            }
        }
    }
}

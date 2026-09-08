import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Config
import qs.Components
import qs.Services

/// Transient notification stack, top-right beneath the bar.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData

        screen: win.modelData
        // Toasts stay behind the lock screen: they would leak message
        // contents to anyone walking past.
        visible: Notifications.popups.length > 0 && !ShellState.locked
        color: "transparent"

        anchors {
            top: true
            right: true
        }

        implicitWidth: 400
        implicitHeight: Math.max(1, stack.implicitHeight + Theme.space.xl)
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "brutaldots-notifications"

        ColumnLayout {
            id: stack

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: Theme.space.md
                leftMargin: Theme.space.md
                rightMargin: Settings.data.bar.sideMargin + Theme.shadow.md
            }
            spacing: Theme.space.md

            Repeater {
                model: Notifications.popups

                delegate: NotificationItem {
                    required property var modelData

                    Layout.fillWidth: true
                    notification: modelData
                    compact: true
                    onDismissed: Notifications.dismissPopup(modelData)
                }
            }
        }
    }
}

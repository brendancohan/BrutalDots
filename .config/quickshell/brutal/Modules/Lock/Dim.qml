import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Config
import qs.Services

/**
 * The warning dim before the session locks.
 *
 * Input-transparent: the mask is an empty region, so clicks, scrolls and
 * pointer motion pass straight through to whatever is underneath — and any of
 * them ends the idle period and takes the veil away again.
 */
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData

        screen: win.modelData
        visible: Idle.dimmed && !ShellState.locked
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "brutaldots-dim"

        mask: Region {}

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0

            // Fades in each time the surface appears. There is deliberately no
            // fade out: the window is gone the instant the user moves.
            NumberAnimation on opacity {
                running: win.visible
                from: 0
                to: Settings.data.idle.dimOpacity
                duration: 700
            }
        }
    }
}

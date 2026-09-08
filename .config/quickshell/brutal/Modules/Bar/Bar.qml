import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Config
import qs.Components
import qs.Services

/**
 * The top bar: three floating islands on a transparent layer-shell surface,
 * one instance per monitor.
 *
 * The surface is taller than the islands so their hard shadows have somewhere
 * to fall, but only the island band is reserved as an exclusive zone.
 */
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar

        required property var modelData

        readonly property int topMargin: Settings.data.bar.topMargin
        readonly property int sideMargin: Settings.data.bar.sideMargin
        readonly property int barHeight: Settings.data.bar.height

        /// What the islands actually came out at. An island grows past
        /// `bar.height` when its controls plus their shadows need the room, so
        /// measuring beats trusting the setting — otherwise the surface clips
        /// the very shadow the island just made space for.
        readonly property int islandHeight: Math.max(
            bar.barHeight, left.implicitHeight, centre.implicitHeight, right.implicitHeight)

        screen: bar.modelData
        color: "transparent"

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: bar.topMargin + bar.islandHeight + Theme.shadow.md + Theme.space.sm

        // Preview mode reserves no space, so running the shell over a live
        // session doesn't shove every window down. Set BRUTALDOTS_PREVIEW=1.
        // Zone is set directly rather than via exclusionMode: assigning
        // exclusiveZone puts the surface back into Normal mode regardless.
        exclusiveZone: Env.preview
            ? 0
            : bar.topMargin + bar.islandHeight + Theme.shadow.md

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "brutaldots-bar"

        // Publish where the bar ends so surfaces that hang off it — the mini
        // player — line up without re-deriving the island height themselves.
        Binding {
            target: ShellState
            property: "barBottom"
            value: bar.topMargin + bar.islandHeight + Theme.shadow.md
        }

        LeftIsland {
            id: left

            screenName: bar.modelData.name
            anchors {
                left: parent.left
                top: parent.top
                leftMargin: bar.sideMargin
                topMargin: bar.topMargin
            }
        }

        CenterIsland {
            id: centre

            anchors {
                horizontalCenter: parent.horizontalCenter
                // The shadow adds width on the right only, so nudge left by
                // half of it to sit optically centred.
                horizontalCenterOffset: -Theme.shadow.md / 2
                top: parent.top
                topMargin: bar.topMargin
            }
        }

        RightIsland {
            id: right

            anchors {
                right: parent.right
                top: parent.top
                // Hard shadows only ever fall down and to the right, so a
                // right-anchored surface must also inset by the shadow to
                // leave the same visual gap as the left island.
                rightMargin: bar.sideMargin + Theme.shadow.md
                topMargin: bar.topMargin
            }
        }
    }
}

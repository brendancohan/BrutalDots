import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.Config
import qs.Components
import qs.Services

/**
 * The now-playing capsule, expanded.
 *
 * Hangs directly under the bar's centre island — click the capsule to open it,
 * Escape or a click anywhere else to put it away. Art, track, a live level
 * meter fed by cava, a seek bar and transport.
 */
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData

        readonly property bool onFocusedMonitor: Hyprland.focusedMonitor
            ? Hyprland.focusedMonitor.name === win.modelData.name
            : true

        readonly property bool shown:
            ShellState.mediaOpen && Players.hasPlayer && !ShellState.locked

        screen: win.modelData
        visible: win.shown && win.onFocusedMonitor
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "brutaldots-media"

        // cava is only worth running while it is on screen.
        onVisibleChanged: {
            if (win.visible) Cava.subscribe();
            else Cava.release();
        }
        Component.onDestruction: {
            if (win.visible) Cava.release();
        }

        // Nothing playing any more? Nothing to expand.
        Connections {
            target: Players
            function onHasPlayerChanged(): void {
                if (!Players.hasPlayer) ShellState.closeMedia();
            }
        }

        // ── Click-away ─────────────────────────────────────────────────────
        // Left transparent: this hangs off the bar like a menu, so dimming the
        // whole screen behind it would be far too heavy a gesture.
        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.closeMedia()
        }

        FocusScope {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: ShellState.closeMedia()

            BrutalBox {
                id: panel

                anchors.horizontalCenter: parent.horizontalCenter
                // The island above is nudged left by half its shadow to sit
                // optically centred; match it or the two look misaligned.
                anchors.horizontalCenterOffset: -Theme.shadow.md / 2
                anchors.top: parent.top
                anchors.topMargin: ShellState.barBottom + Theme.space.sm

                implicitWidth: Math.min(430, win.width - Theme.space.xxl * 2)
                implicitHeight: layout.implicitHeight + Theme.space.lg * 2

                color: Theme.color.surface
                radius: Theme.radius.lg
                shadowOffset: Theme.shadow.md

                scale: win.visible ? 1 : 0.96
                Behavior on scale {
                    NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.curve }
                }

                // Swallow clicks so they never reach the click-away layer.
                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: layout

                    anchors.fill: parent
                    anchors.margins: Theme.space.lg
                    spacing: Theme.space.md

                    // ── Sources ────────────────────────────────────────────
                    // Only drawn when there is a choice to make. Horizontal so
                    // it scrolls rather than wrapping: the panel has a fixed
                    // width, and a second row of chips would push the art off it.
                    ListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        visible: Players.all.length > 1

                        orientation: ListView.Horizontal
                        spacing: Theme.space.xs
                        clip: true
                        model: Players.all
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: BrutalButton {
                            id: chip

                            required property var modelData

                            readonly property bool current: chip.modelData === Players.active

                            implicitWidth: chipRow.implicitWidth + Theme.space.md * 2
                            implicitHeight: 26
                            radius: Theme.radius.pill
                            shadowOffset: Theme.shadow.sm
                            shadowed: chip.current
                            baseColor: chip.current ? Theme.color.lavender : Theme.color.base

                            onClicked: Players.select(chip.modelData)

                            RowLayout {
                                id: chipRow

                                anchors.centerIn: parent
                                spacing: Theme.space.xs

                                // Which of them is actually making noise.
                                Rectangle {
                                    visible: chip.modelData.isPlaying
                                    implicitWidth: 6
                                    implicitHeight: 6
                                    radius: 3
                                    color: chip.onColor
                                    antialiasing: true
                                }

                                BrutalText {
                                    text: chip.modelData.identity
                                    font.pixelSize: Theme.font.size.xs
                                    font.weight: Theme.font.weight.bold
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }
                        }
                    }

                    // ── Art + track ────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space.md

                        BrutalBox {
                            implicitWidth: 64
                            implicitHeight: 64
                            radius: Theme.radius.sm
                            shadowOffset: Theme.shadow.sm
                            color: Theme.color.lavender
                            clip: true

                            Image {
                                anchors.fill: parent
                                anchors.margins: Theme.border.width
                                source: Players.artUrl
                                visible: Players.artUrl !== "" && status === Image.Ready
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 128
                                sourceSize.height: 128
                            }

                            BrutalIcon {
                                anchors.centerIn: parent
                                visible: Players.artUrl === ""
                                text: Icons.music
                                font.pixelSize: Theme.font.size.xl
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            BrutalText {
                                Layout.fillWidth: true
                                text: Players.title || "Nothing playing"
                                font.pixelSize: Theme.font.size.lg
                                font.weight: Theme.font.weight.bold
                                elide: Text.ElideRight
                            }

                            BrutalText {
                                Layout.fillWidth: true
                                text: Players.artist || "—"
                                dim: true
                                font.pixelSize: Theme.font.size.sm
                                elide: Text.ElideRight
                            }

                            BrutalText {
                                Layout.fillWidth: true
                                text: Players.album
                                visible: Players.album !== ""
                                dim: true
                                font.pixelSize: Theme.font.size.xs
                                elide: Text.ElideRight
                            }
                        }
                    }

                    // ── Level meter ────────────────────────────────────────
                    // cava listens to the output device, not the player, so
                    // this moves for anything audible. Hidden entirely when
                    // cava is absent rather than showing a dead flat line.
                    BrutalBox {
                        Layout.fillWidth: true
                        implicitHeight: 52
                        visible: Settings.data.media.visualizer && Cava.running
                        color: Theme.color.mantle
                        radius: Theme.radius.sm
                        shadowed: false

                        BrutalBars {
                            anchors.fill: parent
                            anchors.margins: Theme.space.sm
                            values: Cava.values
                            count: Cava.bars
                            barColor: Players.isPlaying
                                ? Theme.color.ink : Theme.color.subtext
                        }
                    }

                    // ── Seek ───────────────────────────────────────────────
                    BrutalWave {
                        Layout.fillWidth: true
                        progress: Players.progress
                        onSeeked: f => Players.seek(f)
                    }

                    // ── Transport ──────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space.sm

                        BrutalText {
                            text: Players.formatTime(Players.position)
                            font.pixelSize: Theme.font.size.xs
                            font.weight: Theme.font.weight.bold
                        }

                        Item { Layout.fillWidth: true }

                        BrutalIconButton {
                            icon: Icons.previous
                            size: 32
                            radius: Theme.radius.sm
                            onClicked: Players.previous()
                        }

                        BrutalIconButton {
                            icon: Players.isPlaying ? Icons.pause : Icons.play
                            baseColor: Theme.color.salmon
                            hoverColor: Theme.color.coral
                            size: 36
                            radius: Theme.radius.sm
                            iconSize: Theme.font.size.lg
                            onClicked: Players.playPause()
                        }

                        BrutalIconButton {
                            icon: Icons.next
                            size: 32
                            radius: Theme.radius.sm
                            onClicked: Players.next()
                        }

                        Item { Layout.fillWidth: true }

                        BrutalText {
                            text: Players.formatTime(Players.length)
                            font.pixelSize: Theme.font.size.xs
                            font.weight: Theme.font.weight.bold
                        }
                    }
                }
            }
        }
    }
}

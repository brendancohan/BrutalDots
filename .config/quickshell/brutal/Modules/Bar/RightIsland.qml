import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Config
import qs.Components
import qs.Services

/// Tray, status glyph cluster, battery, clock, and notification toggle.
Island {
    id: root

    // ── Active modes (recording, keep-awake, night light) ──────────────────
    StatusFlags {}

    // ── System tray ────────────────────────────────────────────────────────
    TrayIcons {}

    // ── Volume / bluetooth / network ───────────────────────────────────────
    BrutalBox {
        implicitWidth: statusRow.implicitWidth + Theme.space.md * 2
        implicitHeight: Theme.bar.control
        radius: Theme.radius.sm
        color: Theme.color.base
        shadowOffset: Theme.shadow.sm

        RowLayout {
            id: statusRow
            anchors.centerIn: parent
            spacing: Theme.space.md

            BrutalIcon {
                text: Audio.icon
                font.pixelSize: Theme.font.icon.md
                color: Audio.muted ? Theme.color.subtext : Theme.color.ink

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -3
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    // Left opens the device pane; middle still mutes outright,
                    // matching the bluetooth glyph beside it.
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) Audio.toggleMute();
                        else ShellState.toggleAudio();
                    }
                    onWheel: wheel => Audio.setVolume(Audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
                }
            }

            BrutalIcon {
                text: !Network.bluetoothEnabled ? Icons.bluetoothOff
                    : Network.connectedBluetooth.length > 0 ? Icons.bluetoothConnected
                    : Icons.bluetooth
                font.pixelSize: Theme.font.icon.md
                color: Network.bluetoothEnabled ? Theme.color.ink : Theme.color.subtext

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -3
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    // Left opens the device menu — toggling the radio by
                    // accident while reaching for a headset is the wrong
                    // default. Middle click still flips it outright.
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) Network.toggleBluetooth();
                        else ShellState.toggleBluetooth();
                    }
                }
            }

            BrutalIcon {
                text: Network.icon
                font.pixelSize: Theme.font.icon.md
                color: Network.connected ? Theme.color.ink : Theme.color.subtext

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -3
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    // Left opens the network list, middle flips the radio —
                    // the same split as the bluetooth glyph beside it.
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) Network.toggleWifi();
                        else ShellState.toggleWifi();
                    }
                }
            }
        }
    }

    // ── Battery ────────────────────────────────────────────────────────────
    // Absent on a desktop: a pill pinned at 100% forever is just noise.
    BrutalBox {
        visible: Battery.available
        implicitWidth: batteryRow.implicitWidth + Theme.space.md * 2
        implicitHeight: Theme.bar.control
        radius: Theme.radius.sm
        color: Battery.low ? Battery.tint : Theme.color.base
        shadowOffset: Theme.shadow.sm

        RowLayout {
            id: batteryRow
            anchors.centerIn: parent
            spacing: Theme.space.xs

            BrutalIcon {
                text: Battery.icon
                font.pixelSize: Theme.font.icon.md
                color: Battery.critical ? Theme.color.ink : Theme.color.ink
            }

            BrutalText {
                text: `${Battery.percent}%`
                font.pixelSize: Theme.font.barSize.md
                font.weight: Theme.font.weight.bold
            }
        }
    }

    // ── Clock ──────────────────────────────────────────────────────────────
    BrutalBox {
        id: clockBox

        implicitWidth: clockRow.implicitWidth + Theme.space.md * 2
        implicitHeight: Theme.bar.control
        radius: Theme.radius.sm
        color: Theme.color.lavender
        shadowOffset: Theme.shadow.sm

        RowLayout {
            id: clockRow
            anchors.centerIn: parent
            spacing: Theme.space.sm

            BrutalIcon {
                text: Icons.clock
                font.pixelSize: Theme.font.icon.sm
            }

            BrutalText {
                text: Time.hour12
                font.pixelSize: Theme.font.barSize.md
                font.weight: Theme.font.weight.bold
                font.letterSpacing: 1
            }

            // Outlined AM/PM chip, as in the reference: the clock box's own
            // fill showing through, an ink border around it, ink letters. It
            // reads as a chip because of the border, not because of a fill.
            //
            // The see-through fill is what makes it mode-proof. BrutalBox
            // defers `onColor` on a transparent fill, and BrutalText's walk
            // skips such a box, so the letters measure against clockBox's
            // lavender and stay ink in both modes with nothing named here.
            BrutalBox {
                // The border is drawn inside these bounds, so it has to be
                // paid for on top of the padding — `space.sm` alone was the
                // padding of the old unbordered chip, and 4px of it went to
                // the stroke, leaving the letters about a pixel off it.
                //
                // Height needs no such allowance: `implicitHeight` is a line
                // box carrying ascent and descent that two capitals never
                // reach, and that slack is already the clearance.
                implicitWidth: meridiem.implicitWidth + Theme.space.sm
                    + Theme.border.width * 2
                implicitHeight: meridiem.implicitHeight + 2
                radius: Theme.radius.xs
                color: "transparent"
                shadowed: false

                // This border delineates the chip from the lavender it sits
                // inside, not from the island behind it, so it takes the ink
                // that reads on lavender rather than the theme's border ink.
                // The default would flip to cream in dark mode and manage
                // 1.38:1 against the fill — an invisible chip around letters
                // that stay dark. Measuring the fill gives 11.4:1 in both.
                border.color: clockBox.onColor

                BrutalText {
                    id: meridiem
                    anchors.centerIn: parent
                    text: Time.meridiem
                    font.pixelSize: Theme.font.barSize.sm
                    font.weight: Theme.font.weight.bold
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.toggleDashboard()
        }
    }

    // ── Notifications ──────────────────────────────────────────────────────
    BrutalIconButton {
        icon: Notifications.doNotDisturb ? Icons.bellOff : Icons.bell
        baseColor: Notifications.count > 0 && !Notifications.doNotDisturb
            ? Theme.color.pink : Theme.color.base
        hoverColor: Theme.color.pink
        size: Theme.bar.control
        iconSize: Theme.font.icon.md
        radius: Theme.radius.sm
        onClicked: ShellState.toggleNotifications()
    }
}

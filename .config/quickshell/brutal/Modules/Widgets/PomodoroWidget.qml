import QtQuick
import QtQuick.Layouts
import qs.Config
import qs.Components
import qs.Services

/// Pomodoro timer with a stopwatch on a second tab.
BrutalCard {
    id: root

    padding: Theme.space.lg
    showDivider: false

    /// false = pomodoro, true = stopwatch
    property bool stopwatch: false

    // ── Mode tabs ──────────────────────────────────────────────────────────
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Theme.space.sm

        BrutalButton {
            implicitWidth: 84
            implicitHeight: 26
            radius: Theme.radius.pill
            shadowOffset: Theme.shadow.sm
            baseColor: root.stopwatch ? Theme.color.base : Theme.color.green
            hoverColor: Theme.color.mint
            onClicked: root.stopwatch = false

            BrutalText {
                anchors.centerIn: parent
                text: "Pomodoro"
                font.pixelSize: Theme.font.size.xs
                font.weight: Theme.font.weight.bold
            }
        }

        BrutalButton {
            implicitWidth: 84
            implicitHeight: 26
            radius: Theme.radius.pill
            shadowOffset: Theme.shadow.sm
            baseColor: root.stopwatch ? Theme.color.green : Theme.color.base
            hoverColor: Theme.color.mint
            onClicked: root.stopwatch = true

            BrutalText {
                anchors.centerIn: parent
                text: "Stopwatch"
                font.pixelSize: Theme.font.size.xs
                font.weight: Theme.font.weight.bold
            }
        }
    }

    // ── Body ───────────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Theme.space.md
        spacing: Theme.space.md

        // Phase selector — pomodoro only.
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            visible: !root.stopwatch
            spacing: Theme.space.sm

            Repeater {
                model: [
                    { label: "Focus", phase: Pomodoro.Phase.Focus },
                    { label: "Break", phase: Pomodoro.Phase.ShortBreak },
                    { label: "Long",  phase: Pomodoro.Phase.LongBreak }
                ]

                delegate: BrutalButton {
                    id: phaseButton

                    required property var modelData

                    implicitWidth: 58
                    implicitHeight: 24
                    radius: Theme.radius.pill
                    shadowOffset: Theme.shadow.sm
                    baseColor: Pomodoro.phase === phaseButton.modelData.phase
                        ? Theme.color.pink : Theme.color.base
                    hoverColor: Theme.color.pink
                    onClicked: Pomodoro.setPhase(phaseButton.modelData.phase)

                    BrutalText {
                        anchors.centerIn: parent
                        text: phaseButton.modelData.label
                        font.pixelSize: Theme.font.size.xs
                        font.weight: Theme.font.weight.bold
                    }
                }
            }
        }

        // Readout
        BrutalBox {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            implicitHeight: 78
            radius: Theme.radius.md
            color: Theme.color.base
            border.color: root.stopwatch ? Theme.color.ink : Pomodoro.phaseColor
            border.width: Theme.border.thick

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0

                BrutalText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.stopwatch ? Pomodoro.stopwatchDisplay : Pomodoro.display
                    font.pixelSize: 30
                    font.weight: Theme.font.weight.black
                    font.letterSpacing: 2
                }

                BrutalText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.stopwatch ? "• STOPWATCH •" : `• ${Pomodoro.phaseLabel} •`
                    font.pixelSize: Theme.font.size.xs
                    font.weight: Theme.font.weight.bold
                    font.letterSpacing: 1
                    color: root.stopwatch ? Theme.color.subtext : Theme.color.ink
                }
            }
        }

        // Transport
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.space.sm

            BrutalIconButton {
                icon: Icons.refresh
                baseColor: Theme.color.lavender
                size: 28
                radius: Theme.radius.pill
                onClicked: root.stopwatch ? Pomodoro.resetStopwatch() : Pomodoro.reset()
            }

            BrutalIconButton {
                icon: (root.stopwatch ? Pomodoro.stopwatchRunning : Pomodoro.running)
                    ? Icons.pause : Icons.play
                baseColor: Theme.color.salmon
                size: 28
                radius: Theme.radius.pill
                onClicked: root.stopwatch ? Pomodoro.toggleStopwatch() : Pomodoro.toggle()
            }

            BrutalIconButton {
                icon: Icons.settings
                size: 28
                radius: Theme.radius.pill
                onClicked: Pomodoro.advance()
            }
        }
    }
}

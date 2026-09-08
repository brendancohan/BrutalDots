import QtQuick
import QtQuick.Layouts
import qs.Config
import qs.Components
import qs.Services

/// Analog face beside the greeting, digital time and date.
BrutalCard {
    id: root

    padding: Theme.space.lg
    showDivider: false

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space.xl

        BrutalClockFace {
            diameter: 112
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.space.xs

            RowLayout {
                spacing: Theme.space.sm

                BrutalIcon {
                    text: Weather.isDay ? Icons.sun : Icons.moon
                    font.pixelSize: Theme.font.size.md
                }

                BrutalText {
                    text: `${Time.greeting}, ${Settings.data.userName}`
                    font.pixelSize: Theme.font.size.sm
                    font.weight: Theme.font.weight.bold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                spacing: Theme.space.sm

                BrutalText {
                    text: Time.hour12
                    font.pixelSize: 32
                    font.weight: Theme.font.weight.black
                    font.letterSpacing: 1
                }

                BrutalBox {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 26
                    implicitHeight: 18
                    radius: Theme.radius.xs
                    color: Theme.color.lavender
                    shadowed: false

                    BrutalText {
                        anchors.centerIn: parent
                        text: Time.meridiem
                        font.pixelSize: Theme.font.size.xs
                        font.weight: Theme.font.weight.bold
                    }
                }
            }

            BrutalText {
                text: Time.dateMedium
                font.pixelSize: Theme.font.size.xs
                font.weight: Theme.font.weight.bold
                dim: true
            }
        }
    }
}

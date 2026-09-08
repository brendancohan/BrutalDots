import QtQuick
import QtQuick.Layouts
import qs.Config
import qs.Components
import qs.Services

/// Large conditions readout with humidity and wind chips.
BrutalCard {
    id: root

    padding: Theme.space.lg
    showDivider: false

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space.lg

        BrutalIcon {
            text: Weather.icon
            font.pixelSize: 42
            Layout.alignment: Qt.AlignVCenter
        }

        BrutalText {
            text: Weather.loaded ? `${Math.round(Weather.temperature)}°` : "--°"
            font.pixelSize: 38
            font.weight: Theme.font.weight.black
            Layout.alignment: Qt.AlignVCenter
        }

        BrutalDivider {
            vertical: true
            length: 56
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.space.xs

            RowLayout {
                spacing: Theme.space.xs

                BrutalIcon {
                    text: Icons.location
                    font.pixelSize: Theme.font.size.sm
                }

                BrutalText {
                    text: Weather.location || "Locating…"
                    font.pixelSize: Theme.font.size.sm
                    font.weight: Theme.font.weight.bold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            BrutalText {
                text: Weather.loaded ? Weather.description : "…"
                dim: true
                font.pixelSize: Theme.font.size.xs
            }

            RowLayout {
                Layout.topMargin: 2
                spacing: Theme.space.sm

                BrutalPill {
                    icon: Icons.humidity
                    text: `${Math.round(Weather.humidity)}%`
                    color: Theme.color.lavender
                    fontSize: Theme.font.size.xs
                    iconSize: Theme.font.size.sm
                    hPadding: Theme.space.sm
                }

                BrutalPill {
                    icon: Icons.wind
                    text: `${Math.round(Weather.windSpeed)} ${Weather.windUnit}`
                    color: Theme.color.green
                    fontSize: Theme.font.size.xs
                    iconSize: Theme.font.size.sm
                    hPadding: Theme.space.sm
                }
            }
        }
    }
}

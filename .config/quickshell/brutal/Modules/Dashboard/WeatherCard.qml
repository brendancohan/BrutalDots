import QtQuick
import QtQuick.Layouts
import qs.Config
import qs.Components
import qs.Services

/// Temperature and conditions. An inner box: it sits inside EnvironmentCard
/// alongside the day/night button, so it is filled in `base` rather than
/// `surface` and carries the smaller of the two shadows.
BrutalCard {
    id: root

    padding: Theme.space.xxl
    color: Theme.color.base
    radius: Theme.radius.md
    shadowOffset: Theme.shadow.sm

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space.lg

        BrutalText {
            text: Weather.loaded ? Weather.temperatureText : "--°"
            font.pixelSize: Theme.font.size.xxl
            font.weight: Theme.font.weight.black
        }

        BrutalDivider {
            vertical: true
            Layout.fillHeight: true
            Layout.topMargin: Theme.space.xs
            Layout.bottomMargin: Theme.space.xs
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            BrutalText {
                text: Weather.loaded ? Weather.description : "Loading…"
                // One step below the rest of the card: the day/night box takes
                // a square bite out of this row, and "Partly Cloudy" has to fit
                // in what is left without eliding.
                font.pixelSize: Theme.font.size.md
                font.weight: Theme.font.weight.bold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            BrutalText {
                visible: Weather.location !== ""
                text: Weather.location
                dim: true
                font.pixelSize: Theme.font.size.xs
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
}

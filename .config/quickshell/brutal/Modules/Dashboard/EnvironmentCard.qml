import QtQuick
import QtQuick.Layouts
import qs.Config
import qs.Components
import qs.Services

/**
 * Conditions and the line of the hour, grouped into one card.
 *
 * The two read as a single "what is it like out there" block in the reference,
 * so they share an outer panel and are drawn as inner boxes rather than as two
 * more top-level cards competing with the clock above them.
 */
BrutalCard {
    id: root

    padding: Theme.space.xl

    RowLayout {
        Layout.fillWidth: true
        // Only the quote grows when the card is stretched; the conditions row
        // is as tall as its own contents need and no taller.
        Layout.fillHeight: false
        spacing: Theme.space.md

        WeatherCard {
            id: conditions
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        // Square, and exactly as tall as the box beside it — a second inner
        // box rather than a control tucked inside the weather one.
        BrutalIconButton {
            Layout.fillHeight: true
            // Square. Measured off the box beside it rather than off its own
            // height, which the layout is still in the middle of deciding.
            Layout.preferredWidth: conditions.implicitHeight
            icon: Weather.isDay ? Icons.sun : Icons.moon
            baseColor: Theme.color.base
            hoverColor: Weather.isDay ? Theme.color.peach : Theme.color.lavender
            radius: Theme.radius.md
            shadowOffset: Theme.shadow.sm
            iconSize: Theme.font.icon.xl
            onClicked: Weather.refresh()
        }
    }

    QuoteCard {
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
}

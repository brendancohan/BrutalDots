import QtQuick
import QtQuick.Layouts
import qs.Config
import qs.Components
import qs.Services

/// A short line that changes with the hour. Cosmetic, but the reference has it.
/// An inner box of EnvironmentCard — see WeatherCard for why it is `base`.
BrutalCard {
    id: root

    padding: Theme.space.xl
    color: Theme.color.base
    radius: Theme.radius.md
    shadowOffset: Theme.shadow.sm

    readonly property var lines: [
        "A peaceful evening, perfect for compiling.",
        "Ship it. You can refactor tomorrow.",
        "The best config is the one you stop touching.",
        "Every rice is a work in progress.",
        "Borders: 2px. Shadows: hard. Regrets: none.",
        "Coffee first, then kernel panics.",
        "Someone out there is still using floating windows.",
        "Your uptime is a personality trait."
    ]

    readonly property string line:
        root.lines[Time.now.getHours() % root.lines.length]

    /// StyledText parses its input as markup, so anything going into it has to
    /// be escaped — the lines above are ours and contain none, but they are the
    /// kind of string that ends up user-configurable later.
    function escapeMarkup(text: string): string {
        return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    BrutalText {
        Layout.fillWidth: true
        Layout.fillHeight: true

        // Both marks live inside the text rather than beside it. A closing mark
        // as its own layout item would sit against the right edge of the card
        // however short the line was, instead of against the last word.
        textFormat: Text.StyledText
        text: {
            const mark = `<font color="${Theme.color.salmon}">`;
            return `${mark}“</font>${root.escapeMarkup(root.line)}${mark}”</font>`;
        }
        font.pixelSize: Theme.font.size.lg
        wrapMode: Text.WordWrap
        verticalAlignment: Text.AlignVCenter
    }
}

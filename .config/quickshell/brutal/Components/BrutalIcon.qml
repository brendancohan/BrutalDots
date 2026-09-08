import QtQuick
import qs.Config

/// A Nerd Font glyph. Sized in pixels like text, not as an image.
Text {
    id: root

    property bool dim: false

    /// The ink to draw in, inherited from the nearest enclosing BrutalBox.
    /// Only BrutalBox defines `onColor`, so this finds the box the text is
    /// actually drawn on through any number of Layouts. Set `color` explicitly
    /// to override — needed when the thing drawn is not on its ancestor box,
    /// such as a label over a sibling. See AGENTS.md "The design".
    readonly property color inheritedInk: {
        let p = root.parent;
        while (p) {
            // Skip see-through boxes: a transparent button sitting on a card
            // takes the card's ink, not one measured from its own empty fill.
            if (p.onColor !== undefined && p.color !== undefined && p.color.a > 0.5)
                return p.onColor;
            p = p.parent;
        }
        return Theme.color.ink;
    }

    color: root.dim ? Theme.color.subtext : root.inheritedInk
    font.family: Theme.font.mono
    font.pixelSize: Theme.font.icon.sm
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering

    /// A Nerd Font glyph is drawn wider than the cell it advances —
    /// `fa-youtube_play` paints 987 units of ink inside a 600-unit advance,
    /// overflowing to the right. `AlignHCenter` centres the *advance*, so the
    /// ink ends up half that overflow right of centre: 5px at the dashboard's
    /// icon size, on 93 of the 114 glyphs in Icons.qml. Labels are unaffected,
    /// which is why only the icons look off.
    ///
    /// Shift the paint back onto the item's centre. Moving the paint rather
    /// than the item leaves every layout's geometry exactly as it was, and it
    /// stays right if a caller stretches the icon wider than its content.
    /// Rounded because NativeRendering snaps glyphs to whole pixels, and a
    /// fractional offset would blur what it just snapped.
    TextMetrics {
        id: metrics
        font: root.font
        text: root.text
    }

    readonly property int inkOffset: Math.round(
        metrics.advanceWidth / 2
            - (metrics.tightBoundingRect.x + metrics.tightBoundingRect.width / 2))

    transform: Translate { x: root.inkOffset }
}

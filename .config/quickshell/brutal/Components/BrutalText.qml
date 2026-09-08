import QtQuick
import qs.Config

/// Text with the shell's mono face and ink colour applied by default.
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
    font.pixelSize: Theme.font.size.md
    font.weight: Theme.font.weight.medium
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
}

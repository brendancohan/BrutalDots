import QtQuick
import qs.Config

/**
 * Mouse-wheel scrolling for the Flickable it is declared inside.
 *
 * Flickable treats a wheel notch as a *flick*, setting a velocity rather than
 * moving the content, and a second notch arriving mid-flick replaces that
 * velocity instead of adding to it. Spinning the wheel therefore saturates:
 * measured on a 4000px-tall Flickable, one notch moved it 58px and ten notches
 * moved it 61px. That is the "I have to scroll a lot for it to move" feeling.
 *
 * Moving `contentY` directly makes the distance proportional again — the same
 * ten notches move 1200px.
 *
 * Only the mouse is taken. A touchpad sends pixel deltas that Flickable already
 * handles well, with kinetics this would throw away.
 */
WheelHandler {
    id: root

    /// The Flickable this scrolls. Left null it uses the item it is declared
    /// in, so the usual case is a bare `WheelScroll { }` inside one.
    ///
    /// Resolved by walking up when the wheel turns, not bound to `parent`.
    /// Declaring a handler inside a Flickable does *not* parent it to the
    /// Flickable: Flickable's default property is its `contentItem`, so
    /// `parent` is that plain QQuickItem and `parent as Flickable` is null.
    /// A handler that reads it silently scrolls nothing, which is precisely
    /// how the bug presented.
    property Flickable flick: null

    /// Pixels per notch. Three rows-worth, which is what desktop toolkits
    /// settle on; a notch that moves less than a row makes a long pane feel
    /// stuck, and one that moves half a screen loses your place.
    property real step: Theme.bar.control * 3

    acceptedDevices: PointerDevice.Mouse

    onWheel: event => {
        let flick = root.flick;
        for (let p = root.parent; !flick && p; p = p.parent)
            flick = p as Flickable;
        if (!flick)
            return;
        // angleDelta is in eighths of a degree; 120 is one detent.
        const dy = event.angleDelta.y / 120 * root.step;
        const limit = Math.max(0, flick.contentHeight - flick.height);
        flick.contentY = Math.max(0, Math.min(limit, flick.contentY - dy));
    }
}

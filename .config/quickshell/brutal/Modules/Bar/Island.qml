import QtQuick
import QtQuick.Layouts
import qs.Config
import qs.Components

/// One floating segment of the bar. The bar is three of these, not a strip.
BrutalBox {
    id: root

    property int hPadding: Theme.space.md
    property int vPadding: Theme.space.sm
    property int spacing: Theme.space.sm
    default property alias content: row.data

    /// Controls inside cast their own hard shadow down and to the right, and
    /// that shadow is drawn *outside* their bounds — so it never shows up in
    /// `row.implicitHeight`. Reserve it here, or the shadow of a button lands
    /// on the island's own border.
    ///
    /// The reserve is unconditional even for an island that casts nothing, so
    /// that all three islands come out the same height. Only the nudge below
    /// is conditional.
    readonly property int contentShadow: Theme.shadow.sm

    /// Whether the content in fact casts that shadow. False for an island of
    /// flat things — text, glyphs, a tile with `shadowed: false` — which has
    /// nothing below the row to balance the nudge, and so just sits high.
    property bool contentShadowed: true

    /// `bar.height` is a floor rather than a fixed size: a taller row of
    /// controls grows the island instead of being clipped by it.
    readonly property int neededHeight:
        row.implicitHeight + root.contentShadow + root.vPadding * 2

    color: Theme.color.crust
    radius: Theme.radius.lg
    shadowOffset: Theme.shadow.md
    implicitWidth: row.implicitWidth + root.hPadding * 2
    implicitHeight: Math.max(Settings.data.bar.height, root.neededHeight)

    /// Whether the island as a whole is a button. Off by default: most
    /// islands are a tray of independent controls, not one target.
    property bool clickable: false
    signal clicked()

    // Behind the row (z: -1), so controls inside keep their own hit areas —
    // pressing next should skip a track, not open a panel. Anything the row
    // does not claim falls through to here.
    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: root.clickable
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        // The shadow only falls downward, so dead-centre leaves a wider gap
        // above than below. Nudge up by half of it to even the two out — but
        // only where there is actually a shadow down there.
        anchors.verticalCenterOffset: root.contentShadowed
            ? -Math.round(root.contentShadow / 2)
            : 0
        spacing: root.spacing
    }
}

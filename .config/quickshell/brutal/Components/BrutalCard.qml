import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.Config

/**
 * A titled panel: optional glyph + heading with a rule beneath it, then the
 * caller's content.
 *
 * Content is appended straight into the card's ColumnLayout, so children
 * position themselves with `Layout.*` attached properties rather than anchors.
 * The internal layout is assigned through `data` explicitly — declaring it as a
 * normal child would route it into `content` (the default property) and nest
 * the layout inside itself.
 */
BrutalBox {
    id: root

    property string title: ""
    property string icon: ""
    property int padding: Theme.space.lg
    property bool showDivider: true

    /// Optional decoration drawn inside the card, behind the content and
    /// clipped to its corners — the media card's blurred cover art. Declared as
    /// a Component rather than an item so a card without one costs nothing.
    property Component backdrop: null

    default property alias content: layout.data

    color: Theme.color.surface
    radius: Theme.radius.lg
    implicitWidth: layout.implicitWidth + root.padding * 2
    implicitHeight: layout.implicitHeight + root.padding * 2

    data: [
        ClippingRectangle {
            anchors.fill: parent
            anchors.margins: Theme.border.width
            // Inset by the border, so shave the same off the corner or the
            // clip cuts a hair inside the stroke and leaves a pale seam.
            radius: Math.max(0, root.radius - Theme.border.width)
            color: "transparent"
            visible: root.backdrop !== null

            Loader {
                anchors.fill: parent
                sourceComponent: root.backdrop
            }
        },

        ColumnLayout {
            id: layout

            anchors.fill: parent
            anchors.margins: root.padding
            spacing: Theme.space.md

            RowLayout {
                visible: root.title !== ""
                Layout.fillWidth: true
                spacing: Theme.space.sm

                BrutalIcon {
                    visible: root.icon !== ""
                    text: root.icon
                    font.pixelSize: Theme.font.size.md
                }

                BrutalText {
                    text: root.title
                    font.pixelSize: Theme.font.size.md
                    font.weight: Theme.font.weight.bold
                    Layout.fillWidth: true
                }
            }

            BrutalDivider {
                visible: root.title !== "" && root.showDivider
                Layout.fillWidth: true
            }
        }
    ]
}

import QtQuick
import QtQuick.Layouts
import qs.Config
import qs.Components
import qs.Services

/**
 * Modes that are easy to leave on by accident.
 *
 * The pill only exists while one of them is active — a recording light that is
 * always visible is a recording light nobody looks at. Each flag is clickable,
 * so turning the mode off never needs the dashboard.
 */
BrutalBox {
    id: root

    // The tints come from `mark`, not `color`: these are glyphs drawn straight
    // onto the island, with no block behind them to carry the colour.
    readonly property list<var> flags: [
        {
            key: "record",
            icon: Icons.record,
            on: Capture.recording,
            tint: Theme.mark.red
        },
        {
            key: "awake",
            icon: Icons.coffee,
            on: Idle.inhibited,
            tint: Theme.mark.mint
        },
        {
            key: "night",
            icon: Icons.nightLight,
            on: NightLight.enabled,
            tint: Theme.mark.peach
        }
    ]

    readonly property list<var> active: root.flags.filter(flag => flag.on)

    function activate(key: string): void {
        switch (key) {
        case "record": Capture.toggleRecording(false); break;
        case "awake": Idle.toggleInhibit(); break;
        case "night": NightLight.toggle(); break;
        }
    }

    visible: root.active.length > 0
    implicitWidth: row.implicitWidth + Theme.space.md * 2
    implicitHeight: Theme.bar.control
    radius: Theme.radius.sm
    color: Theme.color.base
    shadowOffset: Theme.shadow.sm

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Theme.space.sm

        Repeater {
            model: root.active

            delegate: BrutalIcon {
                id: flag

                required property var modelData

                text: flag.modelData.icon
                color: flag.modelData.tint
                font.pixelSize: Theme.font.barSize.lg

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -3
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activate(flag.modelData.key)
                }
            }
        }
    }
}

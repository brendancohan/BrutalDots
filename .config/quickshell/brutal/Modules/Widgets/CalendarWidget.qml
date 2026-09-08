import QtQuick
import QtQuick.Layouts
import qs.Config
import qs.Components
import qs.Services

/// Month grid with today ringed in mint, and arrows to page through months.
BrutalCard {
    id: root

    padding: Theme.space.lg
    showDivider: false

    /// Offset in months from the current one.
    property int monthOffset: 0

    readonly property date shown: {
        const d = new Date(Time.now.getFullYear(), Time.now.getMonth() + root.monthOffset, 1);
        return d;
    }

    /// 42 cells: leading days from the previous month, this month, then trailing.
    readonly property var cells: {
        const year = root.shown.getFullYear();
        const month = root.shown.getMonth();
        const firstWeekday = new Date(year, month, 1).getDay();
        const daysThis = new Date(year, month + 1, 0).getDate();
        const daysPrev = new Date(year, month, 0).getDate();

        const out = [];
        for (let i = firstWeekday - 1; i >= 0; i--) {
            out.push({ day: daysPrev - i, current: false });
        }
        for (let d = 1; d <= daysThis; d++) {
            out.push({ day: d, current: true });
        }
        let trailing = 1;
        while (out.length < 42) {
            out.push({ day: trailing++, current: false });
        }
        return out;
    }

    function isToday(cell): bool {
        return cell.current
            && root.monthOffset === 0
            && cell.day === Time.now.getDate();
    }

    // ── Header ─────────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space.sm

        BrutalText {
            text: Qt.formatDateTime(root.shown, "MMMM yyyy")
            font.pixelSize: Theme.font.size.lg
            font.weight: Theme.font.weight.bold
            Layout.fillWidth: true
        }

        BrutalIconButton {
            icon: Icons.chevronLeft
            size: 26
            radius: Theme.radius.pill
            onClicked: root.monthOffset--
        }

        BrutalIconButton {
            icon: Icons.chevronRight
            size: 26
            radius: Theme.radius.pill
            baseColor: root.monthOffset === 0 ? Theme.color.base : Theme.color.green
            onClicked: root.monthOffset++
        }
    }

    // ── Weekday header ─────────────────────────────────────────────────────
    GridLayout {
        Layout.fillWidth: true
        Layout.topMargin: Theme.space.sm
        columns: 7
        columnSpacing: 0
        rowSpacing: Theme.space.sm

        Repeater {
            model: ["SU", "MO", "TU", "WE", "TH", "FR", "SA"]

            delegate: BrutalText {
                required property string modelData

                Layout.fillWidth: true
                text: modelData
                dim: true
                font.pixelSize: Theme.font.size.xs
                font.weight: Theme.font.weight.bold
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // ── Days ───────────────────────────────────────────────────────────
        Repeater {
            model: root.cells

            delegate: Item {
                id: cell

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: 26

                Rectangle {
                    id: todayDot

                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    radius: 12
                    visible: root.isToday(cell.modelData)
                    color: Theme.color.green
                    border.width: Theme.border.width
                    border.color: Theme.color.ink
                    antialiasing: true
                }

                BrutalText {
                    anchors.centerIn: parent
                    text: cell.modelData.day
                    font.pixelSize: Theme.font.size.sm
                    font.weight: root.isToday(cell.modelData)
                        ? Theme.font.weight.bold : Theme.font.weight.normal
                    // Today's number sits on the green dot rather than on the
                    // card, so it takes the ink that reads on the dot.
                    color: todayDot.visible ? Theme.inkOn(todayDot.color)
                        : cell.modelData.current ? Theme.color.ink : Theme.color.subtext
                    opacity: cell.modelData.current ? 1 : 0.5
                }
            }
        }
    }
}

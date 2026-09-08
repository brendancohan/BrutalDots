import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.Config
import qs.Components
import qs.Services

/**
 * Wallpaper picker — a grid of everything in the wallpaper directory, filtered
 * as you type, applied on Return or a click.
 *
 * Selecting writes the path to settings.json, so the choice is what the
 * backdrop reads and what survives a restart; there is no separate "current
 * wallpaper" state to fall out of step.
 *
 * Only the focused monitor draws it, matching the launcher.
 */
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData

        readonly property bool onFocusedMonitor: Hyprland.focusedMonitor
            ? Hyprland.focusedMonitor.name === win.modelData.name
            : true

        property string query: ""
        property int selected: 0

        readonly property list<string> results: {
            const needle = win.query.trim().toLowerCase();
            if (needle === "") return Wallpaper.available;
            return Wallpaper.available.filter(file =>
                Wallpaper.basename(file).toLowerCase().includes(needle));
        }

        screen: win.modelData
        visible: ShellState.wallpaperPickerOpen && win.onFocusedMonitor
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "brutaldots-wallpaper-picker"

        function activate(): void {
            if (win.results.length === 0) return;
            Wallpaper.select(win.results[win.selected]);
            ShellState.closeWallpaperPicker();
        }

        /// Wraps, so holding Right walks the whole grid rather than sticking.
        function move(delta: int): void {
            const count = win.results.length;
            if (count === 0) return;
            win.selected = ((win.selected + delta) % count + count) % count;
            grid.positionViewAtIndex(win.selected, GridView.Contain);
        }

        onQueryChanged: {
            win.selected = 0;
            grid.positionViewAtBeginning();
        }

        onVisibleChanged: {
            if (!win.visible) return;
            field.text = "";
            win.query = "";
            // Someone may have dropped files in since the last open.
            Wallpaper.rescan();
            // Open on the wallpaper already in use, so the grid shows where you
            // are rather than always starting from the top.
            const current = Wallpaper.available.indexOf(Wallpaper.path);
            win.selected = current >= 0 ? current : 0;
            grid.positionViewAtIndex(win.selected, GridView.Contain);
            field.forceFocus();
        }

        // ── Scrim ──────────────────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            color: Theme.color.overlay

            MouseArea {
                anchors.fill: parent
                onClicked: ShellState.closeWallpaperPicker()
            }
        }

        // ── Panel ──────────────────────────────────────────────────────────
        BrutalBox {
            id: panel

            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -Theme.shadow.lg / 2

            implicitWidth: Math.min(940, win.width - Theme.space.xxl * 2)
            implicitHeight: Math.min(680, win.height - Theme.space.xxl * 2)

            color: Theme.color.mantle
            radius: Theme.radius.xl
            shadowOffset: Theme.shadow.lg

            scale: win.visible ? 1 : 0.97
            Behavior on scale { NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.curve } }

            // Swallow clicks so they never reach the scrim.
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.space.lg
                spacing: Theme.space.md

                // ── Search row ─────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space.md

                    BrutalBox {
                        implicitWidth: 38
                        implicitHeight: 38
                        radius: Theme.radius.md
                        color: Theme.color.blue
                        shadowOffset: Theme.shadow.sm

                        BrutalIcon {
                            anchors.centerIn: parent
                            text: Icons.image
                            font.pixelSize: Theme.font.size.lg
                        }
                    }

                    BrutalTextField {
                        id: field

                        Layout.fillWidth: true
                        placeholder: "Search wallpapers…"
                        // The box is a filter, not the answer — Return applies
                        // the highlighted tile whether or not anything is typed.
                        acceptEmpty: true

                        onTextChanged: win.query = this.text
                        onAccepted: win.activate()

                        onKeyPressed: event => {
                            switch (event.key) {
                            case Qt.Key_Escape:
                                ShellState.closeWallpaperPicker();
                                event.accepted = true;
                                break;
                            case Qt.Key_Right:
                                win.move(1);
                                event.accepted = true;
                                break;
                            case Qt.Key_Left:
                                win.move(-1);
                                event.accepted = true;
                                break;
                            case Qt.Key_Down:
                                win.move(grid.columns);
                                event.accepted = true;
                                break;
                            case Qt.Key_Up:
                                win.move(-grid.columns);
                                event.accepted = true;
                                break;
                            case Qt.Key_Backspace:
                                // Only clear the wallpaper on a deliberate
                                // empty-field press, or typing a correction
                                // would blow the desktop away mid-search.
                                if (field.text === "" && (event.modifiers & Qt.ShiftModifier)) {
                                    Wallpaper.clear();
                                    ShellState.closeWallpaperPicker();
                                    event.accepted = true;
                                }
                                break;
                            }
                        }
                    }

                    BrutalPill {
                        text: `${win.results.length}`
                        color: Theme.color.lavender
                    }
                }

                // ── Grid ───────────────────────────────────────────────────
                ClippingRectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    radius: Theme.radius.md

                    GridView {
                        id: grid

                        anchors.fill: parent
                        model: win.results
                        clip: true
                        cacheBuffer: grid.height * 2

                        readonly property int columns: 4
                        readonly property int gutter: Theme.space.sm

                        cellWidth: Math.floor(grid.width / grid.columns)
                        cellHeight: Math.round(grid.cellWidth * 9 / 16)

                        currentIndex: win.selected

                        delegate: Item {
                            id: cell

                            required property int index
                            required property string modelData

                            width: grid.cellWidth
                            height: grid.cellHeight

                            readonly property bool active: cell.index === win.selected
                            readonly property bool current: cell.modelData === Wallpaper.path

                            BrutalBox {
                                anchors.fill: parent
                                anchors.margins: grid.gutter

                                color: Theme.color.base
                                radius: Theme.radius.md
                                // The selected tile is the one that lifts off
                                // the page; the rest sit flat, so the grid does
                                // not read as a field of competing cards.
                                shadowOffset: cell.active ? Theme.shadow.md : 0
                                border.width: cell.active ? 3 : 2

                                ClippingRectangle {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    radius: Theme.radius.sm
                                    color: Theme.color.mantle

                                    Image {
                                        id: thumb

                                        anchors.fill: parent
                                        source: `file://${cell.modelData}`
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        // Decode at tile size, not full size —
                                        // a directory of 4K photos is otherwise
                                        // gigabytes of texture.
                                        sourceSize.width: grid.cellWidth
                                        sourceSize.height: grid.cellHeight
                                    }

                                    // The scan matches on extension, which is a
                                    // guess: a failed download saved as .jpg is
                                    // still a .jpg to `find`. Say so on the tile
                                    // rather than letting someone pick a file
                                    // that silently leaves them on the pattern.
                                    Rectangle {
                                        anchors.fill: parent
                                        color: Theme.color.crust
                                        visible: thumb.status === Image.Error

                                        BrutalIcon {
                                            anchors.centerIn: parent
                                            anchors.verticalCenterOffset: -Theme.space.sm
                                            text: Icons.alert
                                            color: Theme.mark.red
                                            font.pixelSize: Theme.font.size.xl
                                        }
                                    }

                                    // Name plate, so tiles are still tellable
                                    // apart when several look alike.
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: label.implicitHeight + Theme.space.xs * 2
                                        color: Theme.color.crust

                                        BrutalText {
                                            id: label

                                            anchors.fill: parent
                                            anchors.leftMargin: Theme.space.sm
                                            anchors.rightMargin: Theme.space.sm
                                            verticalAlignment: Text.AlignVCenter
                                            elide: Text.ElideMiddle
                                            font.pixelSize: Theme.font.size.xs
                                            text: Wallpaper.title(cell.modelData)
                                        }
                                    }

                                    // Marks the wallpaper currently on screen.
                                    BrutalBox {
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: Theme.space.xs
                                        visible: cell.current

                                        implicitWidth: 26
                                        implicitHeight: 26
                                        radius: Theme.radius.sm
                                        color: Theme.color.mint
                                        shadowOffset: 0

                                        BrutalIcon {
                                            anchors.centerIn: parent
                                            text: Icons.check
                                            font.pixelSize: Theme.font.size.sm
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: win.selected = cell.index
                                    onClicked: {
                                        win.selected = cell.index;
                                        win.activate();
                                    }
                                }
                            }
                        }
                    }

                    // ── Empty states ───────────────────────────────────────
                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width - Theme.space.xl * 2
                        spacing: Theme.space.xs
                        visible: win.results.length === 0

                        BrutalText {
                            Layout.alignment: Qt.AlignHCenter
                            font.pixelSize: Theme.font.size.md
                            text: Wallpaper.scanning ? "Looking…"
                                : Wallpaper.available.length === 0 ? "No wallpapers found"
                                : "Nothing matches"
                        }

                        BrutalText {
                            Layout.alignment: Qt.AlignHCenter
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            dim: true
                            visible: !Wallpaper.scanning && Wallpaper.available.length === 0
                            font.pixelSize: Theme.font.size.xs
                            text: `Put images in ${Wallpaper.directory}, `
                                + "or point wallpaper.directory somewhere else."
                        }
                    }
                }

                // ── Footer ─────────────────────────────────────────────────
                BrutalText {
                    Layout.fillWidth: true
                    dim: true
                    font.pixelSize: Theme.font.size.xs
                    elide: Text.ElideRight
                    text: "↑↓←→ move · Return apply · Shift+Backspace use the pattern · Esc close"
                }
            }
        }
    }
}

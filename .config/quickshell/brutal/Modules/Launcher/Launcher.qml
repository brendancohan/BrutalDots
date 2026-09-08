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
 * Application launcher, command runner and clipboard picker — one surface with
 * three modes, because they all answer the same question: "type a bit, pick a
 * thing, press Return".
 *
 * Mode comes from how it was opened, except that a leading `>` always means
 * "run this command", so the terminal is never more than one keystroke away.
 * Only the focused monitor draws it; the others stay dark.
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
        property list<var> results: []

        /// Length of the leading run of previously-launched apps. Only while
        /// browsing: once there is a query the order is relevance, not habit,
        /// and a "frequent" heading over it would be a lie.
        readonly property int frequentCount:
            win.mode === "apps" && win.needle === ""
                ? Apps.frequentCount(win.results) : 0

        readonly property bool runMode: win.query.startsWith(">")
        readonly property string mode:
            ShellState.launcherMode === "clipboard" ? "clipboard"
            : win.runMode ? "run"
            : "apps"

        readonly property string needle: win.runMode ? win.query.slice(1) : win.query

        // Reading the app list here rather than on first open kicks the
        // asynchronous desktop-entry scan off at startup, so the launcher is
        // already populated by the time anyone presses SUPER+Space.
        readonly property int knownApps: Apps.all.length

        readonly property string modeLabel:
            win.mode === "clipboard" ? "CLIPBOARD"
            : win.mode === "run" ? "RUN"
            : "APPS"

        readonly property color modeTint:
            win.mode === "clipboard" ? Theme.color.lavender
            : win.mode === "run" ? Theme.color.peach
            : Theme.color.mint

        screen: win.modelData
        visible: ShellState.launcherOpen && win.onFocusedMonitor
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
        WlrLayershell.namespace: "brutaldots-launcher"

        function recompute(): void {
            if (win.mode === "clipboard") {
                const needle = win.needle.toLowerCase();
                win.results = needle === ""
                    ? Clipboard.entries
                    : Clipboard.entries.filter(entry =>
                        entry.preview.toLowerCase().indexOf(needle) !== -1);
            } else if (win.mode === "run") {
                win.results = [];
            } else {
                win.results = Apps.search(win.needle);
            }
            win.selected = 0;
        }

        function activate(): void {
            if (win.mode === "run") {
                // A bare `>` has nothing to run. Stay open rather than
                // dismissing on a keystroke that did nothing.
                if (win.needle.trim() === "") return;
                Apps.run(win.needle);
            } else if (win.results.length === 0) {
                return;
            } else if (win.mode === "clipboard") {
                Clipboard.copy(win.results[win.selected]);
            } else {
                Apps.launch(win.results[win.selected]);
            }
            ShellState.closeLauncher();
        }

        function move(delta: int): void {
            if (win.results.length === 0) return;
            const count = win.results.length;
            win.selected = ((win.selected + delta) % count + count) % count;
        }

        onQueryChanged: win.recompute()

        onVisibleChanged: {
            if (!win.visible) return;
            field.text = "";
            win.query = "";
            if (ShellState.launcherMode === "clipboard") Clipboard.refresh();
            win.recompute();
            field.forceFocus();
        }

        Connections {
            target: Clipboard
            function onEntriesChanged(): void {
                if (win.visible && win.mode === "clipboard") win.recompute();
            }
        }

        Connections {
            target: Apps
            function onAllChanged(): void {
                if (win.visible && win.mode !== "clipboard") win.recompute();
            }
        }

        // ── Scrim ──────────────────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            color: Theme.color.overlay

            MouseArea {
                anchors.fill: parent
                onClicked: ShellState.closeLauncher()
            }
        }

        // ── Panel ──────────────────────────────────────────────────────────
        BrutalBox {
            id: panel

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: -Theme.shadow.lg / 2
            anchors.top: parent.top
            anchors.topMargin: Math.round(win.height * 0.16)

            implicitWidth: Math.min(620, win.width - Theme.space.xxl * 2)
            implicitHeight: layout.implicitHeight + Theme.space.lg * 2

            color: Theme.color.mantle
            radius: Theme.radius.xl
            shadowOffset: Theme.shadow.lg

            scale: win.visible ? 1 : 0.97
            Behavior on scale { NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.curve } }

            // Swallow clicks so they never reach the scrim.
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: layout

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
                        color: win.modeTint
                        shadowOffset: Theme.shadow.sm

                        BrutalIcon {
                            anchors.centerIn: parent
                            text: win.mode === "clipboard" ? Icons.clipboard
                                : win.mode === "run" ? Icons.commandLine
                                : Icons.search
                            font.pixelSize: Theme.font.size.lg
                        }
                    }

                    BrutalTextField {
                        id: field

                        Layout.fillWidth: true
                        placeholder: win.mode === "clipboard" ? "Search clipboard…"
                            : "Search apps, or > to run a command"

                        // Return acts on the highlighted row, so it has to
                        // work from an empty box too: opening the launcher and
                        // pressing Return should launch the top app.
                        acceptEmpty: true

                        onTextChanged: win.query = this.text
                        onAccepted: win.activate()

                        onKeyPressed: event => {
                            switch (event.key) {
                            case Qt.Key_Escape:
                                ShellState.closeLauncher();
                                event.accepted = true;
                                break;
                            case Qt.Key_Down:
                                win.move(1);
                                event.accepted = true;
                                break;
                            case Qt.Key_Up:
                                win.move(-1);
                                event.accepted = true;
                                break;
                            case Qt.Key_Tab:
                                ShellState.launcherMode =
                                    ShellState.launcherMode === "clipboard" ? "apps" : "clipboard";
                                field.text = "";
                                win.query = "";
                                if (ShellState.launcherMode === "clipboard") Clipboard.refresh();
                                win.recompute();
                                event.accepted = true;
                                break;
                            case Qt.Key_J:
                                if (event.modifiers & Qt.ControlModifier) {
                                    win.move(1);
                                    event.accepted = true;
                                }
                                break;
                            case Qt.Key_K:
                                if (event.modifiers & Qt.ControlModifier) {
                                    win.move(-1);
                                    event.accepted = true;
                                }
                                break;
                            case Qt.Key_Delete:
                                if (win.mode === "clipboard" && win.results.length > 0) {
                                    Clipboard.remove(win.results[win.selected]);
                                    event.accepted = true;
                                }
                                break;
                            }
                        }
                    }

                    BrutalPill {
                        text: win.modeLabel
                        color: win.modeTint
                        fontSize: Theme.font.size.xs
                        shadowOffset: Theme.shadow.sm
                    }
                }

                BrutalDivider { Layout.fillWidth: true }

                // ── Run mode: a single confirmation row ────────────────────
                BrutalBox {
                    Layout.fillWidth: true
                    visible: win.mode === "run"
                    implicitHeight: 44
                    radius: Theme.radius.md
                    color: Theme.color.base
                    shadowOffset: Theme.shadow.sm

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.space.md
                        anchors.rightMargin: Theme.space.md
                        spacing: Theme.space.md

                        BrutalIcon {
                            text: Icons.rocket
                            font.pixelSize: Theme.font.size.lg
                        }

                        BrutalText {
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle
                            text: win.needle.trim() === ""
                                ? "Type a command, then press Return"
                                : win.needle.trim()
                            dim: win.needle.trim() === ""
                            font.pixelSize: Theme.font.size.md
                            font.weight: Theme.font.weight.bold
                        }
                    }
                }

                // ── Results ────────────────────────────────────────────────
                ListView {
                    id: list

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(
                        list.contentHeight, Math.round(win.height * 0.42))
                    visible: win.mode !== "run" && win.results.length > 0

                    clip: true
                    spacing: Theme.space.xs
                    model: win.results
                    currentIndex: win.selected
                    highlightFollowsCurrentItem: true
                    highlightMoveDuration: Theme.anim.fast
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Column {
                        id: rowWrap

                        required property int index
                        required property var modelData

                        /// The two places a heading belongs: above the first
                        /// used app, and above the first unused one.
                        readonly property string heading:
                            win.frequentCount === 0 ? ""
                            : rowWrap.index === 0 ? "FREQUENT"
                            : rowWrap.index === win.frequentCount ? "ALL APPS"
                            : ""

                        width: ListView.view.width
                        spacing: Theme.space.xs

                        BrutalText {
                            visible: rowWrap.heading !== ""
                            text: rowWrap.heading
                            dim: true
                            font.pixelSize: Theme.font.size.xs
                            font.weight: Theme.font.weight.bold
                            font.letterSpacing: 1
                            topPadding: rowWrap.index === 0 ? 0 : Theme.space.sm
                        }

                        BrutalButton {
                            id: row

                            readonly property int index: rowWrap.index
                            readonly property var modelData: rowWrap.modelData

                            readonly property bool current: row.index === win.selected

                            width: parent.width
                            implicitHeight: 46
                            radius: Theme.radius.md
                            shadowOffset: Theme.shadow.sm
                            shadowed: row.current
                            baseColor: row.current ? Theme.color.peach : Theme.color.base
                            hoverColor: row.current ? Theme.color.peach : Theme.color.crust

                            onClicked: {
                                win.selected = row.index;
                                win.activate();
                            }

                            onRightClicked: {
                                if (win.mode === "clipboard") Clipboard.remove(row.modelData);
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.space.md
                                anchors.rightMargin: Theme.space.md
                                spacing: Theme.space.md

                                // Applications get their real icon; clipboard rows
                                // get a glyph saying what kind of thing they hold.
                                IconImage {
                                    visible: win.mode === "apps"
                                    implicitSize: 26
                                    asynchronous: true
                                    source: win.mode === "apps"
                                        ? Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                                        : ""
                                }

                                BrutalIcon {
                                    visible: win.mode === "clipboard"
                                    text: row.modelData.isBinary ? Icons.image : Icons.copy
                                    font.pixelSize: Theme.font.size.lg
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    BrutalText {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        // The model swaps type when the mode
                                        // changes, so both sides need a fallback
                                        // for the frame in between.
                                        text: (win.mode === "apps"
                                            ? row.modelData.name
                                            : row.modelData.preview) ?? ""
                                        font.pixelSize: Theme.font.size.md
                                        font.weight: Theme.font.weight.bold
                                    }

                                    BrutalText {
                                        id: subtitle

                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        visible: subtitle.text !== ""
                                        text: win.mode === "apps"
                                            ? (row.modelData.genericName || row.modelData.comment || "")
                                            : ""
                                        dim: true
                                        font.pixelSize: Theme.font.size.xs
                                    }
                                }

                                BrutalIcon {
                                    visible: row.current
                                    text: Icons.chevronRight
                                    font.pixelSize: Theme.font.size.md
                                }
                            }
                        }
                    }
                }

                // ── Empty state ────────────────────────────────────────────
                BrutalText {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.space.sm
                    Layout.bottomMargin: Theme.space.sm
                    visible: win.mode !== "run" && win.results.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    dim: true
                    font.pixelSize: Theme.font.size.sm
                    text: win.mode === "clipboard"
                        ? (Clipboard.available ? "Clipboard history is empty"
                            : "cliphist is not installed")
                        : "Nothing matches"
                }

                // ── Hints ──────────────────────────────────────────────────
                BrutalText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    dim: true
                    font.pixelSize: Theme.font.size.xs
                    font.letterSpacing: 1
                    text: win.mode === "clipboard"
                        ? "TAB APPS   ·   DEL REMOVE   ·   RETURN COPY"
                        : "TAB CLIPBOARD   ·   > RUN   ·   RETURN LAUNCH"
                }
            }
        }
    }
}

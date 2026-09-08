import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Config
import qs.Components
import qs.Services

/**
 * The dashboard's Keybinds tab: every bind BrutalDots declares, grouped, with a
 * chip you can press a new combo into.
 *
 * Rebinding writes an override and reloads Hyprland; it never edits the Lua.
 * Anything in custom/keybinds.lua is not listed — that file is the user's — but
 * it is still checked for clashes before a new combo is accepted.
 */
ColumnLayout {
    id: root

    property string filter: ""

    /// Flat list of section headers and rows, so one ListView can render both.
    /// A JS-array model has no roles for `section.property` to read, and
    /// interleaving is simpler than reaching for a QAbstractItemModel.
    readonly property var rows: {
        const out = [];
        const needle = root.filter.trim().toLowerCase();

        for (const group of Keybinds.groups) {
            const matching = Keybinds.catalogue.filter(e => {
                if (e.group !== group) return false;
                if (needle === "") return true;
                return e.description.toLowerCase().includes(needle)
                    || Keybinds.comboFor(e).toLowerCase().includes(needle)
                    || group.toLowerCase().includes(needle);
            });

            if (matching.length === 0) continue;
            out.push({ header: group });
            for (const e of matching) out.push({ header: "", entry: e });
        }
        return out;
    }

    readonly property int overriddenCount:
        Keybinds.catalogue.filter(e => Keybinds.isOverridden(e)).length

    /// What the pending combo would collide with, checked against this
    /// catalogue and against everything else Hyprland has bound.
    property string pending: ""

    readonly property var clash: {
        if (root.pending === "") return null;
        const mine = Keybinds.conflict(root.pending, Keybinds.capturingId);
        if (mine) return { combo: root.pending, what: `${mine.group}: ${mine.description}` };
        const theirs = Keybinds.foreignConflict(root.pending);
        if (theirs) return { combo: root.pending, what: theirs.description };
        return null;
    }

    function commit(combo: string): void {
        root.pending = combo;
        // A clash is shown, not blocked: two binds on one combo is legal, and
        // the user may well be in the middle of moving one out of the way.
        Keybinds.assign(Keybinds.capturingId, combo);
        Keybinds.endCapture();
        clearPending.restart();
    }

    Timer {
        id: clearPending
        interval: 6000
        onTriggered: root.pending = ""
    }

    spacing: Theme.space.lg

    // ── Key capture ────────────────────────────────────────────────────────
    // Focus follows capture: the pane only steals the keyboard while a row is
    // actually listening, so Escape still closes the dashboard the rest of the
    // time. While it is listening Hyprland is in an empty submap, so nothing
    // else reacts to the combo either.
    Item {
        id: sink

        focus: Keybinds.capturing
        Keys.onPressed: event => {
            if (!Keybinds.capturing) return;
            event.accepted = true;

            const combo = Keybinds.comboFromEvent(event);
            if (combo !== "") root.commit(combo);
        }
    }

    // ── Header ─────────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space.md

        BrutalTextField {
            Layout.fillWidth: true
            acceptEmpty: true
            placeholder: "Search keybinds…"
            onTextChanged: root.filter = this.text
        }

        BrutalButton {
            implicitWidth: 150
            implicitHeight: 38
            radius: Theme.radius.sm
            enabled: Keybinds.ready && root.overriddenCount > 0
            baseColor: Theme.color.base
            hoverColor: Theme.color.peach
            onClicked: Keybinds.resetAll()

            RowLayout {
                anchors.centerIn: parent
                spacing: Theme.space.sm

                BrutalIcon {
                    text: Icons.restart
                    font.pixelSize: Theme.font.icon.sm
                }

                BrutalText {
                    text: root.overriddenCount > 0
                        ? `Reset ${root.overriddenCount}` : "No changes"
                    font.pixelSize: Theme.font.size.md
                    font.weight: Theme.font.weight.bold
                }
            }
        }
    }

    // ── Banner ─────────────────────────────────────────────────────────────
    // One line that carries whatever the pane needs to say right now.
    BrutalBox {
        Layout.fillWidth: true
        implicitHeight: 40
        radius: Theme.radius.sm
        shadowOffset: Theme.shadow.sm
        visible: Keybinds.capturing || root.clash !== null || !Keybinds.ready
        color: root.clash !== null ? Theme.color.peach
            : Keybinds.capturing ? Theme.color.blue
            : Theme.color.grey

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.space.md
            anchors.rightMargin: Theme.space.md
            spacing: Theme.space.sm

            BrutalIcon {
                text: root.clash !== null ? Icons.alert : Icons.keyboard
                font.pixelSize: Theme.font.icon.sm
            }

            BrutalText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: Theme.font.size.md
                text: {
                    if (root.clash !== null)
                        return `${root.clash.combo} is also bound to ${root.clash.what} — both will fire.`;
                    if (Keybinds.capturing)
                        return "Listening… press the combo you want. Escape cancels.";
                    if (!Keybinds.catalogueLoaded)
                        return "No catalogue yet — run hyprctl reload to generate it.";
                    if (!Keybinds.ready)
                        return "Reading custom/keybinds.lua…";
                    return "";
                }
            }
        }
    }

    // ── The list ───────────────────────────────────────────────────────────
    ClippingRectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: "transparent"
        radius: Theme.radius.sm

        ListView {
            id: list

            anchors.fill: parent
            model: root.rows
            spacing: Theme.space.sm
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            // Room for the row shadows, which fall outside the row's own bounds.
            rightMargin: Theme.shadow.sm

            WheelScroll {}

            delegate: Loader {
                required property var modelData

                width: list.width - Theme.shadow.sm
                sourceComponent: modelData.header !== "" ? headerRow : bindRow

                onLoaded: {
                    if (modelData.header !== "") this.item.title = modelData.header;
                    else this.item.entry = modelData.entry;
                }
            }

            Component {
                id: headerRow

                RowLayout {
                    id: heading

                    property string title: ""

                    spacing: Theme.space.md

                    BrutalText {
                        text: heading.title.toUpperCase()
                        font.pixelSize: Theme.font.size.sm
                        font.weight: Theme.font.weight.black
                        font.letterSpacing: 1
                        dim: true
                    }

                    BrutalDivider { Layout.fillWidth: true }
                }
            }

            Component {
                id: bindRow

                KeybindRow {}
            }
        }
    }
}

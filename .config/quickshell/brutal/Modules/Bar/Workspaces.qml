import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.Config
import qs.Components
import qs.Services

/**
 * Workspace indicators that show the icon of the app living in each workspace,
 * with the focused one filled solid ink — the same treatment as the previews.
 */
RowLayout {
    id: root

    required property var screenName
    /// Always render at least this many slots, so the bar doesn't jump around.
    property int minWorkspaces: 5

    spacing: Theme.space.xs

    /// Focus a workspace by number.
    ///
    /// Not named `focus`: that is a FINAL property on QQuickItem and the call
    /// would silently go nowhere. Not `ws.activate()` either — it dispatches
    /// the bare legacy form, which a Lua config rejects. See AGENTS.md
    /// "Hyprland is configured in Lua". The plain form below is the fallback
    /// for a .conf-based Hyprland.
    function focusWorkspace(id: int): void {
        Quickshell.execDetached(["sh", "-c",
            `hyprctl dispatch 'hl.dsp.focus({ workspace = ${id} })' >/dev/null 2>&1 `
            + `|| hyprctl dispatch workspace ${id}`]);
    }

    /// Workspaces on this monitor, plus empty placeholders up to minWorkspaces.
    readonly property var shown: {
        const mine = Hyprland.workspaces.values
            .filter(ws => ws.id > 0 && (!ws.monitor || ws.monitor.name === root.screenName));
        const highest = mine.reduce((a, ws) => Math.max(a, ws.id), 0);
        const count = Math.max(root.minWorkspaces, highest);
        const out = [];
        for (let i = 1; i <= count; i++) {
            out.push({ id: i, ws: mine.find(w => w.id === i) ?? null });
        }
        return out;
    }

    Repeater {
        model: root.shown

        delegate: BrutalBox {
            id: chip

            required property var modelData

            readonly property var ws: chip.modelData.ws
            readonly property bool active: chip.ws?.focused ?? false
            readonly property bool occupied: (chip.ws?.toplevels?.values?.length ?? 0) > 0
            readonly property bool urgent: chip.ws?.urgent ?? false

            /// Window class of the topmost app. `wayland.appId` first;
            /// `lastIpcObject` carries no `class` for some windows. See
            /// AGENTS.md "Quickshell".
            readonly property string appClass: {
                const tops = chip.ws?.toplevels?.values ?? [];
                if (tops.length === 0) return "";
                const top = tops.find(t => t.activated) ?? tops[tops.length - 1];
                // `||` rather than `??`: an empty string has to fall through too.
                return top?.wayland?.appId || top?.lastIpcObject?.class || "";
            }

            implicitWidth: Theme.bar.control
            implicitHeight: Theme.bar.control
            radius: Theme.radius.sm
            color: chip.active ? Theme.color.ink
                : chip.urgent ? Theme.color.red
                : Theme.color.base
            shadowOffset: Theme.shadow.sm
            shadowed: !mouse.containsPress

            Behavior on color { ColorAnimation { duration: Theme.anim.fast } }

            transform: Translate {
                x: mouse.containsPress ? chip.shadowOffset : 0
                y: mouse.containsPress ? chip.shadowOffset : 0
            }

            /// Resolved once so the icon and the number fallback agree. The
            /// class is not looked up directly: see Apps.iconForClass.
            readonly property string iconSource: Apps.iconForClass(chip.appClass)

            // Real application icon when the workspace has a window...
            IconImage {
                anchors.centerIn: parent
                implicitSize: Theme.bar.glyph
                source: chip.iconSource
                visible: chip.iconSource !== ""
            }

            // ...otherwise just the workspace number.
            BrutalText {
                anchors.centerIn: parent
                visible: chip.iconSource === ""
                text: chip.modelData.id
                color: chip.active ? Theme.color.crust
                    : chip.occupied ? Theme.color.ink
                    : Theme.color.subtext
                font.pixelSize: Theme.font.barSize.sm
                font.weight: Theme.font.weight.bold
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                // Occupied or empty, the workspace is focused the same way —
                // see root.focusWorkspace for why activate() cannot be used.
                onClicked: root.focusWorkspace(chip.modelData.id)
            }
        }
    }
}

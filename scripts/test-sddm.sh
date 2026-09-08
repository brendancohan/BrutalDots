#!/usr/bin/env bash
# Drive the BrutalDots greeter under QtTest.
#
# The greeter is the one part of this repo you cannot test by looking at it: a
# mistake shows up at the login screen, which is exactly where you have no way
# to fix it. This assembles the theme, swaps SDDM's five context objects for
# stand-ins, and clicks the result with synthesised input.
#
# What it does *not* prove: that real pointer input reaches the same items.
# QtTest posts events straight into the window and so cannot see anything the
# compositor or platform plugin does to a real click.
#
#   ./scripts/test-sddm.sh

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

RUNNER=/usr/lib/qt6/bin/qmltestrunner
[[ -x "$RUNNER" ]] || { echo "need $RUNNER (package: qt6-declarative)" >&2; exit 1; }

"$REPO/install.sh" --build-sddm "$WORK/theme" light >/dev/null

python3 - "$WORK/theme" <<'PY'
import pathlib, re, sys
d = pathlib.Path(sys.argv[1])

# Theme reads `config` off the root context, which a test cannot populate.
t = d.joinpath("Theme.qml")
t.write_text(re.sub(r'readonly property bool dark: String\(config\.dark\) === "true"',
                    'readonly property bool dark: false', t.read_text()))

m = d.joinpath("Main.qml").read_text()

mocks = '''
    // ── injected by scripts/test-sddm.sh: stand-ins for SDDM's context objects
    property QtObject config: QtObject {
        property string dark: "false"
        property string message: ""
        property string label: ""
    }
    property QtObject keyboard: QtObject {
        property bool capsLock: false
        property var layouts: []
        property int currentLayout: 0
    }
    property QtObject sddm: QtObject {
        signal loginSucceeded()
        signal loginFailed()
        signal informationMessage(string message)
        property string hostName: "testhost"
        property bool canPowerOff: true
        property bool canReboot: true
        property bool canSuspend: true
        function login(u, p, s) { console.log("harness login:", u, s) }
    }
    property ListModel userModel: ListModel {
        property int lastIndex: 0
        property string lastUser: "tester"
        ListElement { name: "tester"; realName: "Tester" }
    }
    property ListModel sessionModel: ListModel {
        property int lastIndex: 1
        ListElement { name: "Hyprland (uwsm-managed)" }
        ListElement { name: "Hyprland" }
        ListElement { name: "Plasma (Wayland)" }
        ListElement { name: "Weston" }
    }
'''
anchor = "Rectangle {\n    id: root\n"
assert anchor in m, "Main.qml root changed shape"
m = m.replace(anchor, anchor + mocks, 1)

# objectNames, so the test can reach ids that are private to the component.
m, n = re.subn(r'(\n(\s*)id: sessionButton\n)', r'\1\2objectName: "sessionButton"\n', m, count=1)
assert n == 1, "sessionButton not found"
m, n = re.subn(r'(\n(\s*)id: entry\n)', r'\1\2objectName: "sessionEntry" + entry.index\n', m, count=1)
assert n == 1, "entry delegate not found"

d.joinpath("TestMain.qml").write_text(m)
d.joinpath("Main.qml").unlink()
PY

cat > "$WORK/theme/tst_greeter.qml" <<'EOF'
import QtQuick
import QtTest

Item {
    width: 1920; height: 1080

    TestMain { id: greeter; anchors.fill: parent }

    TestCase {
        name: "greeter"
        when: windowShown

        function init() {
            greeter.sessionIndex = 1;
            findChild(greeter, "sessionButton").open = false;
        }

        function test_models_load() {
            compare(greeter.sessions.length, 4, "all sessions read from the model");
            compare(greeter.sessionName, "Hyprland");
            compare(greeter.users.length, 1);
        }

        function test_pick_a_session_with_the_pointer() {
            var btn = findChild(greeter, "sessionButton");
            mouseClick(btn, btn.width / 2, btn.height / 2);
            verify(btn.open, "clicking the button opens the menu");

            var e = findChild(greeter, "sessionEntry2");
            verify(e !== null, "entry 2 exists");
            verify(e.visible && e.width > 0 && e.height > 0, "entry 2 is clickable");

            mouseClick(e, e.width / 2, e.height / 2);
            compare(greeter.sessionIndex, 2, "the click selected entry 2");
            compare(greeter.sessionName, "Plasma (Wayland)");
            verify(!btn.open, "picking closes the menu");
        }

        function test_clicking_away_dismisses() {
            var btn = findChild(greeter, "sessionButton");
            mouseClick(btn, btn.width / 2, btn.height / 2);
            verify(btn.open);
            mouseClick(greeter, 60, 60);
            verify(!btn.open, "a click outside closes the menu");
            compare(greeter.sessionIndex, 1, "and changes nothing");
        }

        // The menu no longer lives inside the button's parent, so nothing
        // structural keeps the two aligned any more — only the margin
        // arithmetic against the power cluster, which test-mode hides and the
        // real greeter shows.
        function test_menu_aligns_with_its_button() {
            var btn = findChild(greeter, "sessionButton");
            var menu = findChild(greeter, "sessionEntry0").parent.parent;
            btn.open = true;
            var btnRight = btn.mapToItem(greeter, btn.width, 0).x;
            var menuRight = menu.mapToItem(greeter, menu.width, 0).x;
            fuzzyCompare(menuRight, btnRight, 1,
                "menu right edge should sit under the button's right edge");
            verify(menu.mapToItem(greeter, 0, menu.height).y <= btn.mapToItem(greeter, 0, 0).y,
                "menu should sit above the button");
        }

        function test_pick_a_session_with_the_keyboard() {
            keyClick(Qt.Key_F2);
            compare(greeter.sessionIndex, 2, "F2 advances the session");
            keyClick(Qt.Key_F2);
            keyClick(Qt.Key_F2);
            compare(greeter.sessionIndex, 0, "and wraps around");
        }
    }
}
EOF

script -qec "QT_QPA_PLATFORM=offscreen $RUNNER -input '$WORK/theme/tst_greeter.qml'" /dev/null 2>&1 \
    | grep -vE 'propertyCache|^\s*$'

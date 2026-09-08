import QtQuick
import QtQml
import QtQuick.Layouts

/**
 * BrutalDots greeter — the lock screen, rewritten against SDDM's API.
 *
 * Theme, Icons and the Brutal* components are copied next to this file by
 * ./install.sh; only this file is written twice, because a greeter has to
 * choose a user and a session where the lock screen knows both.
 *
 * SDDM hands the theme five context objects: `sddm`, `userModel`,
 * `sessionModel`, `keyboard` and `config`. Their fields are read through
 * delegate role *names* rather than raw integers — see AGENTS.md.
 */
Rectangle {
    id: root

    // SDDM resizes the greeter window to the screen. These are only what
    // --test-mode shows a designer.
    width: 1920
    height: 1080
    color: Theme.color.mantle

    // ── State ──────────────────────────────────────────────────────────────
    property string password: ""
    property string status: ""
    property bool failed: false
    property bool busy: false

    property int userIndex: Math.max(0, userModel.lastIndex)
    property int sessionIndex: Math.max(0, sessionModel.lastIndex)

    /// Filled by the Instantiators below: [{ name, label }] in model order.
    property var users: []
    /// Session display names, in model order.
    property var sessions: []

    readonly property var currentUser: root.users[root.userIndex] ?? null
    readonly property string sessionName: root.sessions[root.sessionIndex] ?? ""

    property date now: new Date()

    function submit(): void {
        if (root.busy || root.password === "" || root.currentUser === null) return;
        root.busy = true;
        root.failed = false;
        root.status = "Checking…";
        sddm.login(root.currentUser.name, root.password, root.sessionIndex);
    }

    /// Clear a failure the moment the next attempt starts, so a stale "Wrong
    /// password" never sits over a field you are already retyping into.
    function clearFailure(): void {
        if (!root.failed) return;
        root.failed = false;
        root.status = "";
    }

    /// Choose a session and put focus back where it belongs.
    function pickSession(i: int): void {
        root.sessionIndex = i;
        sessionButton.open = false;
        field.forceFocus();
    }

    function nextSession(): void {
        if (root.sessions.length < 2) return;
        root.pickSession((root.sessionIndex + 1) % root.sessions.length);
    }

    function nextUser(): void {
        if (root.users.length < 2) return;
        root.userIndex = (root.userIndex + 1) % root.users.length;
        root.password = "";
        root.clearFailure();
    }

    Timer {
        // A minute would do for what is displayed, but a minute-aligned timer
        // has to be re-armed on every tick to stay aligned. One second is not
        // worth the extra machinery on a screen that exists for ten of them.
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // ── Model readers ──────────────────────────────────────────────────────
    // Instantiator rather than Repeater: these are not visual, and a Repeater
    // parked inside something invisible is a lie about why it exists. Both run
    // once at startup, in model order, so the arrays line up with the indices
    // SDDM hands back through `lastIndex` and expects in `login`.
    Instantiator {
        model: userModel
        delegate: QtObject {
            required property string name
            required property string realName
            Component.onCompleted: root.users = root.users.concat([{
                name: this.name,
                label: this.realName !== "" ? this.realName : this.name
            }])
        }
    }

    Instantiator {
        model: sessionModel
        delegate: QtObject {
            required property string name
            Component.onCompleted: root.sessions = root.sessions.concat([this.name])
        }
    }

    Connections {
        target: sddm

        function onLoginSucceeded(): void {
            root.busy = false;
            root.failed = false;
            root.status = "Welcome";
        }

        function onLoginFailed(): void {
            root.busy = false;
            root.password = "";
            root.failed = true;
            root.status = "Wrong password";
        }

        // PAM's own words — an expired account, a locked one, the prompt from
        // a second factor. Worth more than anything this file could invent.
        function onInformationMessage(message: string): void {
            root.status = message;
        }
    }

    // ── Clock ──────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.round(root.height * 0.18)
        spacing: Theme.space.sm

        BrutalText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(root.now, "HH:mm")
            font.pixelSize: 96
            font.weight: Theme.font.weight.black
            font.letterSpacing: -2
        }

        BrutalPill {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(root.now, "MMMM d, yyyy")
            color: Theme.color.peach
            fontSize: Theme.font.size.md
        }
    }

    // ── Authentication card ────────────────────────────────────────────────
    BrutalBox {
        id: card

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -Theme.shadow.lg / 2
        anchors.top: parent.top
        anchors.topMargin: Math.round(root.height * 0.52)

        implicitWidth: 360
        implicitHeight: form.implicitHeight + Theme.space.xl * 2
        color: Theme.color.base
        radius: Theme.radius.xl
        shadowOffset: Theme.shadow.lg

        // A wrong password shoves the card sideways once, then settles.
        // Done through a transform so the anchor binding survives.
        transform: Translate { id: nudge }

        SequentialAnimation {
            id: shake
            running: false
            NumberAnimation { target: nudge; property: "x"; to: 12; duration: 50 }
            NumberAnimation { target: nudge; property: "x"; to: -12; duration: 90 }
            NumberAnimation { target: nudge; property: "x"; to: 0; duration: 60 }
        }

        Connections {
            target: root
            function onFailedChanged(): void {
                if (root.failed) shake.restart();
            }
        }

        ColumnLayout {
            id: form

            anchors.fill: parent
            anchors.margins: Theme.space.xl
            spacing: Theme.space.md

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.md

                BrutalBox {
                    implicitWidth: 40
                    implicitHeight: 40
                    radius: Theme.radius.pill
                    color: Theme.color.lavender
                    shadowOffset: Theme.shadow.sm

                    BrutalIcon {
                        anchors.centerIn: parent
                        text: Icons.account
                        font.pixelSize: Theme.font.size.xl
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    BrutalText {
                        Layout.fillWidth: true
                        text: root.currentUser !== null ? root.currentUser.label : "No account"
                        elide: Text.ElideRight
                        font.pixelSize: Theme.font.size.lg
                        font.weight: Theme.font.weight.bold
                    }

                    BrutalText {
                        Layout.fillWidth: true
                        text: String(config.message) !== "" ? config.message : "Sign in"
                        elide: Text.ElideRight
                        dim: true
                        font.pixelSize: Theme.font.size.xs
                    }
                }

                // Only worth drawing where there is somewhere to go. With one
                // account this is the lock screen's static padlock instead.
                BrutalIconButton {
                    visible: root.users.length > 1
                    icon: Icons.chevronRight
                    size: 30
                    onClicked: root.nextUser()
                }

                BrutalIcon {
                    visible: root.users.length <= 1
                    text: Icons.lock
                    font.pixelSize: Theme.font.size.xl
                }
            }

            BrutalDivider { Layout.fillWidth: true }

            BrutalTextField {
                id: field

                Layout.fillWidth: true
                enabled: !root.busy
                echoMode: TextInput.Password
                placeholder: "Password"

                // A greeter has to work without a pointer — a dead mouse is
                // one of the reasons you end up at a login screen wanting a
                // different session in the first place. The field holds focus,
                // so the keys have to be taken here; the root item would never
                // see them.
                onKeyPressed: event => {
                    switch (event.key) {
                    case Qt.Key_F1:
                        root.nextUser();
                        event.accepted = true;
                        break;
                    case Qt.Key_F2:
                        root.nextSession();
                        event.accepted = true;
                        break;
                    case Qt.Key_Escape:
                        sessionButton.open = false;
                        event.accepted = true;
                        break;
                    }
                }

                onTextChanged: {
                    root.password = this.text;
                    if (this.text !== "") root.clearFailure();
                }

                onAccepted: root.submit()

                // The field owns root.password, so a reset has to be pushed
                // back into it.
                Connections {
                    target: root
                    function onPasswordChanged(): void {
                        if (root.password === "" && field.text !== "") field.text = "";
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.sm

                BrutalText {
                    Layout.fillWidth: true
                    text: root.status !== "" ? root.status : "Press Return to log in"
                    color: root.failed ? Theme.mark.red : Theme.color.subtext
                    elide: Text.ElideRight
                    font.pixelSize: Theme.font.size.xs
                }

                BrutalIcon {
                    visible: root.busy
                    text: Icons.refresh
                    font.pixelSize: Theme.font.size.md

                    RotationAnimation on rotation {
                        running: root.busy
                        from: 0
                        to: 360
                        duration: 900
                        loops: Animation.Infinite
                    }
                }
            }
        }
    }

    // Caps Lock earns its own chip rather than a line in the status row: it is
    // the reason for a failed login you have not made yet, so it has to be
    // readable before the mistake, not after it.
    BrutalPill {
        anchors.horizontalCenter: card.horizontalCenter
        anchors.top: card.bottom
        anchors.topMargin: Theme.space.lg + Theme.shadow.lg
        visible: keyboard.capsLock
        icon: Icons.alert
        text: "CAPS LOCK"
        color: Theme.color.yellow
    }

    // ── Bottom bar ─────────────────────────────────────────────────────────
    RowLayout {
        id: bottomBar

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.space.xxl
        spacing: Theme.space.md

        BrutalPill {
            icon: Icons.host
            text: String(config.label) !== "" ? config.label : sddm.hostName
            color: Theme.color.crust
        }

        // `visible: false` does not stop a text binding from being evaluated,
        // and currentLayout can point past the end of layouts when there is
        // only one — or none, which is what SDDM reports in --test-mode.
        BrutalPill {
            readonly property var layout: keyboard.layouts[keyboard.currentLayout] ?? null

            visible: this.layout !== null && keyboard.layouts.length > 1
            icon: Icons.keyboard
            text: this.layout !== null ? String(this.layout.shortName).toUpperCase() : ""
            color: Theme.color.crust
        }

        Item { Layout.fillWidth: true }

        // ── Session picker ─────────────────────────────────────────────────
        // Only the button lives in the bar. Its menu is declared at the top
        // level — see the end of this file for why.
        BrutalButton {
            id: sessionButton

            property bool open: false

            Layout.alignment: Qt.AlignVCenter
            implicitWidth: sessionRow.implicitWidth + Theme.space.md * 2
            implicitHeight: 30
            radius: Theme.radius.pill
            shadowOffset: Theme.shadow.sm
            enabled: root.sessions.length > 1
            onClicked: this.open = !this.open

            RowLayout {
                id: sessionRow
                anchors.centerIn: parent
                spacing: Theme.space.sm

                BrutalIcon {
                    text: Icons.wm
                    font.pixelSize: Theme.font.size.md
                }

                BrutalText {
                    text: root.sessionName
                    font.pixelSize: Theme.font.size.sm
                    font.weight: Theme.font.weight.bold
                }

                // The menu is reachable from the keyboard whether or not the
                // pointer cooperates, so the key that does it is written on
                // the control rather than left to be discovered.
                BrutalText {
                    visible: root.sessions.length > 1
                    text: "F2"
                    dim: true
                    font.pixelSize: Theme.font.size.xs
                }
            }
        }

        // ── Power ──────────────────────────────────────────────────────────
        // SDDM reports these as false when the greeter runs without its daemon
        // — which is exactly what --test-mode is — so a preview shows no power
        // buttons. On a real login screen they are there.
        RowLayout {
            id: powerCluster

            // Kept as one item so the session menu can right-align itself to
            // the button rather than to the edge of the screen. An empty
            // cluster has to be invisible, not merely zero-wide, or the bar
            // still reserves a gap for it.
            visible: sddm.canSuspend || sddm.canReboot || sddm.canPowerOff
            spacing: Theme.space.md

            BrutalIconButton {
                visible: sddm.canSuspend
                icon: Icons.sleep
                baseColor: Theme.color.blue
                onClicked: sddm.suspend()
            }

            BrutalIconButton {
                visible: sddm.canReboot
                icon: Icons.restart
                baseColor: Theme.color.peach
                onClicked: sddm.reboot()
            }

            BrutalIconButton {
                visible: sddm.canPowerOff
                icon: Icons.power
                baseColor: Theme.color.red
                onClicked: sddm.powerOff()
            }
        }
    }

    // ── Session menu ───────────────────────────────────────────────────────
    // A child of `root`, not of the button that opens it, and the last thing
    // in the file. Nested in the bar it had to reach up out of a 30px-tall
    // parent two layouts deep; Qt does deliver clicks to a child drawn outside
    // its parent, but the menu's stacking then depends on nothing else being
    // added below it in the bar. At the top level it is unambiguously above
    // everything, and it can take the click that dismisses it.
    //
    // It anchors to `bottomBar`, which is a real sibling — anchoring to
    // `sessionButton` would not work, since anchors only reach a parent or a
    // sibling and the button is two levels down inside the bar.
    MouseArea {
        anchors.fill: parent
        visible: sessionButton.open
        enabled: sessionButton.open
        // Anywhere outside the menu closes it. Without this the only way out
        // of an opened menu is to pick something from it.
        onClicked: sessionButton.open = false
    }

    BrutalBox {
        id: sessionMenu

        anchors.right: bottomBar.right
        anchors.rightMargin: powerCluster.visible
            ? powerCluster.width + bottomBar.spacing
            : 0
        anchors.bottom: bottomBar.top
        anchors.bottomMargin: Theme.space.sm + Theme.shadow.md

        visible: sessionButton.open
        color: Theme.color.base
        radius: Theme.radius.md
        implicitWidth: Math.max(sessionButton.implicitWidth,
                                sessionList.implicitWidth + Theme.space.sm * 2)
        implicitHeight: sessionList.implicitHeight + Theme.space.sm * 2

        ColumnLayout {
            id: sessionList
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: sessionModel

                BrutalButton {
                    id: entry

                    required property int index
                    required property string name

                    readonly property bool current: entry.index === root.sessionIndex

                    Layout.fillWidth: true
                    implicitWidth: label.implicitWidth + Theme.space.md * 2
                    implicitHeight: 28
                    radius: Theme.radius.sm
                    shadowed: false
                    baseColor: entry.current ? Theme.color.lavender : Theme.color.base

                    onClicked: root.pickSession(entry.index)

                    BrutalText {
                        id: label
                        anchors.centerIn: parent
                        text: entry.name
                        font.pixelSize: Theme.font.size.sm
                        font.weight: entry.current ? Theme.font.weight.bold
                                                   : Theme.font.weight.medium
                    }
                }
            }
        }
    }

    // The field is the only thing that should ever hold focus here.
    Component.onCompleted: field.forceFocus()
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.Config
import qs.Components
import qs.Services

/**
 * Session lock, over the Wayland session-lock protocol — no hyprlock to
 * install or theme separately, and if the shell dies while locked the
 * compositor keeps the session locked rather than exposing the desktop.
 *
 * Authenticates against PAM (/etc/pam.d/<lock.pamConfig>). The PamContext is a
 * sibling of the lock, not a child: the surface is a Component with its own
 * scope, and everything it calls has to resolve from the one context owning both.
 */
Scope {
    id: lock

    property string password: ""
    property string status: ""
    property bool failed: false
    property bool busy: false

    function reset(): void {
        lock.password = "";
        lock.status = "";
        lock.failed = false;
        lock.busy = false;
    }

    function submit(): void {
        if (lock.busy || lock.password === "") return;
        lock.busy = true;
        lock.failed = false;
        lock.status = "Checking…";
        if (!pam.start()) {
            lock.busy = false;
            lock.failed = true;
            lock.status = "Could not start PAM";
        }
    }

    PamContext {
        id: pam

        config: Settings.data.lock.pamConfig || "login"

        onPamMessage: {
            if (this.responseRequired) this.respond(lock.password);
        }

        onCompleted: result => {
            lock.busy = false;
            lock.password = "";

            if (result === PamResult.Success) {
                ShellState.locked = false;
                return;
            }

            lock.failed = true;
            lock.status = result === PamResult.MaxTries
                ? "Too many attempts"
                : "Wrong password";
        }

        onError: error => {
            lock.busy = false;
            lock.failed = true;
            lock.status = PamError.toString(error);
        }
    }

    WlSessionLock {
        id: session

        locked: ShellState.locked

        onLockedChanged: {
            if (!session.locked) lock.reset();
        }

        surface: WlSessionLockSurface {
            id: surface

            color: Theme.color.mantle

            // The field is the only thing that should ever hold focus here.
            Component.onCompleted: field.forceFocus()

            // ── Clock ──────────────────────────────────────────────────────
            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Math.round(surface.height * 0.18)
                spacing: Theme.space.sm

                BrutalText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Time.hour24
                    font.pixelSize: 96
                    font.weight: Theme.font.weight.black
                    font.letterSpacing: -2
                }

                BrutalPill {
                    Layout.alignment: Qt.AlignHCenter
                    text: Time.dateLong
                    color: Theme.color.peach
                    fontSize: Theme.font.size.md
                }
            }

            // ── Authentication card ────────────────────────────────────────
            BrutalBox {
                id: card

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: -Theme.shadow.lg / 2
                anchors.top: parent.top
                anchors.topMargin: Math.round(surface.height * 0.52)

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
                    target: lock
                    function onFailedChanged(): void {
                        if (lock.failed) shake.restart();
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
                                text: Settings.data.userName
                                font.pixelSize: Theme.font.size.lg
                                font.weight: Theme.font.weight.bold
                            }

                            BrutalText {
                                text: Settings.data.lock.message !== ""
                                    ? Settings.data.lock.message
                                    : "Session locked"
                                dim: true
                                font.pixelSize: Theme.font.size.xs
                            }
                        }

                        BrutalIcon {
                            text: Icons.lock
                            font.pixelSize: Theme.font.size.xl
                        }
                    }

                    BrutalDivider { Layout.fillWidth: true }

                    BrutalTextField {
                        id: field

                        Layout.fillWidth: true
                        enabled: !lock.busy
                        echoMode: TextInput.Password
                        placeholder: "Password"

                        onTextChanged: {
                            lock.password = this.text;
                            // Typing clears the last failure, so the message
                            // never lingers over a fresh attempt.
                            if (lock.failed && this.text !== "") {
                                lock.failed = false;
                                lock.status = "";
                            }
                        }

                        onAccepted: lock.submit()

                        // The field owns lock.password, so a reset has to be
                        // pushed back into it.
                        Connections {
                            target: lock
                            function onPasswordChanged(): void {
                                if (lock.password === "" && field.text !== "") field.text = "";
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space.sm

                        BrutalText {
                            Layout.fillWidth: true
                            text: lock.status !== "" ? lock.status : "Press Return to unlock"
                            color: lock.failed ? Theme.mark.red : Theme.color.subtext
                            font.pixelSize: Theme.font.size.xs
                        }

                        BrutalIcon {
                            visible: lock.busy
                            text: Icons.refresh
                            font.pixelSize: Theme.font.size.md

                            RotationAnimation on rotation {
                                running: lock.busy
                                from: 0
                                to: 360
                                duration: 900
                                loops: Animation.Infinite
                            }
                        }
                    }
                }
            }
        }
    }
}

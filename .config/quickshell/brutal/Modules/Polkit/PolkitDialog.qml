import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import qs.Config
import qs.Components
import qs.Services

/**
 * Polkit authentication agent.
 *
 * Registering here means there is no separate polkit-kde or polkit-gnome
 * process to install and keep alive, and the prompt matches the rest of the
 * shell instead of dropping a Breeze dialog onto a brutalist desktop.
 *
 * If another agent already owns the session, registration simply fails and
 * this stays out of the way.
 */
Scope {
    id: root

    readonly property var flow: agent.flow
    readonly property bool active:
        root.flow !== null && !root.flow.isCompleted

    PolkitAgent {
        id: agent
        path: "/dev/brutaldots/PolkitAgent"
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData

            readonly property bool onFocusedMonitor: Hyprland.focusedMonitor
                ? Hyprland.focusedMonitor.name === win.modelData.name
                : true

            screen: win.modelData
            visible: root.active && win.onFocusedMonitor
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
            WlrLayershell.namespace: "brutaldots-polkit"

            function cancel(): void {
                if (root.flow) root.flow.cancelAuthenticationRequest();
            }

            function submit(): void {
                if (root.flow && root.flow.isResponseRequired) root.flow.submit(field.text);
            }

            onVisibleChanged: {
                if (!win.visible) return;
                field.text = "";
                field.forceFocus();
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.color.overlay

                MouseArea {
                    anchors.fill: parent
                    onClicked: win.cancel()
                }
            }

            BrutalBox {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -Theme.shadow.lg / 2
                anchors.verticalCenterOffset: -Theme.shadow.lg / 2

                implicitWidth: 420
                implicitHeight: body.implicitHeight + Theme.space.xl * 2
                color: Theme.color.base
                radius: Theme.radius.xl
                shadowOffset: Theme.shadow.lg

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: body

                    anchors.fill: parent
                    anchors.margins: Theme.space.xl
                    spacing: Theme.space.md

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space.md

                        BrutalBox {
                            implicitWidth: 40
                            implicitHeight: 40
                            radius: Theme.radius.md
                            color: Theme.color.peach
                            shadowOffset: Theme.shadow.sm

                            BrutalIcon {
                                anchors.centerIn: parent
                                text: Icons.shield
                                font.pixelSize: Theme.font.size.xl
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            BrutalText {
                                text: "Authentication required"
                                font.pixelSize: Theme.font.size.lg
                                font.weight: Theme.font.weight.bold
                            }

                            BrutalText {
                                Layout.fillWidth: true
                                text: root.flow?.actionId ?? ""
                                elide: Text.ElideMiddle
                                dim: true
                                font.pixelSize: Theme.font.size.xs
                            }
                        }
                    }

                    BrutalDivider { Layout.fillWidth: true }

                    BrutalText {
                        Layout.fillWidth: true
                        text: root.flow?.message ?? ""
                        wrapMode: Text.WordWrap
                        font.pixelSize: Theme.font.size.md
                    }

                    BrutalTextField {
                        id: field

                        Layout.fillWidth: true
                        visible: root.flow?.isResponseRequired ?? false
                        echoMode: (root.flow?.responseVisible ?? false)
                            ? TextInput.Normal
                            : TextInput.Password
                        placeholder: root.flow?.inputPrompt || "Password"

                        onAccepted: win.submit()
                        onKeyPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                win.cancel();
                                event.accepted = true;
                            }
                        }
                    }

                    BrutalText {
                        Layout.fillWidth: true
                        visible: (root.flow?.supplementaryMessage ?? "") !== ""
                        text: root.flow?.supplementaryMessage ?? ""
                        wrapMode: Text.WordWrap
                        color: (root.flow?.supplementaryIsError ?? false)
                            ? Theme.color.red
                            : Theme.color.subtext
                        font.pixelSize: Theme.font.size.xs
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Theme.space.xs
                        spacing: Theme.space.md

                        Item { Layout.fillWidth: true }

                        BrutalButton {
                            implicitWidth: 110
                            implicitHeight: 34
                            radius: Theme.radius.md
                            shadowOffset: Theme.shadow.sm
                            baseColor: Theme.color.base
                            hoverColor: Theme.color.red
                            onClicked: win.cancel()

                            BrutalText {
                                anchors.centerIn: parent
                                text: "Cancel"
                                font.pixelSize: Theme.font.size.sm
                                font.weight: Theme.font.weight.bold
                            }
                        }

                        BrutalButton {
                            implicitWidth: 140
                            implicitHeight: 34
                            radius: Theme.radius.md
                            shadowOffset: Theme.shadow.sm
                            baseColor: Theme.color.mint
                            hoverColor: Theme.color.green
                            onClicked: win.submit()

                            BrutalText {
                                anchors.centerIn: parent
                                text: "Authenticate"
                                font.pixelSize: Theme.font.size.sm
                                font.weight: Theme.font.weight.bold
                            }
                        }
                    }
                }
            }
        }
    }
}

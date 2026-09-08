import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.Config
import qs.Components
import qs.Services

// Do NOT import Quickshell.Networking here. It exports a type called `Network`,
// which shadows the qs.Services singleton of the same name for this whole file
// — every `Network.foo` then silently resolves against the wrong object and
// reads undefined. Anything needed from that module goes through the service
// instead; `Network.wifiSecured()` exists for exactly that reason.

/**
 * Wi-Fi networks, hanging under the right island.
 *
 * Power the radio, scan, and join or leave a network. A saved or open network
 * joins on one click; anything else opens a passphrase field in the row itself
 * rather than a second window on top of this one.
 */
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData

        readonly property bool onFocusedMonitor: Hyprland.focusedMonitor
            ? Hyprland.focusedMonitor.name === win.modelData.name
            : true

        screen: win.modelData
        visible: ShellState.wifiOpen && !ShellState.locked && win.onFocusedMonitor
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
        WlrLayershell.namespace: "brutaldots-wifi"

        // Scanning keeps the radio busy and costs power, so it runs only while
        // the menu is open and is always handed back on the way out. The open
        // passphrase row goes with it — a half-typed secret should not survive
        // the window closing.
        onVisibleChanged: {
            if (!win.visible) {
                if (Network.wifiScanning) Network.setWifiScanning(false);
                panel.promptFor = "";
                Network.wifiError = "";
            } else if (Network.wifiEnabled) {
                Network.setWifiScanning(true);
            }
        }

        // Turning the radio on from inside the menu should start a scan too,
        // otherwise the list stays empty until you close and reopen it.
        Connections {
            target: Network
            function onWifiEnabledChanged(): void {
                if (win.visible && Network.wifiEnabled) Network.setWifiScanning(true);
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.closeWifi()
        }

        FocusScope {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: ShellState.closeWifi()

            BrutalBox {
                id: panel

                /// SSID of the row currently asking for a passphrase, or "".
                property string promptFor: ""

                anchors.top: parent.top
                anchors.topMargin: ShellState.barBottom + Theme.space.sm
                anchors.right: parent.right
                anchors.rightMargin: Settings.data.bar.sideMargin + Theme.shadow.md

                implicitWidth: 320
                implicitHeight: layout.implicitHeight + Theme.space.lg * 2

                color: Theme.color.surface
                radius: Theme.radius.lg
                shadowOffset: Theme.shadow.md

                scale: win.visible ? 1 : 0.96
                Behavior on scale {
                    NumberAnimation { duration: Theme.anim.normal; easing.type: Theme.anim.curve }
                }

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: layout

                    anchors.fill: parent
                    anchors.margins: Theme.space.lg
                    spacing: Theme.space.md

                    // ── Header: power and scan ─────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space.sm

                        BrutalBox {
                            implicitWidth: 34
                            implicitHeight: 34
                            radius: Theme.radius.sm
                            shadowOffset: Theme.shadow.sm
                            // An rfkill switch cannot be undone from software,
                            // so the toggle goes dead rather than lying.
                            enabled: Network.wifiHardwareEnabled
                            opacity: enabled ? 1 : 0.45
                            color: Network.wifiEnabled
                                ? Theme.color.blue : Theme.color.base

                            BrutalIcon {
                                anchors.centerIn: parent
                                text: Network.wifiEnabled ? Icons.wifi : Icons.wifiOff
                                font.pixelSize: Theme.font.size.lg
                                dim: !Network.wifiEnabled
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: Network.wifiHardwareEnabled
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Network.toggleWifi()
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            BrutalText {
                                text: "Wi-Fi"
                                font.pixelSize: Theme.font.size.md
                                font.weight: Theme.font.weight.bold
                            }

                            BrutalText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                dim: true
                                font.pixelSize: Theme.font.size.xs
                                text: !Network.wifiHardwareEnabled
                                        ? "Blocked by hardware switch"
                                    : !Network.wifiEnabled ? "Off"
                                    : Network.wifiBusySsid !== "" ? `Joining ${Network.wifiBusySsid}…`
                                    : Network.ssid !== "" ? `Connected to ${Network.ssid}`
                                    : Network.wifiScanning ? "Scanning…"
                                    : "Not connected"
                            }
                        }

                        BrutalBox {
                            implicitWidth: 34
                            implicitHeight: 34
                            radius: Theme.radius.sm
                            shadowOffset: Theme.shadow.sm
                            enabled: Network.wifiEnabled
                            opacity: enabled ? 1 : 0.45
                            color: Network.wifiScanning ? Theme.color.mint : Theme.color.base

                            BrutalIcon {
                                id: scanIcon

                                anchors.centerIn: parent
                                text: Icons.refresh
                                font.pixelSize: Theme.font.size.md

                                RotationAnimation on rotation {
                                    running: Network.wifiScanning
                                    from: 0; to: 360
                                    duration: 1600
                                    loops: Animation.Infinite
                                    // Unqualified `rotation` resolves to the
                                    // global scope, not the icon.
                                    onStopped: scanIcon.rotation = 0
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: Network.wifiEnabled
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Network.setWifiScanning(!Network.wifiScanning)
                            }
                        }
                    }

                    BrutalDivider { Layout.fillWidth: true }

                    // ── Networks ───────────────────────────────────────────
                    ClippingRectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(300, list.contentHeight)
                        visible: Network.wifiEnabled && Network.sortedWifi.length > 0
                        color: "transparent"
                        radius: Theme.radius.sm

                        ListView {
                            id: list

                            anchors.fill: parent
                            model: Network.sortedWifi
                            spacing: Theme.space.xs
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: ColumnLayout {
                                id: row

                                required property var modelData

                                readonly property bool secured:
                                    Network.wifiSecured(modelData)
                                readonly property bool busy:
                                    modelData.stateChanging
                                    || Network.wifiBusySsid === modelData.name
                                readonly property bool prompting:
                                    panel.promptFor === modelData.name

                                width: list.width
                                spacing: Theme.space.xs

                                BrutalButton {
                                    Layout.fillWidth: true
                                    implicitHeight: 46
                                    radius: Theme.radius.sm
                                    shadowOffset: Theme.shadow.sm
                                    baseColor: row.modelData.connected
                                        ? Theme.color.mint : Theme.color.base
                                    hoverColor: row.modelData.connected
                                        ? Theme.color.teal : Theme.color.crust

                                    // Connected: leave it. Saved or open: join.
                                    // Otherwise open the passphrase field.
                                    onClicked: {
                                        if (row.modelData.connected) {
                                            Network.disconnectWifi(row.modelData);
                                        } else if (Network.wifiNeedsPassword(row.modelData)) {
                                            Network.wifiError = "";
                                            panel.promptFor = row.prompting
                                                ? "" : row.modelData.name;
                                        } else {
                                            Network.connectWifi(row.modelData);
                                        }
                                    }

                                    // Right-click forgets a saved network, the
                                    // same gesture the wallpaper picker uses to
                                    // remove an entry.
                                    onRightClicked: {
                                        if (row.modelData.known) Network.forgetWifi(row.modelData);
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: Theme.space.md
                                        anchors.rightMargin: Theme.space.md
                                        spacing: Theme.space.sm

                                        BrutalIcon {
                                            text: Network.wifiIcon(
                                                row.modelData.signalStrength, row.secured)
                                            font.pixelSize: Theme.font.size.md
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0

                                            BrutalText {
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                                text: row.modelData.name || "(hidden network)"
                                                font.pixelSize: Theme.font.size.sm
                                                font.weight: Theme.font.weight.bold
                                            }

                                            BrutalText {
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                                dim: true
                                                font.pixelSize: Theme.font.size.xs
                                                text: row.busy ? "Working…"
                                                    : row.modelData.connected ? "Connected"
                                                    : row.modelData.known ? "Saved"
                                                    : row.secured ? "Secured"
                                                    : "Open"
                                            }
                                        }

                                        BrutalText {
                                            text: `${Math.round(row.modelData.signalStrength * 100)}%`
                                            font.pixelSize: Theme.font.size.xs
                                            font.weight: Theme.font.weight.bold
                                        }
                                    }
                                }

                                // ── Passphrase ─────────────────────────────
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: Theme.space.sm
                                    Layout.rightMargin: Theme.space.sm
                                    Layout.bottomMargin: Theme.space.xs
                                    visible: row.prompting
                                    spacing: Theme.space.xs

                                    BrutalTextField {
                                        id: pass

                                        Layout.fillWidth: true
                                        echoMode: TextInput.Password
                                        placeholder: "Passphrase"
                                        onAccepted: text => {
                                            Network.connectWifiWithPassword(
                                                row.modelData.name, text);
                                            pass.clear();
                                            panel.promptFor = "";
                                        }

                                        // Opening the field should put the
                                        // cursor in it; nobody opens this to
                                        // look at it.
                                        onVisibleChanged: if (visible) pass.forceFocus()
                                    }

                                    BrutalIconButton {
                                        icon: Icons.check
                                        onClicked: {
                                            Network.connectWifiWithPassword(
                                                row.modelData.name, pass.text);
                                            pass.clear();
                                            panel.promptFor = "";
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Errors and empty states ────────────────────────────
                    BrutalText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.font.size.xs
                        color: Theme.color.ink
                        visible: Network.wifiError !== ""
                        text: Network.wifiError
                    }

                    BrutalText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        dim: true
                        font.pixelSize: Theme.font.size.xs
                        visible: !Network.wifiEnabled || Network.sortedWifi.length === 0
                        text: !Network.wifiHardwareEnabled
                                ? "A hardware switch has the radio off."
                            : !Network.wifiEnabled ? "Turn Wi-Fi on to see networks."
                            : Network.wifiScanning ? "Looking for networks…"
                            : "No networks in range."
                    }
                }
            }
        }
    }
}

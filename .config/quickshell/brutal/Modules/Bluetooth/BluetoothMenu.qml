import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Bluetooth
import qs.Config
import qs.Components
import qs.Services

/**
 * Bluetooth devices, hanging under the right island.
 *
 * Power the adapter, scan, and connect or disconnect a device. Pairing is
 * handled too — BlueZ refuses to connect to a device it has never paired with,
 * so an unknown device's button pairs first and connects after.
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
        visible: ShellState.bluetoothOpen && !ShellState.locked && win.onFocusedMonitor
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
        WlrLayershell.namespace: "brutaldots-bluetooth"

        // Scanning burns power and keeps the adapter busy, so it only runs
        // while the menu is up, and is always handed back on the way out.
        onVisibleChanged: {
            if (!win.visible && Network.scanning) Network.setScanning(false);
        }

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.closeBluetooth()
        }

        FocusScope {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: ShellState.closeBluetooth()

            BrutalBox {
                id: panel

                anchors.top: parent.top
                anchors.topMargin: ShellState.barBottom + Theme.space.sm
                anchors.right: parent.right
                // Match the right island above, which is inset by its own
                // shadow so the visual gap matches the left side.
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
                            color: Network.bluetoothEnabled
                                ? Theme.color.blue : Theme.color.base

                            BrutalIcon {
                                anchors.centerIn: parent
                                text: Network.bluetoothEnabled
                                    ? Icons.bluetooth : Icons.bluetoothOff
                                font.pixelSize: Theme.font.size.lg
                                dim: !Network.bluetoothEnabled
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Network.toggleBluetooth()
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            BrutalText {
                                text: "Bluetooth"
                                font.pixelSize: Theme.font.size.md
                                font.weight: Theme.font.weight.bold
                            }

                            BrutalText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                dim: true
                                font.pixelSize: Theme.font.size.xs
                                text: !Network.bluetoothEnabled ? "Off"
                                    : Network.scanning ? "Scanning…"
                                    : Network.connectedBluetooth.length > 0
                                        ? `${Network.connectedBluetooth.length} connected`
                                        : "No devices connected"
                            }
                        }

                        BrutalBox {
                            implicitWidth: 34
                            implicitHeight: 34
                            radius: Theme.radius.sm
                            shadowOffset: Theme.shadow.sm
                            enabled: Network.bluetoothEnabled
                            opacity: enabled ? 1 : 0.45
                            color: Network.scanning ? Theme.color.mint : Theme.color.base

                            BrutalIcon {
                                id: scanIcon

                                anchors.centerIn: parent
                                text: Icons.refresh
                                font.pixelSize: Theme.font.size.md

                                // A quiet spin is the only hint that a scan is
                                // running; device rows may not change for
                                // several seconds.
                                RotationAnimation on rotation {
                                    running: Network.scanning
                                    from: 0; to: 360
                                    duration: 1600
                                    loops: Animation.Infinite
                                    // Unqualified `rotation` here resolves to
                                    // the global scope, not the icon.
                                    onStopped: scanIcon.rotation = 0
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: Network.bluetoothEnabled
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Network.setScanning(!Network.scanning)
                            }
                        }
                    }

                    BrutalDivider { Layout.fillWidth: true }

                    // ── Devices ────────────────────────────────────────────
                    ClippingRectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(300, list.contentHeight)
                        visible: Network.bluetoothEnabled && Network.sortedBluetooth.length > 0
                        color: "transparent"
                        radius: Theme.radius.sm

                        ListView {
                            id: list

                            anchors.fill: parent
                            model: Network.sortedBluetooth
                            spacing: Theme.space.xs
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: BrutalButton {
                                id: row

                                required property var modelData

                                readonly property bool busy:
                                    modelData.pairing
                                    || modelData.state === BluetoothDeviceState.Connecting
                                    || modelData.state === BluetoothDeviceState.Disconnecting

                                width: list.width
                                implicitHeight: 46
                                radius: Theme.radius.sm
                                shadowOffset: Theme.shadow.sm
                                baseColor: modelData.connected
                                    ? Theme.color.mint : Theme.color.base
                                hoverColor: modelData.connected
                                    ? Theme.color.teal : Theme.color.crust
                                onClicked: Network.toggleDevice(modelData)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.space.md
                                    anchors.rightMargin: Theme.space.md
                                    spacing: Theme.space.sm

                                    BrutalIcon {
                                        text: modelData.connected
                                            ? Icons.bluetoothConnected : Icons.bluetooth
                                        font.pixelSize: Theme.font.size.md
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        BrutalText {
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                            text: modelData.name || modelData.address
                                            font.pixelSize: Theme.font.size.sm
                                            font.weight: Theme.font.weight.bold
                                        }

                                        BrutalText {
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                            dim: true
                                            font.pixelSize: Theme.font.size.xs
                                            text: row.busy ? "Working…"
                                                : modelData.connected ? "Connected"
                                                : (modelData.paired || modelData.bonded)
                                                    ? "Paired" : "Not paired"
                                        }
                                    }

                                    // Only some devices report a battery, and
                                    // only while connected.
                                    BrutalText {
                                        visible: modelData.connected && modelData.batteryAvailable
                                        text: `${Math.round(modelData.battery * 100)}%`
                                        font.pixelSize: Theme.font.size.xs
                                        font.weight: Theme.font.weight.bold
                                    }
                                }
                            }
                        }
                    }

                    // ── Empty states ───────────────────────────────────────
                    BrutalText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        dim: true
                        font.pixelSize: Theme.font.size.xs
                        visible: !Network.bluetoothEnabled
                            || Network.sortedBluetooth.length === 0
                        text: !Network.bluetoothEnabled
                            ? "Turn bluetooth on to see devices."
                            : Network.scanning ? "Looking for devices…"
                            : "No devices yet — scan to find some."
                    }
                }
            }
        }
    }
}

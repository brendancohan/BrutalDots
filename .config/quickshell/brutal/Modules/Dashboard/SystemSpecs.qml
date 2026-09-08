import QtQuick
import QtQuick.Layouts
import qs.Config
import qs.Components
import qs.Services

/// Two-column grid of static system facts.
BrutalCard {
    id: root

    title: "System Specs"
    icon: Icons.specs
    padding: Theme.space.xl

    readonly property var specs: [
        { label: "OS",       value: SystemInfo.osName,   glyph: Icons.os,       tint: Theme.color.peach },
        { label: "WM",       value: SystemInfo.wm,       glyph: Icons.wm,       tint: Theme.color.blue },
        { label: "Env",    value: SystemInfo.shell,    glyph: Icons.shell,    tint: Theme.color.green },
        { label: "Host",     value: SystemInfo.host,     glyph: Icons.host,     tint: Theme.color.coral },
        { label: "Uptime",   value: SystemInfo.uptime,   glyph: Icons.uptime,   tint: Theme.color.lavender },
        { label: "Packages", value: SystemInfo.packages, glyph: Icons.packages, tint: Theme.color.mint }
    ]

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: Theme.space.md
        columnSpacing: Theme.space.md

        Repeater {
            model: root.specs

            delegate: BrutalBox {
                id: spec

                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: 64
                implicitHeight: 64
                radius: Theme.radius.sm
                color: Theme.color.base
                shadowOffset: Theme.shadow.sm

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space.md
                    spacing: Theme.space.md

                    BrutalBox {
                        implicitWidth: 34
                        implicitHeight: 34
                        radius: Theme.radius.sm
                        color: spec.modelData.tint
                        shadowed: false

                        BrutalIcon {
                            anchors.centerIn: parent
                            text: spec.modelData.glyph
                            font.pixelSize: Theme.font.icon.lg
                        }
                    }

                    ColumnLayout {
                        spacing: -1
                        Layout.fillWidth: true

                        BrutalText {
                            text: spec.modelData.label
                            dim: true
                            font.pixelSize: Theme.font.size.sm
                        }

                        BrutalText {
                            text: spec.modelData.value
                            font.pixelSize: Theme.font.size.lg
                            font.weight: Theme.font.weight.bold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}

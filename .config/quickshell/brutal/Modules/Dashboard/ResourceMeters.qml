import QtQuick
import QtQuick.Layouts
import qs.Config
import qs.Components
import qs.Services

/// CPU / RAM / disk usage bars.
BrutalCard {
    id: root

    padding: Theme.space.lg

    readonly property var meters: [
        { label: "CPU",  glyph: Icons.cpu,  tint: Theme.color.salmon, value: SystemInfo.cpuUsage },
        { label: "RAM",  glyph: Icons.ram,  tint: Theme.color.blue,   value: SystemInfo.memoryUsage },
        { label: "Disk", glyph: Icons.disk, tint: Theme.color.green,  value: SystemInfo.diskUsage }
    ]

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Theme.space.md

        Repeater {
            model: root.meters

            delegate: BrutalBox {
                id: meter

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: 56
                radius: Theme.radius.sm
                color: Theme.color.base
                shadowOffset: Theme.shadow.sm

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space.md
                    spacing: Theme.space.md

                    BrutalBox {
                        implicitWidth: 30
                        implicitHeight: 30
                        radius: Theme.radius.sm
                        color: meter.modelData.tint
                        shadowed: false

                        BrutalIcon {
                            anchors.centerIn: parent
                            text: meter.modelData.glyph
                            font.pixelSize: Theme.font.icon.sm
                        }
                    }

                    BrutalText {
                        text: meter.modelData.label
                        font.pixelSize: Theme.font.size.md
                        font.weight: Theme.font.weight.bold
                        Layout.preferredWidth: 38
                    }

                    BrutalProgress {
                        Layout.fillWidth: true
                        value: meter.modelData.value
                        fillColor: meter.modelData.tint
                        thickness: 16
                    }

                    BrutalText {
                        text: `${Math.round(meter.modelData.value * 100)}%`
                        font.pixelSize: Theme.font.size.md
                        font.weight: Theme.font.weight.bold
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: 40
                    }
                }
            }
        }
    }
}

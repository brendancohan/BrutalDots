import QtQuick
import QtQuick.Layouts
import qs.Config
import qs.Components
import qs.Services

/// Oversized time, with the weekday and date set beside it.
BrutalCard {
    id: root

    padding: Theme.space.xxl

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space.lg

        RowLayout {
            spacing: Theme.space.sm

            BrutalText {
                text: Time.hourPadded12
                font.pixelSize: Theme.font.size.huge
                font.weight: Theme.font.weight.black
                font.letterSpacing: 2
            }

            BrutalText {
                text: Time.meridiem
                dim: true
                font.pixelSize: Theme.font.size.md
                font.weight: Theme.font.weight.bold
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: Theme.space.sm
            }
        }

        BrutalDivider {
            vertical: true
            Layout.fillHeight: true
            Layout.topMargin: Theme.space.xs
            Layout.bottomMargin: Theme.space.xs
        }

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true

            BrutalText {
                text: Time.weekday
                font.pixelSize: Theme.font.size.md
                font.weight: Theme.font.weight.black
                font.letterSpacing: 1
            }

            BrutalText {
                text: Time.dateLong
                dim: true
                font.pixelSize: Theme.font.size.sm
            }
        }
    }
}

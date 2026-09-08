pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

/// One clock for the whole shell, so nothing drifts out of sync.
Singleton {
    id: root

    readonly property date now: clock.date

    readonly property string hour12: Qt.formatDateTime(root.now, "h:mm")
    readonly property string hour24: Qt.formatDateTime(root.now, "HH:mm")
    readonly property string hourPadded12: Qt.formatDateTime(root.now, "hh:mm")
    readonly property string meridiem: Qt.formatDateTime(root.now, "AP")
    readonly property string seconds: Qt.formatDateTime(root.now, "ss")

    readonly property string weekday: Qt.formatDateTime(root.now, "dddd").toUpperCase()
    readonly property string dateLong: Qt.formatDateTime(root.now, "MMMM d, yyyy")
    readonly property string dateMedium: Qt.formatDateTime(root.now, "dddd, MMMM d")

    /// "Good morning" / "Good afternoon" / "Good evening" / "Good night".
    readonly property string greeting: {
        const h = root.now.getHours();
        if (h < 5) return "Good night";
        if (h < 12) return "Good morning";
        if (h < 17) return "Good afternoon";
        if (h < 22) return "Good evening";
        return "Good night";
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}

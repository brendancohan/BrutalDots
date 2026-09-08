pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import qs.Config

/**
 * Notification server, plus a short-lived "popup" queue for toasts.
 *
 * History is whatever the server is tracking; we don't keep a parallel copy.
 * Popups are a separate list that ages out on a timer so a toast can disappear
 * while the notification stays in the panel.
 */
Singleton {
    id: root

    /// Full history, newest first.
    readonly property var list: {
        const v = server.trackedNotifications?.values ?? [];
        return v.slice().reverse();
    }
    readonly property int count: root.list.length

    /// Currently-visible toasts.
    property list<var> popups: []
    property bool doNotDisturb: false

    function dismiss(notification): void {
        root.popups = root.popups.filter(n => n !== notification);
        notification?.dismiss();
    }

    function dismissPopup(notification): void {
        root.popups = root.popups.filter(n => n !== notification);
    }

    function clearAll(): void {
        root.popups = [];
        for (const n of root.list.slice()) n?.dismiss();
    }

    /// `mark`, not `color`: this paints a 6px stripe with nothing on top of it,
    /// so the colour is the whole signal and it needs the end of the ramp that
    /// stands off the card rather than the one meant to sit under ink.
    function urgencyColor(notification): color {
        switch (notification?.urgency) {
            case NotificationUrgency.Critical: return Theme.mark.red;
            case NotificationUrgency.Low: return Theme.mark.blue;
            default: return Theme.mark.green;
        }
    }

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        actionIconsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;
            if (root.doNotDisturb) return;

            root.popups = [notification, ...root.popups].slice(0, 5);

            // Age the toast out; the notification itself stays in history.
            const timeout = notification.expireTimeout > 0
                ? notification.expireTimeout * 1000
                : 5000;
            expiry.createObject(root, { notification, interval: timeout });
        }
    }

    Component {
        id: expiry

        Timer {
            required property var notification

            running: true
            repeat: false
            onTriggered: {
                root.dismissPopup(notification);
                destroy();
            }
        }
    }
}

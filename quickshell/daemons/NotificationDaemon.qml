import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

Scope {
    id: root

    IpcHandler {
        target: "notifications"

        function dismiss_all(): void {
            NotificationService.dismissAll();
        }

        function dnd_toggle(): void {
            NotificationService.doNotDisturb = !NotificationService.doNotDisturb;
        }
    }
}

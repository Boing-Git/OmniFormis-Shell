pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root
    property var windowList: []
    property var windowByAddress: ({})
    property bool pendingWindowsUpdate: false

    function updateWindowList() {
        getClients.running = true;
    }

    function scheduleUpdates() {
        if (!pendingWindowsUpdate) {
            pendingWindowsUpdate = true;
            eventDebounceTimer.restart();
        }
    }

    function flushPendingUpdates() {
        if (pendingWindowsUpdate) {
            pendingWindowsUpdate = false;
            updateWindowList();
        }
    }

    Component.onCompleted: {
        updateWindowList();
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const eventName = `${event?.name ?? event?.event ?? event?.type ?? ""}`;
            if (["openwindow", "closewindow", "movewindow", "movewindowv2", "windowtitle", "workspace", "workspacev2", "activewindow", "activewindowv2"].includes(eventName)) {
                scheduleUpdates();
            }
        }
    }

    Timer {
        id: eventDebounceTimer
        interval: 50
        repeat: false
        onTriggered: root.flushPendingUpdates()
    }

    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                try {
                    root.windowList = JSON.parse(clientsCollector.text);
                    let tempWinByAddress = {};
                    for (var i = 0; i < root.windowList.length; ++i) {
                        var win = root.windowList[i];
                        tempWinByAddress[win.address] = win;
                    }
                    root.windowByAddress = tempWinByAddress;
                } catch (e) {
                    console.log("Failed to parse hyprctl clients", e);
                }
            }
        }
    }
}

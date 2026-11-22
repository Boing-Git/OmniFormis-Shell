pragma Singleton
import QtQuick

QtObject {
    property real targetWidth: 100
    property real targetHeight: 40
    property real targetRadius: 18
    property var activeItem: null
    property int openCount: 0
    property bool anyExpanded: false

    property Timer debounceTimer: Timer {
        interval: 10
        onTriggered: {
            anyExpanded = (openCount > 0);
        }
    }

    function notifyOpened(w, h, r, item) {
        targetWidth = w;
        targetHeight = h;
        if (r !== undefined) targetRadius = r;
        if (item !== undefined) activeItem = item;
        openCount++;
        anyExpanded = true;
        debounceTimer.stop();
    }

    function updateDimensions(w, h, r) {
        if (openCount > 0) {
            targetWidth = w;
            targetHeight = h;
            if (r !== undefined) targetRadius = r;
        }
    }

    function notifyClosed() {
        openCount = Math.max(0, openCount - 1);
        if (openCount === 0) {
            debounceTimer.restart();
        }
    }
}

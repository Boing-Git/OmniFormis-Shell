import QtQuick
import Quickshell
import Quickshell.Wayland
import QtCore
import ".."

PanelWindow {
    id: window
    color: "transparent"
    visible: true

    WlrLayershell.namespace: "desktop-clock"
    WlrLayershell.layer: WlrLayer.Bottom
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Only the clock itself should intercept mouse clicks on the Overlay layer
    mask: Region {
        item: clockContainer
    }

    Settings {
        id: clockSettings
        category: "DesktopClock"
        property int posX: 500
        property int posY: 500
    }

    Item {
        id: clockContainer
        width: clock.width
        height: clock.height
        x: clockSettings.posX
        y: clockSettings.posY

        AnalogClock {
            id: clock
            anchors.centerIn: parent
        }

        DragHandler {
            id: dragHandler
            target: clockContainer

            // Constrain dragging to the window bounds so it doesn't get lost
            xAxis.minimum: 0
            xAxis.maximum: window.width - clockContainer.width
            yAxis.minimum: 0
            yAxis.maximum: window.height - clockContainer.height

            onActiveChanged: {
                if (!active) {
                    clockSettings.posX = clockContainer.x;
                    clockSettings.posY = clockContainer.y;
                }
            }
        }
    }
}

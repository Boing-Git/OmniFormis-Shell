import QtQuick
import Quickshell
import Quickshell.Wayland
import QtCore
import "../.."
import "../../theme/variables.js" as Vars

PanelWindow {
    id: window
    color: "transparent"
    visible: Vars.desktopCalenderEnabled

    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Bottom
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    mask: Region {
        item: clockContainer
    }

    Settings {
        id: clockSettings
        category: "DesktopCalender"
        property int posX: 500
        property int posY: 100
    }

    Item {
        id: clockContainer
        width: clock.width
        height: clock.height
        x: clockSettings.posX
        y: clockSettings.posY

        Calender {
            id: clock
            anchors.centerIn: parent
        }

        DragHandler {
            id: dragHandler
            target: clockContainer

            xAxis.minimum: 0
            xAxis.maximum: window.width > 0 ? window.width - clockContainer.width : 9999
            yAxis.minimum: 0
            yAxis.maximum: window.height > 0 ? window.height - clockContainer.height : 9999

            onActiveChanged: {
                if (!active) {
                    clockSettings.posX = clockContainer.x;
                    clockSettings.posY = clockContainer.y;
                }
            }
        }
    }
}

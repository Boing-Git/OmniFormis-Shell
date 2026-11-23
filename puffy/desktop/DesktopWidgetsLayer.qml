import QtQuick
import Quickshell
import Quickshell.Wayland
import "Widgets"

PanelWindow {
    id: desktopWidgetsWindow
    color: "transparent"
    visible: true

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
        Region {
            item: clockWidget
            // We use item visibility to dynamically include/exclude them from the region
        }
        Region {
            item: calenderWidget
        }
        Region {
            item: mediaPlayerWidget
        }
    }

    Item {
        id: bgContainer
        anchors.fill: parent
        opacity: 0.0
        Component.onCompleted: layerEntranceAnim.start()
        NumberAnimation {
            id: layerEntranceAnim
            target: bgContainer
            property: "opacity"
            to: 1.0
            duration: 800
            easing.type: Easing.OutCubic
        }

        DesktopClock {
            id: clockWidget
        }

        DesktopCalender {
            id: calenderWidget
        }

        DesktopMediaPlayer {
            id: mediaPlayerWidget
        }
    }
}

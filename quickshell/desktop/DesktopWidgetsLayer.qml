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
        anchors.fill: parent

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

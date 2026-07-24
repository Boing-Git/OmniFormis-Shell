import QtQuick
import Quickshell
import Quickshell.Wayland
import QtCore
import "../.."
import "../../panels/ControlCenter" as CC
import "../../theme/variables.js" as Vars

PanelWindow {
    id: window
    color: "transparent"
    visible: Vars.desktopMediaPlayerEnabled

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
        item: playerContainer
    }

    Settings {
        id: playerSettings
        category: "DesktopMediaPlayer"
        property int posX: 100
        property int posY: 500
    }

    Item {
        id: playerContainer
        width: 500
        height: 180
        x: playerSettings.posX
        y: playerSettings.posY

        CC.MediaPlayer {
            id: player
            anchors.fill: parent
        }

        DragHandler {
            id: dragHandler
            target: playerContainer

            xAxis.minimum: 0
            xAxis.maximum: window.width > 0 ? window.width - playerContainer.width : 9999
            yAxis.minimum: 0
            yAxis.maximum: window.height > 0 ? window.height - playerContainer.height : 9999

            onActiveChanged: {
                if (!active) {
                    playerSettings.posX = playerContainer.x;
                    playerSettings.posY = playerContainer.y;
                }
            }
        }
    }
}

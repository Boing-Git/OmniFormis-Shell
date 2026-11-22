import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import ".."

PanelWindow {
    id: frameWindow
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Top
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false

    visible: Vars.panelStyle === "Attached" && !gameMode
    mask: Region {}

    Item {
        id: rootContainer
        anchors.fill: parent
        opacity: 0.0
        Component.onCompleted: layerEntranceAnim.start()
        NumberAnimation {
            id: layerEntranceAnim
            target: rootContainer
            property: "opacity"
            to: 1.0
            duration: 800
            easing.type: Easing.OutCubic
        }

    Item {
        anchors.fill: parent
        layer.enabled: Vars.isTranslucent()
        layer.samples: Vars.layerSamples

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Theme.surface
            border.width: 0
            radius: Vars.radiusExtraLarge
            antialiasing: true
        }

        InvertedCorner {
            anchors.top: parent.top
            anchors.left: parent.left
            side: "top-left"
            radius: Vars.radiusExtraLarge
            antialiasing: true
            color: Vars.tColor(Theme.surface, Vars.panelOpacity)
        }

        InvertedCorner {
            anchors.top: parent.top
            anchors.right: parent.right
            side: "top-right"
            radius: Vars.radiusExtraLarge
            antialiasing: true
            color: Vars.tColor(Theme.surface, Vars.panelOpacity)
        }

        InvertedCorner {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            side: "bottom-left"
            radius: Vars.radiusExtraLarge
            antialiasing: true
            color: Vars.tColor(Theme.surface, Vars.panelOpacity)
        }

        InvertedCorner {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            side: "bottom-right"
            radius: Vars.radiusExtraLarge
            antialiasing: true
            color: Vars.tColor(Theme.surface, Vars.panelOpacity)
        }
    }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtCore
import "../../Variables/variables.js" as Vars
import "../.."

ColumnLayout {
    id: displayMenu
    
    // Parent should set this to control visibility and animations
    property bool isActive: false
    signal backRequested()

    // Remove anchors.fill to allow dynamic implicit height
    anchors.margins: Vars.spacingLarge
    spacing: Vars.spacingMedium
    visible: isActive

    Process {
        id: scaleCmd
        property real targetScale: 1.0
        command: ["hyprctl", "eval", "hl.monitor({ output = \"\", mode = \"preferred\", position = \"auto\", scale = " + targetScale + " })"]
        running: false
    }

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: Vars.spacingMedium
        
        Rectangle {
            width: 40; height: 40; radius: 20
            color: backHoverDisp.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (backHoverDisp.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
            Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_surface; text: "\ue5c4" }
            MouseArea { id: backHoverDisp; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: displayMenu.backRequested() }
            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
        }
        Text { text: "Display Scale"; font.family: Vars.fontFamily; font.pixelSize: 24; font.weight: Font.Bold; color: Theme.on_surface; Layout.fillWidth: true }
    }

    Flickable {
        id: displayFlickable
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 450)
        contentHeight: displayListContainer.childrenRect.height; clip: true

        ColumnLayout {
            id: displayListContainer
            width: displayFlickable.width; spacing: Vars.spacingSmall

            Repeater {
                model: [1.0, 1.25, 1.5, 2.0]
                delegate: Rectangle {
                    property bool isScaleActive: Hyprland.focusedMonitor && Math.abs(Hyprland.focusedMonitor.scale - modelData) < 0.01
                    Layout.fillWidth: true; Layout.preferredHeight: 64
                    radius: isScaleActive ? 16 : 32
                    Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                    color: isScaleActive ? Theme.primary : (dispMouse.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (dispMouse.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : Theme.surface_container_low))
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                    
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 16; spacing: 12
                        
                        Rectangle {
                            Layout.preferredWidth: 40; Layout.preferredHeight: 40
                            radius: isScaleActive ? 12 : 20
                            Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            color: isScaleActive ? Theme.on_primary : Qt.rgba(Theme.on_surface_variant.r, Theme.on_surface_variant.g, Theme.on_surface_variant.b, 0.1)
                            Text {
                                anchors.centerIn: parent
                                font.family: "Material Symbols Outlined"; font.pixelSize: 22
                                color: isScaleActive ? Theme.surface : Theme.on_surface_variant
                                text: "\ue30d"
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            }
                        }
                        
                        ColumnLayout {
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter; spacing: 0
                            Text { 
                                text: modelData + "x Scale"; font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: Font.Bold
                                color: isScaleActive ? Theme.surface : Theme.on_surface_variant
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            }
                            Text { 
                                text: isScaleActive ? "Active" : "Apply scale"; font.family: Vars.fontFamily; font.pixelSize: 12; opacity: 0.8
                                color: isScaleActive ? Theme.surface : Theme.on_surface_variant
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            }
                        }
                        
                        Item { Layout.fillWidth: true } // Spacer
                    }
                    MouseArea {
                        id: dispMouse
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                        onClicked: {
                            scaleCmd.targetScale = modelData;
                            scaleCmd.running = true;
                        }
                    }
                }
            }
        }
    }
}

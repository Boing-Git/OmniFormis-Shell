import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "../../Variables/variables.js" as Vars
import "../.."

ColumnLayout {
    id: wifiMenu
    
    // Parent should set this to control visibility and animations
    property bool isActive: false
    signal backRequested()

    property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)

    // Remove anchors.fill to allow dynamic implicit height
    anchors.margins: Vars.spacingLarge
    spacing: Vars.spacingMedium
    
    opacity: isActive ? 1.0 : 0.0
    visible: opacity > 0
    transform: Translate {
        x: isActive ? 0 : 40
        Behavior on x { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
    }
    Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: isActive ? Vars.customEmphasizedDecelerate : Vars.customEmphasizedAccelerate } }

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: Vars.spacingMedium
        
        Rectangle {
            width: 40; height: 40; radius: 20
            color: backHoverWifi.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (backHoverWifi.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
            Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_surface; text: "\ue5c4" }
            MouseArea { id: backHoverWifi; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: wifiMenu.backRequested() }
            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
        }
        Text { text: "Wi-Fi Networks"; font.family: Vars.fontFamily; font.pixelSize: 24; font.weight: Font.Bold; color: Theme.on_surface; Layout.fillWidth: true }
        
        // Master Toggle Switch
        Rectangle {
            width: 56; height: 32; radius: 16
            color: Networking.wifiEnabled ? Theme.primary : Theme.surface_variant
            Rectangle {
                width: 24; height: 24; radius: 12
                color: Networking.wifiEnabled ? Theme.on_primary : Theme.on_surface_variant
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left; anchors.leftMargin: Networking.wifiEnabled ? 28 : 4
                Behavior on anchors.leftMargin { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Networking.wifiEnabled = !Networking.wifiEnabled }
        }
    }

    Flickable {
        id: wifiFlickable
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 450)
        contentHeight: wifiListContainer.childrenRect.height; clip: true

        ColumnLayout {
            id: wifiListContainer
            width: wifiFlickable.width; spacing: Vars.spacingSmall

            Repeater {
                model: wifiMenu.wifiDevice ? wifiMenu.wifiDevice.networks.values : []
                delegate: Rectangle {
                    visible: modelData.connected
                    Layout.fillWidth: true; Layout.preferredHeight: visible ? 64 : 0
                    radius: 16
                    Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                    color: modelData.connected ? Theme.primary : (wifiMouse.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (wifiMouse.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : Theme.surface_container_low))
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                    
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 16; spacing: 12
                        
                        Rectangle {
                            Layout.preferredWidth: 40; Layout.preferredHeight: 40
                            radius: modelData.connected ? 12 : 20
                            Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            color: modelData.connected ? Theme.on_primary : Qt.rgba(Theme.on_surface_variant.r, Theme.on_surface_variant.g, Theme.on_surface_variant.b, 0.1)
                            Text {
                                anchors.centerIn: parent
                                font.family: "Material Symbols Outlined"; font.pixelSize: 22
                                color: modelData.connected ? Theme.surface : Theme.on_surface_variant
                                text: {
                                    if (modelData.signalStrength === undefined) return "\ue63e";
                                    let tier = Math.min(Math.floor(modelData.signalStrength / 25), 3);
                                    return ["\ue1ba", "\uebe4", "\uebd6", "\uebe1"][tier] || "\ue63e";
                                }
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            }
                        }
                        
                        ColumnLayout {
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter; spacing: 0
                            Text { 
                                text: modelData.name; font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: Font.Bold
                                color: modelData.connected ? Theme.surface : Theme.on_surface_variant
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            }
                            Text { 
                                text: modelData.connected ? "Connected" : "Available"; font.family: Vars.fontFamily; font.pixelSize: 12; opacity: 0.8
                                color: modelData.connected ? Theme.surface : Theme.on_surface_variant
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            }
                        }
                        
                        Item { Layout.fillWidth: true } // Spacer pushes everything to the left
                    }
                    MouseArea {
                        id: wifiMouse
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                        onClicked: {
                            if (modelData.connected) {
                                modelData.disconnect();
                            } else {
                                modelData.connect();
                            }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../../Variables/variables.js" as Vars
import "../.."

ColumnLayout {
    id: bluetoothMenu
    
    // Parent should set this to control visibility and animations
    property bool isActive: false
    signal backRequested()

    property var adapter: Bluetooth.defaultAdapter
    property bool adapterState: adapter ? adapter.enabled : false

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
            color: backHoverBt.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (backHoverBt.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
            Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_surface; text: "\ue5c4" }
            MouseArea { id: backHoverBt; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: bluetoothMenu.backRequested() }
            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
        }
        Text { text: "Bluetooth Devices"; font.family: Vars.fontFamily; font.pixelSize: 24; font.weight: Font.Bold; color: Theme.on_surface; Layout.fillWidth: true }
        
        // Master Toggle Switch
        Rectangle {
            width: 56; height: 32; radius: 16
            color: adapterState ? Theme.primary : Theme.surface_variant
            Rectangle {
                width: 24; height: 24; radius: 12
                color: adapterState ? Theme.on_primary : Theme.on_surface_variant
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left; anchors.leftMargin: adapterState ? 28 : 4
                Behavior on anchors.leftMargin { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if(adapter) adapter.enabled = !adapter.enabled }
        }
    }

    Flickable {
        id: bluetoothFlickable
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 450)
        contentHeight: bluetoothListContainer.childrenRect.height; clip: true

        ColumnLayout {
            id: bluetoothListContainer
            width: bluetoothFlickable.width; spacing: Vars.spacingSmall

            Repeater {
                model: adapter && adapterState ? adapter.devices.values : []
                delegate: Rectangle {
                    visible: modelData.paired || modelData.connected
                    Layout.fillWidth: true; Layout.preferredHeight: visible ? 64 : 0
                    radius: 16
                    Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                    color: modelData.connected ? Theme.primary : (btMouse.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (btMouse.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : Theme.surface_container_low))
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
                                text: modelData.connected ? "\ue1a8" : "\ue1a7"
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            }
                        }
                        
                        ColumnLayout {
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter; spacing: 0
                            Text { 
                                text: modelData.name ? modelData.name : "Unknown Device"; font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: Font.Bold
                                color: modelData.connected ? Theme.surface : Theme.on_surface_variant
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            }
                            Text { 
                                text: modelData.connected ? "Connected" : "Paired"; font.family: Vars.fontFamily; font.pixelSize: 12; opacity: 0.8
                                color: modelData.connected ? Theme.surface : Theme.on_surface_variant
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            }
                        }
                        
                        Item { Layout.fillWidth: true } // Spacer pushes everything to the left
                    }
                    MouseArea {
                        id: btMouse
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

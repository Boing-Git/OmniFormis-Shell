import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import "../.."
import "../../Variables/variables.js" as Vars

ColumnLayout {
    id: rootBluetoothPage
    
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Vars.spacingMedium

    property var adapter
    property bool adapterState: adapter ? adapter.enabled : false

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Text {
            text: "Bluetooth"
            font.family: Vars.fontFamily
            font.pixelSize: 16
            font.weight: 500
            color: Theme.on_surface
        }
        Text {
            text: "Manage devices and discoverability"
            font.family: Vars.fontFamily
            font.pixelSize: 12
            color: Theme.on_surface
            opacity: 0.7
        }
    }

    Flickable {
        Layout.fillWidth: true; Layout.fillHeight: true
        contentHeight: btContent.childrenRect.height; clip: true
        flickDeceleration: 100; maximumFlickVelocity: 4000

        ColumnLayout {
            id: btContent
            width: parent.width; spacing: Vars.spacingSmall
            property bool isPairingMode: false

            // --- MAIN BLUETOOTH VIEW ---
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Vars.spacingSmall
                visible: !btContent.isPairingMode

                // Main Bluetooth Group
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    // Bluetooth Header Card
                    Rectangle {
                        id: btHeader
                        Layout.fillWidth: true; Layout.preferredHeight: 72
                        radius: 16; 
                        color: btHeaderMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container
                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                        
                        property bool hasDeviceBelow: {
                            if (!rootBluetoothPage.adapter || !rootBluetoothPage.adapter.devices.values) return false;
                            for (let i = 0; i < rootBluetoothPage.adapter.devices.values.length; ++i) {
                                let d = rootBluetoothPage.adapter.devices.values[i];
                                if (d && (d.paired || d.connected)) return true;
                            }
                            return false;
                        }
                        
                        Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.left: parent.left; visible: rootBluetoothPage.adapterState && parent.hasDeviceBelow; opacity: 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } } }
                        Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.right: parent.right; visible: rootBluetoothPage.adapterState && parent.hasDeviceBelow; opacity: 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } } }
                        
                        activeFocusOnTab: true
                        Keys.onSpacePressed: if(rootBluetoothPage.adapter) rootBluetoothPage.adapter.enabled = !rootBluetoothPage.adapter.enabled
                        Keys.onReturnPressed: if(rootBluetoothPage.adapter) rootBluetoothPage.adapter.enabled = !rootBluetoothPage.adapter.enabled
                        
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                            Text { text: "Bluetooth"; font.family: Vars.fontFamily; font.pixelSize: 16; font.weight: 500; color: Theme.on_surface; Layout.fillWidth: true }
                            
                            Rectangle {
                                width: 52; height: 32; radius: 16
                                color: rootBluetoothPage.adapterState ? Theme.primary : Theme.surface_variant
                                border.color: btHeader.activeFocus ? Theme.on_surface : "transparent"
                                border.width: btHeader.activeFocus ? 2 : 0
                                Rectangle {
                                    width: 24; height: 24; radius: 12
                                    color: rootBluetoothPage.adapterState ? Theme.on_primary : Theme.on_surface_variant
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left; anchors.leftMargin: rootBluetoothPage.adapterState ? 24 : 4
                                    Behavior on anchors.leftMargin { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                    Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 16; color: rootBluetoothPage.adapterState ? Theme.primary : Theme.surface_variant; text: rootBluetoothPage.adapterState ? "\ue5ca" : "\ue5cd" }
                                }
                            }
                        }
                        MouseArea { id: btHeaderMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: { btHeader.forceActiveFocus(); if(rootBluetoothPage.adapter) rootBluetoothPage.adapter.enabled = !rootBluetoothPage.adapter.enabled; } }
                    }

                    // Empty state (only if enabled and no devices)
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 120
                        visible: rootBluetoothPage.adapterState && (!rootBluetoothPage.adapter || rootBluetoothPage.adapter.devices.values.length === 0)
                        radius: 16; color: Theme.surface_container
                        
                        Rectangle { width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.left: parent.left }
                        Rectangle { width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.right: parent.right }
                        Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.left: parent.left }
                        Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.right: parent.right }
                        
                        ColumnLayout {
                            anchors.centerIn: parent; spacing: 8
                            Text { text: "\ue322"; font.family: "Material Symbols Outlined"; font.pixelSize: 32; color: Theme.on_surface_variant; Layout.alignment: Qt.AlignHCenter } // Devices icon
                            Text { text: "No saved devices"; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface_variant; Layout.alignment: Qt.AlignHCenter }
                        }
                    }

                    // Device List
                    Repeater {
                        model: rootBluetoothPage.adapter && rootBluetoothPage.adapterState ? rootBluetoothPage.adapter.devices.values : []
                        delegate: Rectangle {
                            id: btDelegate
                            Layout.fillWidth: true; Layout.preferredHeight: visible ? 72 : 0
                            visible: modelData.paired || modelData.connected
                            property bool isSelected: modelData.connected
                            property bool showForget: false
                            radius: isSelected ? 36 : 16
                            Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                            color: isSelected ? Theme.secondary_container : (btMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container)
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                            
                            Rectangle {
                                width: parent.radius; height: parent.radius; color: parent.color
                                anchors.top: parent.top; anchors.left: parent.left
                                opacity: parent.isSelected ? 0.0 : 1.0
                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                            }
                            Rectangle {
                                width: parent.radius; height: parent.radius; color: parent.color
                                anchors.top: parent.top; anchors.right: parent.right
                                opacity: parent.isSelected ? 0.0 : 1.0
                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                            }
                            property bool hasDeviceBelow: {
                                if (!rootBluetoothPage.adapter || !rootBluetoothPage.adapter.devices.values) return false;
                                for (let i = index + 1; i < rootBluetoothPage.adapter.devices.values.length; ++i) {
                                    let d = rootBluetoothPage.adapter.devices.values[i];
                                    if (d && (d.paired || d.connected)) return true;
                                }
                                return false;
                            }
                            
                            Rectangle {
                                width: parent.radius; height: parent.radius; color: parent.color
                                anchors.bottom: parent.bottom; anchors.left: parent.left
                                visible: parent.hasDeviceBelow
                                opacity: parent.isSelected ? 0.0 : 1.0
                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                            }
                            Rectangle {
                                width: parent.radius; height: parent.radius; color: parent.color
                                anchors.bottom: parent.bottom; anchors.right: parent.right
                                visible: parent.hasDeviceBelow
                                opacity: parent.isSelected ? 0.0 : 1.0
                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                            }

                            activeFocusOnTab: true
                            Keys.onSpacePressed: { if (modelData.connected) modelData.disconnect(); else modelData.connect(); }
                            Keys.onReturnPressed: { if (modelData.connected) modelData.disconnect(); else modelData.connect(); }
                            
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                                Text { text: modelData.connected ? "\ue1a8" : "\ue1a7"; font.family: "Material Symbols Outlined"; font.pixelSize: 24; color: modelData.connected ? Theme.primary : Theme.on_surface_variant }
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignVCenter; spacing: 0; Layout.fillWidth: true
                                    Text { text: modelData.name ? modelData.name : "Unknown Device"; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
                                    Text { text: modelData.connected ? "Connected" : "Available"; font.family: Vars.fontFamily; font.pixelSize: 11; font.weight: 500; color: Theme.on_surface_variant; visible: text !== ""; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
                                }
                            }
                            MouseArea {
                                id: btMouse
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (mouse) => {
                                    parent.forceActiveFocus();
                                    if (mouse.button === Qt.RightButton) {
                                        btDelegate.showForget = true;
                                    } else {
                                        if (modelData.connected) {
                                            modelData.disconnect();
                                        } else {
                                            modelData.trusted = true;
                                            modelData.connect();
                                        }
                                    }
                                }
                            }
                            
                            // Forget Overlay
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: Theme.surface_container_highest
                                visible: btDelegate.showForget
                                opacity: btDelegate.showForget ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                                
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 16; spacing: 16
                                    Text {
                                        text: "Forget " + (modelData.name || "Device") + "?"
                                        font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; Layout.fillWidth: true; elide: Text.ElideRight
                                    }
                                    Rectangle {
                                        width: 80; height: 32; radius: 16; color: "transparent"
                                        border.color: Theme.outline; border.width: 1
                                        Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.on_surface; font.family: Vars.fontFamily; font.pixelSize: 14 }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: btDelegate.showForget = false }
                                    }
                                    Rectangle {
                                        width: 80; height: 32; radius: 16; color: Theme.error ? Theme.error : "#ffb4ab"
                                        Text { anchors.centerIn: parent; text: "Forget"; color: Theme.on_error ? Theme.on_error : "#690005"; font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: 500 }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (modelData.forget) modelData.forget(); btDelegate.showForget = false; } }
                                    }
                                }
                            }
                        }
                    }

                    // Pair new device
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 72
                        visible: rootBluetoothPage.adapterState
                        radius: 16; color: btPairMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container
                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                        
                        Rectangle { 
                            width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.left: parent.left 
                            opacity: 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        }
                        Rectangle { 
                            width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.right: parent.right 
                            opacity: 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        }
                        
                        activeFocusOnTab: true
                        Keys.onSpacePressed: parent.forceActiveFocus()
                        Keys.onReturnPressed: parent.forceActiveFocus()
                        
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                            Text { text: "\ue145"; font.family: "Material Symbols Outlined"; font.pixelSize: 24; color: Theme.on_surface }
                            Text { text: "Pair new device"; font.family: Vars.fontFamily; font.pixelSize: 16; font.weight: 500; color: Theme.on_surface; Layout.fillWidth: true }
                        }
                        MouseArea { id: btPairMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { parent.forceActiveFocus(); btContent.isPairingMode = true; } }
                    }
                }

                Item { Layout.preferredHeight: Vars.spacingSmall }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    // Discoverable Card
                    Rectangle {
                        id: discCard
                        Layout.fillWidth: true; Layout.preferredHeight: 72; radius: 16; color: discMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container
                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                        visible: rootBluetoothPage.adapterState
                        
                        Rectangle { 
                            width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.left: parent.left 
                            opacity: 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        }
                        Rectangle { 
                            width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.right: parent.right 
                            opacity: 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        }
                        
                        activeFocusOnTab: true
                        Keys.onSpacePressed: if(rootBluetoothPage.adapter) rootBluetoothPage.adapter.discoverable = !rootBluetoothPage.adapter.discoverable
                        Keys.onReturnPressed: if(rootBluetoothPage.adapter) rootBluetoothPage.adapter.discoverable = !rootBluetoothPage.adapter.discoverable
                        
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text { text: "Discoverable"; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
                                Text { text: "Allow nearby devices to find this one"; font.family: Vars.fontFamily; font.pixelSize: 13; color: Theme.on_surface_variant; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
                            }
                            Rectangle {
                                width: 52; height: 32; radius: 16; color: rootBluetoothPage.adapter && rootBluetoothPage.adapter.discoverable ? Theme.primary : Theme.surface_variant
                                border.color: discCard.activeFocus ? Theme.on_surface : "transparent"; border.width: discCard.activeFocus ? 2 : 0
                                Rectangle {
                                    width: 24; height: 24; radius: 12; color: rootBluetoothPage.adapter && rootBluetoothPage.adapter.discoverable ? Theme.on_primary : Theme.on_surface_variant
                                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: rootBluetoothPage.adapter && rootBluetoothPage.adapter.discoverable ? 24 : 4
                                    Behavior on anchors.leftMargin { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                    Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 16; color: rootBluetoothPage.adapter && rootBluetoothPage.adapter.discoverable ? Theme.primary : Theme.surface_variant; text: rootBluetoothPage.adapter && rootBluetoothPage.adapter.discoverable ? "\ue5ca" : "\ue5cd" }
                                }
                            }
                        }
                        MouseArea { id: discMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { discCard.forceActiveFocus(); if(rootBluetoothPage.adapter) rootBluetoothPage.adapter.discoverable = !rootBluetoothPage.adapter.discoverable } }
                    }

                    // Pairable Card
                    Rectangle {
                        id: pairCard
                        Layout.fillWidth: true; Layout.preferredHeight: 72; radius: 16; color: pairMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container
                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                        visible: rootBluetoothPage.adapterState
                        
                        Rectangle { 
                            width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.left: parent.left 
                            opacity: 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        }
                        Rectangle { 
                            width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.right: parent.right 
                            opacity: 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        }
                        
                        activeFocusOnTab: true
                        Keys.onSpacePressed: if(rootBluetoothPage.adapter) rootBluetoothPage.adapter.pairable = !rootBluetoothPage.adapter.pairable
                        Keys.onReturnPressed: if(rootBluetoothPage.adapter) rootBluetoothPage.adapter.pairable = !rootBluetoothPage.adapter.pairable
                        
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text { text: "Pairable"; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
                                Text { text: "Allow devices like phones to pair to this PC (not needed for speakers)"; font.family: Vars.fontFamily; font.pixelSize: 13; color: Theme.on_surface_variant; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
                            }
                            Rectangle {
                                width: 52; height: 32; radius: 16; color: rootBluetoothPage.adapter && rootBluetoothPage.adapter.pairable ? Theme.primary : Theme.surface_variant
                                border.color: pairCard.activeFocus ? Theme.on_surface : "transparent"; border.width: pairCard.activeFocus ? 2 : 0
                                Rectangle {
                                    width: 24; height: 24; radius: 12; color: rootBluetoothPage.adapter && rootBluetoothPage.adapter.pairable ? Theme.on_primary : Theme.on_surface_variant
                                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: rootBluetoothPage.adapter && rootBluetoothPage.adapter.pairable ? 24 : 4
                                    Behavior on anchors.leftMargin { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                    Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 16; color: rootBluetoothPage.adapter && rootBluetoothPage.adapter.pairable ? Theme.primary : Theme.surface_variant; text: rootBluetoothPage.adapter && rootBluetoothPage.adapter.pairable ? "\ue5ca" : "\ue5cd" }
                                }
                            }
                        }
                        MouseArea { id: pairMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { pairCard.forceActiveFocus(); if(rootBluetoothPage.adapter) rootBluetoothPage.adapter.pairable = !rootBluetoothPage.adapter.pairable } }
                    }
                }
            }

            // --- PAIRING VIEW ---
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: btContent.isPairingMode

                // Pairing Header Card
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 72
                    radius: 16; 
                    color: Theme.surface_container
                    
                    property bool hasDeviceBelow: {
                        if (!rootBluetoothPage.adapter || !rootBluetoothPage.adapter.devices.values) return false;
                        for (let i = 0; i < rootBluetoothPage.adapter.devices.values.length; ++i) {
                            let d = rootBluetoothPage.adapter.devices.values[i];
                            if (d && !(d.paired || d.connected)) return true;
                        }
                        return false;
                    }
                    
                    // Square bottom corners for contiguous list
                    Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.left: parent.left; visible: parent.hasDeviceBelow }
                    Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.right: parent.right; visible: parent.hasDeviceBelow }
                    
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                        
                        // Back button
                        Rectangle {
                            width: 40; height: 40; radius: 20; color: backMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12)) : "transparent"
                            Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 24; color: Theme.on_surface; text: "\ue5c4" }
                            MouseArea { id: backMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: btContent.isPairingMode = false }
                        }

                        Text { text: "Pair new device"; font.family: Vars.fontFamily; font.pixelSize: 16; font.weight: 500; color: Theme.on_surface; Layout.fillWidth: true }
                        
                        // Discovering Toggle
                        Rectangle {
                            width: 52; height: 32; radius: 16
                            property bool isDiscovering: rootBluetoothPage.adapter && rootBluetoothPage.adapter.discovering !== undefined ? rootBluetoothPage.adapter.discovering : false
                            color: isDiscovering ? Theme.primary : Theme.surface_variant
                            Rectangle {
                                width: 24; height: 24; radius: 12
                                color: parent.isDiscovering ? Theme.on_primary : Theme.on_surface_variant
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left; anchors.leftMargin: parent.isDiscovering ? 24 : 4
                                Behavior on anchors.leftMargin { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Text { 
                                    id: rotIcon
                                    anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 16
                                    color: parent.parent.isDiscovering ? Theme.primary : Theme.surface_variant
                                    text: parent.parent.isDiscovering ? "\ue86a" : "\ue5cd" 
                                    RotationAnimation {
                                        target: rotIcon; property: "rotation"
                                        loops: Animation.Infinite; from: 0; to: 360; duration: 2000; running: rotIcon.parent.parent.isDiscovering
                                        onRunningChanged: if (!running) rotIcon.rotation = 0
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (rootBluetoothPage.adapter) {
                                        rootBluetoothPage.adapter.discovering = !rootBluetoothPage.adapter.discovering;
                                    }
                                }
                            }
                        }
                    }
                }

                // Device List
                Repeater {
                    model: rootBluetoothPage.adapter && rootBluetoothPage.adapterState && rootBluetoothPage.adapter.discovering ? rootBluetoothPage.adapter.devices.values : []
                    delegate: Rectangle {
                        id: btPairDelegate
                        Layout.fillWidth: true; Layout.preferredHeight: visible ? 72 : 0
                        property bool isSelected: modelData.connected
                        property bool showForget: false
                        radius: isSelected ? 36 : 16
                        color: isSelected ? Theme.secondary_container : (btPairItemMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container)
                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                        visible: !(modelData.paired || modelData.connected)
                        
                        Rectangle {
                            width: parent.radius; height: parent.radius; color: parent.color
                            anchors.top: parent.top; anchors.left: parent.left
                            opacity: parent.isSelected ? 0.0 : 1.0
                            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        }
                        Rectangle {
                            width: parent.radius; height: parent.radius; color: parent.color
                            anchors.top: parent.top; anchors.right: parent.right
                            opacity: parent.isSelected ? 0.0 : 1.0
                            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        }
                        property bool hasDeviceBelow: {
                            if (!rootBluetoothPage.adapter || !rootBluetoothPage.adapter.devices.values) return false;
                            for (let i = index + 1; i < rootBluetoothPage.adapter.devices.values.length; ++i) {
                                let d = rootBluetoothPage.adapter.devices.values[i];
                                if (d && !(d.paired || d.connected)) return true;
                            }
                            return false;
                        }
                        

                        
                        Rectangle {
                            width: parent.radius; height: parent.radius; color: parent.color
                            anchors.bottom: parent.bottom; anchors.left: parent.left
                            visible: parent.hasDeviceBelow
                            opacity: parent.isSelected ? 0.0 : 1.0
                            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        }
                        Rectangle {
                            width: parent.radius; height: parent.radius; color: parent.color
                            anchors.bottom: parent.bottom; anchors.right: parent.right
                            visible: parent.hasDeviceBelow
                            opacity: parent.isSelected ? 0.0 : 1.0
                            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        }
                        
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                            Text { text: "\ue1a7"; font.family: "Material Symbols Outlined"; font.pixelSize: 24; color: Theme.on_surface_variant }
                            ColumnLayout {
                                Layout.alignment: Qt.AlignVCenter; spacing: 0; Layout.fillWidth: true
                                Text { text: modelData.name ? modelData.name : "Unknown Device"; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
                                Text { text: "Available to pair"; font.family: Vars.fontFamily; font.pixelSize: 11; font.weight: 500; color: Theme.on_surface_variant; visible: text !== ""; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
                            }
                        }
                        MouseArea {
                            id: btPairItemMouse
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                parent.forceActiveFocus();
                                if (mouse.button === Qt.RightButton) {
                                    btPairDelegate.showForget = true;
                                } else {
                                    if (!modelData.paired) {
                                        if (rootBluetoothPage.adapter && !rootBluetoothPage.adapter.pairable) {
                                            rootBluetoothPage.adapter.pairable = true;
                                        }
                                        modelData.pair();
                                        Quickshell.execDetached({ command: ["bash", "-c", `
                                            for i in {1..60}; do
                                                if bluetoothctl info ${modelData.address} | grep -q "Paired: yes"; then
                                                    bluetoothctl trust ${modelData.address}
                                                    sleep 0.5
                                                    bluetoothctl connect ${modelData.address}
                                                    break
                                                fi
                                                sleep 0.5
                                            done
                                        `] });
                                    } else {
                                        modelData.trusted = true;
                                        modelData.connect();
                                    }
                                }
                            }
                        }
                        
                        // Forget Overlay
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Theme.surface_container_highest
                            visible: btPairDelegate.showForget
                            opacity: btPairDelegate.showForget ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                            
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 16
                                Text {
                                    text: "Forget " + (modelData.name || "Device") + "?"
                                    font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; Layout.fillWidth: true; elide: Text.ElideRight
                                }
                                Rectangle {
                                    width: 80; height: 32; radius: 16; color: "transparent"
                                    border.color: Theme.outline; border.width: 1
                                    Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.on_surface; font.family: Vars.fontFamily; font.pixelSize: 14 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: btPairDelegate.showForget = false }
                                }
                                Rectangle {
                                    width: 80; height: 32; radius: 16; color: Theme.error ? Theme.error : "#ffb4ab"
                                    Text { anchors.centerIn: parent; text: "Forget"; color: Theme.on_error ? Theme.on_error : "#690005"; font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: 500 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (modelData.forget) modelData.forget(); btPairDelegate.showForget = false; } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

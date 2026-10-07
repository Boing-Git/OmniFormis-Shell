import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import "../../.."
import "../../../theme"
import "../../../core/primitives" as Primitives
import ".."

Item {
    id: btDelegate
    property var rootPage

    Layout.fillWidth: true; Layout.preferredHeight: visible ? 80 : 0
    visible: modelData.paired || modelData.connected
    property bool isSelected: modelData.connected
    property bool showForget: false
    
    property color targetColor: isSelected ? (Vars.tColorSelected(Theme.primary_container)) : (btMouse.containsMouse ? (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)))
    scale: btMouse.pressed ? 1.08 : 1.0
    Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }
    Behavior on targetColor { ColorAnimation { duration: Vars.animationDuration } }
    
    property bool hasDeviceBelow: {
        if (!rootPage.adapter || !rootPage.adapter.devices.values) return false;
        for (let i = index + 1; i < rootPage.adapter.devices.values.length; ++i) {
            let d = rootPage.adapter.devices.values[i];
            if (d && (d.paired || d.connected)) return true;
        }
        return true; // Pair new device is ALWAYS below!
    }
    
    Item {
        anchors.fill: parent
        opacity: parent.targetColor.a
        Rectangle {
            antialiasing: true
            anchors.fill: parent
            color: Qt.rgba(parent.parent.targetColor.r, parent.parent.targetColor.g, parent.parent.targetColor.b, 1.0)
            
            property real baseRadius: Vars.radiusLarge
            property real edgeRadius: 4
            
            
            topLeftRadius: parent.parent.isSelected ? height / 2 : edgeRadius
            topRightRadius: parent.parent.isSelected ? height / 2 : edgeRadius
            bottomLeftRadius: parent.parent.isSelected ? height / 2 : (parent.parent.hasDeviceBelow ? edgeRadius : baseRadius)
            bottomRightRadius: parent.parent.isSelected ? height / 2 : (parent.parent.hasDeviceBelow ? edgeRadius : baseRadius)

            Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
            Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
            Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
            Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        }
    }

    property bool isChangingState: false

    readonly property string statusText: {
        if (modelData.state === BluetoothDeviceState.Connecting)
            return "Connecting…";
        if (modelData.state === BluetoothDeviceState.Disconnecting)
            return "Disconnecting…";
        if (modelData.connected) {
            if (modelData.batteryAvailable) {
                var pct = modelData.battery <= 1 ? modelData.battery * 100 : modelData.battery;
                return "Connected · " + Math.round(pct) + "%";
            }
            return "Connected";
        }
        return "Paired";
    }
    
    Timer {
        id: stateTimeoutTimer
        interval: 15000 // 15-second safety timeout if connection attempt stalls
        repeat: false
        onTriggered: btDelegate.isChangingState = false
    }

    Connections {
        target: modelData
        function onConnectedChanged() {
            btDelegate.isChangingState = false;
            stateTimeoutTimer.stop();
        }
        // A failed attempt goes back to Disconnected without connectedChanged ever firing
        function onStateChanged() {
            if (modelData.state === BluetoothDeviceState.Connected || modelData.state === BluetoothDeviceState.Disconnected) {
                btDelegate.isChangingState = false;
                stateTimeoutTimer.stop();
            }
        }
    }

    function toggleConnection() {
        if (btDelegate.isChangingState) return;
        btDelegate.isChangingState = true;
        stateTimeoutTimer.restart();
        if (modelData.connected) {
            modelData.disconnect();
        } else {
            modelData.trusted = true;
            modelData.connect();
        }
    }

    activeFocusOnTab: true
    Keys.onSpacePressed: toggleConnection()
    Keys.onReturnPressed: toggleConnection()
    
    RowLayout {
        anchors.fill: parent; anchors.leftMargin: Vars.spacingLarge; anchors.rightMargin: Vars.spacingLarge; spacing: 16
        SettingsIcon {
            size: 40
            Layout.alignment: Qt.AlignVCenter
            selected: btDelegate.isSelected
            filled: modelData.connected
            icon: modelData.connected ? "\ue1a8" : "\ue1a7"
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter; spacing: 0; Layout.fillWidth: true
            QsText { text: modelData.name ? modelData.name : "Unknown Device"; font.family: Vars.fontFamily; font.pixelSize: 16; color: modelData.connected ? Theme.on_primary_container : Theme.on_surface; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
            QsText { text: btDelegate.statusText; font.family: Vars.fontFamily; font.pixelSize: 11; setWeight: 500; color: modelData.connected ? Theme.on_primary_container : Theme.on_surface_variant; visible: text !== ""; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
        }
        Item {
            width: 40; height: 40
            Layout.alignment: Qt.AlignVCenter
            Primitives.LoadingIndicator {
                anchors.fill: parent
                running: btDelegate.isChangingState || modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
            }
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
                toggleConnection();
            }
        }
    }
    
    // Forget Overlay
    Rectangle {
        antialiasing: true
        anchors.fill: parent
        
        property real baseRadius: Vars.radiusLarge
        property real edgeRadius: 4
        
        
        topLeftRadius: btDelegate.isSelected ? height / 2 : edgeRadius
        topRightRadius: btDelegate.isSelected ? height / 2 : edgeRadius
        bottomLeftRadius: btDelegate.isSelected ? height / 2 : (parent.hasDeviceBelow ? edgeRadius : baseRadius)
        bottomRightRadius: btDelegate.isSelected ? height / 2 : (parent.hasDeviceBelow ? edgeRadius : baseRadius)

        Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        color: Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)
        visible: btDelegate.showForget
        opacity: btDelegate.showForget ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        
        RowLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 16
            QsText {
                text: "Forget " + (modelData.name || "Device") + "?"
                font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; Layout.fillWidth: true; elide: Text.ElideRight
            }
            Rectangle {
                antialiasing: true
                width: 80; height: 32; radius: 16; color: "transparent"
                border.color: Theme.outline; border.width: 1
                QsText { anchors.centerIn: parent; text: "Cancel"; color: Theme.on_surface; font.family: Vars.fontFamily; font.pixelSize: 14 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: btDelegate.showForget = false }
            }
            Rectangle {
                antialiasing: true
                width: 80; height: 32; radius: 16; color: Theme.error ? Theme.error : "#ffb4ab"
                QsText { anchors.centerIn: parent; text: "Forget"; color: Theme.on_error ? Theme.on_error : "#690005"; font.family: Vars.fontFamily; font.pixelSize: 14; setWeight: 500 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (modelData.forget) modelData.forget(); btDelegate.showForget = false; } }
            }
        }
    }
}

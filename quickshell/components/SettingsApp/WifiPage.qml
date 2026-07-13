import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "../.."
import "../../Variables/variables.js" as Vars

Item {
    id: rootWifiPage
    
    Layout.fillWidth: true
    Layout.fillHeight: true

    property var panelRef
    property var wifiDevice

    property string selectedNetworkForInfo: ""
    property string selectedNetworkPassword: ""

    Process {
        id: nmcliPwdProcess
        property string targetSsid: ""
        command: ["pkexec", "nmcli", "-s", "-g", "802-11-wireless-security.psk", "connection", "show", targetSsid]
        stdout: StdioCollector {
            onStreamFinished: {
                let res = this.text.trim();
                rootWifiPage.selectedNetworkPassword = res ? res : "Authentication failed or not found";
            }
        }
    }

    function showPasswordFor(ssid) {
        rootWifiPage.selectedNetworkForInfo = ssid;
        rootWifiPage.selectedNetworkPassword = "Fetching...";
        nmcliPwdProcess.targetSsid = ssid;
        nmcliPwdProcess.running = true;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Vars.spacingMedium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
        Text {
            text: "Wi-Fi Networks"
            font.family: Vars.fontFamily
            font.pixelSize: 16
            font.weight: 500
            color: Theme.on_surface
        }
        Text {
            text: "Network connection and internet availability"
            font.family: Vars.fontFamily
            font.pixelSize: 12
            color: Theme.on_surface
            opacity: 0.7
        }
    }

    Flickable {
        Layout.fillWidth: true; Layout.fillHeight: true
        contentHeight: wifiContent.childrenRect.height; clip: true

        ColumnLayout {
            id: wifiContent
            width: parent.width; spacing: Vars.spacingSmall

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                // Wi-Fi Header Card
                Rectangle {
                    id: wifiHeader
                    Layout.fillWidth: true; Layout.preferredHeight: 72
                    radius: 16; color: wifiHeaderMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                    
                    Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.left: parent.left; visible: Networking.wifiEnabled; opacity: wifiHeaderMouse.containsMouse ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } } }
                    Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.right: parent.right; visible: Networking.wifiEnabled; opacity: wifiHeaderMouse.containsMouse ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } } }
                    
                    activeFocusOnTab: true
                    Keys.onSpacePressed: Networking.wifiEnabled = !Networking.wifiEnabled
                    Keys.onReturnPressed: Networking.wifiEnabled = !Networking.wifiEnabled
                    
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                        Text { text: "Wi-Fi"; font.family: Vars.fontFamily; font.pixelSize: 16; font.weight: 500; color: Theme.on_surface; Layout.fillWidth: true }
                        
                        Rectangle {
                            width: 52; height: 32; radius: 16
                            color: Networking.wifiEnabled ? Theme.primary : Theme.surface_variant
                            border.color: wifiHeader.activeFocus ? Theme.on_surface : "transparent"
                            border.width: wifiHeader.activeFocus ? 2 : 0
                            Rectangle {
                                width: 24; height: 24; radius: 12
                                color: Networking.wifiEnabled ? Theme.on_primary : Theme.on_surface_variant
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left; anchors.leftMargin: Networking.wifiEnabled ? 24 : 4
                                Behavior on anchors.leftMargin { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 16; color: Networking.wifiEnabled ? Theme.primary : Theme.surface_variant; text: Networking.wifiEnabled ? "\ue5ca" : "\ue5cd" }
                            }
                        }
                    }
                    MouseArea { id: wifiHeaderMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: { wifiHeader.forceActiveFocus(); Networking.wifiEnabled = !Networking.wifiEnabled; } }
                }

                // Empty state (only if enabled and no networks)
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 120
                    visible: Networking.wifiEnabled && (!rootWifiPage.wifiDevice || rootWifiPage.wifiDevice.networks.values.length === 0)
                    radius: 16; color: Theme.surface_container
                    
                    Rectangle { width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.left: parent.left }
                    Rectangle { width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.right: parent.right }
                    Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.left: parent.left }
                    Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.right: parent.right }
                    
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 8
                        Text { text: "\ue63e"; font.family: "Material Symbols Outlined"; font.pixelSize: 32; color: Theme.on_surface_variant; Layout.alignment: Qt.AlignHCenter } // Wifi off icon
                        Text { text: "No networks found"; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface_variant; Layout.alignment: Qt.AlignHCenter }
                    }
                }

                // Wi-Fi List
                Repeater {
                    model: rootWifiPage.wifiDevice && Networking.wifiEnabled ? rootWifiPage.wifiDevice.networks.values : []
                    delegate: Rectangle {
                        id: wifiDelegate
                        Layout.fillWidth: true
                        
                        property bool isPasswordMode: false
                        Layout.preferredHeight: isPasswordMode ? 140 : 72
                        Behavior on Layout.preferredHeight { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                        
                        property bool isSelected: modelData.connected || isPasswordMode
                        property bool showForget: false
                        radius: isSelected ? 36 : 16
                        Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                        color: modelData.connected ? Theme.secondary_container : (isSelected ? Theme.surface_container_high : (wifiMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container))
                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                        
                        function submitPassword() {
                            console.log("[WifiPage] Submitting password for:", modelData.name, "| Pwd length:", wifiPwdInput.text.length);
                            try {
                                if (wifiPwdInput.text.length > 0) {
                                    modelData.connectWithPsk(wifiPwdInput.text);
                                } else {
                                    modelData.connect();
                                }
                                console.log("[WifiPage] Native connect method invoked successfully.");
                            } catch(e) {
                                console.error("[WifiPage] Error invoking connect:", e);
                            }
                            wifiDelegate.isPasswordMode = false;
                        }
                        
                        Rectangle { width: parent.radius; height: parent.radius; color: parent.color; anchors.top: parent.top; anchors.left: parent.left; opacity: parent.isSelected ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } } }
                        Rectangle { width: parent.radius; height: parent.radius; color: parent.color; anchors.top: parent.top; anchors.right: parent.right; opacity: parent.isSelected ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } } }
                        Rectangle { width: parent.radius; height: parent.radius; color: parent.color; anchors.bottom: parent.bottom; anchors.left: parent.left; opacity: parent.isSelected ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } } }
                        Rectangle { width: parent.radius; height: parent.radius; color: parent.color; anchors.bottom: parent.bottom; anchors.right: parent.right; opacity: parent.isSelected ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } } }
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 0
                            spacing: 0
                            
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 72
                                RowLayout {
                                    z: 1
                                    anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                                    
                                    Text {
                                        font.family: "Material Symbols Outlined"; font.pixelSize: 24
                                        color: modelData.connected ? Theme.primary : Theme.on_surface_variant
                                        text: {
                                            if (modelData.signalStrength === undefined) return "\ue63e";
                                            let tier = Math.min(Math.floor(modelData.signalStrength / 25), 3);
                                            return ["\ue1ba", "\uebe4", "\uebd6", "\uebe1"][tier] || "\ue63e";
                                        }
                                    }
                                    
                                    ColumnLayout {
                                        Layout.alignment: Qt.AlignVCenter; spacing: 0; Layout.fillWidth: true
                                        Text { 
                                            text: modelData.name; font.family: Vars.fontFamily; font.pixelSize: 16
                                            color: Theme.on_surface
                                            Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft
                                        }
                                        Text { 
                                            text: modelData.connected ? "Connected" : "Available"
                                            font.family: Vars.fontFamily; font.pixelSize: 11; font.weight: 500
                                            color: Theme.on_surface_variant
                                            Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft
                                        }
                                    }
                                    
                                    Rectangle {
                                        width: 32; height: 32; radius: 16; color: infoHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent"
                                        visible: modelData.saved || modelData.known || modelData.connected
                                        Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_surface_variant; text: "info" }
                                        MouseArea { id: infoHover; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: rootWifiPage.showPasswordFor(modelData.name) }
                                    }
                                    
                                    Rectangle {
                                        width: 32; height: 32; radius: 16; color: "transparent"
                                        visible: wifiDelegate.isPasswordMode
                                        Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_surface_variant; text: "\ue5cd" }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: wifiDelegate.isPasswordMode = false }
                                    }
                                }
                                MouseArea {
                                    id: wifiMouse
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: (mouse) => {
                                        wifiDelegate.forceActiveFocus();
                                        if (mouse.button === Qt.RightButton) {
                                            wifiDelegate.showForget = true;
                                        } else {
                                            if (modelData.connected) {
                                                console.log("[WifiPage] Disconnecting from:", modelData.name);
                                                modelData.disconnect();
                                            } else {
                                                if (modelData.saved || modelData.known || modelData.security === "none" || modelData.security === 0) {
                                                    console.log("[WifiPage] Connecting to known/saved network:", modelData.name);
                                                    
                                                    // Dump live data from the network model
                                                    let details = [];
                                                    for (let prop in modelData) {
                                                        try {
                                                            if (typeof modelData[prop] !== "function" && typeof modelData[prop] !== "object") {
                                                                details.push(prop + "=" + modelData[prop]);
                                                            }
                                                        } catch(err) {}
                                                    }
                                                    console.log("[WifiPage] Network live data:", details.join(" | "));
                                                    
                                                    try {
                                                        modelData.connect();
                                                    } catch(e) {
                                                        console.error("[WifiPage] Error connecting to known network:", e);
                                                    }
                                                } else {
                                                    console.log("[WifiPage] Opening password entry for new network:", modelData.name);
                                                    wifiDelegate.isPasswordMode = true;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: wifiDelegate.isPasswordMode
                                opacity: wifiDelegate.isPasswordMode ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                clip: true
                                
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; anchors.bottomMargin: 16; anchors.topMargin: 0; spacing: 16
                                    
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 44
                                        color: wifiPwdInput.activeFocus ? Qt.tint(Theme.surface_container_highest, Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)) : Theme.surface_container_highest
                                        radius: 16
                                        border.color: wifiPwdInput.activeFocus ? Theme.primary : Theme.outline
                                        border.width: wifiPwdInput.activeFocus ? 2 : 1
                                        Behavior on border.color { ColorAnimation { duration: 150 } }
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 8; spacing: 12
                                            Text { text: "\ue897"; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: wifiPwdInput.activeFocus ? Theme.primary : Theme.on_surface_variant }
                                            TextInput {
                                                id: wifiPwdInput
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                verticalAlignment: Text.AlignVCenter
                                                font.family: Vars.fontFamily
                                                font.pixelSize: 16
                                                color: Theme.on_surface
                                                echoMode: pwdToggle.showPwd ? TextInput.Normal : TextInput.Password
                                                selectByMouse: true
                                                clip: true
                                                Keys.onReturnPressed: wifiDelegate.submitPassword()
                                                onVisibleChanged: {
                                                    if(visible) {
                                                        text = "";
                                                        pwdToggle.showPwd = false;
                                                        forceActiveFocus();
                                                    }
                                                }
                                            }
                                            Rectangle {
                                                id: pwdToggle
                                                property bool showPwd: false
                                                width: 36; height: 36; radius: 18
                                                color: pwdToggleHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent"
                                                Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_surface_variant; text: pwdToggle.showPwd ? "\ue8f4" : "\ue8f5" }
                                                MouseArea { id: pwdToggleHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pwdToggle.showPwd = !pwdToggle.showPwd }
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }
                                        }
                                    }
                                    
                                    Rectangle {
                                        Layout.preferredWidth: connectBtnTxt.implicitWidth + 32
                                        Layout.preferredHeight: 44
                                        radius: 22
                                        color: connectHover.containsMouse ? Qt.tint(Theme.primary, Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08)) : Theme.primary
                                        Text { id: connectBtnTxt; anchors.centerIn: parent; text: "Connect"; color: Theme.on_primary; font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: 500 }
                                        MouseArea { id: connectHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: wifiDelegate.submitPassword() }
                                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                                    }
                                }
                            }
                        }
                        
                        // Forget Overlay
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Theme.surface_container_highest
                            visible: wifiDelegate.showForget
                            opacity: wifiDelegate.showForget ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                            
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 16
                                Text {
                                    text: "Forget " + (modelData.name || "Network") + "?"
                                    font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; Layout.fillWidth: true; elide: Text.ElideRight
                                }
                                Rectangle {
                                    width: 80; height: 32; radius: 16; color: "transparent"
                                    border.color: Theme.outline; border.width: 1
                                    Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.on_surface; font.family: Vars.fontFamily; font.pixelSize: 14 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: wifiDelegate.showForget = false }
                                }
                                Rectangle {
                                    width: 80; height: 32; radius: 16; color: Theme.error ? Theme.error : "#ffb4ab"
                                    Text { anchors.centerIn: parent; text: "Forget"; color: Theme.on_error ? Theme.on_error : "#690005"; font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: 500 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (modelData.forget) modelData.forget(); wifiDelegate.showForget = false; } }
                                }
                            }
                        }
                    }
                }

                // Scan for Networks Card
                Rectangle {
                    id: scanCard
                    Layout.fillWidth: true; Layout.preferredHeight: 72
                    visible: Networking.wifiEnabled
                    radius: 16; color: scanMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                    
                    Rectangle { 
                        width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.left: parent.left 
                        opacity: scanMouse.containsMouse ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                    }
                    Rectangle { 
                        width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.right: parent.right 
                        opacity: scanMouse.containsMouse ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                    }
                    
                    activeFocusOnTab: true
                    Keys.onSpacePressed: { if(rootWifiPage.wifiDevice) rootWifiPage.wifiDevice.scannerEnabled = !rootWifiPage.wifiDevice.scannerEnabled }
                    Keys.onReturnPressed: { if(rootWifiPage.wifiDevice) rootWifiPage.wifiDevice.scannerEnabled = !rootWifiPage.wifiDevice.scannerEnabled }
                    
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                        Text { 
                            id: wifiScanIcon
                            text: "\ue863"; font.family: "Material Symbols Outlined"; font.pixelSize: 24; 
                            color: rootWifiPage.wifiDevice && rootWifiPage.wifiDevice.scannerEnabled ? Theme.primary : Theme.on_surface 
                            RotationAnimation {
                                target: wifiScanIcon; property: "rotation"
                                loops: Animation.Infinite; from: 0; to: 360; duration: 2000; running: rootWifiPage.wifiDevice && rootWifiPage.wifiDevice.scannerEnabled !== undefined ? rootWifiPage.wifiDevice.scannerEnabled : false
                                onRunningChanged: if (!running) wifiScanIcon.rotation = 0
                            }
                        }
                        Text { text: (rootWifiPage.wifiDevice && rootWifiPage.wifiDevice.scannerEnabled) ? "Scanning..." : "Scan for Networks"; font.family: Vars.fontFamily; font.pixelSize: 16; font.weight: 500; color: Theme.on_surface; Layout.fillWidth: true }
                    }
                    MouseArea { id: scanMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { scanCard.forceActiveFocus(); if(rootWifiPage.wifiDevice) rootWifiPage.wifiDevice.scannerEnabled = !rootWifiPage.wifiDevice.scannerEnabled; } }
                }
            }
        }
    }
    }

    // Password Info Page Overlay
    Rectangle {
        id: infoPageOverlay
        anchors.fill: parent
        color: Theme.surface_container_low
        visible: rootWifiPage.selectedNetworkForInfo !== ""
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        z: 100

        // Intercept mouse events so they don't fall through to the list beneath
        MouseArea { anchors.fill: parent; hoverEnabled: true }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Vars.spacingMedium

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Rectangle {
                    width: 40; height: 40; radius: 20
                    color: backInfoHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (backInfoHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                    Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_surface; text: "\ue5c4" }
                    MouseArea { id: backInfoHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: rootWifiPage.selectedNetworkForInfo = "" }
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                }

                Text { text: "Network Password"; font.family: Vars.fontFamily; font.pixelSize: 20; font.weight: 600; color: Theme.on_surface }
                Item { Layout.fillWidth: true }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                radius: 16
                color: Theme.surface_container

                ColumnLayout {
                    anchors.centerIn: parent
                    Text { text: rootWifiPage.selectedNetworkForInfo; font.family: Vars.fontFamily; font.pixelSize: 18; font.weight: 500; color: Theme.on_surface; Layout.alignment: Qt.AlignHCenter }
                    Text { text: "Saved Password"; font.family: Vars.fontFamily; font.pixelSize: 12; color: Theme.on_surface_variant; Layout.alignment: Qt.AlignHCenter }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                radius: 16
                color: Theme.surface_container_highest

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16

                    Text { 
                        text: rootWifiPage.selectedNetworkPassword !== "" ? rootWifiPage.selectedNetworkPassword : "No password found"
                        font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; Layout.fillWidth: true 
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        width: 32; height: 32; radius: 16; color: copyHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent"
                        Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_surface_variant; text: "content_copy" }
                        MouseArea { 
                            id: copyHover
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onClicked: { Quickshell.execDetached({ command: ["wl-copy", rootWifiPage.selectedNetworkPassword] }); }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}

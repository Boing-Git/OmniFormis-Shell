import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import "../Variables/variables.js" as Vars
import "SettingsApp"
import ".."

Item {
    id: root
    
    Layout.preferredWidth: 100
    Layout.preferredHeight: 40
    
    property bool expanded: false
    property bool forceHidePill: false
    property var focusWindow: null
    property bool gameMode: false
    property var allVars: []
    property alias panel: panel
    property alias panelMask: panelMask
    
    property bool isFloatingInstance: false
    signal detachToggled(bool isFloating)
    
    property string currentSection: "General"
    
    // Wi-Fi
    property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    property var activeNet: wifiDevice ? wifiDevice.networks.values.find(n => n.connected) : null
    property var wifiSignal: activeNet ? activeNet.signalStrength : 0

    readonly property string wifiIcon: {
        if (!Networking.wifiEnabled) return "\ue1da"; 
        if (!activeNet) return "\uf067"; 
        let tier = Math.min(Math.floor(wifiSignal / 25), 3);
        let icons = ["\ue1ba", "\uebe4", "\uebd6", "\uebe1"];
        return icons[tier];
    }
    
    // Bluetooth
    property var adapter: Bluetooth.defaultAdapter
    property bool adapterState: adapter ? adapter.enabled : false
    property var connectDevice: adapter ? adapter.devices.values.find(d => d.connected) : null

    readonly property string bluetoothIcon: {
        if (!adapterState) return "\ue1a9"; 
        if (!connectDevice) return "\ue1a7"; 
        return "\ue1a8"; 
    }
    
    opacity: forceHidePill ? 0.0 : 1.0
    visible: opacity > 0
    signal closeRequested()

    HyprlandFocusGrab {
        active: root.expanded && root.focusWindow !== null
        windows: root.focusWindow ? [root.focusWindow] : []
    }
    
    Item {
        id: panelMask
        anchors.centerIn: panel
        width: panel.width + 40
        height: panel.height + 40
    }
    
    Rectangle {
        id: panel
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: !root.gameMode; shadowBlur: 1.0; shadowColor: Qt.rgba(0,0,0,0.25); shadowVerticalOffset: 4; shadowHorizontalOffset: 0 }
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        
        width: root.expanded ? (root.isFloatingInstance ? root.width : 1100) : 100
        height: root.expanded ? (root.isFloatingInstance ? root.height : 650) : 40
        
        color: Vars.translucent ? Qt.rgba(Theme.surface_container_low.r, Theme.surface_container_low.g, Theme.surface_container_low.b, 0.85) : Theme.surface_container_low
        radius: root.gameMode ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        
        opacity: root.expanded || panel.width > 105 ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on radius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

        Item {
            anchors.fill: parent
            anchors.margins: Vars.spacingLarge
            
            opacity: root.expanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { enabled: !root.gameMode; SequentialAnimation { PauseAnimation { duration: root.expanded ? Vars.animationDuration : 0 } NumberAnimation { duration: root.expanded ? Vars.animationDuration : Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.expanded ? Vars.customEmphasizedDecelerate : Vars.customEmphasizedAccelerate } } }

            RowLayout {
                anchors.fill: parent
                spacing: Vars.spacingLarge

                // Sidebar
                ColumnLayout {
                    Layout.preferredWidth: 280
                    Layout.maximumWidth: 280
                    Layout.fillHeight: true
                    spacing: Vars.spacingMedium

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Vars.spacingMedium

                        Rectangle {
                            width: 48; height: 48; radius: Vars.radiusMedium
                            color: backHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (backHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                            Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_surface; text: "\ue5cd" }
                            MouseArea { id: backHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.expanded = false }
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                        }
                        
                        Rectangle {
                            width: 48; height: 48; radius: Vars.radiusMedium
                            color: detachHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (detachHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                            Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_surface; text: root.isFloatingInstance ? "\ue5ce" : "\ue89b" }
                            MouseArea { 
                                id: detachHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; 
                                onClicked: {
                                    root.expanded = false; 
                                    root.detachToggled(!root.isFloatingInstance);
                                }
                            }
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                        }
                        
                        Text {
                            text: "Settings"
                            font.family: Vars.fontFamily
                            font.pixelSize: 24
                            font.weight: 700
                            color: Theme.on_surface
                        }
                    }

                    Item { Layout.preferredHeight: Vars.spacingSmall }

                    // Navigation Items
                    SettingsSidebar {
                        id: sidebar
                        currentSection: root.currentSection
                        wifiIcon: root.wifiIcon
                        bluetoothIcon: root.bluetoothIcon
                        onCurrentSectionChanged: {
                            if (root.currentSection !== currentSection) {
                                root.currentSection = currentSection
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                // Vertical Divider
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.2)
                }

                // Content Area
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: {
                        if (root.currentSection === "bezier") return 1;
                        if (root.currentSection === "wifi") return 2;
                        if (root.currentSection === "bluetooth") return 3;
                        return 0; // "General", "Appearance", "Input" map to UnifiedSettingsPage
                    }

                    // 0: Unified Settings (Hyprland + Quickshell)
                    UnifiedSettingsPage {
                        id: unifiedPage
                        activeCategory: root.currentSection === "bezier" || root.currentSection === "wifi" || root.currentSection === "bluetooth" ? "General" : root.currentSection
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    // 1: Bezier Editor
                    BezierEditorPage {
                        id: bezierPage
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    // 2: Wi-Fi Settings
                    WifiPage {
                        id: wifiPage
                        wifiDevice: root.wifiDevice
                        panelRef: root.panel
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    // 3: Bluetooth Settings
                    BluetoothPage {
                        id: bluetoothPage
                        adapter: root.adapter
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}

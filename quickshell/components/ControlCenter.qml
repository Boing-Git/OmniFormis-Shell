import QtQuick
import QtQuick.Effects
import ".."
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import QtCore
import "../Variables/variables.js" as Vars
import "ControlCenter" as CC

Item {
    id: root
    
    // Fixed layout footprint - never animates, no parent relayout
    Layout.preferredWidth: 100
    Layout.preferredHeight: 40
    
    property bool expanded: false
    property var focusWindow: null
    property bool forceHidePill: false
    property bool gameMode: false

    // Navigation state: "" (Main Dashboard), "wifi" (Wi-Fi Settings), "bluetooth" (Bluetooth Settings)
    property string currentSubMenu: ""
    property bool isEditorMode: false
    
    signal closeRequested()
    signal popupOpened()
    signal openColorSchemeRequested()
    signal openSettingsRequested()
    signal openWallpaperRequested()
    signal openPowerMenuRequested()
    signal openOverviewRequested()
    
    // Expose the visual panel for mask tracking in TopPills
    property alias panel: panel
    property alias panelMask: panelMask

    HyprlandFocusGrab {
        active: root.expanded && root.focusWindow !== null
        windows: root.focusWindow ? [root.focusWindow] : []
        onCleared: root.expanded = false
    }
    
    focus: root.expanded
    onExpandedChanged: {
        if (expanded) {
            forceActiveFocus();
        } else {
            isEditorMode = false;
            currentSubMenu = "";
        }
    }
    Keys.onEscapePressed: {
        root.expanded = false;
    }

    Item {
        id: panelMask
        anchors.centerIn: panel
        width: panel.width + 40
        height: panel.height + 40
    }

    // The visual panel that animates independently of the layout
    Rectangle {
        id: panel
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: !root.gameMode; shadowBlur: 1.0; shadowColor: Qt.rgba(0,0,0,0.25); shadowVerticalOffset: 4; shadowHorizontalOffset: 0 }
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        
        property real targetHeight: {
            if (!root.expanded) return 40;
            if (root.currentSubMenu === "wifi") return Math.min(800, wifiMenuObj.implicitHeight + (Vars.spacingLarge * 2));
            if (root.currentSubMenu === "bluetooth") return Math.min(800, bluetoothMenuObj.implicitHeight + (Vars.spacingLarge * 2));
            if (root.currentSubMenu === "display") return Math.min(800, displayMenuObj.implicitHeight + (Vars.spacingLarge * 2));
            return 660; // Main dashboard
        }
        
        width: root.expanded ? 600 : 100
        height: targetHeight
        
        color: Vars.translucent ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.85) : Theme.surface
        radius: root.gameMode ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        
        opacity: root.expanded || panel.width > 105 ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on radius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

        // EXPANDED PANEL CONTAINER
        Item {
            id: expandedUI
            anchors.fill: parent
            
            opacity: root.expanded ? 1.0 : 0.0
            visible: opacity > 0
            clip: true
            Behavior on opacity { enabled: !root.gameMode; SequentialAnimation { PauseAnimation { duration: root.expanded ? Vars.animationDuration : 0 } NumberAnimation { duration: root.expanded ? Vars.animationDuration : Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.expanded ? Vars.customEmphasizedDecelerate : Vars.customEmphasizedAccelerate } } }

            // ------------------------------------------
            // VIEW 1: MAIN DASHBOARD MENU
            // ------------------------------------------
            Flickable {
                id: mainDashboardFlickable
                anchors.fill: parent
                anchors.margins: Vars.spacingLarge * 1.5
                contentHeight: mainDashboardView.implicitHeight
                interactive: true
                
                opacity: root.currentSubMenu === "" ? 1.0 : 0.0
                visible: opacity > 0
                transform: Translate {
                    x: root.currentSubMenu === "" ? 0 : -40
                    Behavior on x { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                }
                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.currentSubMenu === "" ? Vars.customEmphasizedDecelerate : Vars.customEmphasizedAccelerate } }
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: mainDashboardView
                    width: mainDashboardFlickable.width
                    spacing: Vars.spacingMedium

                    // Header Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        RowLayout {
                            spacing: 8
                            Text { text: "Control Center"; font.family: Vars.fontFamily; font.pixelSize: 18; font.weight: Font.Bold; color: Theme.on_surface }
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        // Edit Button
                        Rectangle {
                            width: 36; height: 36; radius: root.isEditorMode ? 10 : height / 2
                            color: editHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (editHover.containsMouse || root.isEditorMode ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                            Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: root.isEditorMode ? Theme.primary : Theme.on_surface; text: "edit" }
                            MouseArea { 
                                id: editHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; 
                                onClicked: root.isEditorMode = !root.isEditorMode 
                            }
                            Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                        }
                        
                        // Refresh Button (Mock)
                        Rectangle {
                            width: 36; height: 36; radius: 12
                            color: refreshHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (refreshHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                            Text { 
                                id: refreshIcon
                                anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_surface; text: "refresh" 
                                RotationAnimation {
                                    id: refreshAnim
                                    target: refreshIcon
                                    property: "rotation"
                                    from: 0; to: 360
                                    duration: 700
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Vars.customExpressiveSpatialSlow
                                }
                            }
                            MouseArea { 
                                id: refreshHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; 
                                onClicked: {
                                    refreshAnim.restart();
                                    Quickshell.execDetached({ command: ["hyprctl", "reload"] });
                                    Quickshell.execDetached({ command: ["bash", "-c", "pkill quickshell; sleep 0.2; quickshell"] });
                                }
                            }
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                        }
                        
                        // Settings Button
                        Rectangle {
                            width: 36; height: 36; radius: 12
                            color: settingsHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (settingsHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                            Text { 
                                id: settingsIcon
                                anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_surface; text: "settings" 
                                RotationAnimation {
                                    id: settingsAnim
                                    target: settingsIcon
                                    property: "rotation"
                                    from: 0; to: 360
                                    duration: 700
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Vars.customExpressiveSpatialSlow
                                }
                            }
                            MouseArea { 
                                id: settingsHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; 
                                onClicked: { 
                                    settingsAnim.restart();
                                    root.expanded = false; 
                                    root.openSettingsRequested();
                                } 
                            }
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                        }
                        
                        // Power Button
                        Rectangle {
                            width: 36; height: 36; radius: 12
                            color: powerHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (powerHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                            Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_surface; text: "power_settings_new" }
                            MouseArea { 
                                id: powerHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; 
                                onClicked: { root.expanded = false; root.openPowerMenuRequested() } 
                            }
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                        }
                    }

                    // Modular Components
                    CC.ModuleGrid {
                        isEditorMode: root.isEditorMode
                        gameMode: root.gameMode
                        onSubMenuRequested: (menuName) => { root.currentSubMenu = menuName; }
                        onOpenColorSchemeRequested: { root.expanded = false; root.openColorSchemeRequested() }
                        onOpenSettingsRequested: { root.expanded = false; root.openSettingsRequested() }
                        onOpenWallpaperRequested: { root.expanded = false; root.openWallpaperRequested() }
                        onOpenOverviewRequested: { root.expanded = false; root.openOverviewRequested() }
                    }

                    CC.Sliders { }
                    CC.MediaPlayer { }
                    CC.Notifications { }
                }
            }

            // ------------------------------------------
            // SUB-MENUS
            // ------------------------------------------
            CC.WifiMenu {
                id: wifiMenuObj
                isActive: root.currentSubMenu === "wifi"
                onBackRequested: { root.currentSubMenu = "" }
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
            }
            
            CC.BluetoothMenu {
                id: bluetoothMenuObj
                isActive: root.currentSubMenu === "bluetooth"
                onBackRequested: { root.currentSubMenu = "" }
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
            }
            
            CC.DisplayMenu {
                id: displayMenuObj
                isActive: root.currentSubMenu === "display"
                onBackRequested: { root.currentSubMenu = "" }
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
            }
        }
    }
}
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
        
        width: root.expanded ? 600 : 100
        height: root.expanded ? 660 : 40
        
        color: Theme.surface
        radius: root.gameMode ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        
        opacity: root.expanded || panel.width > 105 ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on radius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }

        // EXPANDED PANEL CONTAINER
        Item {
            id: expandedUI
            anchors.fill: parent
            
            opacity: root.expanded ? 1.0 : 0.0
            visible: opacity > 0
            clip: true
            Behavior on opacity { enabled: !root.gameMode; SequentialAnimation { PauseAnimation { duration: root.expanded ? Vars.animationDuration : 0 } NumberAnimation { duration: root.expanded ? Vars.animationDuration : Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.expanded ? Vars.m3StandardDecelerate : Vars.m3StandardAccelerate } } }

            // ------------------------------------------
            // VIEW 1: MAIN DASHBOARD MENU
            // ------------------------------------------
            Flickable {
                id: mainDashboardFlickable
                anchors.fill: parent
                anchors.margins: Vars.spacingLarge * 1.5
                contentHeight: mainDashboardView.implicitHeight
                interactive: !root.isEditorMode
                
                opacity: root.currentSubMenu === "" ? 1.0 : 0.0
                visible: opacity > 0
                transform: Translate {
                    x: root.currentSubMenu === "" ? 0 : -40
                    Behavior on x { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
                }
                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.currentSubMenu === "" ? Vars.m3StandardDecelerate : Vars.m3StandardAccelerate } }
                clip: !root.isEditorMode
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: mainDashboardView
                    width: mainDashboardFlickable.width
                    spacing: Vars.spacingMedium

                    // Header Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Vars.spacingMedium
                        
                        RowLayout {
                            spacing: 8
                            Text { text: "Control Center"; font.family: Vars.fontFamily; font.pixelSize: 18; font.weight: Font.Bold; color: Theme.on_surface }
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        // Edit Button
                        Rectangle {
                            width: 48; height: 48; radius: root.isEditorMode ? 12 : height / 2
                            color: editHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (editHover.containsMouse || root.isEditorMode ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                            Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 22; color: root.isEditorMode ? Theme.primary : Theme.on_surface; text: "edit" }
                            MouseArea { 
                                id: editHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; 
                                onClicked: root.isEditorMode = !root.isEditorMode 
                            }
                            Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                        }
                        
                        // Refresh Button (Mock)
                        Rectangle {
                            width: 48; height: 48; radius: 16
                            color: refreshHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (refreshHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                            Text { 
                                id: refreshIcon
                                anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 22; color: Theme.on_surface; text: "refresh" 
                                RotationAnimation {
                                    id: refreshAnim
                                    target: refreshIcon
                                    property: "rotation"
                                    from: 0; to: 360
                                    duration: 700
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Vars.m3ExpressiveSpatialSlow
                                }
                            }
                            MouseArea { 
                                id: refreshHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; 
                                onClicked: {
                                    refreshAnim.restart();
                                    Quickshell.execDetached({ command: ["hyprctl", "reload"] });
                                    Quickshell.execDetached({ command: ["bash", "-c", "qs kill; sleep 0.1; qs"] });
                                }
                            }
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                        }
                        
                        // Settings Button
                        Rectangle {
                            width: 48; height: 48; radius: 16
                            color: settingsHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (settingsHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                            Text { 
                                id: settingsIcon
                                anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 22; color: Theme.on_surface; text: "settings" 
                                RotationAnimation {
                                    id: settingsAnim
                                    target: settingsIcon
                                    property: "rotation"
                                    from: 0; to: 360
                                    duration: 700
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Vars.m3ExpressiveSpatialSlow
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
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                        }
                        
                        // Power Button
                        Rectangle {
                            width: 48; height: 48; radius: 16
                            color: powerHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (powerHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                            Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 22; color: Theme.on_surface; text: "power_settings_new" }
                            MouseArea { 
                                id: powerHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; 
                                onClicked: { root.expanded = false; root.openPowerMenuRequested() } 
                            }
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                        }
                    }

                    // Modular Components
                    CC.ModuleGrid {
                        isEditorMode: root.isEditorMode
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
                isActive: root.currentSubMenu === "wifi"
                onBackRequested: { root.currentSubMenu = "" }
            }
            
            CC.BluetoothMenu {
                isActive: root.currentSubMenu === "bluetooth"
                onBackRequested: { root.currentSubMenu = "" }
            }
            
            CC.DisplayMenu {
                isActive: root.currentSubMenu === "display"
                onBackRequested: { root.currentSubMenu = "" }
            }
        }
    }
}
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
import "../Variables/variables.js" as Vars

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
    property var historyList: []
    
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

    Process {
        id: scaleCmd
        property real targetScale: 1.0
        command: ["hyprctl", "eval", "hl.monitor({ output = \"\", mode = \"preferred\", position = \"auto\", scale = " + targetScale + " })"]
        running: false
    }

    HyprlandFocusGrab {
        active: root.expanded && root.focusWindow !== null
        windows: root.focusWindow ? [root.focusWindow] : []
        onCleared: root.expanded = false
    }
    
    focus: root.expanded
    onExpandedChanged: {
        if (expanded) {
            forceActiveFocus();
        }
    }
    Keys.onEscapePressed: {
        root.expanded = false;
    }

    // ==========================================
    // BACKEND DATA BINDINGS
    // ==========================================
    
    // 1. Wi-Fi
    property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    property var activeNet: wifiDevice ? wifiDevice.networks.values.find(n => n.connected) : null
    property var signal: activeNet ? activeNet.signalStrength : 0

    readonly property string wifiIcon: {
        if (!Networking.wifiEnabled) return "\ue1da"; 
        if (!activeNet) return "\uf067"; 
        let tier = Math.min(Math.floor(signal / 25), 3);
        let icons = ["\ue1ba", "\uebe4", "\uebd6", "\uebe1"];
        return icons[tier];
    }

    // 2. Bluetooth
    property var adapter: Bluetooth.defaultAdapter
    property bool adapterState: adapter ? adapter.enabled : false
    property var connectDevice: adapter ? adapter.devices.values.find(d => d.connected) : null

    readonly property string bluetoothIcon: {
        if (!adapterState) return "\ue1a9"; 
        if (!connectDevice) return "\ue1a7"; 
        return "\ue1a8"; 
    }

    // 3. Audio & Media
    property var audioNode: Pipewire.defaultAudioSink
    property real currentVolume: audioNode && audioNode.audio ? audioNode.audio.volume : 0.0
    property var preferredMprisPlayer: null
    property var mprisPlayer: {
        let vals = Mpris.players.values;
        if (vals.length === 0) return null;
        if (preferredMprisPlayer && vals.indexOf(preferredMprisPlayer) !== -1) {
            return preferredMprisPlayer;
        }
        return vals[0];
    }
    property bool isPlaying: mprisPlayer ? mprisPlayer.isPlaying : false
    
    // Quick Settings Editor Mode State
    property bool isEditorMode: false

    ListModel {
        id: activeTiles
        ListElement { moduleId: "wifi"; expanded: true }
        ListElement { moduleId: "bluetooth"; expanded: true }
        ListElement { moduleId: "audio"; expanded: false }
        ListElement { moduleId: "display"; expanded: false }
        ListElement { moduleId: "peace"; expanded: false }
        ListElement { moduleId: "color"; expanded: false }
        ListElement { moduleId: "wallpaper"; expanded: false }
        ListElement { moduleId: "overview"; expanded: false }
    }

    ListModel {
        id: availableTiles
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
        
        color: Theme.surface_container_low
        radius: root.gameMode ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        // clip: true removed to allow shadow to render
        
        opacity: root.expanded || panel.width > 105 ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on radius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }



    // ==========================================
    // EXPANDED PANEL CONTAINER
    // ==========================================
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
            
            opacity: root.currentSubMenu === "" ? 1.0 : 0.0
            visible: opacity > 0
            transform: Translate {
                x: root.currentSubMenu === "" ? 0 : -40
                Behavior on x { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
            }
            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.currentSubMenu === "" ? Vars.m3StandardDecelerate : Vars.m3StandardAccelerate } }
            clip: true
            
            // Allow tracking scroll to hide popups if needed, or just fluid scrolling
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
                    width: 48; height: 48; radius: 16
                    color: editHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (editHover.containsMouse || root.isEditorMode ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                    Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 22; color: root.isEditorMode ? Theme.primary : Theme.on_surface; text: "edit" }
                    MouseArea { 
                        id: editHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; 
                        onClicked: root.isEditorMode = !root.isEditorMode 
                    }
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                }
                
                // Refresh Button (Mock)
                Rectangle {
                    width: 48; height: 48; radius: 16
                    color: refreshHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (refreshHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                    Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 22; color: Theme.on_surface; text: "refresh" }
                    MouseArea { 
                        id: refreshHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; 
                    }
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                }
                
                // Settings Button
                Rectangle {
                    width: 48; height: 48; radius: 16
                    color: settingsHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (settingsHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                    Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 22; color: Theme.on_surface; text: "settings" }
                    MouseArea { 
                        id: settingsHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; 
                        onClicked: { root.expanded = false; root.openSettingsRequested() } 
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

            // Quick Settings 4x2 Grid
            // Quick Settings Grid
            GridLayout {
                id: activeGrid
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 12
                rowSpacing: 12

                Repeater {
                    model: activeTiles
                    delegate: Rectangle {
                        id: tileDelegate
                        property real cellW: (mainDashboardFlickable.width - 36) / 4
                        Layout.preferredWidth: model.expanded ? (cellW * 2 + 12) : cellW
                        Layout.fillWidth: false
                        Layout.columnSpan: model.expanded ? 2 : 1
                        Layout.preferredHeight: 64
                        radius: 16
                        Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                        
                        property string mId: model.moduleId
                        
                        property bool isActive: (mId === "wifi" ? Networking.wifiEnabled : false) || 
                                                (mId === "bluetooth" ? adapterState : false) || 
                                                (mId === "audio" ? (audioNode && !audioNode.audio.muted) : false) || 
                                                (mId === "display" ? (root.currentSubMenu === "display" || (Hyprland.focusedMonitor && Math.abs(Hyprland.focusedMonitor.scale - 1.0) > 0.01)) : false) ||
                                                (mId === "peace" ? NotificationService.peaceMode : false)
                                                
                        property string mIcon: mId === "wifi" ? wifiIcon :
                                               mId === "bluetooth" ? bluetoothIcon :
                                               mId === "audio" ? (audioNode && audioNode.audio.muted ? "\ue04f" : "\ue050") :
                                               mId === "display" ? "\ue30d" :
                                               mId === "peace" ? "\ue15c" :
                                               mId === "color" ? "palette" :
                                               mId === "wallpaper" ? "wallpaper" :
                                               mId === "overview" ? "grid_view" : ""
                                               
                        property string mTitle: mId === "wifi" ? "Wi-Fi" :
                                                mId === "bluetooth" ? "Bluetooth" :
                                                mId === "audio" ? "Audio" :
                                                mId === "display" ? "Display" :
                                                mId === "peace" ? "Peace" :
                                                mId === "color" ? "Colors" :
                                                mId === "wallpaper" ? "Wallpaper" :
                                                mId === "overview" ? "Overview" : ""
                                                
                        property string mSubtext: mId === "wifi" ? (activeNet ? activeNet.name : "Off") :
                                                  mId === "bluetooth" ? (connectDevice ? connectDevice.name : (adapterState ? "On" : "Off")) :
                                                  mId === "audio" ? (audioNode && audioNode.audio.muted ? "Muted" : "Active") :
                                                  mId === "display" ? (isActive ? "Adjusted" : "Default") :
                                                  mId === "peace" ? (isActive ? "Active" : "Inactive") :
                                                  mId === "color" ? "Change Theme" :
                                                  mId === "wallpaper" ? "Switcher" :
                                                  mId === "overview" ? "Workspaces" : ""
                                                  
                        function doAction() {
                            if (mId === "wifi") root.currentSubMenu = "wifi";
                            else if (mId === "bluetooth") root.currentSubMenu = "bluetooth";
                            else if (mId === "display") root.currentSubMenu = "display";
                            else if (mId === "color") { root.expanded = false; root.openColorSchemeRequested() }
                            else if (mId === "wallpaper") { root.expanded = false; root.openWallpaperRequested() }
                            else if (mId === "overview") { root.expanded = false; root.openOverviewRequested() }
                            else doToggle();
                        }
                        
                        function doToggle() {
                            if (mId === "wifi") Networking.wifiEnabled = !Networking.wifiEnabled;
                            else if (mId === "bluetooth") { if (adapter) adapter.enabled = !adapter.enabled }
                            else if (mId === "audio") { if (audioNode) audioNode.audio.muted = !audioNode.audio.muted }
                            else if (mId === "peace") NotificationService.peaceMode = !NotificationService.peaceMode;
                            else doAction();
                        }
                        
                        color: isActive ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25) : Theme.surface_container_highest
                        
                        Item {
                            anchors.fill: parent
                            Text { anchors.centerIn: parent; visible: !model.expanded; font.family: "Material Symbols Outlined"; font.pixelSize: 24; color: tileDelegate.isActive ? Theme.primary : Theme.on_surface_variant; text: mIcon }
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 16; spacing: 12; visible: model.expanded
                                Text { Layout.leftMargin: 8; font.family: "Material Symbols Outlined"; font.pixelSize: 22; color: tileDelegate.isActive ? Theme.primary : Theme.on_surface_variant; text: mIcon
                                    MouseArea { anchors.fill: parent; anchors.margins: -10; cursorShape: Qt.PointingHandCursor; onClicked: if (!root.isEditorMode) doToggle() }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 0; Layout.alignment: Qt.AlignVCenter
                                    Text { text: mTitle; font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: 600; color: tileDelegate.isActive ? Theme.primary : Theme.on_surface_variant }
                                    Text { text: mSubtext; font.family: Vars.fontFamily; font.pixelSize: 11; opacity: 0.7; color: tileDelegate.isActive ? Theme.primary : Theme.on_surface_variant; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (root.isEditorMode) activeTiles.setProperty(index, "expanded", !model.expanded); else doAction() } }
                        }
                        
                        Rectangle {
                            anchors.fill: parent; radius: 16; color: "transparent"; opacity: root.isEditorMode ? 1.0 : 0.0
                            visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 150 } }
                            
                            MouseArea {
                                id: dragArea
                                anchors.fill: parent; cursorShape: Qt.OpenHandCursor
                                drag.target: ghost
                                onPressed: { tileDelegate.z = 100; ghost.x = mouse.x - 24; ghost.y = mouse.y - 24; ghost.visible = true; }
                                onReleased: { tileDelegate.z = 0; ghost.visible = false; ghost.Drag.drop(); ghost.x = 0; ghost.y = 0; }
                                onDoubleClicked: activeTiles.setProperty(index, "expanded", !model.expanded)
                            }
                            
                            Rectangle {
                                id: ghost
                                width: 48; height: 48; radius: 24; color: Theme.primary; visible: false
                                Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 24; color: Theme.on_primary; text: mIcon }
                                Drag.active: dragArea.drag.active
                                Drag.hotSpot.x: 24; Drag.hotSpot.y: 24
                                Drag.keys: ["module"]
                                property int sourceIndex: index
                            }
                            
                            DropArea {
                                anchors.fill: parent
                                keys: ["module"]
                                onEntered: (drag) => {
                                    let from = drag.source.sourceIndex;
                                    let to = index;
                                    if (from !== undefined && from !== to) {
                                        activeTiles.move(from, to, 1);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Available Modules Area
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.isEditorMode
                Layout.topMargin: 16
                spacing: 12

                Text {
                    text: "Available Modules"
                    font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: 600; color: Theme.on_surface_variant
                }

                DropArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(64, availableGrid.implicitHeight)
                    keys: ["module"]
                    
                    Rectangle {
                        anchors.fill: parent
                        color: parent.containsDrag ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1) : "transparent"
                        radius: 16
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    onDropped: (drag) => {
                        let from = drag.source.sourceIndex;
                        if (from !== undefined) {
                            let mId = activeTiles.get(from).moduleId;
                            let exp = activeTiles.get(from).expanded;
                            availableTiles.append({"moduleId": mId, "expanded": exp});
                            activeTiles.remove(from, 1);
                        }
                    }

                    GridLayout {
                        id: availableGrid
                        anchors.fill: parent
                        columns: 4; columnSpacing: 12; rowSpacing: 12
                        
                        Repeater {
                            model: availableTiles
                            delegate: Rectangle {
                                property real cellW: (mainDashboardFlickable.width - 36) / 4
                                Layout.preferredWidth: cellW
                                Layout.fillWidth: false
                                Layout.columnSpan: 1; Layout.preferredHeight: 64; radius: 16
                                color: Theme.surface_container_highest
                                
                                property string mId: model.moduleId
                                property string mIcon: mId === "wifi" ? wifiIcon : mId === "bluetooth" ? bluetoothIcon : mId === "audio" ? "\ue050" : mId === "display" ? "\ue30d" : mId === "peace" ? "\ue15c" : mId === "color" ? "palette" : mId === "wallpaper" ? "wallpaper" : mId === "overview" ? "grid_view" : ""
                                
                                Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 24; color: Theme.on_surface_variant; text: mIcon }
                                
                                Rectangle {
                                    anchors.fill: parent; radius: 16
                                    color: addHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    MouseArea { id: addHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { activeTiles.append({"moduleId": mId, "expanded": model.expanded}); availableTiles.remove(index, 1) } }
                                }
                            }
                        }
                    }
                }
            }

            // Sliders Section
            ColumnLayout {
                Layout.fillWidth: true; spacing: 16
                
                // Volume Row
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    spacing: 16

                    Text { 
                        font.family: "Material Symbols Outlined"; font.pixelSize: 24
                        color: Theme.on_surface_variant
                        text: audioNode && audioNode.audio.muted ? "\ue04f" : "\ue050" 
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // Inactive Track
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 16
                            radius: 8
                            color: Theme.surface_variant
                        }
                        // Active Track
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(16, parent.width * currentVolume)
                            height: 16
                            radius: 8
                            color: Theme.primary
                            Behavior on width { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
                        }
                        // Thumb
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(parent.width - width, parent.width * currentVolume - width/2))
                            width: 16
                            height: 16
                            radius: 8
                            color: Theme.primary
                            Behavior on x { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onPositionChanged: (mouse) => { if(audioNode) audioNode.audio.volume = Math.max(0, Math.min(1, mouse.x / width)) }
                            onPressed: (mouse) => { if(audioNode) audioNode.audio.volume = Math.max(0, Math.min(1, mouse.x / width)) }
                        }
                    }
                }

                // Brightness Row
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    spacing: 16

                    Text { 
                        font.family: "Material Symbols Outlined"; font.pixelSize: 24
                        color: Theme.on_surface_variant
                        text: "\ue518" 
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // Inactive Track
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 16
                            radius: 8
                            color: Theme.surface_variant
                        }
                        // Active Track
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(16, parent.width * 0.35)
                            height: 16
                            radius: 8
                            color: Theme.primary
                            Behavior on width { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
                        }
                        // Thumb
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(parent.width - width, parent.width * 0.35 - width/2))
                            width: 16
                            height: 16
                            radius: 8
                            color: Theme.primary
                            Behavior on x { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
                        }
                    }
                }
            }

            // Media Player Area
            Rectangle {
                id: mediaPlayerRoot
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                radius: 16
                color: Theme.surface_container_highest
                clip: true
                property int slideDirection: 1

                property real timeScale: mprisPlayer && mprisPlayer.length > 10000000 ? 1000000 : (mprisPlayer && mprisPlayer.length > 10000 ? 1000 : 1)

                function formatTime(val) {
                    if (isNaN(val) || val <= 0) return "0:00";
                    let totalSeconds = Math.floor(val / timeScale);
                    let mins = Math.floor(totalSeconds / 60);
                    let secs = Math.floor(totalSeconds % 60);
                    return mins + ":" + (secs < 10 ? "0" : "") + secs;
                }

                Timer {
                    interval: 1000
                    repeat: true
                    running: mprisPlayer && mprisPlayer.isPlaying
                    onTriggered: {
                        if (mprisPlayer && typeof mprisPlayer.positionChanged === "function") {
                            mprisPlayer.positionChanged();
                        }
                    }
                }

                // Background Image Sliding Container
                Item {
                    id: albumArtContainer
                    anchors.fill: parent
                    property string currentUrl: mprisPlayer && mprisPlayer.trackArtUrl ? mprisPlayer.trackArtUrl : ""
                    property string oldUrl: ""

                    onCurrentUrlChanged: {
                        if (oldUrl !== "" && currentUrl !== "" && oldUrl !== currentUrl) {
                            albumArtOld.source = oldUrl;
                            albumArtOld.x = 0;
                            albumArtOld.visible = true;
                            
                            albumArtNew.x = mediaPlayerRoot.slideDirection * width;
                            
                            slideOutOld.to = -mediaPlayerRoot.slideDirection * width;
                            slideAnim.restart();
                        } else if (currentUrl !== "") {
                            albumArtNew.x = 0;
                            albumArtOld.visible = false;
                        } else {
                            albumArtOld.visible = false;
                        }
                        oldUrl = currentUrl;
                        mediaPlayerRoot.slideDirection = 1;
                    }

                    Image {
                        id: albumArtOld
                        width: parent.width; height: parent.height
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                    }

                    Image {
                        id: albumArtNew
                        width: parent.width; height: parent.height
                        source: albumArtContainer.currentUrl
                        fillMode: Image.PreserveAspectCrop
                        opacity: source !== "" ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: albumArtNew.source !== "" ? Vars.m3StandardDecelerate : Vars.m3StandardAccelerate } }
                    }

                    ParallelAnimation {
                        id: slideAnim
                        NumberAnimation { 
                            id: slideOutOld
                            target: albumArtOld; property: "x"; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast 
                        }
                        NumberAnimation { 
                            target: albumArtNew; property: "x"; to: 0; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast 
                        }
                        onFinished: {
                            albumArtOld.visible = false;
                        }
                    }
                }
                
                // Corner masks to simulate rounding against the Control Center background
                Item {
                    id: cornerMasks
                    anchors.fill: parent
                    visible: albumArtContainer.currentUrl !== ""

                    property real r: 16
                    property color maskColor: Theme.surface_container_low
                    z: 5 // Bring to front above the gradient overlay
                    
                    // Top-Left
                    Item {
                        x: 0; y: 0; width: cornerMasks.r; height: cornerMasks.r; clip: true
                        Rectangle {
                            x: -cornerMasks.r; y: -cornerMasks.r; width: cornerMasks.r * 4; height: cornerMasks.r * 4; radius: cornerMasks.r * 2
                            color: "transparent"; border.color: cornerMasks.maskColor; border.width: cornerMasks.r
                        }
                    }
                    // Top-Right
                    Item {
                        x: parent.width - cornerMasks.r; y: 0; width: cornerMasks.r; height: cornerMasks.r; clip: true
                        Rectangle {
                            x: -cornerMasks.r * 2; y: -cornerMasks.r; width: cornerMasks.r * 4; height: cornerMasks.r * 4; radius: cornerMasks.r * 2
                            color: "transparent"; border.color: cornerMasks.maskColor; border.width: cornerMasks.r
                        }
                    }
                    // Bottom-Left
                    Item {
                        x: 0; y: parent.height - cornerMasks.r; width: cornerMasks.r; height: cornerMasks.r; clip: true
                        Rectangle {
                            x: -cornerMasks.r; y: -cornerMasks.r * 2; width: cornerMasks.r * 4; height: cornerMasks.r * 4; radius: cornerMasks.r * 2
                            color: "transparent"; border.color: cornerMasks.maskColor; border.width: cornerMasks.r
                        }
                    }
                    // Bottom-Right
                    Item {
                        x: parent.width - cornerMasks.r; y: parent.height - cornerMasks.r; width: cornerMasks.r; height: cornerMasks.r; clip: true
                        Rectangle {
                            x: -cornerMasks.r * 2; y: -cornerMasks.r * 2; width: cornerMasks.r * 4; height: cornerMasks.r * 4; radius: cornerMasks.r * 2
                            color: "transparent"; border.color: cornerMasks.maskColor; border.width: cornerMasks.r
                        }
                    }
                }
                
                // Fallback background icon when no album art
                Item {
                    anchors.fill: parent
                    visible: !mprisPlayer || !mprisPlayer.trackArtUrl
                    
                    Text {
                        anchors.centerIn: parent
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 120
                        color: Theme.primary
                        opacity: 0.15
                        text: "\ue405" // audiotrack
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    visible: mprisPlayer && mprisPlayer.trackArtUrl !== ""
                    z: 1
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.4; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.95) }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Vars.spacingLarge
                    spacing: Vars.spacingSmall
                    
                    // Spacer to push content down if needed, or rely on fillHeight
                    Item { Layout.fillWidth: true; Layout.fillHeight: true }

                    // Metadata and Controls row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Vars.spacingMedium
                        
                        // Text Column
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Text { 
                                text: mprisPlayer ? (mprisPlayer.trackTitle || (mprisPlayer.metadata ? mprisPlayer.metadata["xesam:title"] : null) || mprisPlayer.identity || "Unknown Title") : "No Media Playing"
                                font.family: Vars.fontFamily
                                font.pixelSize: 20
                                font.weight: 700
                                color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.on_surface
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text { 
                                text: mprisPlayer && mprisPlayer.trackArtist ? mprisPlayer.trackArtist : "Artist"
                                font.family: Vars.fontFamily
                                font.pixelSize: 14
                                color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.on_surface
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                opacity: 0.8
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text { 
                                text: mprisPlayer && mprisPlayer.trackAlbum ? mprisPlayer.trackAlbum : ""
                                font.family: Vars.fontFamily
                                font.pixelSize: 12
                                color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.on_surface
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                opacity: 0.6
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                visible: text !== ""
                            }
                        }
                        
                        RowLayout {
                            spacing: 12
                            Layout.alignment: Qt.AlignBottom
                            
                            Rectangle {
                                width: 32; height: 32; radius: 16; color: "transparent"
                                Text { 
                                    anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 24
                                    color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.on_primary_container; text: "\ue045" 
                                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                }
                                MouseArea { anchors.fill: parent; onClicked: { mediaPlayerRoot.slideDirection = -1; if(mprisPlayer) mprisPlayer.previous(); } cursorShape: Qt.PointingHandCursor }
                            }
                            
                            Rectangle {
                                width: 56; height: 56; radius: 28; color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.primary
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                Text { 
                                    anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 32; color: mprisPlayer && mprisPlayer.trackArtUrl ? "black" : Theme.on_surface
                                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                    text: mprisPlayer && mprisPlayer.isPlaying ? "\ue034" : "\ue037"
                                }
                                MouseArea { 
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: if(mprisPlayer) {
                                        if (typeof mprisPlayer.togglePlaying === "function") mprisPlayer.togglePlaying();
                                        else if (typeof mprisPlayer.playPause === "function") mprisPlayer.playPause();
                                    } 
                                }
                            }

                            Rectangle {
                                width: 32; height: 32; radius: 16; color: "transparent"
                                Text { 
                                    anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 24
                                    color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.on_primary_container; text: "\ue044" 
                                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                }
                                MouseArea { anchors.fill: parent; onClicked: { mediaPlayerRoot.slideDirection = 1; if(mprisPlayer) mprisPlayer.next(); } cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }

                    Item { Layout.preferredHeight: 16 }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        radius: 2
                        color: mprisPlayer && mprisPlayer.trackArtUrl ? Qt.rgba(1,1,1,0.3) : Qt.rgba(Theme.on_primary_container.r, Theme.on_primary_container.g, Theme.on_primary_container.b, 0.2)
                        
                        Rectangle {
                            height: parent.height
                            width: mprisPlayer && mprisPlayer.length > 0 && mprisPlayer.position !== undefined ? parent.width * (mprisPlayer.position / mprisPlayer.length) : 0
                            radius: 2
                            color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.on_primary_container
                            Behavior on width { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            function seekToMouse(mouse) {
                                if(mprisPlayer && mprisPlayer.length > 0) {
                                    let ratio = Math.max(0, Math.min(1, mouse.x / width));
                                    let newPos = ratio * mprisPlayer.length;
                                    if (mprisPlayer.canSeek) {
                                        mprisPlayer.position = newPos; 
                                    }
                                }
                            }
                            onPressed: (mouse) => seekToMouse(mouse)
                            onPositionChanged: (mouse) => { if (pressed) seekToMouse(mouse) }
                        }
                    }
                }

                // MPRIS Player Selector Toggle
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: Vars.spacingMedium
                    width: selectorRow.width + Vars.spacingLarge
                    height: 28
                    radius: height / 2
                    color: selectorMouse.containsMouse ? Qt.rgba(255,255,255, 0.2) : Qt.rgba(255,255,255, 0.1)
                    visible: Mpris.players.values.length > 1
                    z: 5
                    
                    RowLayout {
                        id: selectorRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: mprisPlayer ? (mprisPlayer.identity || "Unknown") : ""
                            font.family: Vars.fontFamily
                            font.pixelSize: 13
                            font.weight: 600
                            color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.on_surface
                        }
                        Text {
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.on_surface
                            text: playerDropdown.visible ? "\ue5ce" : "\ue5cf" // expand_less / expand_more
                        }
                    }
                    
                    MouseArea {
                        id: selectorMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: playerDropdown.visible = !playerDropdown.visible
                    }
                }
                
                // MPRIS Player Dropdown
                Rectangle {
                    id: playerDropdown
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: Vars.spacingMedium + 28 + 4
                    anchors.rightMargin: Vars.spacingMedium
                    width: 180
                    height: playerColumn.implicitHeight + 8
                    radius: Vars.radiusMedium
                    color: Theme.surface_container_highest
                    border.color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.1)
                    border.width: 1
                    visible: false
                    z: 10
                    
                    Column {
                        id: playerColumn
                        anchors.fill: parent
                        anchors.margins: 4
                        
                        Repeater {
                            model: Mpris.players.values
                            delegate: Rectangle {
                                width: playerColumn.width
                                height: 36
                                radius: Vars.radiusSmall
                                color: itemMouse.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent"
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 12
                                    
                                    Text {
                                        text: modelData.identity || "Unknown"
                                        font.family: Vars.fontFamily
                                        font.pixelSize: 14
                                        color: mprisPlayer === modelData ? Theme.primary : Theme.on_surface
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    
                                    Text {
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 18
                                        color: Theme.primary
                                        text: "\ue876" // check
                                        visible: mprisPlayer === modelData
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                                
                                MouseArea {
                                    id: itemMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.preferredMprisPlayer = modelData;
                                        playerDropdown.visible = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ==========================================
            // NOTIFICATIONS AREA
            // ==========================================
            Timer {
                interval: 200
                running: true
                repeat: true
                property int lastSync: -1
                onTriggered: {
                    if (lastSync !== Vars.historyUpdated) {
                        lastSync = Vars.historyUpdated;
                        root.historyList = Vars.notificationHistory.slice();
                    }
                }
            }

            // Empty State
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                Layout.topMargin: Vars.spacingSmall
                radius: Vars.radiusLarge
                color: Theme.surface_container_high
                visible: root.historyList.length === 0
                
                Text {
                    text: "No new notifications"
                    font.family: Vars.fontFamily; font.pixelSize: 14; color: Theme.on_surface_variant
                    anchors.centerIn: parent
                }
            }

            Repeater {
                model: root.historyList

                NotificationCard {
                    isPopup: false
                    fontName: Vars.fontFamily
                    Layout.fillWidth: true
                }
            }

            Item {
                Layout.preferredHeight: 80
                Layout.fillWidth: true
                visible: root.historyList.length > 0
            }
        }
    }

    // Floating action bar
    Rectangle {
        width: parent.width - (Vars.spacingLarge * 3)
        height: 64
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Vars.spacingLarge * 1.5
        anchors.horizontalCenter: parent.horizontalCenter
        radius: 16
        color: Theme.surface_container_highest
        visible: root.currentSubMenu === "" && root.historyList.length > 0
        z: 10
        opacity: root.currentSubMenu === "" ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 8
            
            // Clear all button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 16
                color: clearAllHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.16) : (clearAllHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08))
                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                
                Text {
                    anchors.centerIn: parent
                    text: "Clear all"
                    font.family: Vars.fontFamily
                    font.pixelSize: 14
                    font.weight: 600
                    color: Theme.on_surface
                }
                MouseArea {
                    id: clearAllHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Vars.clearNotifications()
                }
            }
        }
    }

        // ------------------------------------------
        // VIEW 2: WI-FI DETAILED SUB-MENU VIEW
        // ------------------------------------------
        ColumnLayout {
            id: wifiSubMenuView
            anchors.fill: parent
            anchors.margins: Vars.spacingLarge
            spacing: Vars.spacingMedium
            
            opacity: root.currentSubMenu === "wifi" ? 1.0 : 0.0
            visible: opacity > 0
            transform: Translate {
                x: root.currentSubMenu === "wifi" ? 0 : 40
                Behavior on x { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
            }
            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.currentSubMenu === "wifi" ? Vars.m3StandardDecelerate : Vars.m3StandardAccelerate } }

            // Header matching the UI screenshot
            RowLayout {
                Layout.fillWidth: true
                spacing: Vars.spacingMedium
                
                Rectangle {
                    width: 40; height: 40; radius: 20
                    color: backHoverWifi.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (backHoverWifi.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                    Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_surface; text: "\ue5c4" }
                    MouseArea { id: backHoverWifi; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.currentSubMenu = "" }
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
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
                        Behavior on anchors.leftMargin { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Networking.wifiEnabled = !Networking.wifiEnabled }
                }
            }

            Flickable {
                id: wifiFlickable
                Layout.fillWidth: true; Layout.fillHeight: true
                contentHeight: wifiListContainer.childrenRect.height; clip: true

                ColumnLayout {
                    id: wifiListContainer
                    width: wifiFlickable.width; spacing: Vars.spacingSmall

                    Repeater {
                        model: wifiDevice ? wifiDevice.networks.values : []
                        delegate: Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 64
                            radius: 16
                            Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                            color: modelData.connected ? Theme.secondary_container : (wifiMouse.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (wifiMouse.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : Theme.surface_container_low))
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                            
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 16; spacing: 12
                                
                                Rectangle {
                                    Layout.preferredWidth: 40; Layout.preferredHeight: 40
                                    radius: modelData.connected ? 12 : 20
                                    Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                    color: modelData.connected ? Qt.rgba(Theme.on_secondary_container.r, Theme.on_secondary_container.g, Theme.on_secondary_container.b, 0.15) : Qt.rgba(Theme.on_surface_variant.r, Theme.on_surface_variant.g, Theme.on_surface_variant.b, 0.1)
                                    Text {
                                        anchors.centerIn: parent
                                        font.family: "Material Symbols Outlined"; font.pixelSize: 22
                                        color: modelData.connected ? Theme.on_secondary_container : Theme.on_surface_variant
                                        text: {
                                            if (modelData.signalStrength === undefined) return "\ue63e";
                                            let tier = Math.min(Math.floor(modelData.signalStrength / 25), 3);
                                            return ["\ue1ba", "\uebe4", "\uebd6", "\uebe1"][tier] || "\ue63e";
                                        }
                                        Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                    }
                                }
                                
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter; spacing: 0
                                    Text { 
                                        text: modelData.name; font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: Font.Bold
                                        color: modelData.connected ? Theme.on_secondary_container : Theme.on_surface_variant
                                        Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                    }
                                    Text { 
                                        text: modelData.connected ? "Connected" : "Available"; font.family: Vars.fontFamily; font.pixelSize: 12; opacity: 0.8
                                        color: modelData.connected ? Theme.on_secondary_container : Theme.on_surface_variant
                                        Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
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

        // ------------------------------------------
        // VIEW 3: BLUETOOTH DETAILED SUB-MENU VIEW
        // ------------------------------------------
        ColumnLayout {
            id: bluetoothSubMenuView
            anchors.fill: parent
            anchors.margins: Vars.spacingLarge
            spacing: Vars.spacingMedium
            
            opacity: root.currentSubMenu === "bluetooth" ? 1.0 : 0.0
            visible: opacity > 0
            transform: Translate {
                x: root.currentSubMenu === "bluetooth" ? 0 : 40
                Behavior on x { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
            }
            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.currentSubMenu === "bluetooth" ? Vars.m3StandardDecelerate : Vars.m3StandardAccelerate } }

            // Header matching the UI screenshot
            RowLayout {
                Layout.fillWidth: true
                spacing: Vars.spacingMedium
                
                Rectangle {
                    width: 40; height: 40; radius: 20
                    color: backHoverBt.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (backHoverBt.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                    Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_surface; text: "\ue5c4" }
                    MouseArea { id: backHoverBt; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.currentSubMenu = "" }
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
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
                        Behavior on anchors.leftMargin { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if(adapter) adapter.enabled = !adapter.enabled }
                }
            }

            Flickable {
                id: bluetoothFlickable
                Layout.fillWidth: true; Layout.fillHeight: true
                contentHeight: bluetoothListContainer.childrenRect.height; clip: true

                ColumnLayout {
                    id: bluetoothListContainer
                    width: bluetoothFlickable.width; spacing: Vars.spacingSmall

                    Repeater {
                        model: adapter ? adapter.devices.values : []
                        delegate: Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 64
                            radius: 16
                            Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                            color: modelData.connected ? Theme.secondary_container : (btMouse.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (btMouse.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : Theme.surface_container_low))
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                            
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 16; spacing: 12
                                
                                Rectangle {
                                    Layout.preferredWidth: 40; Layout.preferredHeight: 40
                                    radius: modelData.connected ? 12 : 20
                                    Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                    color: modelData.connected ? Qt.rgba(Theme.on_secondary_container.r, Theme.on_secondary_container.g, Theme.on_secondary_container.b, 0.15) : Qt.rgba(Theme.on_surface_variant.r, Theme.on_surface_variant.g, Theme.on_surface_variant.b, 0.1)
                                    Text {
                                        anchors.centerIn: parent
                                        font.family: "Material Symbols Outlined"; font.pixelSize: 22
                                        color: modelData.connected ? Theme.on_secondary_container : Theme.on_surface_variant
                                        text: modelData.connected ? "\ue1a8" : "\ue1a7"
                                        Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                    }
                                }
                                
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter; spacing: 0
                                    Text { 
                                        text: modelData.name ? modelData.name : "Unknown Device"; font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: Font.Bold
                                        color: modelData.connected ? Theme.on_secondary_container : Theme.on_surface_variant
                                        Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                    }
                                    Text { 
                                        text: modelData.connected ? "Connected" : "Paired"; font.family: Vars.fontFamily; font.pixelSize: 12; opacity: 0.8
                                        color: modelData.connected ? Theme.on_secondary_container : Theme.on_surface_variant
                                        Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
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

        // ------------------------------------------
        // VIEW 4: DISPLAY DETAILED SUB-MENU VIEW
        // ------------------------------------------
        ColumnLayout {
            id: displaySubMenuView
            anchors.fill: parent
            anchors.margins: Vars.spacingLarge
            spacing: Vars.spacingMedium
            visible: root.currentSubMenu === "display"

            // Header matching the UI screenshot
            RowLayout {
                Layout.fillWidth: true
                spacing: Vars.spacingMedium
                
                Rectangle {
                    width: 40; height: 40; radius: 20
                    color: backHoverDisp.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (backHoverDisp.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                    Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_surface; text: "\ue5c4" }
                    MouseArea { id: backHoverDisp; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.currentSubMenu = "" }
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                }
                Text { text: "Display Scale"; font.family: Vars.fontFamily; font.pixelSize: 24; font.weight: Font.Bold; color: Theme.on_surface; Layout.fillWidth: true }
            }

            Flickable {
                id: displayFlickable
                Layout.fillWidth: true; Layout.fillHeight: true
                contentHeight: displayListContainer.childrenRect.height; clip: true

                ColumnLayout {
                    id: displayListContainer
                    width: displayFlickable.width; spacing: Vars.spacingSmall

                    Repeater {
                        model: [1.0, 1.25, 1.5, 2.0]
                        delegate: Rectangle {
                            property bool isActive: Hyprland.focusedMonitor && Math.abs(Hyprland.focusedMonitor.scale - modelData) < 0.01
                            Layout.fillWidth: true; Layout.preferredHeight: 64
                            radius: isActive ? 16 : 32
                            Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                            color: isActive ? Theme.secondary_container : (dispMouse.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (dispMouse.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : Theme.surface_container_low))
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                            
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 16; spacing: 12
                                
                                Rectangle {
                                    Layout.preferredWidth: 40; Layout.preferredHeight: 40
                                    radius: isActive ? 12 : 20
                                    Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                    color: isActive ? Qt.rgba(Theme.on_secondary_container.r, Theme.on_secondary_container.g, Theme.on_secondary_container.b, 0.15) : Qt.rgba(Theme.on_surface_variant.r, Theme.on_surface_variant.g, Theme.on_surface_variant.b, 0.1)
                                    Text {
                                        anchors.centerIn: parent
                                        font.family: "Material Symbols Outlined"; font.pixelSize: 22
                                        color: isActive ? Theme.on_secondary_container : Theme.on_surface_variant
                                        text: "\ue30d"
                                        Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                    }
                                }
                                
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter; spacing: 0
                                    Text { 
                                        text: modelData + "x Scale"; font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: Font.Bold
                                        color: isActive ? Theme.on_secondary_container : Theme.on_surface_variant
                                        Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                    }
                                    Text { 
                                        text: isActive ? "Active" : "Apply scale"; font.family: Vars.fontFamily; font.pixelSize: 12; opacity: 0.8
                                        color: isActive ? Theme.on_secondary_container : Theme.on_surface_variant
                                        Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
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
    }
    }
}
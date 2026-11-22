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
import Quickshell.Services.SystemTray
import Quickshell.Hyprland
import QtCore
import "../theme"
import "../core/primitives" as Primitives
import "ControlCenter" as CC

Item {
    id: root
    
    // Fixed layout footprint - never animates, no parent relayout
    Layout.preferredWidth: 100
    Layout.preferredHeight: 40
    
    property bool expanded: false
    property var focusWindow: null
    property bool forceHidePill: false
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false

    // Navigation state: "" (Main Dashboard), "wifi" (Wi-Fi Settings), "bluetooth" (Bluetooth Settings)
    property string currentSubMenu: ""
    property bool isEditorMode: false
    property string systemUptime: ""

    // Custom M3 System Tray Menu state & positioning
    property var activeTrayMenu: null
    property real trayMenuX: 0
    property real trayMenuY: 0

    Process {
        id: uptimeProc
        command: ["uptime"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let output = this.text.trim();
                if (output !== "") {
                    let tokens = output.split(/\s+/).filter(t => t !== "");
                    if (tokens.length >= 3) {
                        // 1st: 04:22:28, 2nd: up, 3rd: 1:02,
                        root.systemUptime = tokens[2].replace(",", "");
                    } else {
                        root.systemUptime = output;
                    }
                }
            }
        }
    }
    Timer {
        interval: 60000 // Refresh every minute
        running: root.expanded
        repeat: true
        onTriggered: uptimeProc.running = true
    }
    
    signal closeRequested()
    signal popupOpened()
    signal openColorSchemeRequested()
    signal openSettingsRequested()
    signal openWallpaperRequested()
    signal openPowerMenuRequested()
    signal openOverviewRequested()
    signal openGameLibraryRequested()
    signal openCheatSheetRequested()
    
    // Expose the visual panel for mask tracking in TopPills
    property alias panel: panel
    property alias panelMask: panelMask


    
    focus: root.expanded
    onExpandedChanged: {
        if (expanded) {
            MorphState.notifyOpened(600, panel.targetHeight, panel.targetRad, panel);
            expandedUI.visible = true;
            forceActiveFocus();
            expandedUI.visible = Qt.binding(() => root.expanded || expandedUI.opacity > 0);
            uptimeProc.running = true;
            // The dashboard is a persistent Flickable, not recreated per open, so without this
            // it silently reopens scrolled to wherever it was last left — hiding the module grid
            // above the fold with no visible indication there's more content to scroll to.
            mainDashboardFlickable.contentY = 0;
        } else {
            MorphState.notifyClosed();
            isEditorMode = false;
            currentSubMenu = "";
            activeTrayMenu = null;
        }
    }
    Keys.onEscapePressed: {
        root.expanded = false;
    }

    Item {
        id: panelMask
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines plus four bleed-margin lines, so a pillPosition change can't
        // leave this item part-anchored to the old edge while the other axis has already moved
        // to the new one (that mismatch is what made expanded popups fail to render their
        // content after a live position change).
        property real _bleed: root.expanded ? -20 : 0
        x: {
            if (Vars.pillPosition === "Left") return _bleed;
            if (Vars.pillPosition === "Right") return parent.width - width - _bleed;
            return (parent.width - width) / 2;
        }
        y: {
            if (Vars.pillPosition === "Bottom") return parent.height - height - _bleed;
            if (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") return (parent.height - height) / 2;
            return _bleed;
        }
        width: root.expanded ? 640 : 0
        height: root.expanded ? 640 : 0
    }

    Primitives.SquircleMask {
        id: panel
        property bool isBackgroundActive: root.expanded || (MorphState.openCount === 0 && MorphState.activeItem === panel && panel.width > 105)
        layer.enabled: false
        layer.samples: Vars.layerSamples
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines, so a pillPosition change can't leave this item part-anchored to
        // the old edge while the other axis has already moved to the new one (that mismatch is
        // what made expanded popups fail to render their content after a live position change).
        x: {
            if (Vars.pillPosition === "Left") return 0;
            if (Vars.pillPosition === "Right") return parent.width - width;
            return (parent.width - width) / 2;
        }
        y: {
            if (Vars.pillPosition === "Bottom") return parent.height - height;
            if (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") return (parent.height - height) / 2;
            return 0;
        }
        
        property real targetHeight: {
            if (!root.expanded) return MorphState.anyExpanded ? MorphState.targetHeight : 40;
            if (root.currentSubMenu === "wifi") return Math.min(800, wifiMenuObj.implicitHeight + (Vars.spacingLarge * 2));
            if (root.currentSubMenu === "bluetooth") return Math.min(800, bluetoothMenuObj.implicitHeight + (Vars.spacingLarge * 2));
            if (root.currentSubMenu === "display") return Math.min(800, displayMenuObj.implicitHeight + (Vars.spacingLarge * 2));
            if (root.currentSubMenu === "disk") return Math.min(800, diskMenuObj.implicitHeight + (Vars.spacingLarge * 2));
            return 660; // Main dashboard
        }
        
        width: root.expanded ? 600 : (MorphState.anyExpanded ? MorphState.targetWidth : 100)
        height: targetHeight
        
        onTargetHeightChanged: {
            if (root.expanded) MorphState.updateDimensions(600, targetHeight, targetRad);
        }
        
        color: Vars.tColorActive(isBackgroundActive, Theme.surface, Vars.panelOpacity)
        property real targetRad: root.expanded ? Vars.radiusExtraLarge : (MorphState.anyExpanded ? MorphState.targetRadius : height / 2)
        topLeftRadius: Vars.getTopLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        topRightRadius: Vars.getTopRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomLeftRadius: Vars.getBottomLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomRightRadius: Vars.getBottomRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        
        opacity: isBackgroundActive || expandedUI.opacity > 0 ? 1.0 : 0.0
        // visible: opacity > 0 // Removed to preserve Behavior when hidden

        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

        // EXPANDED PANEL CONTAINER
        Item {
            id: expandedUI
            anchors.fill: parent
            
            opacity: root.expanded ? 1.0 : 0.0
            visible: root.expanded || opacity > 0
            clip: true
            Behavior on opacity { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.expanded ? Vars.customEmphasizedDecelerate : Vars.customEmphasizedAccelerate } }

            // ------------------------------------------
            // VIEW 1: MAIN DASHBOARD MENU
            // ------------------------------------------
            Flickable {
                id: mainDashboardFlickable
                anchors.fill: parent
                anchors.margins: Vars.spacingLarge * 1.5
                // In Overlay Mode (mediaPlayerExpandOverlaps), the media player's wrapper
                // deliberately keeps its own Layout.preferredHeight pinned small while expanded —
                // on purpose, so the rest of the dashboard doesn't reflow/push down — but that
                // also means mainDashboardView's implicitHeight never grows to cover the part of
                // the expanded player that's overlapping on top rather than pushing. Without
                // adding that overlap back in here, there was no way to scroll far enough to reach
                // whatever of the expanded player extended past the collapsed wrapper's height.
                contentHeight: mainDashboardView.implicitHeight + (Vars.mediaPlayerExpandOverlaps && mediaPlayer.isExpanded ? Math.max(0, mediaPlayer.height - (mediaPlayer.isVertical ? 300 : 180)) : 0)
                interactive: true
                
                onContentYChanged: {
                    if (root.activeTrayMenu !== null) {
                        root.activeTrayMenu = null;
                    }
                }
                
                opacity: root.currentSubMenu === "" ? 1.0 : 0.0
                visible: opacity > 0
                transform: Translate {
                    x: root.currentSubMenu === "" ? 0 : -40
                    Behavior on x { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                }
                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.currentSubMenu === "" ? Vars.customEmphasizedDecelerate : Vars.customEmphasizedAccelerate } }
                clip: true
                // boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: mainDashboardView
                    width: mainDashboardFlickable.width
                    spacing: Vars.spacingMedium

                    // Header Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Rectangle {
                            Layout.preferredHeight: 40
                            Layout.preferredWidth: logoLayout.implicitWidth + 16
                            radius: 20
                            antialiasing: true
                            color: Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)
                            clip: true
                            
                            RowLayout {
                                id: logoLayout
                                anchors.centerIn: parent
                                spacing: 8
                                
                                Image {
                                    source: typeof globalOsIconPath !== "undefined" && globalOsIconPath !== "" ? globalOsIconPath : ""
                                    fillMode: Image.PreserveAspectFit
                                    Layout.preferredHeight: 28
                                    Layout.preferredWidth: source.toString() !== "" ? 28 : 0
                                    visible: source.toString() !== ""
                                    smooth: true
                                    antialiasing: true
                                }
                                QsText { 
                                    text: (typeof globalOsIconPath !== "undefined" && globalOsIconPath !== "") ? "" : "Control Center"; 
                                    font.family: Vars.fontFamily; 
                                    font.pixelSize: 18; 
                                    setWeight: Font.Bold; 
                                    color: Theme.on_surface;
                                    visible: text !== ""
                                }
                                Rectangle {
                                    Layout.preferredWidth: 4
                                    Layout.preferredHeight: 4
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: 2
                                    antialiasing: true
                                    color: Theme.primary
                                    visible: root.systemUptime !== ""
                                }
                                QsText {
                                    text: root.systemUptime
                                    font.family: Vars.fontFamily
                                    font.pixelSize: 18
                                    setWeight: Font.Medium
                                    color: Theme.primary
                                    visible: root.systemUptime !== ""
                                }
                                Rectangle {
                                    Layout.preferredWidth: 4
                                    Layout.preferredHeight: 4
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: 2
                                    antialiasing: true
                                    color: Theme.primary
                                    visible: trayRepeater.count > 0
                                }
                                RowLayout {
                                    id: trayLayout
                                    spacing: 2
                                    visible: trayRepeater.count > 0
                                    Layout.preferredWidth: implicitWidth
                                    Layout.preferredHeight: implicitHeight
                                    Layout.alignment: Qt.AlignVCenter

                                    Repeater {
                                        id: trayRepeater
                                        model: SystemTray.items

                                        delegate: Rectangle {
                                            id: trayPill
                                            Layout.preferredWidth: 28
                                            Layout.preferredHeight: 28
                                            Layout.alignment: Qt.AlignVCenter
                                            
                                            color: itemMouseArea.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (itemMouseArea.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                                            radius: height / 2
                                            antialiasing: true

                                            Behavior on color {
                                                ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard }
                                            }

                                            property var trayItem: modelData 

                                            MouseArea {
                                                id: itemMouseArea
                                                anchors.fill: parent
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor

                                                onClicked: (mouse) => {
                                                    if (!trayItem) return;
                                                    if (mouse.button === Qt.RightButton && trayItem.menu) {
                                                        if (root.activeTrayMenu === trayItem.menu) {
                                                            root.activeTrayMenu = null;
                                                        } else {
                                                            var pillCoords = trayPill.mapToItem(expandedUI, 0, trayPill.height);
                                                            root.trayMenuX = pillCoords.x - 40;
                                                            root.trayMenuY = pillCoords.y + 6;
                                                            root.activeTrayMenu = trayItem.menu;
                                                        }
                                                    } else if (mouse.button === Qt.LeftButton) {
                                                        root.activeTrayMenu = null;
                                                        trayItem.activate();
                                                        root.expanded = false;
                                                    } else if (mouse.button === Qt.MiddleButton && typeof trayItem.secondaryActivate === "function") {
                                                        root.activeTrayMenu = null;
                                                        trayItem.secondaryActivate();
                                                    }
                                                }
                                            }

                                            Image {
                                                id: itemIcon
                                                width: 20
                                                height: 20
                                                anchors.centerIn: parent
                                                source: trayItem && trayItem.icon ? trayItem.icon : "" 
                                                fillMode: Image.PreserveAspectFit
                                                
                                                opacity: itemMouseArea.containsMouse ? 1.0 : 0.7
                                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration } }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        Rectangle {
                            Layout.preferredHeight: 40
                            Layout.preferredWidth: btnLayout.implicitWidth + 16
                            radius: 20
                            antialiasing: true
                            color: Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)
                            clip: true
                            
                            RowLayout {
                                id: btnLayout
                                anchors.centerIn: parent
                                spacing: 4
                                
                                // Edit Button
                                Rectangle {
                                    antialiasing: true
                                    Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 16
                                    color: editHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (editHover.containsMouse || root.isEditorMode ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                                    QsText { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 18; color: root.isEditorMode ? Theme.primary : Theme.on_surface; text: "edit" }
                                    MouseArea { 
                                        id: editHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; 
                                        onClicked: root.isEditorMode = !root.isEditorMode 
                                    }
                                    Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                }
                                
                                // Refresh Button
                                Rectangle {
                                    antialiasing: true
                                    Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 16
                                    color: refreshHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (refreshHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                                    QsText { 
                                        id: refreshIcon
                                        anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 18; color: Theme.on_surface; text: "refresh" 
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
                                            Quickshell.execDetached({ command: ["bash", "-c", "nohup bash ~/Dotfiles/scripts/reload.sh >/dev/null 2>&1 &"] });
                                        }
                                    }
                                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                }
                                
                                // Settings Button
                                Rectangle {
                                    antialiasing: true
                                    Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 16
                                    color: settingsHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (settingsHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                                    QsText { 
                                        id: settingsIcon
                                        anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 18; color: Theme.on_surface; text: "settings" 
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
                                            root.openSettingsRequested();
                                        } 
                                    }
                                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                }
                                
                                // Power Button
                                Rectangle {
                                    antialiasing: true
                                    Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 16
                                    color: powerHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (powerHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                                    QsText { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 18; color: Theme.on_surface; text: "power_settings_new" }
                                    MouseArea { 
                                        id: powerHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; 
                                        onClicked: { root.openPowerMenuRequested() } 
                                    }
                                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                }
                            }
                        }
                    }

                    // Modular Components
                    CC.ModuleGrid {
                        id: moduleGridObj
                        isEditorMode: root.isEditorMode
                        gameMode: root.gameMode
                        onSubMenuRequested: (menuName) => { root.currentSubMenu = menuName; }
                        onOpenColorSchemeRequested: { root.openColorSchemeRequested() }
                        onOpenSettingsRequested: { root.openSettingsRequested() }
                        onOpenWallpaperRequested: { root.openWallpaperRequested() }
                        onOpenOverviewRequested: { root.openOverviewRequested() }
                        onOpenGameLibraryRequested: { root.openGameLibraryRequested() }
                        onOpenCheatSheetRequested: { root.openCheatSheetRequested() }
                    }

                    CC.Sliders { }
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Vars.mediaPlayerExpandOverlaps ? (mediaPlayer.isVertical ? 300 : 180) : mediaPlayer.Layout.preferredHeight
                        Layout.preferredWidth: Vars.mediaPlayerExpandOverlaps ? -1 : mediaPlayer.Layout.preferredWidth
                        
                        z: (mediaPlayer.isExpanded || mediaPlayer.playerDropdownVisible) ? 100 : 1
                        
                        Behavior on Layout.preferredHeight { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutCubic } }
                        Behavior on Layout.preferredWidth { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutCubic } }
                        
                        CC.MediaPlayer {
                            id: mediaPlayer
                            forceVerticalExpansion: true
                            width: Vars.mediaPlayerExpandOverlaps ? (isExpanded && isHorizontalExpansion ? 900 : parent.width) : parent.width
                            height: Vars.mediaPlayerExpandOverlaps ? (isExpanded && !isHorizontalExpansion ? 650 : parent.height) : parent.height
                            
                            Behavior on height { enabled: Vars.mediaPlayerExpandOverlaps; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutCubic } }
                            Behavior on width { enabled: Vars.mediaPlayerExpandOverlaps; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutCubic } }
                        }
                    }
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

            CC.DiskMenu {
                id: diskMenuObj
                isActive: root.currentSubMenu === "disk"
                rows: moduleGridObj.diskRows
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
            }

            // ------------------------------------------
            // CUSTOM M3 SYSTEM TRAY CONTEXT MENU
            // ------------------------------------------
            QsMenuOpener {
                id: trayMenuOpener
                menu: root.activeTrayMenu
            }

            // Backdrop area to cleanly dismiss menu when clicking anywhere outside
            MouseArea {
                anchors.fill: parent
                enabled: root.activeTrayMenu !== null
                visible: enabled
                onClicked: {
                    root.activeTrayMenu = null;
                }
            }

            Rectangle {
                id: trayMenuPopup
                x: Math.max(10, Math.min(expandedUI.width - width - 10, root.trayMenuX))
                y: Math.min(expandedUI.height - height - 10, root.trayMenuY)
                width: Math.max(150, menuColumn.implicitWidth + 8)
                height: menuColumn.implicitHeight + 8
                
                color: Vars.tColor(Theme.surface_container_highest, Vars.panelOpacity)
                radius: Vars.radiusMedium
                antialiasing: true
                border.width: 1
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                clip: true
                

                transformOrigin: Item.Top
                opacity: root.activeTrayMenu !== null ? 1.0 : 0.0
                visible: opacity > 0
                scale: root.activeTrayMenu !== null ? 1.0 : 0.88

                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.activeTrayMenu !== null ? Vars.customEmphasizedDecelerate : Vars.customEmphasizedAccelerate } }
                Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                Behavior on x { enabled: root.activeTrayMenu !== null && trayMenuPopup.opacity > 0.5; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                Behavior on y { enabled: root.activeTrayMenu !== null && trayMenuPopup.opacity > 0.5; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

                ColumnLayout {
                    id: menuColumn
                    anchors.centerIn: parent
                    spacing: 1
                    width: trayMenuPopup.width - 8

                    Repeater {
                        model: trayMenuOpener.children

                        delegate: Item {
                            id: entryItem
                            Layout.fillWidth: true
                            Layout.preferredHeight: modelData && modelData.isSeparator ? 7 : 28
                            property var entry: modelData

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 8
                                height: 1
                                color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
                                visible: entry && entry.isSeparator
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: entry && !entry.isSeparator
                                color: entryMouseArea.pressed ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18) : (entryMouseArea.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                                radius: Vars.radiusSmall || 4
                                antialiasing: true
                                Behavior on color { ColorAnimation { duration: 120 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 6

                                    Image {
                                        source: entry && entry.icon ? entry.icon : ""
                                        Layout.preferredWidth: source.toString() !== "" ? 16 : 0
                                        Layout.preferredHeight: 16
                                        fillMode: Image.PreserveAspectFit
                                        visible: source.toString() !== ""
                                        smooth: true
                                    }

                                    QsText {
                                        Layout.fillWidth: true
                                        text: entry && entry.text ? entry.text.replace(/&/g, "") : ""
                                        font.family: Vars.fontFamily
                                        font.pixelSize: 13
                                        setWeight: Font.Medium
                                        color: entry && entry.enabled !== false ? Theme.on_surface : Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.4)
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: entryMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: entry && entry.enabled !== false
                                    cursorShape: entry && entry.enabled !== false ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (!entry || entry.enabled === false) return;
                                        if (typeof entry.triggered === "function") {
                                            entry.triggered();
                                        } else if (typeof entry.trigger === "function") {
                                            entry.trigger();
                                        }
                                        root.activeTrayMenu = null;
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
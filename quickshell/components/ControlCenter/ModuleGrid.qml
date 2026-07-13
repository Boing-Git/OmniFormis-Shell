import QtQuick
import QtQuick.Layouts
import Quickshell
import QtCore
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Hyprland
import "../../Variables/variables.js" as Vars
import "../.."

ColumnLayout {
    id: moduleGridRoot
    
    property bool isEditorMode: false
    property int activeMaxRow: 4
    property real baseCellWidth: (width - (12 * 3)) / 4
    signal subMenuRequested(string menuName)
    signal openColorSchemeRequested()
    signal openSettingsRequested()
    signal openWallpaperRequested()
    signal openOverviewRequested()
    
    // External states for some modules
    property var audioNode: Pipewire.defaultAudioSink
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

    property var adapter: Bluetooth.defaultAdapter
    property bool adapterState: adapter ? adapter.enabled : false
    property var connectDevice: adapter ? adapter.devices.values.find(d => d.connected) : null

    readonly property string bluetoothIcon: {
        if (!adapterState) return "\ue1a9"; 
        if (!connectDevice) return "\ue1a7"; 
        return "\ue1a8"; 
    }

    ListModel { id: activeTiles }
    ListModel { id: availableTiles }

    Settings {
        id: layoutSettings
        category: "ControlCenterLayout"
        property string activeLayout: "[]"
        property string availableLayout: "[]"
        
        Component.onCompleted: {
            loadLayout()
        }
    }

    function getDefaultColSpan(moduleId) {
        return (moduleId === "wifi" || moduleId === "bluetooth" || moduleId === "display" || moduleId === "color" || moduleId === "wallpaper" || moduleId === "overview") ? 2 : 1;
    }

    function saveLayout() {
        let maxRow = 0;
        let activeArr = [];
        for (let i = 0; i < activeTiles.count; i++) {
            let item = activeTiles.get(i);
            if (item.yIndex > maxRow) maxRow = item.yIndex;
            activeArr.push({
                "moduleId": item.moduleId,
                "colSpan": item.colSpan !== undefined ? item.colSpan : moduleGridRoot.getDefaultColSpan(item.moduleId),
                "xIndex": item.xIndex !== undefined ? item.xIndex : 0,
                "yIndex": item.yIndex !== undefined ? item.yIndex : 0
            });
        }
        moduleGridRoot.activeMaxRow = maxRow + 1;
        layoutSettings.activeLayout = JSON.stringify(activeArr);

        let availArr = [];
        for (let i = 0; i < availableTiles.count; i++) {
            availArr.push({ "moduleId": availableTiles.get(i).moduleId, "colSpan": 1 });
        }
        layoutSettings.availableLayout = JSON.stringify(availArr);
    }

    function findEmptySlot(colSpan) {
        let occupied = {};
        for (let i = 0; i < activeTiles.count; i++) {
            let item = activeTiles.get(i);
            if (item.xIndex === -1) continue;
            occupied[item.xIndex + "," + item.yIndex] = true;
            if (item.colSpan === 2) occupied[(item.xIndex + 1) + "," + item.yIndex] = true;
        }
        
        for (let y = 0; y < 4; y++) {
            for (let x = 0; x < (colSpan === 2 ? 3 : 4); x++) {
                if (!occupied[x + "," + y] && (colSpan === 1 || !occupied[(x + 1) + "," + y])) {
                    return { x: x, y: y };
                }
            }
        }
        return { x: 0, y: 0 };
    }

    function moveModule(moduleId, targetX, targetY) {
        let sourceIdx = -1;
        let sourceItem = null;
        for (let i = 0; i < activeTiles.count; i++) {
            if (activeTiles.get(i).moduleId === moduleId) {
                sourceIdx = i;
                sourceItem = activeTiles.get(i);
                break;
            }
        }
        if (sourceIdx === -1) return;

        if (sourceItem.colSpan === 2 && targetX > 2) targetX = 2;

        let oldX = sourceItem.xIndex;
        let oldY = sourceItem.yIndex;

        activeTiles.setProperty(sourceIdx, "xIndex", targetX);
        activeTiles.setProperty(sourceIdx, "yIndex", targetY);

        let displaced = [];
        for (let i = 0; i < activeTiles.count; i++) {
            if (i !== sourceIdx) {
                let item = activeTiles.get(i);
                let collides = false;
                if (item.xIndex === targetX && item.yIndex === targetY) collides = true;
                if (item.colSpan === 2 && item.xIndex + 1 === targetX && item.yIndex === targetY) collides = true;
                if (sourceItem.colSpan === 2 && targetX + 1 === item.xIndex && targetY === item.yIndex) collides = true;
                
                if (collides) {
                    displaced.push({idx: i, item: { colSpan: item.colSpan }});
                    activeTiles.setProperty(i, "xIndex", -1);
                    activeTiles.setProperty(i, "yIndex", -1);
                }
            }
        }

        for (let d of displaced) {
            let item = d.item;
            let idx = d.idx;
            
            let fitsOld = true;
            if (item.colSpan === 2 && oldX > 2) fitsOld = false;
            
            if (fitsOld) {
                let occupied = false;
                for (let j = 0; j < activeTiles.count; j++) {
                    if (j !== idx) {
                        let other = activeTiles.get(j);
                        if (other.xIndex === -1) continue;
                        
                        if (other.xIndex === oldX && other.yIndex === oldY) occupied = true;
                        if (other.colSpan === 2 && other.xIndex + 1 === oldX && other.yIndex === oldY) occupied = true;
                        if (item.colSpan === 2 && oldX + 1 === other.xIndex && oldY === other.yIndex) occupied = true;
                    }
                }
                if (!occupied) {
                    activeTiles.setProperty(idx, "xIndex", oldX);
                    activeTiles.setProperty(idx, "yIndex", oldY);
                    continue;
                }
            }
            
            let pos = findEmptySlot(item.colSpan);
            activeTiles.setProperty(idx, "xIndex", pos.x);
            activeTiles.setProperty(idx, "yIndex", pos.y);
        }

        saveLayout();
    }

    function resizeModule(moduleId, targetColSpan) {
        let idx = -1;
        let item = null;
        for (let i = 0; i < activeTiles.count; i++) {
            if (activeTiles.get(i).moduleId === moduleId) {
                idx = i;
                item = activeTiles.get(i);
                break;
            }
        }
        if (idx === -1) return;
        
        if (targetColSpan === 2 && item.xIndex === 3) return;
        
        activeTiles.setProperty(idx, "colSpan", targetColSpan);
        
        if (targetColSpan === 2) {
            let displaced = [];
            for (let i = 0; i < activeTiles.count; i++) {
                if (i !== idx) {
                    let other = activeTiles.get(i);
                    if (other.xIndex === item.xIndex + 1 && other.yIndex === item.yIndex) displaced.push(i);
                    else if (other.colSpan === 2 && other.xIndex + 1 === item.xIndex + 1 && other.yIndex === item.yIndex) displaced.push(i);
                }
            }
            
            for (let i of displaced) {
                let otherColSpan = activeTiles.get(i).colSpan;
                activeTiles.setProperty(i, "xIndex", -1);
                activeTiles.setProperty(i, "yIndex", -1);
                let pos = findEmptySlot(otherColSpan);
                activeTiles.setProperty(i, "xIndex", pos.x);
                activeTiles.setProperty(i, "yIndex", pos.y);
            }
        }
        saveLayout();
    }

    function activateModule(moduleId, targetX, targetY) {
        if (targetX === undefined) targetX = -1;
        if (targetY === undefined) targetY = -1;
        for (let i = 0; i < availableTiles.count; i++) {
            if (availableTiles.get(i).moduleId === moduleId) {
                let colSpan = moduleGridRoot.getDefaultColSpan(moduleId);
                let pos = { x: targetX, y: targetY };
                if (targetX === -1) {
                    pos = findEmptySlot(colSpan);
                }
                
                let payload = { "moduleId": availableTiles.get(i).moduleId, "colSpan": colSpan, "xIndex": pos.x, "yIndex": pos.y };
                availableTiles.remove(i);
                activeTiles.append(payload);
                saveLayout();
                return;
            }
        }
    }

    function deactivateModule(moduleId) {
        for (let i = 0; i < activeTiles.count; i++) {
            if (activeTiles.get(i).moduleId === moduleId) {
                let payload = { "moduleId": activeTiles.get(i).moduleId, "colSpan": 1 };
                activeTiles.remove(i);
                availableTiles.append(payload);
                saveLayout();
                return;
            }
        }
    }

    function loadLayout() {
        let defaultActive = [
            {"moduleId": "wifi", "colSpan": 2, "xIndex": 0, "yIndex": 0},
            {"moduleId": "bluetooth", "colSpan": 2, "xIndex": 2, "yIndex": 0},
            {"moduleId": "audio", "colSpan": 1, "xIndex": 0, "yIndex": 1},
            {"moduleId": "display", "colSpan": 2, "xIndex": 1, "yIndex": 1}
        ];
        let defaultAvailable = [
            {"moduleId": "peace", "colSpan": 1},
            {"moduleId": "color", "colSpan": 1},
            {"moduleId": "wallpaper", "colSpan": 1},
            {"moduleId": "overview", "colSpan": 1}
        ];
        
        activeTiles.clear();
        availableTiles.clear();

        let seen = {};

        try {
            let activeArr = JSON.parse(layoutSettings.activeLayout);
            if (!activeArr || activeArr.length === 0) activeArr = defaultActive;
            for (let i = 0; i < activeArr.length; i++) {
                if (!seen[activeArr[i].moduleId]) {
                    seen[activeArr[i].moduleId] = true;
                    if (activeArr[i].colSpan === undefined) activeArr[i].colSpan = moduleGridRoot.getDefaultColSpan(activeArr[i].moduleId);
                    if (activeArr[i].xIndex === undefined) {
                        activeArr[i].xIndex = i % 4;
                        activeArr[i].yIndex = Math.floor(i / 4);
                    }
                    activeTiles.append(activeArr[i]);
                }
            }
        } catch(e) {
            for (let i = 0; i < defaultActive.length; i++) {
                if (!seen[defaultActive[i].moduleId]) {
                    seen[defaultActive[i].moduleId] = true;
                    activeTiles.append(defaultActive[i]);
                }
            }
        }
        
        try {
            let availArr = JSON.parse(layoutSettings.availableLayout);
            if (!availArr || availArr.length === 0) availArr = defaultAvailable;
            for (let i = 0; i < availArr.length; i++) {
                if (!seen[availArr[i].moduleId]) {
                    seen[availArr[i].moduleId] = true;
                    availableTiles.append(availArr[i]);
                }
            }
        } catch(e) {
            for (let i = 0; i < defaultAvailable.length; i++) {
                if (!seen[defaultAvailable[i].moduleId]) {
                    seen[defaultAvailable[i].moduleId] = true;
                    availableTiles.append(defaultAvailable[i]);
                }
            }
        }
        
        // Ensure all valid modules exist somewhere (self-healing)
        let allModules = [...defaultActive, ...defaultAvailable];
        for (let i = 0; i < allModules.length; i++) {
            if (!seen[allModules[i].moduleId]) {
                seen[allModules[i].moduleId] = true;
                availableTiles.append(allModules[i]);
            }
        }
        
        saveLayout();
    }

    // ==========================================
    // DELEGATE MODELS FOR DRAG AND DROP
    // ==========================================
    DelegateModel {
        id: activeVisualModel
        model: activeTiles
        delegate: Item {
            id: activeDelegateWrapper
            
            property int colSpan: model.colSpan !== undefined ? model.colSpan : 1
            property int xIndex: model.xIndex !== undefined ? model.xIndex : 0
            property int yIndex: model.yIndex !== undefined ? model.yIndex : 0
            
            width: colSpan === 2 ? (moduleGridRoot.baseCellWidth * 2) + 12 : moduleGridRoot.baseCellWidth
            height: 64
            
            x: xIndex * (moduleGridRoot.baseCellWidth + 12)
            y: yIndex * (64 + 12)
            
            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            
            z: dragArea.drag.active ? 100 : 1

            property int visualIndex: DelegateModel.itemsIndex
            property string dragMode: "active_module"
            property string moduleId: model.moduleId
            property var gridRoot: moduleGridRoot

            Rectangle {
                id: tileDelegate
                property int visualIndex: DelegateModel.itemsIndex

                x: 0
                y: 0
                width: activeDelegateWrapper.width
                height: activeDelegateWrapper.height
                radius: isActive ? 16 : height / 2
                color: dragArea.drag.active ? Theme.surface_container_highest : (isActive ? Theme.primary : Theme.surface_container_high)
                scale: dragArea.drag.active ? 1.05 : 1.0
                
                Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }
                
                border.color: moduleGridRoot.isEditorMode ? Theme.outline_variant : "transparent"
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 250 } }
                
                property string moduleId: model.moduleId
                
                property bool isActive: (moduleId === "wifi" ? Networking.wifiEnabled : false) || 
                                        (moduleId === "bluetooth" ? moduleGridRoot.adapterState : false) || 
                                        (moduleId === "audio" ? (moduleGridRoot.audioNode && !moduleGridRoot.audioNode.audio.muted) : false) || 
                                        (moduleId === "display" ? false : false) ||
                                        (moduleId === "peace" ? NotificationService.peaceMode : false)
                                        
                property bool hasSubMenu: moduleId === "wifi" || moduleId === "bluetooth" || moduleId === "display" || moduleId === "color" || moduleId === "wallpaper" || moduleId === "overview"
                                        
                property string mIcon: moduleId === "wifi" ? moduleGridRoot.wifiIcon :
                                       moduleId === "bluetooth" ? moduleGridRoot.bluetoothIcon :
                                       moduleId === "audio" ? (moduleGridRoot.audioNode && moduleGridRoot.audioNode.audio.muted ? "\ue04f" : "\ue050") :
                                       moduleId === "display" ? "\ue30d" :
                                       moduleId === "peace" ? "\ue15c" :
                                       moduleId === "color" ? "palette" :
                                       moduleId === "wallpaper" ? "wallpaper" :
                                       moduleId === "overview" ? "grid_view" : ""
                                       
                property string mTitle: moduleId === "wifi" ? "Wi-Fi" :
                                        moduleId === "bluetooth" ? "Bluetooth" :
                                        moduleId === "audio" ? "Audio" :
                                        moduleId === "display" ? "Display" :
                                        moduleId === "peace" ? "Peace" :
                                        moduleId === "color" ? "Colors" :
                                        moduleId === "wallpaper" ? "Wallpaper" :
                                        moduleId === "overview" ? "Overview" : ""
                                        
                function getExpandedSubtitle() {
                    switch(moduleId) {
                        case "wifi": 
                            return moduleGridRoot.activeNet ? moduleGridRoot.activeNet.name : "Not Connected";
                        case "bluetooth": 
                            return moduleGridRoot.connectDevice ? moduleGridRoot.connectDevice.name : (moduleGridRoot.adapterState ? "On" : "Available");
                        case "audio": 
                            return moduleGridRoot.audioNode && moduleGridRoot.audioNode.audio.muted ? "Muted" : "Active";
                        case "display": 
                            return "Default";
                        case "peace":
                            return isActive ? "Active" : "Inactive";
                        case "color":
                            return "Change Theme";
                        case "wallpaper":
                            return "Switcher";
                        case "overview":
                            return "Workspaces";
                        default: 
                            return "";
                    }
                }
                                          
                function doAction() {
                    if (moduleId === "wifi") activeDelegateWrapper.gridRoot.subMenuRequested("wifi");
                    else if (moduleId === "bluetooth") activeDelegateWrapper.gridRoot.subMenuRequested("bluetooth");
                    else if (moduleId === "display") activeDelegateWrapper.gridRoot.subMenuRequested("display");
                    else if (moduleId === "color") activeDelegateWrapper.gridRoot.openColorSchemeRequested()
                    else if (moduleId === "wallpaper") activeDelegateWrapper.gridRoot.openWallpaperRequested()
                    else if (moduleId === "overview") activeDelegateWrapper.gridRoot.openOverviewRequested()
                    else doToggle();
                }
                
                function doToggle() {
                    if (moduleId === "wifi") Networking.wifiEnabled = !Networking.wifiEnabled;
                    else if (moduleId === "bluetooth") { if (activeDelegateWrapper.gridRoot.adapter) activeDelegateWrapper.gridRoot.adapter.enabled = !activeDelegateWrapper.gridRoot.adapter.enabled }
                    else if (moduleId === "audio") { if (activeDelegateWrapper.gridRoot.audioNode) activeDelegateWrapper.gridRoot.audioNode.audio.muted = !activeDelegateWrapper.gridRoot.audioNode.audio.muted }
                    else if (moduleId === "peace") NotificationService.peaceMode = !NotificationService.peaceMode;
                    else doAction();
                }

                // --- INSERT YOUR WORKING MODULE UI HERE ---
                Item {
                    id: contentWrapper
                    anchors.fill: parent
                    anchors.margins: 12
                    clip: true
                    
                    // ColSpan 1 UI (Centered Icon)
                    Item {
                        anchors.fill: parent
                        visible: activeDelegateWrapper.colSpan === 1
                        
                        Text {
                            anchors.centerIn: parent
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 24
                            color: tileDelegate.isActive ? Theme.on_primary : Theme.on_surface_variant
                            Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }
                            text: tileDelegate.mIcon
                        }
                    }

                    // The Expanded UI (Left-Aligned List Item)
                    Item {
                        id: expandedUI
                        anchors.fill: parent
                        visible: activeDelegateWrapper.colSpan === 2
                        
                        RowLayout {
                            anchors.fill: parent
                            spacing: 16
                            
                            // Static Icon Container
                            Item {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                Layout.alignment: Qt.AlignVCenter
                                
                                Text {
                                    anchors.centerIn: parent
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 24
                                    color: tileDelegate.isActive ? Theme.on_primary : Theme.on_surface_variant
                                    Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                    text: tileDelegate.mIcon
                                }
                            }
                            
                            // Morphing Text Column
                            ColumnLayout {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.fillWidth: true
                                
                                Text {
                                    Layout.alignment: Qt.AlignLeft
                                    horizontalAlignment: Text.AlignLeft
                                    text: tileDelegate.mTitle
                                    font.family: Vars.fontFamily
                                    font.pixelSize: 16
                                    font.weight: 600
                                    color: tileDelegate.isActive ? Theme.on_primary : Theme.on_surface_variant
                                    Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                
                                Text {
                                    Layout.alignment: Qt.AlignLeft
                                    horizontalAlignment: Text.AlignLeft
                                    color: tileDelegate.isActive ? Theme.on_primary : Theme.on_surface_variant
                                    Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                    font.family: Vars.fontFamily
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    
                                    text: tileDelegate.getExpandedSubtitle()
                                }
                            }
                        }
                    }
                    
                    MouseArea { 
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; 
                        onClicked: { if (!activeDelegateWrapper.gridRoot.isEditorMode) tileDelegate.doToggle() } 
                    }

                    // Sub-menu Chevron
                    Rectangle {
                        visible: tileDelegate.hasSubMenu && activeDelegateWrapper.colSpan === 2
                        width: 32
                        height: 32
                        radius: 16
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        color: "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            font.family: "Material Symbols Outlined"; font.pixelSize: 24
                            color: tileDelegate.isActive ? Theme.on_primary : Theme.on_surface_variant
                            Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }
                            text: "chevron_right"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!activeDelegateWrapper.gridRoot.isEditorMode) tileDelegate.doAction()
                            }
                        }
                    }
                }
                // --- END WORKING MODULE UI ---

                // ---- EDITOR OVERLAY ----
                Item {
                    anchors.fill: parent
                    opacity: moduleGridRoot.isEditorMode ? 1.0 : 0.0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    // Overlay to show edit mode is active, slightly dimming the content
                    Rectangle {
                        anchors.fill: parent; radius: 16
                        color: dragArea.drag.active ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.0) : (dragArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : Qt.rgba(0, 0, 0, 0.1))
                        Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3EmphasizedDecelerate } }
                    }

                    // Full Card Drag Handle
                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        cursorShape: Qt.OpenHandCursor
                        
                        drag.target: tileDelegate

                        onReleased: {
                            cursorShape = Qt.OpenHandCursor;
                            tileDelegate.Drag.drop();
                            tileDelegate.x = 0;
                            tileDelegate.y = 0;
                            activeDelegateWrapper.gridRoot.saveLayout();
                        }
                    }
                    // Top-Left Remove Button (-)
                    Rectangle {
                        width: 24; height: 24; radius: 12
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.topMargin: -4
                        anchors.leftMargin: -4
                        color: Theme.error
                        
                        
                        Text { 
                            anchors.centerIn: parent
                            text: "remove"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: Theme.on_error 
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: activeDelegateWrapper.gridRoot.deactivateModule(tileDelegate.moduleId)
                        }
                    }

                    // Resize Pill Handle (Right Edge)
                    Rectangle {
                        width: 4
                        height: 32
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        color: Theme.on_surface_variant
                        
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8 // increase hit area
                            cursorShape: Qt.SizeHorCursor
                            preventStealing: true
                            
                            property real startRootX: 0
                            
                            onPressed: (mouse) => { 
                                let pt = mapToItem(activeGrid, mouse.x, mouse.y);
                                startRootX = pt.x; 
                            }
                            onPositionChanged: (mouse) => {
                                let pt = mapToItem(activeGrid, mouse.x, mouse.y);
                                let deltaX = pt.x - startRootX;
                                if (deltaX > 20 && activeDelegateWrapper.colSpan === 1) {
                                    activeDelegateWrapper.gridRoot.resizeModule(activeDelegateWrapper.moduleId, 2);
                                    startRootX = pt.x;
                                } else if (deltaX < -20 && activeDelegateWrapper.colSpan === 2) {
                                    activeDelegateWrapper.gridRoot.resizeModule(activeDelegateWrapper.moduleId, 1);
                                    startRootX = pt.x;
                                }
                            }
                        }
                    }
                }


                
                Drag.active: dragArea.drag.active
                Drag.source: activeDelegateWrapper
                z: dragArea.drag.active ? 100 : 1
                Drag.keys: ["m3_module"]
            }
        }
    }

    // ==========================================
    // VISUAL GRIDS
    // ==========================================
    
    // Background 4x4 coordinate grid
    Item {
        id: activeGrid
        Layout.fillWidth: true
        
        property int displayRows: moduleGridRoot.isEditorMode ? 4 : Math.max(1, moduleGridRoot.activeMaxRow)
        Layout.preferredHeight: (64 * displayRows) + (12 * Math.max(0, displayRows - 1))
        
        Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        
        GridLayout {
            anchors.fill: parent
            columns: 4
            rows: 4
            columnSpacing: 12
            rowSpacing: 12
            
            Repeater {
                model: 16
                DropArea {
                    id: cellDrop
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    keys: ["m3_module"]
                    
                    property int xIndex: index % 4
                    property int yIndex: Math.floor(index / 4)

                    Rectangle {
                        anchors.fill: parent
                        color: moduleGridRoot.isEditorMode ? Theme.surface_variant : "transparent"
                        opacity: moduleGridRoot.isEditorMode ? 0.3 : 0
                        radius: 16
                        border.color: cellDrop.containsDrag ? Theme.primary : "transparent"
                        border.width: 2
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }

                    onDropped: (drag) => {
                        if (drag.source.dragMode === "active_module") {
                            moduleGridRoot.moveModule(drag.source.moduleId, xIndex, yIndex);
                        } else if (drag.source.dragMode === "available_module") {
                            moduleGridRoot.activateModule(drag.source.moduleId, xIndex, yIndex);
                        }
                        drag.accept();
                    }
                }
            }
        }
        
        Repeater {
            model: activeVisualModel
        }
    }

    ModuleStore {
        isEditorMode: moduleGridRoot.isEditorMode
        moduleGridRoot: moduleGridRoot
        availableTiles: availableTiles
        baseCellWidth: moduleGridRoot.baseCellWidth
    }
}

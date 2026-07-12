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
    id: moduleGrid
    
    property bool isEditorMode: false
    property real baseCellWidth: (width / 4) - 12
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

    function saveLayout() {
        let activeArr = [];
        for (let i = 0; i < activeTiles.count; i++) {
            activeArr.push({ "moduleId": activeTiles.get(i).moduleId, "expanded": activeTiles.get(i).expanded });
        }
        layoutSettings.activeLayout = JSON.stringify(activeArr);

        let availArr = [];
        for (let i = 0; i < availableTiles.count; i++) {
            availArr.push({ "moduleId": availableTiles.get(i).moduleId, "expanded": availableTiles.get(i).expanded });
        }
        layoutSettings.availableLayout = JSON.stringify(availArr);
    }

    function loadLayout() {
        let defaultActive = [
            {"moduleId": "wifi", "expanded": false},
            {"moduleId": "bluetooth", "expanded": false},
            {"moduleId": "audio", "expanded": false},
            {"moduleId": "display", "expanded": false}
        ];
        let defaultAvailable = [
            {"moduleId": "peace", "expanded": false},
            {"moduleId": "color", "expanded": false},
            {"moduleId": "wallpaper", "expanded": false},
            {"moduleId": "overview", "expanded": false}
        ];
        
        activeTiles.clear();
        availableTiles.clear();

        try {
            let activeArr = JSON.parse(layoutSettings.activeLayout);
            if (!activeArr || activeArr.length === 0) activeArr = defaultActive;
            for (let i = 0; i < activeArr.length; i++) {
                activeTiles.append(activeArr[i]);
            }
        } catch(e) {
            for (let i = 0; i < defaultActive.length; i++) activeTiles.append(defaultActive[i]);
        }
        
        try {
            let availArr = JSON.parse(layoutSettings.availableLayout);
            if (!availArr || availArr.length === 0) availArr = defaultAvailable;
            for (let i = 0; i < availArr.length; i++) {
                availableTiles.append(availArr[i]);
            }
        } catch(e) {
            for (let i = 0; i < defaultAvailable.length; i++) availableTiles.append(defaultAvailable[i]);
        }
    }

    // ==========================================
    // DELEGATE MODELS FOR DRAG AND DROP
    // ==========================================
    DelegateModel {
        id: activeVisualModel
        model: activeTiles
        delegate: DropArea {
            id: activeDropArea
            
            property bool isExpanded: model.expanded !== undefined ? model.expanded : false
            
            width: isExpanded ? (moduleGrid.baseCellWidth * 2) + 12 : moduleGrid.baseCellWidth
            height: 64
            keys: ["active_module", "available_module"]
            
            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            
            z: dragArea.drag.active ? 100 : 1

            property int visualIndex: DelegateModel.itemsIndex
            property string dragMode: "active_module"

            onEntered: function(drag) {
                if (!moduleGrid.isEditorMode) return;
                if (!drag.source) return;
                
                // WARNING: If using a custom C++ QAbstractListModel or external JS array, 
                // ensure items.move() splices the array properly and does not duplicate entries.
                let from = drag.source.visualIndex;
                let to = activeDropArea.visualIndex;
                
                if (from !== undefined && to !== undefined && from !== to && drag.source !== activeDropArea) {
                    activeVisualModel.items.move(from, to);
                    drag.source.visualIndex = to; // Anti-thrashing guard
                }
            }
            onDropped: function(drag) {
                if (drag.source.dragMode === "available_module") {
                    let from = drag.source.sourceIndex; // from availableTiles
                    if (from >= 0 && from < availableTiles.count) {
                        let mIdVal = availableTiles.get(from).moduleId;
                        availableTiles.remove(from, 1);
                        activeTiles.insert(activeDropArea.visualIndex, { "moduleId": mIdVal, "expanded": false });
                        moduleGrid.saveLayout();
                    }
                } else {
                    moduleGrid.saveLayout();
                }
            }

            Rectangle {
                id: tileDelegate
                property int visualIndex: DelegateModel.itemsIndex

                x: 0
                y: 0
                width: activeDropArea.width
                height: activeDropArea.height
                radius: 16
                color: dragArea.drag.active ? Theme.surface_container_highest : (isActive ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25) : Theme.surface_container)
                scale: dragArea.drag.active ? 1.05 : 1.0
                
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }
                
                property string mId: model.moduleId
                
                property bool isActive: (mId === "wifi" ? Networking.wifiEnabled : false) || 
                                        (mId === "bluetooth" ? moduleGrid.adapterState : false) || 
                                        (mId === "audio" ? (moduleGrid.audioNode && !moduleGrid.audioNode.audio.muted) : false) || 
                                        (mId === "display" ? false : false) ||
                                        (mId === "peace" ? NotificationService.peaceMode : false)
                                        
                property string mIcon: mId === "wifi" ? moduleGrid.wifiIcon :
                                       mId === "bluetooth" ? moduleGrid.bluetoothIcon :
                                       mId === "audio" ? (moduleGrid.audioNode && moduleGrid.audioNode.audio.muted ? "\ue04f" : "\ue050") :
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
                                        
                property string mSubtext: mId === "wifi" ? (moduleGrid.activeNet ? moduleGrid.activeNet.name : "Off") :
                                          mId === "bluetooth" ? (moduleGrid.connectDevice ? moduleGrid.connectDevice.name : (moduleGrid.adapterState ? "On" : "Off")) :
                                          mId === "audio" ? (moduleGrid.audioNode && moduleGrid.audioNode.audio.muted ? "Muted" : "Active") :
                                          mId === "display" ? "Default" :
                                          mId === "peace" ? (isActive ? "Active" : "Inactive") :
                                          mId === "color" ? "Change Theme" :
                                          mId === "wallpaper" ? "Switcher" :
                                          mId === "overview" ? "Workspaces" : ""
                                          
                function doAction() {
                    if (mId === "wifi") moduleGrid.subMenuRequested("wifi");
                    else if (mId === "bluetooth") moduleGrid.subMenuRequested("bluetooth");
                    else if (mId === "display") moduleGrid.subMenuRequested("display");
                    else if (mId === "color") moduleGrid.openColorSchemeRequested()
                    else if (mId === "wallpaper") moduleGrid.openWallpaperRequested()
                    else if (mId === "overview") moduleGrid.openOverviewRequested()
                    else doToggle();
                }
                
                function doToggle() {
                    if (mId === "wifi") Networking.wifiEnabled = !Networking.wifiEnabled;
                    else if (mId === "bluetooth") { if (moduleGrid.adapter) moduleGrid.adapter.enabled = !moduleGrid.adapter.enabled }
                    else if (mId === "audio") { if (moduleGrid.audioNode) moduleGrid.audioNode.audio.muted = !moduleGrid.audioNode.audio.muted }
                    else if (mId === "peace") NotificationService.peaceMode = !NotificationService.peaceMode;
                    else doAction();
                }

                // --- INSERT YOUR WORKING MODULE UI HERE ---
                Item {
                    anchors.fill: parent
                    clip: true
                    
                    Text { 
                        anchors.centerIn: parent
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 24
                        color: tileDelegate.isActive ? Theme.primary : Theme.on_surface_variant
                        text: tileDelegate.mIcon
                    }
                    MouseArea { 
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; 
                        onClicked: { if (!moduleGrid.isEditorMode) tileDelegate.doAction() } 
                    }
                }
                // --- END WORKING MODULE UI ---

                // ---- EDITOR OVERLAY ----
                Item {
                    anchors.fill: parent
                    opacity: moduleGrid.isEditorMode ? 1.0 : 0.0
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

                        onPressed: {
                            cursorShape = Qt.ClosedHandCursor;
                        }
                        onReleased: {
                            cursorShape = Qt.OpenHandCursor;
                            tileDelegate.Drag.drop();
                            tileDelegate.x = 0;
                            tileDelegate.y = 0;
                            moduleGrid.saveLayout();
                        }
                    }

                    // Top-Left Drag Indicator Badge
                    Text {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 12
                        font.family: "Material Symbols Outlined"; font.pixelSize: 20
                        color: Theme.on_surface_variant
                        text: "drag_indicator"
                    }
                    
                    // Expand/Collapse Chevron Pill (Right Edge)
                    Rectangle {
                        width: 12
                        height: 48
                        radius: 6
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: -6
                        color: Theme.secondary_container
                        
                        Text {
                            anchors.centerIn: parent
                            font.family: "Material Symbols Outlined"; font.pixelSize: 12
                            color: Theme.on_secondary_container
                            text: activeDropArea.isExpanded ? "expand_less" : "expand_more"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                model.expanded = !model.expanded
                                moduleGrid.saveLayout()
                            }
                        }
                    }
                }


                
                Drag.active: dragArea.drag.active
                Drag.source: activeDropArea
                Drag.keys: ["active_module"]
            }
        }
    }

    DelegateModel {
        id: availableVisualModel
        model: availableTiles
        delegate: DropArea {
            id: availableDropArea
            width: moduleGrid.baseCellWidth
            height: 64
            keys: ["available_module", "active_module"]
            
            z: availDragArea.drag.active ? 100 : 1
            
            property int visualIndex: DelegateModel.itemsIndex
            property string dragMode: "available_module"
            
            // To pass the index easily on drop from available to active:
            property int sourceIndex: model.index

            onEntered: function(drag) {
                if (!moduleGrid.isEditorMode) return;
                if (!drag.source) return;
                
                let from = drag.source.visualIndex;
                let to = availableDropArea.visualIndex;
                
                if (from !== undefined && to !== undefined && from !== to && drag.source !== availableDropArea) {
                    availableVisualModel.items.move(from, to);
                    drag.source.visualIndex = to; // Anti-thrashing guard
                }
            }
            onDropped: function(drag) {
                if (drag.source.dragMode === "active_module") {
                    let from = drag.source.visualIndex;
                    if (from >= 0 && from < activeTiles.count) {
                        let mIdVal = activeTiles.get(from).moduleId;
                        activeTiles.remove(from, 1);
                        availableTiles.insert(availableDropArea.visualIndex, { "moduleId": mIdVal, "expanded": false });
                        moduleGrid.saveLayout();
                    }
                } else {
                    moduleGrid.saveLayout();
                }
            }

            Rectangle {
                id: availDelegate
                property int visualIndex: DelegateModel.itemsIndex

                x: 0
                y: 0
                width: availableDropArea.width
                height: availableDropArea.height
                radius: 16
                
                color: availDragArea.drag.active ? Theme.surface_container_highest : Theme.surface_container
                scale: availDragArea.drag.active ? 1.05 : 1.0
                
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }

                property string mId: model.moduleId
                property string mIcon: mId === "wifi" ? moduleGrid.wifiIcon : mId === "bluetooth" ? moduleGrid.bluetoothIcon : mId === "audio" ? "\ue050" : mId === "display" ? "\ue30d" : mId === "peace" ? "\ue15c" : mId === "color" ? "palette" : mId === "wallpaper" ? "wallpaper" : mId === "overview" ? "grid_view" : ""

                // --- INSERT YOUR WORKING MODULE UI HERE ---
                Text {
                    anchors.centerIn: parent
                    font.family: "Material Symbols Outlined"; font.pixelSize: 24
                    color: Theme.on_surface_variant
                    text: availDelegate.mIcon
                }
                // --- END WORKING MODULE UI ---

                // ---- EDITOR OVERLAY ----
                Item {
                    anchors.fill: parent
                    opacity: moduleGrid.isEditorMode ? 1.0 : 0.0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    // Overlay to show edit mode is active, slightly dimming the content
                    Rectangle {
                        anchors.fill: parent; radius: 16
                        color: availDragArea.drag.active ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.0) : (availDragArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : Qt.rgba(0, 0, 0, 0.1))
                        Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3EmphasizedDecelerate } }
                    }

                    // Full Card Drag Handle
                    MouseArea {
                        id: availDragArea
                        anchors.fill: parent
                        cursorShape: Qt.OpenHandCursor
                        
                        drag.target: availDelegate

                        onPressed: {
                            cursorShape = Qt.ClosedHandCursor;
                        }
                        onReleased: {
                            cursorShape = Qt.OpenHandCursor;
                            availDelegate.Drag.drop();
                            availDelegate.x = 0;
                            availDelegate.y = 0;
                            moduleGrid.saveLayout();
                        }
                    }

                    // Top-Left Drag Indicator Badge
                    Text {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 12
                        font.family: "Material Symbols Outlined"; font.pixelSize: 20
                        color: Theme.on_surface_variant
                        text: "drag_indicator"
                    }
                }
                

                Drag.active: availDragArea.drag.active
                Drag.source: availableDropArea
                Drag.keys: ["available_module"]
            }
        }
    }

    // ==========================================
    // VISUAL GRIDS
    // ==========================================
    
    // Background drop area to catch active tiles dropped at the end
    DropArea {
        Layout.fillWidth: true
        Layout.preferredHeight: activeFlow.implicitHeight > 64 ? activeFlow.implicitHeight : 64
        keys: ["available_module"]
        onDropped: function(drag) {
            if (drag.source.dragMode === "available_module") {
                let from = drag.source.sourceIndex; // from availableDropArea.sourceIndex
                if (from >= 0 && from < availableTiles.count) {
                    let mIdVal = availableTiles.get(from).moduleId;
                    availableTiles.remove(from, 1);
                    activeTiles.append({ "moduleId": mIdVal, "expanded": false });
                    moduleGrid.saveLayout();
                }
            }
        }
        
        Flow {
            id: activeFlow
            anchors.fill: parent
            spacing: 12
            
            move: Transition {
                NumberAnimation { properties: "x,y"; duration: 250; easing.type: Easing.OutCubic }
            }
            
            Repeater {
                model: activeVisualModel
            }
        }
    }

    ColumnLayout {
        id: availableGridWrapper
        Layout.fillWidth: true
        visible: moduleGrid.isEditorMode
        Layout.topMargin: 16
        spacing: 12

        Text {
            text: "Available Modules"
            font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: 600; color: Theme.on_surface_variant
        }

        DropArea {
            Layout.fillWidth: true
            Layout.preferredHeight: availableFlow.implicitHeight > 64 ? availableFlow.implicitHeight : 64
            keys: ["active_module"]
            onDropped: function(drag) {
                if (drag.source.dragMode === "active_module") {
                    let from = drag.source.visualIndex;
                    if (from >= 0 && from < activeTiles.count) {
                        let mIdVal = activeTiles.get(from).moduleId;
                        activeTiles.remove(from, 1);
                        availableTiles.append({ "moduleId": mIdVal, "expanded": false });
                        moduleGrid.saveLayout();
                    }
                }
            }

            Flow {
                id: availableFlow
                anchors.fill: parent
                spacing: 12
                
                move: Transition {
                    NumberAnimation { properties: "x,y"; duration: 250; easing.type: Easing.OutCubic }
                }
                
                Repeater {
                    model: availableVisualModel
                }
            }
        }
    }
}

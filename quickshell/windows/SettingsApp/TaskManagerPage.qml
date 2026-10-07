import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../.." // For M3Shapes
import "../../theme"

Item {
    id: rootTaskManager
    
    property int currentTab: 0 // 0: Monitoring, 1: Managing
    
    property string pageTitle: "Task Manager"
    property string pageIcon: "\ue85c"
    property string pageShape: "Puffy"
    property color pageColor: Theme.primary
    property color pageOnColor: Theme.on_primary
    
    // System Monitoring State
    property string cpuUsage: "0%"
    property string gpuUsage: "0%"
    property string ramUsage: "0MB / 0MB"
    
    // Task Manager State
    property var processModel: []
    property var autostartModel: []
    property string processFilter: "cpu"
    property string searchText: ""
    onSearchTextChanged: {
        if (rootTaskManager.currentTab === 1) {
            psProc.running = true;
        }
    }
    
    onProcessFilterChanged: {
        if (currentTab === 1 && rootTaskManager.visible) psProc.running = true;
    }
    
    // M3 Shape Helper
    M3Shapes { id: m3TaskManager }
    
    onCurrentTabChanged: {
        if (rootTaskManager.visible) {
            if (currentTab === 1) {
                parseAutostart.running = true;
                psProc.running = true;
            } else {
                cpuProc.running = true;
                gpuProc.running = true;
                ramProc.running = true;
            }
        }
    }
    
    onVisibleChanged: {
        if (rootTaskManager.visible) {
            if (currentTab === 1) {
                parseAutostart.running = true;
                psProc.running = true;
            } else {
                cpuProc.running = true;
                gpuProc.running = true;
                ramProc.running = true;
            }
        }
    }
    
    // --- System Monitoring Processes ---
    Process {
        id: cpuProc
        command: ["sh", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'"]
        running: currentTab === 0 && rootTaskManager.visible
        stdout: StdioCollector {
            onStreamFinished: rootTaskManager.cpuUsage = this.text.trim() + "%"
        }
    }

    Process {
        id: gpuProc
        command: ["nvidia-smi", "--query-gpu=utilization.gpu", "--format=csv,noheader,nounits"]
        running: currentTab === 0 && rootTaskManager.visible
        stdout: StdioCollector {
            onStreamFinished: rootTaskManager.gpuUsage = this.text.trim() + "%"
        }
    }
    
    Process {
        id: ramProc
        command: ["free", "-m"]
        running: currentTab === 0 && rootTaskManager.visible
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split('\n')
                if (lines.length > 1) {
                    var memLine = lines[1].split(/\s+/)
                    if (memLine.length >= 3) {
                        var total = memLine[1]
                        var used = memLine[2]
                        rootTaskManager.ramUsage = used + "MB / " + total + "MB"
                    }
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: currentTab === 0 && rootTaskManager.visible
        repeat: true
        onTriggered: {
            cpuProc.running = true;
            gpuProc.running = true;
            ramProc.running = true;
        }
    }
    
    // --- Task Manager Processes ---
    Process {
        id: psProc
        command: ["sh", "-c", 
            rootTaskManager.processFilter === "gpu" 
                ? "nvidia-smi" 
                : "ps -axo pid,comm,%cpu,%mem --sort=-%" + rootTaskManager.processFilter + " | head -n 16"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text.trim();
                if (!text) return;
                let lines = text.split('\n');
                let procs = [];
                
                if (rootTaskManager.processFilter === "gpu") {
                    for (let i = 0; i < lines.length; i++) {
                        let line = lines[i].trim();
                        let parts = line.split(/\s+/);
                        let typeIdx = Math.max(parts.indexOf("C"), parts.indexOf("G"), parts.indexOf("C+G"));
                        if (typeIdx > 0 && parts.length > typeIdx + 2) {
                            let pid = parts[typeIdx - 1];
                            let namePath = parts[typeIdx + 1];
                            let name = namePath.split('/').pop();
                            let mem = parts[parts.length - 2];
                            procs.push({ pid: pid, name: name, cpu: "N/A", mem: mem });
                        }
                    }
                    procs.sort((a, b) => {
                        let aMem = parseInt(a.mem.replace(/[^0-9]/g, '')) || 0;
                        let bMem = parseInt(b.mem.replace(/[^0-9]/g, '')) || 0;
                        return bMem - aMem;
                    });
                    procs = procs.slice(0, 15);
                } else {
                    for (let i = 1; i < lines.length; i++) {
                        let parts = lines[i].trim().split(/\s+/);
                        if (parts.length >= 4) {
                            let mem = parts.pop();
                            let cpu = parts.pop();
                            let pid = parts.shift();
                            let comm = parts.join(" ");
                            procs.push({ pid: pid, name: comm, cpu: cpu + "%", mem: mem + "%" });
                        }
                    }
                }
                
                if (rootTaskManager.searchText !== "") {
                    let searchLower = rootTaskManager.searchText.toLowerCase();
                    // Split the search string and join with .* to create a fuzzy match regex (e.g. "ffx" -> /f.*f.*x/i)
                    let fuzzyRegex = new RegExp(searchLower.split('').join('.*'), 'i');
                    procs = procs.filter(p => fuzzyRegex.test(p.name) || p.pid.toString().includes(searchLower));
                }
                
                rootTaskManager.processModel = procs;
            }
        }
    }
    
    Timer {
        interval: 5000 // Poll processes every 5 seconds
        running: currentTab === 1 && rootTaskManager.visible
        repeat: true
        onTriggered: psProc.running = true
    }

    Process {
        id: parseAutostart
        command: ["cat", "/home/boing/Dotfiles/hypr/modules/autostart.lua"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.split('\n');
                let apps = [];
                for (let i=0; i<lines.length; i++) {
                    let line = lines[i].trim();
                    let matchEnabled = line.match(/^hl\.exec_cmd\("([^"]+)"\)/);
                    let matchDisabled = line.match(/^--\s*hl\.exec_cmd\("([^"]+)"\)/);
                    
                    if (matchEnabled) {
                        apps.push({ cmd: matchEnabled[1], enabled: true });
                    } else if (matchDisabled) {
                        apps.push({ cmd: matchDisabled[1], enabled: false });
                    }
                }
                rootTaskManager.autostartModel = apps;
            }
        }
    }
    
    // Component to kill a process
    Component {
        id: killProcessAction
        Process {
            property string pidToKill: ""
            command: ["kill", "-9", pidToKill]
            running: true
            onExited: psProc.running = true // refresh list
        }
    }
    
    // Component to toggle autostart
    Component {
        id: toggleAutostartAction
        Process {
            property string cmdToToggle: ""
            property bool enable: false
            command: ["sed", "-i", 
                      enable ? "s/^[[:space:]]*--[[:space:]]*hl.exec_cmd(\"" + cmdToToggle + "\")/    hl.exec_cmd(\"" + cmdToToggle + "\")/" 
                             : "s/^[[:space:]]*hl.exec_cmd(\"" + cmdToToggle + "\")/    -- hl.exec_cmd(\"" + cmdToToggle + "\")/",
                      "/home/boing/Dotfiles/hypr/modules/autostart.lua"]
            running: true
            onExited: parseAutostart.running = true // refresh list
        }
    }
    
    // Component to add autostart
    Component {
        id: addAutostartAction
        Process {
            property string cmdToAdd: ""
            command: ["sed", "-i", "s/^ end)/    hl.exec_cmd(\"" + cmdToAdd + "\")\\n end)/", "/home/boing/Dotfiles/hypr/modules/autostart.lua"]
            running: true
            onExited: parseAutostart.running = true // refresh list
        }
    }
    
    // Component to save (delete commented out autostart entries)
    Component {
        id: saveAutostartAction
        Process {
            command: ["sed", "-i", "/^[[:space:]]*--[[:space:]]*hl\\.exec_cmd/d", "/home/boing/Dotfiles/hypr/modules/autostart.lua"]
            running: true
            onExited: parseAutostart.running = true // refresh list
        }
    }
    
    // Component to save reordered layout
    Component {
        id: saveLayoutAction
        Process {
            property string layoutData: ""
            command: ["python3", "/home/boing/Dotfiles/quickshell/scripts/qs-autostart-save.py", layoutData]
            running: true
            onExited: parseAutostart.running = true
        }
    }
    
    // --- UI Layout ---
    ColumnLayout {
        anchors.fill: parent
        spacing: Vars.spacingLarge
        
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Vars.spacingLarge
            Layout.rightMargin: Vars.spacingLarge
            spacing: 12

            Item {
                width: 38
                height: 38

                Image {
                    anchors.fill: parent
                    sourceSize: Qt.size(width, height)
                    source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + m3TaskManager.getPath(rootTaskManager.pageShape) + "' fill='" + String(rootTaskManager.pageColor || "#3b383e").replace("#", "%23") + "'/></svg>"
                    smooth: true
                    antialiasing: true
                }

                QsText {
                    anchors.centerIn: parent
                    text: rootTaskManager.pageIcon
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: rootTaskManager.pageOnColor
                }
            }

            QsText {
                Layout.fillWidth: true
                text: rootTaskManager.pageTitle
                font.family: Vars.fontFamily
                font.pixelSize: 18
                setWeight: 600
                color: Theme.on_surface
                elide: Text.ElideRight
            }
        }

        // Tab Header Segmented Control
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            Layout.margins: Vars.spacingLarge
            Layout.bottomMargin: 0
            radius: 22
            antialiasing: true
            color: Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 18
                    antialiasing: true
                    color: rootTaskManager.currentTab === 0 ? (Vars.tColorSelected(Theme.primary)) : "transparent"
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                    QsText {
                        anchors.centerIn: parent
                        text: "System Monitoring"
                        font.family: Vars.fontFamily
                        font.pixelSize: 14
                        setWeight: Font.Medium
                        color: rootTaskManager.currentTab === 0 ? Theme.on_primary : Theme.on_surface_variant
                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: rootTaskManager.currentTab = 0 }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 18
                    antialiasing: true
                    color: rootTaskManager.currentTab === 1 ? (Vars.tColorSelected(Theme.primary)) : "transparent"
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                    QsText {
                        anchors.centerIn: parent
                        text: "Task Manager"
                        font.family: Vars.fontFamily
                        font.pixelSize: 14
                        setWeight: Font.Medium
                        color: rootTaskManager.currentTab === 1 ? Theme.on_primary : Theme.on_surface_variant
                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { rootTaskManager.currentTab = 1; parseAutostart.running = true; } }
                }
            }
        }
        
        // Tab Content
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: rootTaskManager.currentTab
            
            // Tab 0: System Monitoring
            Flickable {
                Layout.fillWidth: true; Layout.fillHeight: true
                contentHeight: monitoringLayout.implicitHeight
                clip: true; // boundsBehavior: Flickable.StopAtBounds
                interactive: true
                flickDeceleration: Vars.flickDeceleration
                maximumFlickVelocity: Vars.maximumFlickVelocity
                
                ColumnLayout {
                    id: monitoringLayout
                    width: parent.width
                    spacing: Vars.spacingMedium
                    
                    Item { Layout.preferredHeight: Vars.spacingSmall }
                    
                    QsText { text: "Resource Usage"; font.family: Vars.fontFamily; font.pixelSize: 18; setWeight: Font.Bold; color: Theme.on_surface }
                    
                    // CPU Card
                    Rectangle {
                        antialiasing: true
                        Layout.fillWidth: true; Layout.preferredHeight: 96; radius: 16; color: Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 16; spacing: 16
                            Item { 
                                width: 64; height: 64
                                Image {
                                    anchors.fill: parent; sourceSize: Qt.size(64, 64); smooth: true; antialiasing: true; mipmap: true
                                    property color bg: Theme.primary_container
                                    property string pathColor: "rgb(" + Math.round(bg.r * 255) + "," + Math.round(bg.g * 255) + "," + Math.round(bg.b * 255) + ")"
                                    property string currentPath: m3TaskManager.getPath("Pill")
                                    source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + currentPath + "' fill='" + pathColor + "'/></svg>"
                                }
                                QsText { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 32; color: Theme.on_primary_container; text: "memory" } 
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 4
                                QsText { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; text: "CPU Usage"; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; setWeight: Font.Medium }
                                QsText { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; text: rootTaskManager.cpuUsage; font.family: Vars.fontFamily; font.pixelSize: 24; color: Theme.primary; setWeight: Font.Bold }
                            }
                        }
                    }
                    
                    // GPU Card
                    Rectangle {
                        antialiasing: true
                        Layout.fillWidth: true; Layout.preferredHeight: 96; radius: 16; color: Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 16; spacing: 16
                            Item { 
                                width: 64; height: 64
                                Image {
                                    anchors.fill: parent; sourceSize: Qt.size(64, 64); smooth: true; antialiasing: true; mipmap: true
                                    property color bg: Theme.secondary_container
                                    property string pathColor: "rgb(" + Math.round(bg.r * 255) + "," + Math.round(bg.g * 255) + "," + Math.round(bg.b * 255) + ")"
                                    property string currentPath: m3TaskManager.getPath("Slanted")
                                    source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + currentPath + "' fill='" + pathColor + "'/></svg>"
                                }
                                QsText { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 32; color: Theme.on_secondary_container; text: "developer_board" } 
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 4
                                QsText { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; text: "GPU Usage"; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; setWeight: Font.Medium }
                                QsText { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; text: rootTaskManager.gpuUsage; font.family: Vars.fontFamily; font.pixelSize: 24; color: Theme.secondary; setWeight: Font.Bold }
                            }
                        }
                    }
                    
                    // RAM Card
                    Rectangle {
                        antialiasing: true
                        Layout.fillWidth: true; Layout.preferredHeight: 96; radius: 16; color: Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 16; spacing: 16
                            Item { 
                                width: 64; height: 64
                                Image {
                                    anchors.fill: parent; sourceSize: Qt.size(64, 64); smooth: true; antialiasing: true; mipmap: true
                                    property color bg: Theme.tertiary_container
                                    property string pathColor: "rgb(" + Math.round(bg.r * 255) + "," + Math.round(bg.g * 255) + "," + Math.round(bg.b * 255) + ")"
                                    property string currentPath: m3TaskManager.getPath("Clamshell")
                                    source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + currentPath + "' fill='" + pathColor + "'/></svg>"
                                }
                                QsText { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 32; color: Theme.on_tertiary_container; text: "storage" } 
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 4
                                QsText { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; text: "RAM Usage"; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; setWeight: Font.Medium }
                                QsText { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; text: rootTaskManager.ramUsage; font.family: Vars.fontFamily; font.pixelSize: 24; color: Theme.tertiary; setWeight: Font.Bold }
                            }
                        }
                    }
                    
                    Item { Layout.preferredHeight: Vars.spacingLarge }
                }
            }
            
            // Tab 1: Task Manager
            Flickable {
                Layout.fillWidth: true; Layout.fillHeight: true
                contentHeight: managingLayout.implicitHeight
                clip: true; // boundsBehavior: Flickable.StopAtBounds
                interactive: true
                flickDeceleration: Vars.flickDeceleration
                maximumFlickVelocity: Vars.maximumFlickVelocity
                
                ColumnLayout {
                    id: managingLayout
                    width: parent.width
                    spacing: Vars.spacingLarge
                    
                    Item { Layout.preferredHeight: 0 }
                    
                    // Startup Apps
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: startupLayout.implicitHeight + 40
                        color: Vars.tColor(Theme.surface_container_low, Vars.componentOpacity)
                        radius: 32
                        antialiasing: true
                        
                        ColumnLayout {
                            id: startupLayout
                            anchors.fill: parent; anchors.margins: 20
                            spacing: Vars.spacingMedium
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                QsText { text: "Startup Apps"; font.family: Vars.fontFamily; font.pixelSize: 22; setWeight: Font.Bold; color: Theme.on_surface }
                                QsText { text: "Enter the exact command to run on startup (not just the app name)"; font.family: Vars.fontFamily; font.pixelSize: 14; color: Theme.on_surface_variant }
                            }
                            
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 56
                                spacing: 2
                                
                                Rectangle {
                                    antialiasing: true
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)
                                    topLeftRadius: 28
                                    bottomLeftRadius: 28
                                    topRightRadius: 6
                                    bottomRightRadius: 6
                                    TextInput {
                                        id: newAppInput
                                        anchors.fill: parent
                                        anchors.leftMargin: 20; anchors.rightMargin: 20
                                        verticalAlignment: TextInput.AlignVCenter
                                        font.family: Vars.fontFamily
                                        font.pixelSize: 16
                                        color: Theme.on_surface
                                        clip: true
                                        selectByMouse: true
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onPressed: (mouse) => { parent.forceActiveFocus(); mouse.accepted = false; } }
                                        QsText {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "e.g., blanket or wl-paste ..."
                                            color: Theme.on_surface_variant
                                            font.family: Vars.fontFamily
                                            font.pixelSize: 16
                                            visible: !newAppInput.text && !newAppInput.activeFocus
                                        }
                                    }
                                }
                                
                                Rectangle {
                                    antialiasing: true
                                    Layout.preferredWidth: 90
                                    Layout.fillHeight: true
                                    color: Vars.tColorSelected(Theme.primary)
                                    topLeftRadius: 6
                                    bottomLeftRadius: 6
                                    topRightRadius: 6
                                    bottomRightRadius: 6
                                    
                                    scale: addHover.pressed ? 1.08 : 1.0
                                    Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }
                                    QsText {
                                        anchors.centerIn: parent
                                        text: "Add"
                                        font.family: Vars.fontFamily
                                        font.pixelSize: 16
                                        setWeight: Font.Bold
                                        color: Theme.on_primary
                                    }
                                    MouseArea {
                                        id: addHover
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (newAppInput.text.trim().length > 0) {
                                                addAutostartAction.createObject(rootTaskManager, { cmdToAdd: newAppInput.text.trim() });
                                                newAppInput.text = "";
                                            }
                                        }
                                    }
                                }
                                
                                Rectangle {
                                    antialiasing: true
                                    Layout.preferredWidth: 90
                                    Layout.fillHeight: true
                                    color: Vars.tColor(Theme.surface_variant, Vars.componentOpacity)
                                    topLeftRadius: 6
                                    bottomLeftRadius: 6
                                    topRightRadius: 28
                                    bottomRightRadius: 28
                                    
                                    scale: saveHover.pressed ? 1.08 : 1.0
                                    Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }
                                    QsText {
                                        anchors.centerIn: parent
                                        text: "Save"
                                        font.family: Vars.fontFamily
                                        font.pixelSize: 16
                                        setWeight: Font.Bold
                                        color: Theme.on_surface_variant
                                    }
                                    MouseArea {
                                        id: saveHover
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            saveAutostartAction.createObject(rootTaskManager);
                                        }
                                    }
                                }
                            }
                            
                            ListView {
                                id: autostartList
                                Layout.fillWidth: true
                                Layout.preferredHeight: contentHeight
                                interactive: false // Parent Flickable handles scrolling
                                spacing: Vars.spacingMedium
                                
                                model: DelegateModel {
                                    id: visualModel
                                    model: rootTaskManager.autostartModel
                                    
                                    delegate: MouseArea {
                                        id: dragArea
                                        width: autostartList.width
                                        height: 72
                                        property int visualIndex: DelegateModel.itemsIndex
                                        
                                        drag.target: contentRect
                                        drag.axis: Drag.YAxis
                                        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                        
                                        DropArea {
                                            anchors.fill: parent
                                            onEntered: (drag) => {
                                                visualModel.items.move(drag.source.visualIndex, dragArea.visualIndex);
                                            }
                                        }
                                        
                                        Rectangle {
                                            id: contentRect
                                            width: dragArea.width; height: dragArea.height
                                            radius: 16
                                            antialiasing: true
                                            color: modelData.enabled ? (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity))
                                            
                                            // Pop out effect when dragging
                                            scale: dragArea.drag.active ? 1.02 : 1.0
                                            z: dragArea.drag.active ? 100 : 1
                                            Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }
                                            
                                            Drag.active: dragArea.drag.active
                                            Drag.source: dragArea
                                            Drag.hotSpot.x: width / 2
                                            Drag.hotSpot.y: height / 2
                                            
                                            Drag.onActiveChanged: {
                                                if (!active) {
                                                    var arr = [];
                                                    for (var i = 0; i < visualModel.items.count; i++) {
                                                        var obj = visualModel.items.get(i).model.modelData || visualModel.items.get(i).model;
                                                        arr.push({ cmd: obj.cmd, enabled: obj.enabled });
                                                    }
                                                    var jsonStr = JSON.stringify(arr);
                                                    saveLayoutAction.createObject(rootTaskManager, { layoutData: jsonStr });
                                                }
                                            }
                                            
                                            states: [
                                                State {
                                                    when: dragArea.drag.active
                                                    ParentChange { target: contentRect; parent: autostartList }
                                                    AnchorChanges { target: contentRect; anchors.horizontalCenter: undefined; anchors.verticalCenter: undefined }
                                                }
                                            ]
                                            
                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
                                                
                                                QsText { 
                                                    text: "drag_indicator"
                                                    font.family: "Material Symbols Outlined"
                                                    font.pixelSize: 24
                                                    color: Theme.on_surface_variant
                                                    opacity: dragArea.drag.active ? 1.0 : 0.6
                                                }
                                                
                                                QsText { Layout.fillWidth: true; text: modelData.cmd; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface }
                                                
                                                Rectangle {
                                                    antialiasing: true
                                                    width: 48; height: 48; radius: 24; color: toggleHover.containsMouse ? (Vars.tColor(Theme.surface_variant, 0.4)) : "transparent"
                                                    QsText { 
                                                        anchors.centerIn: parent; 
                                                        font.family: "Material Symbols Outlined"; 
                                                        font.pixelSize: 24; 
                                                        color: modelData.enabled ? Theme.error : Theme.on_surface_variant;
                                                        text: modelData.enabled ? "close" : "undo" 
                                                    }
                                                    MouseArea {
                                                        id: toggleHover; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                                        onClicked: {
                                                            toggleAutostartAction.createObject(rootTaskManager, {
                                                                cmdToToggle: modelData.cmd,
                                                                enable: !modelData.enabled
                                                            });
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
                    
                    // Top Processes
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: processesLayout.implicitHeight + 40
                        color: Vars.tColor(Theme.surface_container_low, Vars.componentOpacity)
                        radius: 32
                        antialiasing: true
                        
                        ColumnLayout {
                            id: processesLayout
                            anchors.fill: parent; anchors.margins: 20
                            spacing: Vars.spacingMedium
                            
                            RowLayout {
                                Layout.fillWidth: true
                                QsText { text: "Top Processes"; font.family: Vars.fontFamily; font.pixelSize: 22; setWeight: Font.Bold; color: Theme.on_surface; Layout.fillWidth: true }
                                

                                
                                // Segmented Control Filter
                                Rectangle {
                                    Layout.preferredWidth: 200
                                    Layout.preferredHeight: 40
                                    radius: 20
                                    antialiasing: true
                                    color: "transparent"
                                    
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 0; spacing: 4
                                        
                                        Rectangle {
                                            antialiasing: true
                                            Layout.fillWidth: true; Layout.fillHeight: true
                                            property bool isSel: rootTaskManager.processFilter === "cpu"
                                            color: isSel ? (Vars.tColorSelected(Theme.primary)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity))
                                            topLeftRadius: 20; bottomLeftRadius: 20
                                            topRightRadius: isSel ? 20 : 4; bottomRightRadius: isSel ? 20 : 4
                                            Behavior on topRightRadius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                            Behavior on bottomRightRadius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                            Behavior on color { ColorAnimation { duration: 250 } }
                                            QsText { anchors.centerIn: parent; text: "CPU"; font.pixelSize: 13; setWeight: Font.Bold; color: parent.isSel ? Theme.on_primary : Theme.on_surface_variant; Behavior on color { ColorAnimation { duration: 250 } } }
                                            MouseArea { anchors.fill: parent; onClicked: rootTaskManager.processFilter = "cpu"; cursorShape: Qt.PointingHandCursor }
                                        }
                                        Rectangle {
                                            antialiasing: true
                                            Layout.fillWidth: true; Layout.fillHeight: true
                                            property bool isSel: rootTaskManager.processFilter === "mem"
                                            color: isSel ? (Vars.tColorSelected(Theme.primary)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity))
                                            topLeftRadius: isSel ? 20 : 4; bottomLeftRadius: isSel ? 20 : 4
                                            topRightRadius: isSel ? 20 : 4; bottomRightRadius: isSel ? 20 : 4
                                            Behavior on topLeftRadius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                            Behavior on bottomLeftRadius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                            Behavior on topRightRadius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                            Behavior on bottomRightRadius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                            Behavior on color { ColorAnimation { duration: 250 } }
                                            QsText { anchors.centerIn: parent; text: "Mem"; font.pixelSize: 13; setWeight: Font.Bold; color: parent.isSel ? Theme.on_primary : Theme.on_surface_variant; Behavior on color { ColorAnimation { duration: 250 } } }
                                            MouseArea { anchors.fill: parent; onClicked: rootTaskManager.processFilter = "mem"; cursorShape: Qt.PointingHandCursor }
                                        }
                                        Rectangle {
                                            antialiasing: true
                                            Layout.fillWidth: true; Layout.fillHeight: true
                                            property bool isSel: rootTaskManager.processFilter === "gpu"
                                            color: isSel ? (Vars.tColorSelected(Theme.primary)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity))
                                            topLeftRadius: isSel ? 20 : 4; bottomLeftRadius: isSel ? 20 : 4
                                            topRightRadius: 20; bottomRightRadius: 20
                                            Behavior on topLeftRadius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                            Behavior on bottomLeftRadius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                            Behavior on color { ColorAnimation { duration: 250 } }
                                            QsText { anchors.centerIn: parent; text: "GPU"; font.pixelSize: 13; setWeight: Font.Bold; color: parent.isSel ? Theme.on_primary : Theme.on_surface_variant; Behavior on color { ColorAnimation { duration: 250 } } }
                                            MouseArea { anchors.fill: parent; onClicked: rootTaskManager.processFilter = "gpu"; cursorShape: Qt.PointingHandCursor }
                                        }
                                    }
                                }
                            }
                            
                            Repeater {
                                model: rootTaskManager.processModel
                                delegate: Rectangle {
                                    antialiasing: true
                                    Layout.fillWidth: true; Layout.preferredHeight: 72; radius: 24; 
                                    color: Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 24; anchors.rightMargin: 24; spacing: 16
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 4
                                            QsText { text: modelData.name; font.family: Vars.fontFamily; font.pixelSize: 18; setWeight: Font.Bold; color: Theme.on_surface; elide: Text.ElideRight; Layout.fillWidth: true }
                                            QsText { 
                                                text: "PID: " + modelData.pid + " • CPU: " + modelData.cpu + " • Mem: " + modelData.mem; 
                                                font.family: Vars.fontFamily; font.pixelSize: 13; color: Theme.on_surface_variant 
                                            }
                                        }
                                        
                                        Rectangle {
                                            antialiasing: true
                                            width: 48; height: 48; radius: 24; color: killHover.containsMouse ? (Vars.tColor(Theme.error, 0.7)) : "transparent"
                                            QsText { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 24; color: killHover.containsMouse ? Theme.on_error : Theme.error; text: "close" }
                                            MouseArea {
                                                id: killHover; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                                onClicked: killProcessAction.createObject(rootTaskManager, { pidToKill: modelData.pid })
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
    }
}

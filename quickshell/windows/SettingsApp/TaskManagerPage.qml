import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../.." // For M3Shapes
import "../../theme/variables.js" as Vars

Item {
    id: rootTaskManager
    
    property int currentTab: 0 // 0: Monitoring, 1: Managing
    
    // System Monitoring State
    property string cpuUsage: "0%"
    property string gpuUsage: "0%"
    property string ramUsage: "0MB / 0MB"
    
    // Task Managing State
    property var processModel: []
    property var autostartModel: []
    property string processFilter: "mem"
    property string processSearchText: ""
    
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
    
    // --- Task Managing Processes ---
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
                
                if (rootTaskManager.processSearchText !== "") {
                    let searchLower = rootTaskManager.processSearchText.toLowerCase();
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
    
    // --- UI Layout ---
    ColumnLayout {
        anchors.fill: parent
        spacing: Vars.spacingLarge
        
        // Tab Header Segmented Control
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            Layout.margins: Vars.spacingLarge
            Layout.bottomMargin: 0
            radius: 22
            color: Theme.surface_container
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 18
                    color: rootTaskManager.currentTab === 0 ? Theme.primary : "transparent"
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                    Text {
                        anchors.centerIn: parent
                        text: "System Monitoring"
                        font.family: Vars.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: rootTaskManager.currentTab === 0 ? Theme.on_primary : Theme.on_surface_variant
                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: rootTaskManager.currentTab = 0 }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 18
                    color: rootTaskManager.currentTab === 1 ? Theme.primary : "transparent"
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                    Text {
                        anchors.centerIn: parent
                        text: "Task Managing"
                        font.family: Vars.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Medium
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
                    
                    Text { text: "Resource Usage"; font.family: Vars.fontFamily; font.pixelSize: 18; font.weight: Font.Bold; color: Theme.on_surface }
                    
                    // CPU Card
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 96; radius: 16; color: Theme.surface_container
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
                                Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 32; color: Theme.on_primary_container; text: "memory" } 
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 4
                                Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; text: "CPU Usage"; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; font.weight: Font.Medium }
                                Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; text: rootTaskManager.cpuUsage; font.family: Vars.fontFamily; font.pixelSize: 24; color: Theme.primary; font.weight: Font.Bold }
                            }
                        }
                    }
                    
                    // GPU Card
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 96; radius: 16; color: Theme.surface_container
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 16; spacing: 16
                            Item { 
                                width: 64; height: 64
                                Image {
                                    anchors.fill: parent; sourceSize: Qt.size(64, 64); smooth: true; antialiasing: true; mipmap: true
                                    property color bg: Theme.primary_container
                                    property string pathColor: "rgb(" + Math.round(bg.r * 255) + "," + Math.round(bg.g * 255) + "," + Math.round(bg.b * 255) + ")"
                                    property string currentPath: m3TaskManager.getPath("Slanted")
                                    source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + currentPath + "' fill='" + pathColor + "'/></svg>"
                                }
                                Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 32; color: Theme.on_primary_container; text: "grid_view" } 
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 4
                                Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; text: "GPU Usage"; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; font.weight: Font.Medium }
                                Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; text: rootTaskManager.gpuUsage; font.family: Vars.fontFamily; font.pixelSize: 24; color: Theme.primary; font.weight: Font.Bold }
                            }
                        }
                    }
                    
                    // RAM Card
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 96; radius: 16; color: Theme.surface_container
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 16; spacing: 16
                            Item { 
                                width: 64; height: 64
                                Image {
                                    anchors.fill: parent; sourceSize: Qt.size(64, 64); smooth: true; antialiasing: true; mipmap: true
                                    property color bg: Theme.primary_container
                                    property string pathColor: "rgb(" + Math.round(bg.r * 255) + "," + Math.round(bg.g * 255) + "," + Math.round(bg.b * 255) + ")"
                                    property string currentPath: m3TaskManager.getPath("Clamshell")
                                    source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + currentPath + "' fill='" + pathColor + "'/></svg>"
                                }
                                Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 32; color: Theme.on_primary_container; text: "data_usage" } 
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 4
                                Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; text: "RAM Usage"; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; font.weight: Font.Medium }
                                Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; text: rootTaskManager.ramUsage; font.family: Vars.fontFamily; font.pixelSize: 24; color: Theme.primary; font.weight: Font.Bold }
                            }
                        }
                    }
                    
                    Item { Layout.preferredHeight: Vars.spacingLarge }
                }
            }
            
            // Tab 1: Task Managing
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
                        color: Theme.surface_container_low
                        radius: 32
                        
                        ColumnLayout {
                            id: startupLayout
                            anchors.fill: parent; anchors.margins: 20
                            spacing: Vars.spacingMedium
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text { text: "Startup Apps"; font.family: Vars.fontFamily; font.pixelSize: 22; font.weight: Font.Bold; color: Theme.on_surface }
                                Text { text: "Enter the exact command to run on startup (not just the app name)"; font.family: Vars.fontFamily; font.pixelSize: 14; color: Theme.on_surface_variant }
                            }
                            
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 56
                                spacing: 12
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: Theme.surface_container_high
                                    radius: 28
                                    TextInput {
                                        id: newAppInput
                                        anchors.fill: parent
                                        anchors.leftMargin: 20; anchors.rightMargin: 20
                                        verticalAlignment: TextInput.AlignVCenter
                                        font.family: Vars.fontFamily
                                        font.pixelSize: 16
                                        color: Theme.on_surface
                                        clip: true
                                        Text {
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
                                    Layout.preferredWidth: 90
                                    Layout.fillHeight: true
                                    color: Theme.primary
                                    radius: 28
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Add"
                                        font.family: Vars.fontFamily
                                        font.pixelSize: 16
                                        font.weight: Font.Bold
                                        color: Theme.on_primary
                                    }
                                    MouseArea {
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
                                    Layout.preferredWidth: 90
                                    Layout.fillHeight: true
                                    color: Theme.surface_variant
                                    radius: 28
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Save"
                                        font.family: Vars.fontFamily
                                        font.pixelSize: 16
                                        font.weight: Font.Bold
                                        color: Theme.on_surface_variant
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            saveAutostartAction.createObject(rootTaskManager);
                                        }
                                    }
                                }
                            }
                            
                            Repeater {
                                model: rootTaskManager.autostartModel
                                delegate: Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 72; radius: 16; 
                                    color: modelData.enabled ? Theme.surface_container_high : Theme.surface_container
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 24; anchors.rightMargin: 24; spacing: 16
                                        Text { Layout.fillWidth: true; text: modelData.cmd; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface }
                                        
                                        Rectangle {
                                            width: 48; height: 48; radius: 24; color: toggleHover.containsMouse ? Theme.surface_variant : "transparent"
                                            Text { 
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
                    
                    // Top Processes
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: processesLayout.implicitHeight + 40
                        color: Theme.surface_container_low
                        radius: 32
                        
                        ColumnLayout {
                            id: processesLayout
                            anchors.fill: parent; anchors.margins: 20
                            spacing: Vars.spacingMedium
                            
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Top Processes"; font.family: Vars.fontFamily; font.pixelSize: 22; font.weight: Font.Bold; color: Theme.on_surface; Layout.fillWidth: true }
                                
                                // Search Bar
                                Rectangle {
                                    Layout.preferredWidth: 200
                                    Layout.preferredHeight: 40
                                    radius: 20
                                    color: Theme.surface_container_high
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16; anchors.rightMargin: 16
                                        spacing: 8
                                        Text {
                                            text: "search"
                                            font.family: "Material Symbols Outlined"
                                            font.pixelSize: 18
                                            color: procSearchInput.activeFocus ? Theme.primary : Theme.on_surface_variant
                                        }
                                        TextInput {
                                            id: procSearchInput
                                            Layout.fillWidth: true; Layout.fillHeight: true
                                            verticalAlignment: TextInput.AlignVCenter
                                            font.family: Vars.fontFamily
                                            font.pixelSize: 14
                                            color: Theme.on_surface
                                            clip: true
                                            onTextChanged: {
                                                rootTaskManager.processSearchText = text;
                                                psProc.running = true; // refresh immediately on typing
                                            }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Search..."
                                                color: Theme.on_surface_variant
                                                font.family: Vars.fontFamily
                                                font.pixelSize: 14
                                                visible: !procSearchInput.text && !procSearchInput.activeFocus
                                            }
                                        }
                                    }
                                }
                                
                                // Segmented Control Filter
                                Rectangle {
                                    Layout.preferredWidth: 200
                                    Layout.preferredHeight: 40
                                    radius: 20
                                    color: Theme.surface_container_high
                                    
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 4; spacing: 4
                                        
                                        Rectangle {
                                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 16
                                            color: rootTaskManager.processFilter === "cpu" ? Theme.primary : "transparent"
                                            Text { anchors.centerIn: parent; text: "CPU"; font.pixelSize: 13; font.weight: Font.Bold; color: rootTaskManager.processFilter === "cpu" ? Theme.on_primary : Theme.on_surface_variant }
                                            MouseArea { anchors.fill: parent; onClicked: rootTaskManager.processFilter = "cpu"; cursorShape: Qt.PointingHandCursor }
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 16
                                            color: rootTaskManager.processFilter === "mem" ? Theme.primary : "transparent"
                                            Text { anchors.centerIn: parent; text: "Mem"; font.pixelSize: 13; font.weight: Font.Bold; color: rootTaskManager.processFilter === "mem" ? Theme.on_primary : Theme.on_surface_variant }
                                            MouseArea { anchors.fill: parent; onClicked: rootTaskManager.processFilter = "mem"; cursorShape: Qt.PointingHandCursor }
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 16
                                            color: rootTaskManager.processFilter === "gpu" ? Theme.primary : "transparent"
                                            Text { anchors.centerIn: parent; text: "GPU"; font.pixelSize: 13; font.weight: Font.Bold; color: rootTaskManager.processFilter === "gpu" ? Theme.on_primary : Theme.on_surface_variant }
                                            MouseArea { anchors.fill: parent; onClicked: rootTaskManager.processFilter = "gpu"; cursorShape: Qt.PointingHandCursor }
                                        }
                                    }
                                }
                            }
                            
                            Repeater {
                                model: rootTaskManager.processModel
                                delegate: Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 72; radius: 24; 
                                    color: Theme.surface_container_high
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 24; anchors.rightMargin: 24; spacing: 16
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 4
                                            Text { text: modelData.name; font.family: Vars.fontFamily; font.pixelSize: 18; font.weight: Font.Bold; color: Theme.on_surface; elide: Text.ElideRight; Layout.fillWidth: true }
                                            Text { 
                                                text: "PID: " + modelData.pid + " • CPU: " + modelData.cpu + " • Mem: " + modelData.mem; 
                                                font.family: Vars.fontFamily; font.pixelSize: 13; color: Theme.on_surface_variant 
                                            }
                                        }
                                        
                                        Rectangle {
                                            width: 48; height: 48; radius: 24; color: killHover.containsMouse ? Theme.error : "transparent"
                                            Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 24; color: killHover.containsMouse ? Theme.on_error : Theme.error; text: "close" }
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

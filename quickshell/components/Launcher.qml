import QtQuick
import QtQuick.Effects
import ".."
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../Variables/variables.js" as Vars

Item {
    id: root
    
    // Fixed layout footprint - never animates, no parent relayout
    Layout.preferredWidth: 100
    Layout.preferredHeight: 40
    
    property bool expanded: false
    property var focusWindow: null
    property bool gameMode: false
    
    // Expose panel for TopPills Wayland mask tracking
    property alias panel: panel
    property alias panelMask: panelMask
    property alias searchText: searchInput.text

    function setSearchText(t) {
        searchInput.text = t;
    }

    signal appLaunched()

    property var emojiModel: []
    Process {
        id: emojiLoader
        command: ["cat", Quickshell.env("HOME") + "/.config/quickshell/scripts/emojis.txt"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.length > 0) {
                    var lines = this.text.split("\n");
                    var arr = [];
                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i].trim();
                        if (line.length > 0) {
                            var firstSpace = line.indexOf(" ");
                            var glyph = line;
                            if (firstSpace !== -1) {
                                glyph = line.substring(0, firstSpace);
                            } else {
                                // Fallback if no space
                                glyph = line;
                            }
                            
                            arr.push({
                                name: line,
                                command: ["wl-copy", glyph],
                                workingDirectory: Quickshell.env("HOME"),
                                icon: "",
                                isFile: false,
                                isSetting: true,
                                iconName: "emoji_emotions"
                            });
                        }
                    }
                    root.emojiModel = arr;
                }
            }
        }
    }

    property var fileModel: []

    Process {
        id: fileFinderProc
        command: ["bash", "-c", "find ~/ -maxdepth 3 -type f -o -type d | grep -v '/\\.'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                var arr = [];
                for (var i = 0; i < lines.length; i++) {
                    var path = lines[i].trim();
                    if (path.length > 0 && path !== Quickshell.env("HOME") && path !== Quickshell.env("HOME") + "/") {
                        var name = path.substring(path.lastIndexOf('/') + 1);
                        var isDir = (path.indexOf('.') === -1 || path.lastIndexOf('.') < path.lastIndexOf('/'));
                        arr.push({
                            name: name,
                            command: ["xdg-open", path],
                            workingDirectory: Quickshell.env("HOME"),
                            icon: "",
                            isFile: true,
                            isDir: isDir
                        });
                    }
                }
                root.fileModel = arr;
            }
        }
    }

    property var clipboardModel: []

    Process {
        id: cliphistProc
        command: ["bash", "-c", "mkdir -p /tmp/qs_clip && cliphist list | head -n 100 | while IFS=$'\t' read -r id snippet; do if [[ \"$snippet\" == *\"[[ binary data\"* ]]; then if [ ! -f \"/tmp/qs_clip/clip_$id.img\" ]; then cliphist decode \"$id\" > \"/tmp/qs_clip/clip_$id.img\"; fi; fi; echo -e \"$id\\t$snippet\"; done"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                var arr = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i];
                    if (line.trim().length > 0) {
                        var tabIndex = line.indexOf("\t");
                        if (tabIndex !== -1) {
                            var id = line.substring(0, tabIndex);
                            var snippet = line.substring(tabIndex + 1);
                            
                            var isImage = snippet.startsWith("[[ binary data") && (snippet.indexOf("png") !== -1 || snippet.indexOf("jpeg") !== -1 || snippet.indexOf("jpg") !== -1 || snippet.indexOf("webp") !== -1 || snippet.indexOf("bmp") !== -1);
                            
                            var isFileUri = snippet.startsWith("file://");
                            var isUriImage = false;
                            var cleanPath = "";
                            if (isFileUri) {
                                cleanPath = snippet.replace("file://", "").split(" ")[0].split("\n")[0].trim();
                                try { cleanPath = decodeURIComponent(cleanPath); } catch(e) {}
                                var ext = cleanPath.substring(cleanPath.lastIndexOf('.')).toLowerCase();
                                if (ext === ".png" || ext === ".jpg" || ext === ".jpeg" || ext === ".webp" || ext === ".gif") {
                                    isUriImage = true;
                                }
                            }

                            var clipImgPath = "";
                            if (isImage) clipImgPath = "/tmp/qs_clip/clip_" + id + ".img";
                            else if (isUriImage) clipImgPath = cleanPath;
                            
                            var dispName = snippet;
                            if (isImage) dispName = "Copied Image (" + id + ")";
                            else if (isFileUri) dispName = "File: " + cleanPath.substring(cleanPath.lastIndexOf('/') + 1);
                            
                            arr.push({
                                name: dispName,
                                clipId: id,
                                fullLine: line,
                                command: ["bash", "-c", "cliphist decode " + id + " | wl-copy"],
                                workingDirectory: Quickshell.env("HOME"),
                                icon: "",
                                isFile: false,
                                isDir: false,
                                isMath: false,
                                isClipboard: true,
                                clipImagePath: clipImgPath
                            });
                        }
                    }
                }
                root.clipboardModel = arr;
            }
        }
    }

    property var filteredModel: {
        var filterText = searchInput.text.toLowerCase();
        
        if (filterText.startsWith("=")) {
            var expr = filterText.substring(1).trim();
            if (expr.length > 0) {
                try {
                    // Restrict characters for basic math safety
                    var safeExpr = expr.replace(/[^0-9+\-*/().%\s]/g, "");
                    if (safeExpr.length > 0) {
                        var result = eval(safeExpr);
                        if (result !== undefined && !isNaN(result)) {
                            return [{
                                name: result.toString(),
                                command: ["wl-copy", result.toString()],
                                workingDirectory: Quickshell.env("HOME"),
                                icon: "",
                                isFile: false,
                                isDir: false,
                                isMath: true
                            }];
                        }
                    }
                } catch(e) {}
            }
            return [];
        }

        if (filterText.startsWith("/")) {
            var query = filterText.substring(1).trim();
            
            if (filterText.startsWith("/clipboard")) {
                if (!cliphistProc.running && root.clipboardModel.length === 0) {
                    cliphistProc.running = true;
                }
                var clipQuery = filterText.substring(10).trim();
                var results = clipQuery === "" ? root.clipboardModel : root.clipboardModel.filter(item => Vars.fuzzyMatch(clipQuery, item.name));
                var finalResults = results.slice(0, 100);
                if (finalResults.length > 0) {
                    finalResults.unshift({
                        name: "Clear Clipboard History",
                        command: ["INTERNAL:CLEAR_CLIPBOARD"],
                        workingDirectory: Quickshell.env("HOME"),
                        icon: "",
                        isFile: false,
                        isDir: false,
                        isMath: false,
                        isClipboard: false,
                        isSetting: false,
                        isClearAll: true,
                        iconName: "delete"
                    });
                }
                return finalResults;
            }

            if (filterText.startsWith("/emoji")) {
                var emQuery = filterText.substring(6).trim();
                var results = emQuery === "" ? root.emojiModel : root.emojiModel.filter(item => Vars.fuzzyMatch(emQuery, item.name));
                return results.slice(0, 100);
            }
            
            var settingsOptions = [
                {
                    name: "Color Scheme",
                    command: [""],
                    workingDirectory: Quickshell.env("HOME"),
                    icon: "",
                    isFile: false,
                    isSetting: true,
                    iconName: "palette"
                },
                {
                    name: "Wi-Fi",
                    command: [""],
                    workingDirectory: Quickshell.env("HOME"),
                    icon: "",
                    isFile: false,
                    isSetting: true,
                    iconName: "wifi"
                },
                {
                    name: "Bluetooth",
                    command: [""],
                    workingDirectory: Quickshell.env("HOME"),
                    icon: "",
                    isFile: false,
                    isSetting: true,
                    iconName: "bluetooth"
                },
                {
                    name: "Clipboard Manager",
                    command: ["INTERNAL:CLIPBOARD"],
                    workingDirectory: Quickshell.env("HOME"),
                    icon: "",
                    isFile: false,
                    isSetting: true,
                    iconName: "content_paste"
                },
                {
                    name: "Emoji Picker",
                    command: ["INTERNAL:EMOJI"],
                    workingDirectory: Quickshell.env("HOME"),
                    icon: "",
                    isFile: false,
                    isSetting: true,
                    iconName: "emoji_emotions"
                }
            ];
            
            if (query === "") return settingsOptions;
            return settingsOptions.filter(item => Vars.fuzzyMatch(query, item.name));
        }

        var allApps = DesktopEntries.applications.values;
        if (filterText === "") return allApps;
        
        var matchedApps = allApps.filter(app => Vars.fuzzyMatch(filterText, app.name));
        
        if (filterText.indexOf("./") !== -1) {
            var fileQuery = filterText.replace(/\.\//g, "").trim();
            var matchedFiles = fileQuery === "" ? root.fileModel.slice(0, 50) : root.fileModel.filter(file => Vars.fuzzyMatch(fileQuery, file.name));
            return matchedApps.concat(matchedFiles);
        }
        
        return matchedApps;
    }

    HyprlandFocusGrab {
        active: root.expanded && root.focusWindow !== null
        windows: root.focusWindow ? [root.focusWindow] : []
        onCleared: root.expanded = false
    }
    
    // Clear search when closed, focus when opened
    onExpandedChanged: {
        if (!expanded) {
            searchInput.text = "";
        } else {
            // Refresh clipboard history when opened
            cliphistProc.running = true;
            searchInput.forceActiveFocus();
        }
    }

    Item {
        id: panelMask
        anchors.centerIn: panel
        width: panel.width + 40
        height: panel.height + 40
    }

    // The visual panel that animates
    Rectangle {
        id: panel
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: !root.gameMode; shadowBlur: 1.0; shadowColor: Qt.rgba(0,0,0,0.25); shadowVerticalOffset: 4; shadowHorizontalOffset: 0 }
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        
        width: root.expanded ? 500 : 100
        height: root.expanded ? 450 : 40
        
        opacity: root.expanded || panel.width > 105 ? 1.0 : 0.0
        visible: opacity > 0
        
        color: Theme.surface_container_high
        radius: root.gameMode ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        // clip removed for shadow

        Behavior on radius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }

        // EXPANDED UI
        Item {
            anchors.fill: parent
            anchors.margins: Vars.spacingLarge
            
            opacity: root.expanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { enabled: !root.gameMode; SequentialAnimation { PauseAnimation { duration: root.expanded ? Vars.animationDuration : 0 } NumberAnimation { duration: root.expanded ? Vars.animationDuration : Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.expanded ? Vars.m3StandardDecelerate : Vars.m3StandardAccelerate } } }



            ColumnLayout {
                id: mainLayout
                anchors.fill: parent
                spacing: Vars.spacingMedium

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Vars.spacingMedium
                    

                    Text { text: "App Launcher"; font.family: Vars.fontFamily; font.pixelSize: 20; font.weight: 600; color: Theme.on_surface }
                }

                Rectangle {
                    id: searchBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    color: searchInput.activeFocus ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Theme.surface_container_highest
                    border.color: Theme.primary
                    border.width: searchInput.activeFocus ? 2 : 0
                    radius: Vars.radiusMedium

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Vars.spacingMedium
                        anchors.rightMargin: Vars.spacingMedium

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font.family: Vars.fontFamily
                            font.pixelSize: 14
                            color: Theme.on_surface
                            focus: root.expanded
                            selectByMouse: true

                            Text {
                                text: "Search apps..."
                                font.family: Vars.fontFamily
                                font.pixelSize: 14
                                color: Theme.on_surface_variant
                                visible: !searchInput.text && !searchInput.activeFocus
                            }

                            Keys.onDownPressed: (event) => {
                                if (appListView.count > 0 && appListView.currentIndex === -1) {
                                    appListView.currentIndex = 0;
                                }
                                appListView.forceActiveFocus();
                                event.accepted = true;
                            }
                            Keys.onReturnPressed: (event) => {
                                if (appListView.count > 0 && appListView.currentIndex === -1) {
                                    appListView.currentIndex = 0;
                                }
                                appListView.forceActiveFocus();
                                event.accepted = true;
                            }
                            Keys.onEscapePressed: (event) => {
                                root.expanded = false;
                                event.accepted = true;
                            }
                        }

                        Text {
                            text: "✕"
                            font.pixelSize: 14
                            color: Theme.on_surface_variant
                            visible: searchInput.text.length > 0
                            Layout.alignment: Qt.AlignVCenter
                            MouseArea {
                                anchors.fill: parent
                                onClicked: searchInput.text = ""
                            }
                        }
                    }
                }

                ListView {
                    id: appListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: root.filteredModel
                    
                    orientation: ListView.Vertical
                    boundsBehavior: Flickable.StopAtBounds

                    focus: true
                    keyNavigationEnabled: true
                    highlightFollowsCurrentItem: false
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                    
                    highlightRangeMode: ListView.ApplyRange
                    preferredHighlightBegin: 20
                    preferredHighlightEnd: appListView.height - 20

                    Keys.onReturnPressed: (event) => { if (currentItem) currentItem.triggerSelection(); event.accepted = true; }
                    Keys.onSpacePressed: (event) => { if (currentItem) currentItem.triggerSelection(); event.accepted = true; }
                    Keys.onEscapePressed: (event) => { root.expanded = false; event.accepted = true; }
                    
                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) {
                            if (currentItem && currentItem.deleteClipboardItem) {
                                currentItem.deleteClipboardItem();
                                event.accepted = true;
                            }
                        }
                    }
                    
                    Keys.onUpPressed: (event) => {
                        if (currentIndex <= 0) {
                            searchInput.forceActiveFocus();
                        } else {
                            decrementCurrentIndex();
                        }
                        event.accepted = true;
                    }
                    Keys.onDownPressed: (event) => {
                        if (currentIndex === -1 && count > 0) {
                            currentIndex = 0;
                        } else {
                            incrementCurrentIndex();
                        }
                        event.accepted = true;
                    }
                    
                    onModelChanged: {
                        if (count > 0 && currentIndex === -1) {
                            currentIndex = 0;
                        }
                    }

                    delegate: Item {
                        id: delegateItem
                        width: appListView.width
                        height: 48

                        function triggerSelection() {
                            if (modelData.command[0] === "INTERNAL:CLIPBOARD") {
                                searchInput.text = "/clipboard ";
                                return;
                            }
                            if (modelData.command[0] === "INTERNAL:EMOJI") {
                                searchInput.text = "/emoji ";
                                return;
                            }
                            if (modelData.command[0] === "INTERNAL:CLEAR_CLIPBOARD") {
                                Quickshell.execDetached({ command: ["cliphist", "wipe"] });
                                root.clipboardModel = [];
                                var oldText = searchInput.text;
                                searchInput.text = "";
                                searchInput.text = oldText;
                                return;
                            }
                            
                            Quickshell.execDetached({
                                command: modelData.command,
                                workingDirectory: modelData.workingDirectory
                            });
                            root.appLaunched();
                            root.expanded = false;
                        }

                        property bool isCurrent: delegateItem.ListView.isCurrentItem && appListView.activeFocus
                        
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            color: isCurrent ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                            radius: Vars.radiusMedium
                            border.color: Theme.primary
                            border.width: isCurrent ? 2 : 0

                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                        }

                        function deleteClipboardItem() {
                            if (modelData.isClipboard) {
                                Quickshell.execDetached({
                                    command: ["bash", "-c", "echo -e '" + modelData.fullLine.replace(/'/g, "'\\''") + "' | cliphist delete"]
                                });
                                var newModel = root.clipboardModel.slice();
                                var idx = newModel.findIndex(x => x.clipId === modelData.clipId);
                                if (idx !== -1) {
                                    newModel.splice(idx, 1);
                                    root.clipboardModel = newModel;
                                    var oldText = searchInput.text;
                                    searchInput.text = "";
                                    searchInput.text = oldText;
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            preventStealing: false
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            onEntered: {
                                appListView.currentIndex = index;
                            }

                            onClicked: (mouse) => {
                                appListView.currentIndex = index;
                                if (mouse.button === Qt.RightButton && modelData.isClipboard) {
                                    delegateItem.deleteClipboardItem();
                                } else {
                                    delegateItem.triggerSelection();
                                }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16 + (isCurrent ? 8 : 0)
                            anchors.rightMargin: 16
                            spacing: 16

                            Behavior on anchors.leftMargin { 
                                NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } 
                            }

                            Rectangle {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                color: "transparent"
                                radius: Vars.radiusSmall
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: (modelData.clipImagePath !== undefined && modelData.clipImagePath !== "") ? "file://" + modelData.clipImagePath : (modelData.icon ? "image://icon/" + modelData.icon : "")
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: (modelData.isFile !== true && modelData.isMath !== true && modelData.isSetting !== true && modelData.isClipboard !== true && modelData.isClearAll !== true) || (modelData.isClipboard === true && modelData.clipImagePath !== undefined && modelData.clipImagePath !== "")
                                    
                                    opacity: isCurrent ? 1.0 : (itemMouseArea.containsMouse ? 0.9 : 0.7)
                                    Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 24
                                    text: modelData.isMath ? "calculate" : 
                                          (modelData.isClipboard ? "content_copy" : 
                                          (modelData.isSetting ? modelData.iconName : 
                                          (modelData.isClearAll ? "delete" :
                                          (modelData.isFile ? (modelData.isDir ? "folder" : "description") : ""))))
                                    color: modelData.isClearAll ? Theme.error : (isCurrent ? Theme.primary : Theme.on_surface)
                                    visible: (modelData.isFile === true || modelData.isMath === true || modelData.isSetting === true || modelData.isClipboard === true || modelData.isClearAll === true) && !(modelData.isClipboard && modelData.clipImagePath !== undefined && modelData.clipImagePath !== "")
                                    
                                    opacity: isCurrent ? 1.0 : (itemMouseArea.containsMouse ? 0.9 : 0.7)
                                    Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
                                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                font.family: Vars.fontFamily
                                font.pixelSize: 14
                                font.weight: isCurrent ? Font.DemiBold : Font.Medium
                                text: modelData.name
                                
                                color: modelData.isClearAll ? Theme.error : (isCurrent ? Theme.primary : Theme.on_surface)
                                opacity: isCurrent ? 1.0 : (itemMouseArea.containsMouse ? 0.8 : 0.6)
                                
                                maximumLineCount: 1
                                elide: Text.ElideRight
                                
                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
                            }
                        }
                    }
                }
            }
        }
    }
}
import QtQuick
import QtQuick.Effects
import ".."
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtCore

import "../Variables/variables.js" as Vars
import "WallpaperSwitcher"

Item {
    id: root
    
    Layout.preferredWidth: 100
    Layout.preferredHeight: 40
    
    property bool expanded: false
    property bool forceHidePill: false
    property var focusWindow: null
    property bool gameMode: false
    property alias panel: panel
    property alias panelMask: panelMask

    opacity: forceHidePill ? 0.0 : 1.0
    visible: opacity > 0

    property string wallpaperDir: settings.wallpaperDir || (Quickshell.env("HOME") + "/Pictures/Wallpapers")
    property string currentWallpaper: ""

    Settings {
        id: settings
        category: "WallpaperSwitcher"
        property string matugenScheme: "scheme-tonal-spot"
        property string wallpaperDir: ""
    }

    signal closeRequested()

    HyprlandFocusGrab {
        active: root.expanded && root.focusWindow !== null
        windows: root.focusWindow ? [root.focusWindow] : []
        onCleared: root.expanded = false
    }
    
    onExpandedChanged: {
        if (!expanded) {
            searchInput.text = "";
        } else {
            searchInput.forceActiveFocus();
        }
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
        
        width: root.expanded ? 900 : 100
        height: root.expanded ? 550 : 40
        
        color: Theme.surface_container_low
        radius: root.gameMode ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        
        opacity: root.expanded || panel.width > 105 ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on radius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }

        Item {
            anchors.fill: parent
            anchors.margins: Vars.spacingLarge
            
            opacity: root.expanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { enabled: !root.gameMode; SequentialAnimation { PauseAnimation { duration: root.expanded ? Vars.animationDuration : 0 } NumberAnimation { duration: root.expanded ? Vars.animationDuration : Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.expanded ? Vars.m3StandardDecelerate : Vars.m3StandardAccelerate } } }

            ColumnLayout {
                anchors.fill: parent
                spacing: Vars.spacingMedium

                WallpaperControls {
                    id: controls
                    rootRef: root
                    settingsRef: settings
                    loadWallpapersProcRef: loadWallpapersProc
                    gridViewRef: gridView
                    autocompleteProcRef: autocompleteProc
                    autocompleteModelRef: autocompleteModel
                }

                WallpaperGrid {
                    id: gridView
                    model: sortFilterProxyModel.proxyModel
                    rootRef: root
                    
                    onWallpaperSelected: (path) => {
                        executeWallpaperChange(path);
                    }
                    onRequestFocusSearch: {
                        pathInput.forceActiveFocus();
                    }
                }
            }
        }
    }

    function executeWallpaperChange(filePath) {
        console.log("[USER ACTION] Wallpaper selected: " + filePath);
        root.currentWallpaper = filePath;

        matugenProc.command = ["matugen", "image", filePath, "-m", "light", "-t", settings.matugenScheme, "--source-color-index", "0"];
        matugenProc.running = true;
    }

    Process {
        id: matugenProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.log("[MATUGEN STDOUT]\n" + this.text);
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.error("[MATUGEN STDERR]\n" + this.text);
            }
        }
        onExited: (code, status) => {
            Quickshell.execDetached({ command: ['bash', '-c', '.config/quickshell/sync_colors.py'] });
            Quickshell.execDetached({ command: ['bash', '-c', 'qs kill; sleep 0.1; qs'] });
        }
    }

    ListModel { id: wallpaperModel }

    QtObject {
        id: sortFilterProxyModel
        property string filterText: controls.filterText
        onFilterTextChanged: updateVisualGrid()
        function updateVisualGrid() {
            proxyModel.clear();
            for (var i = 0; i < wallpaperModel.count; i++) {
                var item = wallpaperModel.get(i);
                if (Vars.fuzzyMatch(filterText, item.fileName)) {
                    proxyModel.append({ "filePath": item.filePath, "fileName": item.fileName });
                }
            }
        }
        property ListModel proxyModel: ListModel {}
    }

    Process {
        id: loadWallpapersProc
        command: ["find", root.wallpaperDir.replace(/^~/, Quickshell.env("HOME")), "-maxdepth", "2", "-type", "f", "-regextype", "posix-extended", "-regex", ".*\\.(jpg|jpeg|png|gif)$"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                wallpaperModel.clear();
                var lines = this.text.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var path = lines[i].trim();
                    if (path.length > 0) {
                        var name = path.substring(path.lastIndexOf('/') + 1);
                        wallpaperModel.append({ "filePath": path, "fileName": name });
                    }
                }
                sortFilterProxyModel.updateVisualGrid();
            }
        }
    }

    ListModel { id: autocompleteModel }

    Process {
        id: autocompleteProc
        stdout: StdioCollector {
            onStreamFinished: {
                autocompleteModel.clear();
                var lines = this.text.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var path = lines[i].trim();
                    if (path.length > 0) {
                        autocompleteModel.append({ "path": path });
                    }
                }
            }
        }
    }
}

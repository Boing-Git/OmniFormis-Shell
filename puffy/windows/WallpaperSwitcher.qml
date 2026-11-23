import QtQuick
import QtQuick.Effects
import ".."
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtCore

import "../theme"
import "../core/primitives" as Primitives
import "WallpaperSwitcher"

Item {
    id: root

    Layout.preferredWidth: 100
    Layout.preferredHeight: 40

    property bool expanded: false
    property bool forceHidePill: false
    property var focusWindow: null
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false
    property alias panel: panel
    property alias panelMask: panelMask

    opacity: forceHidePill ? 0.0 : 1.0
    visible: opacity > 0

    property string wallpaperDir: settings.wallpaperDir || (Quickshell.env("HOME") + "/Pictures/Wallpapers")
    property string currentWallpaper: settings.currentWallpaper

    Settings {
        id: settings
        category: "WallpaperSwitcher"
        property string matugenScheme: "scheme-tonal-spot"
        property string wallpaperDir: ""
        property string currentWallpaper: ""
        property string awwwTransitionType: "wipe"
        property string awwwTransitionStep: "90"
        property string awwwTransitionAngle: "30"
    }

    Settings {
        id: themeModeSettings
        category: "ColorScheme"
        property string currentMode: "dark"
    }

    signal closeRequested



    onExpandedChanged: {
        if (contentLoader.item && contentLoader.item.controls) {
            if (!expanded) {
                MorphState.notifyClosed();
                contentLoader.item.controls.clearSearch();
            } else {
                MorphState.notifyOpened(1100, 650, panel.targetRad, panel);
                contentLoader.visible = true;
            contentLoader.item.controls.focusSearch();
            contentLoader.visible = Qt.binding(() => root.expanded || contentLoader.opacity > 0);
            }
        } else {
            if (!expanded) MorphState.notifyClosed();
            else MorphState.notifyOpened(1100, 650, panel.targetRad, panel);
        }
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
        height: root.expanded ? 590 : 0
    }

    Primitives.SquircleMask {
        id: panel
        property bool isBackgroundActive: root.expanded || (MorphState.openCount === 0 && MorphState.activeItem === panel && panel.width > 105)
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

        width: root.expanded ? 1100 : (MorphState.anyExpanded ? MorphState.targetWidth : 100)
        height: root.expanded ? 650 : (MorphState.anyExpanded ? MorphState.targetHeight : 40)

        color: Vars.tColorActive(isBackgroundActive, Theme.surface, Vars.panelOpacity)
        property real targetRad: root.expanded ? Vars.radiusExtraLarge : (MorphState.anyExpanded ? MorphState.targetRadius : height / 2)
        topLeftRadius: Vars.getTopLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        topRightRadius: Vars.getTopRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomLeftRadius: Vars.getBottomLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomRightRadius: Vars.getBottomRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)

        opacity: isBackgroundActive || innerUI.opacity > 0 ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on width {
            enabled: !root.gameMode
            NumberAnimation {
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customExpressiveSpatialSlow
            }
        }
        Behavior on height {
            enabled: !root.gameMode
            NumberAnimation {
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customExpressiveSpatialSlow
            }
        }

        Item {
            id: innerUI
            anchors.centerIn: parent
            width: Math.max(1, parent.width - Vars.spacingLarge * 2)
            height: Math.max(1, parent.height - Vars.spacingLarge * 2)

            opacity: root.expanded ? 1.0 : 0.0
            visible: root.expanded || opacity > 0
            clip: true
            Behavior on opacity {
                enabled: !root.gameMode
                NumberAnimation {
                    duration: Vars.animationDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Vars.getFadeCurve(root.expanded)
                }
            }

            // Shown while a wallpaper is being applied and the colours are generated from it
            Primitives.LoadingIndicator {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: Vars.spacingSmall
                width: 44
                height: 44
                running: matugenProc.running
                z: 10
            }

            Loader {
                id: contentLoader
                anchors.fill: parent
                active: root.expanded || parent.opacity > 0
                asynchronous: false
                onLoaded: {
                    if (root.expanded && item && item.controls) {
                        item.controls.focusSearch();
                    }
                }
                sourceComponent: Component {
                    Item {
                        property var controls: controlsBar
                        width: 1052
                        height: parent.height
                        anchors.left: parent.left
                        anchors.top: parent.top

                        // Quick-return search bar: tracks scroll direction instead of living in
                        // GridView's `header` (which just scrolls away with the content). A
                        // deliberate downward scroll hides it so more of the grid is visible; any
                        // upward scroll — even a couple pixels — brings it straight back, and
                        // landing back at the very top always shows it. Mirrors Material's
                        // FloatingToolbar "quick return" scroll behavior (the reference design
                        // system's own FloatingToolbar docs note that behavior as a real M3
                        // pattern it deliberately left unported — see
                        // Design language/src/tokens/defaults/floating-toolbar.ts).
                        property real _lastContentY: 0
                        property bool controlsHidden: false

                        WallpaperGrid {
                            id: gridView
                            anchors.fill: parent
                            model: sortFilterProxyModel.proxyModel
                            rootRef: root
                            topMargin: controlsBar.height + Vars.spacingMedium

                            onContentYChanged: {
                                if (contentY <= 0) {
                                    controlsHidden = false;
                                } else {
                                    var delta = contentY - _lastContentY;
                                    if (delta > 4) {
                                        controlsHidden = true;
                                    } else if (delta < -1) {
                                        controlsHidden = false;
                                    }
                                }
                                _lastContentY = contentY;
                            }

                            onWallpaperSelected: path => {
                                executeWallpaperChange(path);
                            }
                            onRequestFocusSearch: {
                                gridView.positionViewAtBeginning();
                                controlsBar.focusSearch();
                            }
                        }

                        WallpaperControls {
                            id: controlsBar
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            z: 10
                            rootRef: root
                            settingsRef: settings
                            loadWallpapersProcRef: loadWallpapersProc
                            gridViewRef: gridView
                            autocompleteProcRef: autocompleteProc
                            autocompleteModelRef: autocompleteModel

                            y: (!controlsHidden || hasFocus) ? 0 : -(height + Vars.spacingMedium)
                            Behavior on y {
                                NumberAnimation {
                                    duration: Vars.animationDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: controlsHidden ? Vars.customEmphasizedAccelerate : Vars.customEmphasizedDecelerate
                                }
                            }
                        }

                        ListModel { id: wallpaperModel }
                        ListModel { id: proxyModelObj }

                        QtObject {
                            id: sortFilterProxyModel
                            property string filterText: controls ? controls.filterText : ""
                            onFilterTextChanged: updateVisualGrid()
                            function updateVisualGrid() {
                                proxyModelObj.clear();
                                for (var i = 0; i < wallpaperModel.count; i++) {
                                    var item = wallpaperModel.get(i);
                                    if (Vars.fuzzyMatch(filterText, item.fileName) || (item.folderName && Vars.fuzzyMatch(filterText, item.folderName))) {
                                        proxyModelObj.append({
                                            "filePath": item.filePath,
                                            "fileName": item.fileName,
                                            "folderName": item.folderName
                                        });
                                    }
                                }
                            }
                            property var proxyModel: proxyModelObj
                        }

                        Process {
                            id: loadWallpapersProc
                            property string defaultDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
                            property string resolvedDir: root.wallpaperDir.replace(/^~/, Quickshell.env("HOME"))
                            // Validate dir with -d, fall back to default if it doesn't exist
                            command: ["bash", "-c",
                                "DIR='" + resolvedDir.replace(/'/g, "'\\''") + "'; " +
                                "if [ ! -d \"$DIR\" ]; then DIR='" + defaultDir + "'; fi; " +
                                "find \"$DIR\" -maxdepth 4 -type f | grep -iE '\\.(jpg|jpeg|png|gif)$'"
                            ]
                            running: true
                            stdout: StdioCollector {
                                onStreamFinished: {
                                    wallpaperModel.clear();
                                    var lines = this.text.split("\n");
                                    var items = [];
                                    for (var i = 0; i < lines.length; i++) {
                                        var path = lines[i].trim();
                                        if (path.length > 0) {
                                            var pathParts = path.split('/');
                                            var folderName = pathParts.length > 1 ? pathParts[pathParts.length - 2] : "";
                                            var name = pathParts[pathParts.length - 1];
                                            items.push({
                                                "filePath": path,
                                                "fileName": name,
                                                "folderName": folderName
                                            });
                                        }
                                    }

                                    // If 0 wallpapers found and we had a stale stored dir, clear it
                                    if (items.length === 0 && settings.wallpaperDir !== "") {
                                        settings.wallpaperDir = "";
                                    }
                                    // Also clear stale currentWallpaper if it references a missing path
                                    if (settings.currentWallpaper !== "" && settings.currentWallpaper.indexOf("/wallpapers/") !== -1) {
                                        settings.currentWallpaper = "";
                                    }

                                    items.sort((a, b) => a.fileName.toLowerCase().localeCompare(b.fileName.toLowerCase()));
                                    for (var j = 0; j < items.length; j++) {
                                        wallpaperModel.append(items[j]);
                                    }
                                    sortFilterProxyModel.updateVisualGrid();
                                }
                            }
                            stderr: StdioCollector {
                                onStreamFinished: {
                                    var errText = this.text.trim();
                                    if (errText.length > 0) {
                                        console.log("WallpaperSwitcher find stderr: " + errText);
                                    }
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
                                            autocompleteModel.append({
                                                "path": path
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

    function executeWallpaperChange(filePath) {
        console.log("[USER ACTION] Wallpaper selected: " + filePath);
        settings.currentWallpaper = filePath;

        var matugenSchemeArg = (settings.matugenScheme === "scheme-auto" || settings.matugenScheme === "auto") ? "scheme-tonal-spot" : (settings.matugenScheme || "scheme-tonal-spot");
        
        // Execute awww immediately via detached process
        var safePath = filePath.replace(/'/g, "'\\''");
        var trans = settings.awwwTransitionType || "wipe";
        var step = settings.awwwTransitionStep || "90";
        var angle = settings.awwwTransitionAngle || "30";
        Quickshell.execDetached({
            command: ["bash", "-c", "awww img '" + safePath + "' --transition-type " + trans + " --transition-angle " + angle + " --transition-step " + step]
        });

        // Run matugen via the Process component
        var mode = themeModeSettings.currentMode || "dark";
        var cmd = "";
        if (settings.matugenScheme === "scheme-auto" || settings.matugenScheme === "auto" || !settings.matugenScheme) {
            // First run matugen immediately for instant feedback, then run auto_scheme_matugen to refine it in background
            cmd = "bash ~/Dotfiles/scripts/theme-apply.sh '" + safePath + "' " + matugenSchemeArg + " saturation";
            // We run auto_scheme_matugen.sh in detached process so it doesn't block UI and can update later
            Quickshell.execDetached({
                command: ["bash", "-c", "sleep 1.5; bash ~/Dotfiles/scripts/auto_scheme_matugen.sh '" + safePath + "' " + mode + "; bash ~/.config/color-schemes/set-theme.sh material-you " + mode + "; nohup bash ~/Dotfiles/scripts/reload.sh >/dev/null 2>&1 &"]
            });
        } else {
            // the shared theming script (scripts/theme-apply.sh): the repo's matugen config,
            // one run at a time, a log and a notification when it fails
            cmd = "bash ~/Dotfiles/scripts/theme-apply.sh '" + safePath + "' " + matugenSchemeArg + " saturation";
        }
                  
        matugenProc.command = ["bash", "-c", cmd];
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
            if (code === 0) {
                // Delay slightly to ensure matugen has fully flushed to disk, then run set-theme and reload
                var mode = themeModeSettings.currentMode || "dark";
                Quickshell.execDetached({
                    command: ['bash', '-c', 'sleep 0.5; bash ~/.config/color-schemes/set-theme.sh material-you ' + mode + '; nohup bash ~/Dotfiles/scripts/reload.sh >/dev/null 2>&1 &']
                });
            } else {
                console.error("[USER ACTION] Matugen failed with exit code: " + code + ". Skipping color sync.");
            }
        }
    }

}

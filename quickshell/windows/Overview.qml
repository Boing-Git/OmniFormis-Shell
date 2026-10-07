import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "./Overview" as OC
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import "../theme"
import "../theme"
import "../core/primitives" as Primitives
import ".."
import Quickshell.Io

Item {
    id: overviewContainer
    property bool visibleState: false
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false
    signal closeRequested

    property bool vimKeysEnabled: false
    Process {
        id: vimKeysChecker
        command: ["bash", "-c", "grep -qi 'vimkeys[ \t]*=[ \t]*true' ~/.config/hypr/modules/variables.lua && echo 'true' || echo 'false'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                overviewContainer.vimKeysEnabled = (this.text.trim() === 'true');
            }
        }
    }

    function resolveIcon(appId) {
        if (!appId) return "application-x-executable";
        
        let searchId = appId;
        if (appId.startsWith("steam_app_")) searchId = "steam";
        else if (appId.toLowerCase().includes("zen")) searchId = "zen";
        
        try {
            if (typeof DesktopEntries !== "undefined") {
                let app = null;
                if (typeof DesktopEntries.getApp === "function") app = DesktopEntries.getApp(searchId);
                else if (typeof DesktopEntries.getByAppId === "function") app = DesktopEntries.getByAppId(searchId);
                
                if (!app && typeof DesktopEntries.getApp === "function") {
                    if (searchId === "zen") app = DesktopEntries.getApp("zen-browser") || DesktopEntries.getApp("zen-twilight") || DesktopEntries.getApp("zen-alpha");
                }
                
                if (app && app.icon) return app.icon;
            }
        } catch(e) {
            console.log("Error resolving icon via Quickshell service:", e);
        }
        
        if (searchId === "steam") return "steam";
        if (searchId === "zen") return "zen-browser";
        
        return appId;
    }

    // Overview config
    readonly property bool isVertical: Vars.pillPosition === "Left" || Vars.pillPosition === "Right"
    readonly property int gridRows: isVertical ? (Vars.overviewGridColumns !== undefined ? Vars.overviewGridColumns : 5) : (Vars.overviewGridRows !== undefined ? Vars.overviewGridRows : 2)
    readonly property int gridColumns: isVertical ? (Vars.overviewGridRows !== undefined ? Vars.overviewGridRows : 2) : (Vars.overviewGridColumns !== undefined ? Vars.overviewGridColumns : 5)
    readonly property real overviewScale: Vars.overviewScale !== undefined ? Vars.overviewScale : 0.15

    function wsIdFromIndex(index, baseId) {
        const total = gridRows * gridColumns;
        if (index >= total) return baseId + index;
        
        let row = Math.floor(index / gridColumns);
        let col = index % gridColumns;
        
        if (!isVertical) {
            let mappedRow = Vars.pillPosition === "Bottom" ? (gridRows - 1 - row) : row;
            return baseId + (mappedRow * gridColumns + col);
        }
        
        let mappedCol = Vars.pillPosition === "Right" ? (gridColumns - 1 - col) : col;
        return baseId + (mappedCol * gridRows + row);
    }

    function indexFromWsId(wsId, baseId) {
        const localWs = wsId - baseId;
        const total = gridRows * gridColumns;
        if (localWs < 0 || localWs >= total) return localWs;
        
        if (!isVertical) {
            let logicalRow = Math.floor(localWs / gridColumns);
            let logicalCol = localWs % gridColumns;
            let visualRow = Vars.pillPosition === "Bottom" ? (gridRows - 1 - logicalRow) : logicalRow;
            return visualRow * gridColumns + logicalCol;
        }
        
        let logicalCol = Math.floor(localWs / gridRows);
        let row = localWs % gridRows;
        let visualCol = Vars.pillPosition === "Right" ? (gridColumns - 1 - logicalCol) : logicalCol;
        return row * gridColumns + visualCol;
    }

    Component.onCompleted: {
        console.log("OVERVIEW CONFIG LOADED:", gridRows, gridColumns, overviewScale, Vars.overviewGridRows);
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: overviewPanel
            required property var modelData

            property bool isAnimating: wAnim.running || hAnim.running
            
            Connections {
                target: overviewContainer
                function onVisibleStateChanged() {
                    if (overviewContainer.visibleState) {
                        MorphState.notifyOpened(panelBackground.targetWidth, panelBackground.targetHeight, panelBackground.defaultRadius, panelBackground);
                    } else {
                        MorphState.notifyClosed();
                    }
                }
            }
            
            visible: true
            color: "transparent"

            WlrLayershell.namespace: "quickshell"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore
            
            mask: Region {
                item: (overviewContainer.visibleState || isAnimating) ? panelBackground : null
            }
            


            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            screen: modelData

            readonly property var hyprMonitor: Hyprland.monitorFor(overviewPanel.screen)
            readonly property real monitorWidth: hyprMonitor?.width ?? 1920
            readonly property real monitorHeight: hyprMonitor?.height ?? 1080
            readonly property real monitorScale: hyprMonitor?.scale ?? 1

            // Workspace tile dimensions, driven by scale
            readonly property real wsSpacing: 6
            readonly property real bgPadding: 12
            readonly property real screenMargin: 64

            readonly property real availableW: (monitorWidth / monitorScale) - (bgPadding * 2) - (screenMargin * 2)
            readonly property real availableH: (monitorHeight / monitorScale) - (bgPadding * 2) - (screenMargin * 2)
            
            readonly property real maxWsWidthByW: Math.max(1, (availableW * overviewContainer.overviewScale - (overviewContainer.gridColumns - 1) * wsSpacing) / overviewContainer.gridColumns)
            readonly property real maxWsWidthByH: Math.max(1, ((availableH * overviewContainer.overviewScale - (overviewContainer.gridRows - 1) * wsSpacing) / overviewContainer.gridRows) * (monitorWidth / monitorHeight))

            readonly property real wsWidth: Math.round(Math.min(maxWsWidthByW, maxWsWidthByH))
            readonly property real wsHeight: Math.round(wsWidth / (monitorWidth / monitorHeight))
            readonly property int totalWorkspaces: overviewContainer.gridRows * overviewContainer.gridColumns
            property int draggingTargetWorkspace: -1
            property int draggingFromWorkspace: -1

            Timer {
                id: grabDelayTimer
                interval: 50
                running: false
            }

            Connections {
                target: overviewContainer
                function onVisibleStateChanged() {
                    if (overviewContainer.visibleState) {
                        grabDelayTimer.restart();
                    } else {
                        grabDelayTimer.stop();
                    }
                }
            }

            HyprlandFocusGrab {
                id: focusGrab
                windows: [overviewPanel]
                active: !grabDelayTimer.running && (overviewContainer.visibleState || overviewPanel.isAnimating)
                onCleared: {
                    if (overviewContainer.visibleState && !grabDelayTimer.running)
                        overviewContainer.closeRequested();
                }
            }

            // === BACKDROP ===
            Rectangle {
                anchors.fill: parent
                color: "transparent"

                MouseArea {
                    anchors.fill: parent
                    onClicked: overviewContainer.closeRequested()
                }
            }

            // === OVERVIEW PANEL ===
            Primitives.SquircleMask {
                id: panelBackground
                property bool isBackgroundActive: overviewContainer.visibleState || (MorphState.openCount === 0 && MorphState.activeItem === panelBackground && panelBackground.width > 105)
                layer.enabled: true
                layer.smooth: true
                layer.samples: Vars.layerSamples

                anchors.top: (!Vars.pillPosition || Vars.pillPosition === "Top") ? parent.top : undefined
                anchors.bottom: Vars.pillPosition === "Bottom" ? parent.bottom : undefined
                anchors.left: Vars.pillPosition === "Left" ? parent.left : undefined
                anchors.right: Vars.pillPosition === "Right" ? parent.right : undefined
                anchors.horizontalCenter: (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") ? undefined : parent.horizontalCenter
                anchors.verticalCenter: (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") ? parent.verticalCenter : undefined

                property real targetWidth: workspaceGrid.implicitWidth + overviewPanel.bgPadding * 2
                property real targetHeight: workspaceGrid.implicitHeight + overviewPanel.bgPadding * 2
                
                property real innerMaxWidth: parent.width - (2 * Vars.spacingSmall)
                property bool touchesEdges: false

                property real activeMargin: (Vars.panelStyle === "Flat" || Vars.panelStyle === "Attached") ? 0 : Vars.spacingSmall
                anchors.topMargin: (!Vars.pillPosition || Vars.pillPosition === "Top") ? activeMargin : 0
                anchors.bottomMargin: Vars.pillPosition === "Bottom" ? activeMargin : 0
                anchors.leftMargin: Vars.pillPosition === "Left" ? activeMargin : 0
                anchors.rightMargin: Vars.pillPosition === "Right" ? activeMargin : 0

                width: overviewContainer.visibleState ? (touchesEdges ? innerMaxWidth : targetWidth) : (MorphState.anyExpanded ? MorphState.targetWidth : 100)
                height: overviewContainer.visibleState ? targetHeight : (MorphState.anyExpanded ? MorphState.targetHeight : 40)
                
                onTargetHeightChanged: {
                    if (overviewContainer.visibleState) MorphState.updateDimensions(panelBackground.targetWidth, panelBackground.targetHeight, panelBackground.defaultRadius);
                }
                
                onTargetWidthChanged: {
                    if (overviewContainer.visibleState) MorphState.updateDimensions(panelBackground.targetWidth, panelBackground.targetHeight, panelBackground.defaultRadius);
                }

                property real defaultRadius: overviewContainer.visibleState ? Vars.radiusExtraLarge : (MorphState.anyExpanded ? MorphState.targetRadius : height / 2)
                property real innerFrameRadius: Math.max(0, Vars.radiusExtraLarge - Vars.spacingSmall)

                topLeftRadius: touchesEdges ? innerFrameRadius : Vars.getTopLeftRadius(Vars.panelStyle, Vars.pillPosition, false, defaultRadius)
                topRightRadius: touchesEdges ? innerFrameRadius : Vars.getTopRightRadius(Vars.panelStyle, Vars.pillPosition, false, defaultRadius)
                bottomLeftRadius: touchesEdges ? 0 : Vars.getBottomLeftRadius(Vars.panelStyle, Vars.pillPosition, false, defaultRadius)
                bottomRightRadius: touchesEdges ? 0 : Vars.getBottomRightRadius(Vars.panelStyle, Vars.pillPosition, false, defaultRadius)

                color: Vars.tColorActive(isBackgroundActive, Theme.surface, Vars.panelOpacity)
                
                opacity: isBackgroundActive || expandedUI.opacity > 0 ? 1.0 : 0.0
                // visible: opacity > 0 // Removed to preserve Behavior when hidden
                
                Behavior on width {
                    enabled: !overviewContainer.gameMode
                    NumberAnimation {
                        id: wAnim
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.customExpressiveSpatialSlow
                    }
                }
                Behavior on height {
                    enabled: !overviewContainer.gameMode
                    NumberAnimation {
                        id: hAnim
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.customExpressiveSpatialSlow
                    }
                }

                Behavior on color {
                    enabled: !overviewContainer.gameMode
                    ColorAnimation {
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.customExpressiveSpatialSlow
                    }
                }

                Item {
                    id: expandedUI
                    anchors.fill: parent

                    opacity: overviewContainer.visibleState ? 1.0 : 0.0
                    visible: opacity > 0
                    clip: true
                    Behavior on opacity {
                        enabled: !overviewContainer.gameMode
                        NumberAnimation {
                            duration: Vars.animationDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Vars.getFadeCurve(overviewContainer.visibleState)
                        }
                    }

                    Item {
                        id: innerContainer
                        width: workspaceGrid.implicitWidth
                        height: workspaceGrid.implicitHeight

                        anchors.top: (!Vars.pillPosition || Vars.pillPosition === "Top") ? parent.top : undefined
                        anchors.bottom: Vars.pillPosition === "Bottom" ? parent.bottom : undefined
                        anchors.left: Vars.pillPosition === "Left" ? parent.left : undefined
                        anchors.right: Vars.pillPosition === "Right" ? parent.right : undefined
                        anchors.horizontalCenter: (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") ? undefined : parent.horizontalCenter
                        anchors.verticalCenter: (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") ? parent.verticalCenter : undefined

                        anchors.topMargin: (!Vars.pillPosition || Vars.pillPosition === "Top") ? overviewPanel.bgPadding : 0
                        anchors.bottomMargin: Vars.pillPosition === "Bottom" ? overviewPanel.bgPadding : 0
                        anchors.leftMargin: Vars.pillPosition === "Left" ? overviewPanel.bgPadding : 0
                        anchors.rightMargin: Vars.pillPosition === "Right" ? overviewPanel.bgPadding : 0

                        // === WORKSPACE GRID (background tiles only) ===
                        OC.WorkspaceGrid {
                            id: workspaceGrid
                            anchors.fill: parent
                            columns: overviewContainer.gridColumns
                            rows: overviewContainer.gridRows
                            totalWorkspaces: overviewPanel.totalWorkspaces
                            wsWidth: overviewPanel.wsWidth
                            wsHeight: overviewPanel.wsHeight
                            gameMode: overviewContainer.gameMode
                            overviewPanel: overviewPanel
                            rootContainer: overviewContainer
                            onCloseRequested: overviewContainer.closeRequested()
                        }

                        // === WINDOW LAYER (overlaid on top of workspace grid) ===
                        OC.WindowLayer {
                            id: windowLayer
                            anchors.fill: parent
                            overviewPanel: overviewPanel
                            rootContainer: overviewContainer
                            gameMode: overviewContainer ? overviewContainer.gameMode : false
                            onCloseRequested: overviewContainer.closeRequested()
                        }
                    }

                } // End of expandedUI
            } // End of panelBackground

            // === FRAME CORNERS ===
            InvertedCorner {
                anchors.top: panelBackground.top
                anchors.right: panelBackground.left
                side: "left"
                visible: Vars.panelStyle === "Attached" && panelBackground.opacity > 0 && (!Vars.pillPosition || Vars.pillPosition === "Top")
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: Math.max(0, Math.min(Vars.radiusExtraLarge, Math.min(panelBackground.width, panelBackground.height) / 2))
                antialiasing: true
            }

            InvertedCorner {
                anchors.top: panelBackground.top
                anchors.left: panelBackground.right
                side: "right"
                visible: Vars.panelStyle === "Attached" && panelBackground.opacity > 0 && (!Vars.pillPosition || Vars.pillPosition === "Top")
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: Math.max(0, Math.min(Vars.radiusExtraLarge, Math.min(panelBackground.width, panelBackground.height) / 2))
                antialiasing: true
            }

            InvertedCorner {
                anchors.bottom: panelBackground.bottom
                anchors.right: panelBackground.left
                side: "bottom-right"
                visible: Vars.panelStyle === "Attached" && panelBackground.opacity > 0 && Vars.pillPosition === "Bottom"
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: Math.max(0, Math.min(Vars.radiusExtraLarge, Math.min(panelBackground.width, panelBackground.height) / 2))
                antialiasing: true
            }

            InvertedCorner {
                anchors.bottom: panelBackground.bottom
                anchors.left: panelBackground.right
                side: "bottom-left"
                visible: Vars.panelStyle === "Attached" && panelBackground.opacity > 0 && Vars.pillPosition === "Bottom"
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: Math.max(0, Math.min(Vars.radiusExtraLarge, Math.min(panelBackground.width, panelBackground.height) / 2))
                antialiasing: true
            }

            InvertedCorner {
                anchors.bottom: panelBackground.top
                anchors.left: panelBackground.left
                side: "bottom-left"
                visible: Vars.panelStyle === "Attached" && panelBackground.opacity > 0 && Vars.pillPosition === "Left"
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: Math.max(0, Math.min(Vars.radiusExtraLarge, Math.min(panelBackground.width, panelBackground.height) / 2))
                antialiasing: true
            }

            InvertedCorner {
                anchors.top: panelBackground.bottom
                anchors.left: panelBackground.left
                side: "top-left"
                visible: Vars.panelStyle === "Attached" && panelBackground.opacity > 0 && Vars.pillPosition === "Left"
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: Math.max(0, Math.min(Vars.radiusExtraLarge, Math.min(panelBackground.width, panelBackground.height) / 2))
                antialiasing: true
            }

            InvertedCorner {
                anchors.bottom: panelBackground.top
                anchors.right: panelBackground.right
                side: "bottom-right"
                visible: Vars.panelStyle === "Attached" && panelBackground.opacity > 0 && Vars.pillPosition === "Right"
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: Math.max(0, Math.min(Vars.radiusExtraLarge, Math.min(panelBackground.width, panelBackground.height) / 2))
                antialiasing: true
            }

            InvertedCorner {
                anchors.top: panelBackground.bottom
                anchors.right: panelBackground.right
                side: "top-right"
                visible: Vars.panelStyle === "Attached" && panelBackground.opacity > 0 && Vars.pillPosition === "Right"
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: Math.max(0, Math.min(Vars.radiusExtraLarge, Math.min(panelBackground.width, panelBackground.height) / 2))
                antialiasing: true
            }

            // === KEYBOARD NAVIGATION ===
            Item {
                anchors.fill: parent
                focus: overviewContainer.visibleState

                Keys.onPressed: event => {
                    const cols = overviewContainer.gridColumns;
                    const total = overviewPanel.totalWorkspaces;

                    if (event.key === Qt.Key_Escape || event.key === Qt.Key_Return) {
                        overviewContainer.closeRequested();
                        event.accepted = true;
                    } else
                    // Number keys 1-9, 0=10
                    if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                        const ws = event.key - Qt.Key_0;
                        if (ws <= total) {
                            Hyprland.dispatch(`hl.dsp.focus({workspace = '${ws}'})`);
                            overviewContainer.closeRequested();
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_0) {
                        if (total >= 10) {
                            Hyprland.dispatch(`hl.dsp.focus({workspace = '10'})`);
                            overviewContainer.closeRequested();
                        }
                        event.accepted = true;
                    } else
                    // Arrow/vim navigation
                    if (event.key === Qt.Key_Left || (overviewContainer.vimKeysEnabled && (event.key === Qt.Key_H || event.key === Qt.Key_A)) ||
                        event.key === Qt.Key_Right || (overviewContainer.vimKeysEnabled && (event.key === Qt.Key_L || event.key === Qt.Key_F)) ||
                        event.key === Qt.Key_Up || (overviewContainer.vimKeysEnabled && (event.key === Qt.Key_K || event.key === Qt.Key_D)) ||
                        event.key === Qt.Key_Down || (overviewContainer.vimKeysEnabled && (event.key === Qt.Key_J || event.key === Qt.Key_S))) {
                        
                        const currentId = Hyprland.focusedWorkspace?.id ?? 1;
                        const baseId = Math.floor((currentId - 1) / total) * total + 1;
                        let currentIndex = overviewContainer.indexFromWsId(currentId, baseId);
                        
                        if (event.key === Qt.Key_Left || (overviewContainer.vimKeysEnabled && (event.key === Qt.Key_H || event.key === Qt.Key_A))) {
                            currentIndex = Math.max(0, currentIndex - 1);
                        } else if (event.key === Qt.Key_Right || (overviewContainer.vimKeysEnabled && (event.key === Qt.Key_L || event.key === Qt.Key_F))) {
                            currentIndex = Math.min(total - 1, currentIndex + 1);
                        } else if (event.key === Qt.Key_Up || (overviewContainer.vimKeysEnabled && (event.key === Qt.Key_K || event.key === Qt.Key_D))) {
                            currentIndex = Math.max(0, currentIndex - cols);
                        } else if (event.key === Qt.Key_Down || (overviewContainer.vimKeysEnabled && (event.key === Qt.Key_J || event.key === Qt.Key_S))) {
                            currentIndex = Math.min(total - 1, currentIndex + cols);
                        }
                        
                        const targetWs = overviewContainer.wsIdFromIndex(currentIndex, baseId);
                        Hyprland.dispatch(`hl.dsp.focus({workspace = '${targetWs}'})`);
                        event.accepted = true;
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "./Overview" as OC
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import "../theme"
import "../theme/variables.js" as Vars
import ".."
import Quickshell.Io

Item {
    id: overviewContainer
    property bool visibleState: false
    property bool gameMode: false
    signal closeRequested

    Process {
        id: gameModeChecker
        command: ["bash", "-c", "grep -qi 'GameMode[ \t]*=[ \t]*true' ~/.config/hypr/modules/variables.lua && echo 'true' || echo 'false'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                overviewContainer.gameMode = (this.text.trim() === 'true');
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
    readonly property int gridRows: Vars.overviewGridRows !== undefined ? Vars.overviewGridRows : 2
    readonly property int gridColumns: Vars.overviewGridColumns !== undefined ? Vars.overviewGridColumns : 5
    readonly property real overviewScale: Vars.overviewScale !== undefined ? Vars.overviewScale : 0.15

    Component.onCompleted: {
        console.log("OVERVIEW CONFIG LOADED:", gridRows, gridColumns, overviewScale, Vars.overviewGridRows);
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: overviewPanel
            required property var modelData

            property bool isAnimating: oAnim.running || wAnim.running || hAnim.running
            visible: overviewContainer.visibleState || isAnimating
            color: "transparent"

            WlrLayershell.namespace: "quickshell"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            


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

            HyprlandFocusGrab {
                id: focusGrab
                windows: [overviewPanel]
                active: overviewContainer.visibleState || overviewPanel.isAnimating
                onCleared: {
                    if (overviewContainer.visibleState)
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
            Rectangle {
                id: panelBackground
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: !overviewContainer.gameMode
                    shadowBlur: 1.0
                    shadowColor: Qt.rgba(0, 0, 0, 0.25)
                    shadowVerticalOffset: 4
                    shadowHorizontalOffset: 0
                }

                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter

                property real targetWidth: workspaceGrid.implicitWidth + overviewPanel.bgPadding * 2
                property real targetHeight: workspaceGrid.implicitHeight + overviewPanel.bgPadding * 2
                
                property real innerMaxWidth: parent.width - (2 * Vars.spacingSmall)
                property bool touchesEdges: Vars.panelStyle === "Framed" && targetWidth >= innerMaxWidth - 20

                anchors.topMargin: overviewContainer.gameMode || Vars.panelStyle === "Attached" || Vars.panelStyle === "Flat" ? 0 : Vars.spacingSmall

                width: overviewContainer.visibleState ? (touchesEdges ? innerMaxWidth : targetWidth) : 100
                height: overviewContainer.visibleState ? targetHeight : 40

                property real defaultRadius: overviewContainer.gameMode ? 0 : (overviewContainer.visibleState ? Vars.radiusExtraLarge : height / 2)
                property real innerFrameRadius: Math.max(0, Vars.radiusExtraLarge - Vars.spacingSmall)

                topLeftRadius: overviewContainer.gameMode || Vars.panelStyle === "Attached" ? 0 : (Vars.panelStyle === "Framed" ? (touchesEdges ? innerFrameRadius : 0) : defaultRadius)
                topRightRadius: overviewContainer.gameMode || Vars.panelStyle === "Attached" ? 0 : (Vars.panelStyle === "Framed" ? (touchesEdges ? innerFrameRadius : 0) : defaultRadius)
                bottomLeftRadius: overviewContainer.gameMode || touchesEdges ? 0 : defaultRadius
                bottomRightRadius: overviewContainer.gameMode || touchesEdges ? 0 : defaultRadius

                color: Vars.translucent ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.85) : Theme.surface
                
                opacity: overviewContainer.visibleState ? 1.0 : 0.0
                
                Behavior on topLeftRadius { enabled: !overviewContainer.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                Behavior on topRightRadius { enabled: !overviewContainer.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                Behavior on bottomLeftRadius { enabled: !overviewContainer.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                Behavior on bottomRightRadius { enabled: !overviewContainer.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

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
                Behavior on opacity {
                    enabled: !overviewContainer.gameMode
                    NumberAnimation {
                        id: oAnim
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: overviewContainer.visibleState ? Vars.customEmphasizedDecelerate : Vars.customEmphasizedAccelerate
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
                    anchors.centerIn: parent
                    width: workspaceGrid.implicitWidth
                    height: workspaceGrid.implicitHeight
                    
                    scale: Math.min(panelBackground.width / panelBackground.targetWidth, panelBackground.height / panelBackground.targetHeight)

                    opacity: overviewContainer.visibleState ? 1.0 : 0.0
                    visible: opacity > 0
                    Behavior on opacity {
                        enabled: !overviewContainer.gameMode
                        NumberAnimation {
                            duration: Vars.animationDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: overviewContainer.visibleState ? Vars.customEmphasizedDecelerate : Vars.customEmphasizedAccelerate
                        }
                    }

                    // === WORKSPACE GRID (background tiles only) ===
                    OC.WorkspaceGrid {
                        id: workspaceGrid
                        anchors.centerIn: parent
                        columns: overviewContainer.gridColumns
                        rows: overviewContainer.gridRows
                        totalWorkspaces: overviewPanel.totalWorkspaces
                        wsWidth: overviewPanel.wsWidth
                        wsHeight: overviewPanel.wsHeight
                        gameMode: overviewContainer.gameMode
                        overviewPanel: overviewPanel
                        onCloseRequested: overviewContainer.closeRequested()
                    }

                    // === WINDOW LAYER (overlaid on top of workspace grid) ===
                    OC.WindowLayer {
                        id: windowLayer
                        anchors.fill: parent
                        overviewContainer: overviewContainer
                        overviewPanel: overviewPanel
                        gameMode: overviewContainer ? overviewContainer.gameMode : false
                        onCloseRequested: overviewContainer.closeRequested()
                    }

                } // End of expandedUI
            } // End of panelBackground

            // === FRAME CORNERS ===
            InvertedCorner {
                anchors.top: panelBackground.top
                anchors.right: panelBackground.left
                side: "left"
                visible: Vars.panelStyle === "Framed" && !panelBackground.touchesEdges && overviewContainer.visibleState
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: panelBackground.innerFrameRadius
            }

            InvertedCorner {
                anchors.top: panelBackground.top
                anchors.left: panelBackground.right
                side: "right"
                visible: Vars.panelStyle === "Framed" && !panelBackground.touchesEdges && overviewContainer.visibleState
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: panelBackground.innerFrameRadius
            }

            InvertedCorner {
                anchors.top: panelBackground.bottom
                anchors.left: panelBackground.left
                side: "top-left"
                visible: Vars.panelStyle === "Framed" && panelBackground.touchesEdges && overviewContainer.visibleState
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: panelBackground.innerFrameRadius
            }

            InvertedCorner {
                anchors.top: panelBackground.bottom
                anchors.right: panelBackground.right
                side: "top-right"
                visible: Vars.panelStyle === "Framed" && panelBackground.touchesEdges && overviewContainer.visibleState
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: panelBackground.innerFrameRadius
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
                    if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                        const current = Hyprland.focusedWorkspace?.id ?? 1;
                        Hyprland.dispatch(`hl.dsp.focus({workspace = '${Math.max(1, current - 1)}'})`);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                        const current = Hyprland.focusedWorkspace?.id ?? 1;
                        Hyprland.dispatch(`hl.dsp.focus({workspace = '${Math.min(total, current + 1)}'})`);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                        const current = Hyprland.focusedWorkspace?.id ?? 1;
                        const target = current - cols;
                        if (target >= 1)
                            Hyprland.dispatch(`hl.dsp.focus({workspace = '${target}'})`);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                        const current = Hyprland.focusedWorkspace?.id ?? 1;
                        const target = current + cols;
                        if (target <= total)
                            Hyprland.dispatch(`hl.dsp.focus({workspace = '${target}'})`);
                        event.accepted = true;
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import "../Variables"
import "../Variables/variables.js" as Vars
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
    readonly property int gridRows: 2
    readonly property int gridColumns: 5
    readonly property real overviewScale: 0.15

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: overviewPanel
            required property var modelData

            property bool isAnimating: oAnim.running || wAnim.running || hAnim.running
            visible: overviewContainer.visibleState || isAnimating
            color: "transparent"

            WlrLayershell.namespace: "overview"
            WlrLayershell.layer: WlrLayer.Overlay
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
            readonly property real wsWidth: Math.round((monitorWidth / monitorScale) * overviewContainer.overviewScale)
            readonly property real wsHeight: Math.round((monitorHeight / monitorScale) * overviewContainer.overviewScale)
            readonly property real wsSpacing: 6
            readonly property real bgPadding: 12
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
                anchors.topMargin: overviewContainer.gameMode ? 0 : 5

                property real targetWidth: workspaceGrid.implicitWidth + overviewPanel.bgPadding * 2
                property real targetHeight: workspaceGrid.implicitHeight + overviewPanel.bgPadding * 2

                width: overviewContainer.visibleState ? targetWidth : 100
                height: overviewContainer.visibleState ? targetHeight : 40

                radius: overviewContainer.gameMode ? 0 : (overviewContainer.visibleState ? Vars.radiusExtraLarge : height / 2)
                color: Theme.surface_container_high
                
                opacity: overviewContainer.visibleState ? 1.0 : 0.0
                
                Behavior on radius {
                    enabled: !overviewContainer.gameMode
                    NumberAnimation {
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.m3ExpressiveSpatialSlow
                    }
                }
                Behavior on width {
                    enabled: !overviewContainer.gameMode
                    NumberAnimation {
                        id: wAnim
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.m3ExpressiveSpatialSlow
                    }
                }
                Behavior on height {
                    enabled: !overviewContainer.gameMode
                    NumberAnimation {
                        id: hAnim
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.m3ExpressiveSpatialSlow
                    }
                }
                Behavior on opacity {
                    enabled: !overviewContainer.gameMode
                    NumberAnimation {
                        id: oAnim
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: overviewContainer.visibleState ? Vars.m3StandardDecelerate : Vars.m3StandardAccelerate
                    }
                }

                Behavior on color {
                    enabled: !overviewContainer.gameMode
                    ColorAnimation {
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.m3ExpressiveSpatialSlow
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
                            easing.bezierCurve: overviewContainer.visibleState ? Vars.m3StandardDecelerate : Vars.m3StandardAccelerate
                        }
                    }

                    // === WORKSPACE GRID (background tiles only) ===
                    GridLayout {
                        id: workspaceGrid
                        anchors.centerIn: parent
                        columns: overviewContainer.gridColumns
                        rows: overviewContainer.gridRows
                        rowSpacing: overviewPanel.wsSpacing
                        columnSpacing: overviewPanel.wsSpacing

                        Repeater {
                            model: overviewPanel.totalWorkspaces

                            Item {
                                id: wsContainer
                                readonly property int wsId: index + 1
                                readonly property bool isFocused: Hyprland.focusedWorkspace?.id === wsId
                                property bool hoveredWhileDragging: false

                                Layout.preferredWidth: overviewPanel.wsWidth
                                Layout.preferredHeight: overviewPanel.wsHeight



                                Rectangle {
                                    id: wsTile
                                    anchors.fill: parent
                                    radius: Vars.radiusSmall
                                    clip: true

                                    color: wsContainer.hoveredWhileDragging ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.15) : wsContainer.isFocused ? Theme.primary_container : Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.06)
                                    border.width: (wsContainer.isFocused || wsContainer.hoveredWhileDragging) ? 2 : 0
                                    border.color: (wsContainer.isFocused || wsContainer.hoveredWhileDragging) ? Theme.on_primary_container : "transparent"

                                    Behavior on color {
                                        enabled: !overviewContainer.gameMode
                                        ColorAnimation {
                                            duration: Vars.animationDuration
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: Vars.m3ExpressiveSpatialFast
                                        }
                                    }
                                    Behavior on border.color {
                                        enabled: !overviewContainer.gameMode
                                        ColorAnimation {
                                            duration: Vars.animationDuration
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: Vars.m3ExpressiveSpatialFast
                                        }
                                    }

                                    // Workspace number watermark
                                    Text {
                                        anchors.centerIn: parent
                                        text: wsContainer.wsId
                                        font.family: Vars.fontFamily
                                        font.pixelSize: Math.round(overviewPanel.wsHeight * 0.6) | 0
                                        font.weight: 600
                                        color: wsContainer.isFocused ? Theme.on_primary_container : Theme.on_surface_variant
                                        opacity: 0.15
                                    }

                                    // Click workspace to switch
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Hyprland.dispatch(`hl.dsp.focus({workspace = '${wsContainer.wsId}'})`);
                                            overviewContainer.closeRequested();
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: wsTile.radius
                                            color: Theme.on_surface
                                            opacity: parent.containsMouse ? 0.08 : 0
                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: Vars.animationDuration
                                                }
                                            }
                                        }
                                    }

                                    // Drop target for drag-and-drop
                                    DropArea {
                                        anchors.fill: parent
                                        keys: ["window"]
                                        onEntered: {
                                            overviewPanel.draggingTargetWorkspace = wsContainer.wsId;
                                            if (overviewPanel.draggingFromWorkspace === wsContainer.wsId)
                                                return;
                                            wsContainer.hoveredWhileDragging = true;
                                        }
                                        onExited: {
                                            wsContainer.hoveredWhileDragging = false;
                                            if (overviewPanel.draggingTargetWorkspace === wsContainer.wsId)
                                                overviewPanel.draggingTargetWorkspace = -1;
                                        }
                                        onDropped: drop => {
                                            wsContainer.hoveredWhileDragging = false;
                                            overviewPanel.draggingTargetWorkspace = -1;
                                            const addr = drop.source.address;
                                            if (addr) {
                                                Hyprland.dispatch(`hl.dsp.window.move({workspace = '${wsContainer.wsId}', follow = false, window = 'address:${addr}'})`);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // === WINDOW LAYER (overlaid on top of workspace grid) ===
                    Item {
                        id: windowLayer
                        anchors.fill: parent

                        // Debug: log toplevel data on visibility change
                        onVisibleChanged: {
                            if (visible) {
                                const tpls = ToplevelManager.toplevels.values;
                                console.log("=== OVERVIEW DEBUG ===");
                                console.log("ToplevelManager.toplevels.values count:", tpls ? tpls.length : "null/undefined");
                                console.log("HyprlandData.windowList count:", HyprlandData.windowList.length);
                                console.log("HyprlandData.windowByAddress keys:", Object.keys(HyprlandData.windowByAddress).join(", "));
                                if (tpls && tpls.length > 0) {
                                    for (let i = 0; i < Math.min(tpls.length, 5); i++) {
                                        const t = tpls[i];
                                        const hyprAddr = t.HyprlandToplevel ? t.HyprlandToplevel.address : "NO_HYPRLAND_TOPLEVEL";
                                        console.log("  Toplevel", i, "appId:", t.appId, "address:", hyprAddr);
                                    }
                                }
                                console.log("=== END DEBUG ===");
                            }
                        }

                        Repeater {
                            model: ScriptModel {
                                values: {
                                    // Reactive dependencies
                                    const dummy = HyprlandData.windowList.length;
                                    const tpls = ToplevelManager.toplevels.values;
                                    if (!tpls || tpls.length === 0)
                                        return [];

                                    const result = tpls.filter(toplevel => {
                                        if (!toplevel)
                                            return false;
                                        // Try both with and without HyprlandToplevel
                                        let address = "";
                                        if (toplevel.HyprlandToplevel) {
                                            address = `0x${toplevel.HyprlandToplevel.address}`;
                                        } else {
                                            return false;
                                        }
                                        const win = HyprlandData.windowByAddress[address];
                                        if (!win || !win.workspace)
                                            return false;
                                        const wsId = win.workspace.id;
                                        return wsId >= 1 && wsId <= overviewPanel.totalWorkspaces;
                                    }).sort((a, b) => {
                                        const addrA = `0x${a.HyprlandToplevel.address}`;
                                        const addrB = `0x${b.HyprlandToplevel.address}`;
                                        const winA = HyprlandData.windowByAddress[addrA];
                                        const winB = HyprlandData.windowByAddress[addrB];
                                        if (winA?.floating !== winB?.floating)
                                            return winA?.floating ? 1 : -1;
                                        return (winB?.focusHistoryID ?? 0) - (winA?.focusHistoryID ?? 0);
                                    });
                                    return result;
                                }
                            }

                            delegate: Item {
                                id: winItem
                                required property var modelData
                                required property int index

                                property string address: `0x${modelData.HyprlandToplevel.address}`
                                property var winData: HyprlandData.windowByAddress[address]

                                // Which workspace cell does this window belong to?
                                property int wsId: winData?.workspace?.id ?? 1
                                property int wsRow: Math.floor((wsId - 1) / overviewContainer.gridColumns)
                                property int wsCol: (wsId - 1) % overviewContainer.gridColumns

                                // Grid cell origin (top-left corner of that workspace tile)
                                property real cellX: wsCol * (overviewPanel.wsWidth + overviewPanel.wsSpacing)
                                property real cellY: wsRow * (overviewPanel.wsHeight + overviewPanel.wsSpacing)

                                // Monitor geometry
                                property real monX: overviewPanel.hyprMonitor?.x ?? 0
                                property real monY: overviewPanel.hyprMonitor?.y ?? 0

                                // Window geometry relative to the monitor
                                property real winX: (winData?.at?.[0] ?? 0) - monX
                                property real winY: (winData?.at?.[1] ?? 0) - monY
                                property real winW: winData?.size?.[0] ?? 100
                                property real winH: winData?.size?.[1] ?? 100

                                // Scale from real monitor pixels to tile pixels
                                property real scaleX: overviewPanel.wsWidth / (overviewPanel.monitorWidth / overviewPanel.monitorScale)
                                property real scaleY: overviewPanel.wsHeight / (overviewPanel.monitorHeight / overviewPanel.monitorScale)

                                // Final position: cell origin + scaled window position within monitor
                                property real initX: Math.round(cellX + Math.max(0, winX * scaleX))
                                property real initY: Math.round(cellY + Math.max(0, winY * scaleY))

                                x: initX
                                y: initY
                                width: Math.round(Math.min(winW * scaleX, overviewPanel.wsWidth))
                                height: Math.round(Math.min(winH * scaleY, overviewPanel.wsHeight))
                                z: dragArea.drag.active ? 99999 : index

                                clip: true

                                property string windowAddress: address

                                // Drag is manually managed - do NOT bind Drag.active
                                Drag.keys: ["window"]
                                Drag.source: winItem
                                Drag.hotSpot.x: width / 2
                                Drag.hotSpot.y: height / 2

                                Component.onCompleted: {
                                    console.log("Window delegate created:", modelData.appId, "addr:", address, "wsId:", wsId, "pos:", Math.round(x), Math.round(y), "size:", Math.round(width), "x", Math.round(height));
                                }

                                // Opaque background behind preview
                                Rectangle {
                                    anchors.fill: parent
                                    radius: Vars.radiusMedium
                                    color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12)
                                    border.width: 1
                                    border.color: winItem.winData?.floating ? Theme.tertiary_container : Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.2)
                                }

                                // Live screen capture
                                ScreencopyView {
                                    id: preview
                                    anchors.fill: parent
                                    captureSource: winItem.modelData
                                    live: true
                                    layer.enabled: true
                                    layer.smooth: true
                                    layer.effect: MultiEffect {
                                        maskEnabled: true
                                        maskSource: previewMask
                                        maskThresholdMin: 0.5
                                        maskSpreadAtMin: 1.0
                                    }
                                }

                                // Mask for rounded corners
                                Item {
                                    id: previewMask
                                    anchors.fill: parent
                                    visible: false
                                    layer.enabled: true
                                    layer.smooth: true
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Vars.radiusMedium
                                    }
                                }

                                // Hover/press overlay + icon
                                Rectangle {
                                    anchors.fill: parent
                                    radius: Vars.radiusMedium
                                    color: dragArea.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.05)
                                    border.width: 1
                                    border.color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.1)

                                    // App icon centered over preview
                                    IconImage {
                                        anchors.centerIn: parent
                                        width: Math.min(parent.width, parent.height) * 0.35
                                        height: width
                                        source: Quickshell.iconPath(overviewContainer.resolveIcon(winItem.modelData.appId), "application-x-executable")
                                        asynchronous: false
                                    }
                                }

                                // Interaction: click to focus, middle-click to close, drag to move
                                MouseArea {
                                    id: dragArea
                                    property bool wasDragged: false
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                    cursorShape: Qt.PointingHandCursor
                                    drag.target: winItem

                                    onPressed: {
                                        wasDragged = false;
                                        overviewPanel.draggingFromWorkspace = winItem.wsId;
                                    }

                                    onPositionChanged: {
                                        if (drag.active && !wasDragged) {
                                            wasDragged = true;
                                            winItem.Drag.active = true;
                                        }
                                    }

                                    onClicked: mouse => {
                                        if (wasDragged)
                                            return;
                                        if (mouse.button === Qt.LeftButton) {
                                            Hyprland.dispatch(`hl.dsp.focus({ window = 'address:${winItem.address}' })`);
                                            overviewContainer.closeRequested();
                                        } else if (mouse.button === Qt.MiddleButton) {
                                            Hyprland.dispatch(`hl.dsp.window.close({ window = 'address:${winItem.address}' })`);
                                        }
                                    }

                                    onReleased: {
                                        const targetWs = overviewPanel.draggingTargetWorkspace;
                                        overviewPanel.draggingFromWorkspace = -1;

                                        if (wasDragged) {
                                            winItem.Drag.active = false;

                                            if (targetWs !== -1 && targetWs !== winItem.wsId) {
                                                Hyprland.dispatch(`hl.dsp.window.move({workspace = '${targetWs}', follow = false, window = 'address:${winItem.address}'})`);
                                            }
                                        }

                                        // Restore bindings so position reacts to workspace changes
                                        winItem.x = Qt.binding(function () {
                                            return winItem.initX;
                                        });
                                        winItem.y = Qt.binding(function () {
                                            return winItem.initY;
                                        });
                                    }
                                }
                            }
                        }
                    }

                    // === FOCUSED WORKSPACE INDICATOR ===
                    Rectangle {
                        id: focusedIndicator
                        readonly property int activeWsId: Hyprland.focusedWorkspace?.id ?? 1
                        readonly property int activeRow: Math.floor((activeWsId - 1) / overviewContainer.gridColumns)
                        readonly property int activeCol: (activeWsId - 1) % overviewContainer.gridColumns

                        x: Math.round(windowLayer.x + activeCol * (overviewPanel.wsWidth + overviewPanel.wsSpacing))
                        y: Math.round(windowLayer.y + activeRow * (overviewPanel.wsHeight + overviewPanel.wsSpacing))
                        width: Math.round(overviewPanel.wsWidth)
                        height: Math.round(overviewPanel.wsHeight)
                        z: 99999
                        color: "transparent"
                        radius: Vars.radiusSmall
                        border.width: 2
                        border.color: Theme.on_primary_container

                        visible: activeWsId >= 1 && activeWsId <= overviewPanel.totalWorkspaces

                        Behavior on x {
                            enabled: !overviewContainer.gameMode
                            NumberAnimation {
                                duration: Vars.animationDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Vars.m3ExpressiveSpatialFast
                            }
                        }
                        Behavior on y {
                            enabled: !overviewContainer.gameMode
                            NumberAnimation {
                                duration: Vars.animationDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Vars.m3ExpressiveSpatialFast
                            }
                        }
                    }
                } // End of expandedUI
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

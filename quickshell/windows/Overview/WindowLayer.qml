import QtQuick
import QtQuick.Effects
import Quickshell
import "../.."
import "../../theme"
import Quickshell.Io
import "../.."
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import "../../theme"
import "../../core/primitives" as Primitives

Item {
    id: root

    property var overviewPanel
    property var rootContainer
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false

    signal closeRequested

    // ==========================================
    // DUAL MONITOR WORKSPACE CALCULATION
    // ==========================================
    readonly property int baseWorkspaceId: {
        if (!overviewPanel || !overviewPanel.hyprMonitor || !overviewPanel.hyprMonitor.activeWorkspace)
            return 1;
        return Math.floor((overviewPanel.hyprMonitor.activeWorkspace.id - 1) / overviewPanel.totalWorkspaces) * overviewPanel.totalWorkspaces + 1;
    }

    Repeater {
        model: ScriptModel {
            values: {
                const dummy = HyprlandData.windowList.length;
                const tpls = ToplevelManager.toplevels.values;
                if (!tpls || tpls.length === 0)
                    return [];

                const result = tpls.filter(toplevel => {
                    if (!toplevel || !toplevel.HyprlandToplevel)
                        return false;

                    let rawAddr = toplevel.HyprlandToplevel.address.toString();
                    let address = rawAddr.startsWith("0x") ? rawAddr : `0x${rawAddr}`;

                    const win = HyprlandData.windowByAddress[address];
                    if (!win || !win.workspace)
                        return false;

                    let wsId = 1;
                    if (typeof win.workspace === 'object') {
                        wsId = win.workspace.id ?? 1;
                    } else if (typeof win.workspace === 'number') {
                        wsId = win.workspace;
                    }

                    return wsId >= baseWorkspaceId && wsId < (baseWorkspaceId + overviewPanel.totalWorkspaces);
                }).sort((a, b) => {
                    let rawA = a.HyprlandToplevel.address.toString();
                    let rawB = b.HyprlandToplevel.address.toString();
                    let addrA = rawA.startsWith("0x") ? rawA : `0x${rawA}`;
                    let addrB = rawB.startsWith("0x") ? rawB : `0x${rawB}`;

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

            property string rawAddress: modelData.HyprlandToplevel.address.toString()
            property string address: rawAddress.startsWith("0x") ? rawAddress : `0x${rawAddress}`
            property var winData: HyprlandData.windowByAddress[address]

            property int wsId: {
                if (!winData || !winData.workspace)
                    return 1;
                if (typeof winData.workspace === 'object')
                    return winData.workspace.id ?? 1;
                return winData.workspace;
            }

            property int safeCols: (rootContainer && rootContainer.gridColumns > 0) ? rootContainer.gridColumns : 5
            property int safeRows: (rootContainer && rootContainer.gridRows > 0) ? rootContainer.gridRows : 2
            property int localWsIndex: {
                let localWs = Math.max(0, wsId - baseWorkspaceId);
                let total = overviewPanel ? overviewPanel.totalWorkspaces : 10;
                if (!rootContainer || localWs >= total) return localWs;
                
                if (!rootContainer.isVertical) {
                    let logicalRow = Math.floor(localWs / safeCols);
                    let logicalCol = localWs % safeCols;
                    let visualRow = Vars.pillPosition === "Bottom" ? (safeRows - 1 - logicalRow) : logicalRow;
                    return visualRow * safeCols + logicalCol;
                }
                
                let logicalCol = Math.floor(localWs / safeRows);
                let logicalRow = localWs % safeRows;
                let visualCol = Vars.pillPosition === "Right" ? (safeCols - 1 - logicalCol) : logicalCol;
                return logicalRow * safeCols + visualCol;
            }
            property int wsRow: Math.floor(localWsIndex / safeCols)
            property int wsCol: localWsIndex % safeCols

            property real safeWsWidth: overviewPanel ? overviewPanel.wsWidth : 100
            property real safeWsSpacing: overviewPanel ? overviewPanel.wsSpacing : 6
            property real cellX: wsCol * (safeWsWidth + safeWsSpacing)
            property real cellY: wsRow * (overviewPanel ? overviewPanel.wsHeight + safeWsSpacing : 106)

            property real monX: overviewPanel?.hyprMonitor?.x ?? 0
            property real monY: overviewPanel?.hyprMonitor?.y ?? 0

            property real winX: (winData?.at && winData.at.length >= 2) ? (winData.at[0] - monX) : 0
            property real winY: (winData?.at && winData.at.length >= 2) ? (winData.at[1] - monY) : 0
            property real winW: (winData?.size && winData.size.length >= 2) ? winData.size[0] : 100
            property real winH: (winData?.size && winData.size.length >= 2) ? winData.size[1] : 100

            property real monitorWidthActual: (overviewPanel && overviewPanel.monitorWidth > 0) ? (overviewPanel.monitorWidth / overviewPanel.monitorScale) : 1920
            property real monitorHeightActual: (overviewPanel && overviewPanel.monitorHeight > 0) ? (overviewPanel.monitorHeight / overviewPanel.monitorScale) : 1080

            property real scaleX: safeWsWidth / monitorWidthActual
            property real scaleY: (overviewPanel ? overviewPanel.wsHeight : 100) / monitorHeightActual

            property real initX: Math.round(cellX + Math.max(0, winX * scaleX))
            property real initY: Math.round(cellY + Math.max(0, winY * scaleY))

            x: initX
            y: initY
            width: Math.max(10, Math.round(Math.min(winW * scaleX, safeWsWidth)))
            height: Math.max(10, Math.round(Math.min(winH * scaleY, overviewPanel ? overviewPanel.wsHeight : 100)))
            
            property bool isAnimatingPos: xAnim.running || yAnim.running
            z: (dragArea.drag.active || isAnimatingPos) ? 99999 : index
            clip: true

            Behavior on x {
                enabled: !root.gameMode && !dragArea.drag.active
                NumberAnimation { id: xAnim; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow }
            }
            Behavior on y {
                enabled: !root.gameMode && !dragArea.drag.active
                NumberAnimation { id: yAnim; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow }
            }

            property string windowAddress: address

            Drag.keys: ["window"]
            Drag.source: winItem
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2

            function getWinRadius(isOuterCorner, offsetX, offsetY) {
                if (!isOuterCorner) return Vars.radiusSmall;
                let offsetMargin = Math.max(0, Math.max(offsetX, offsetY));
                let p = (overviewPanel ? overviewPanel.bgPadding : 12) + offsetMargin;
                return Math.max(Vars.radiusSmall, Vars.radiusExtraLarge - p);
            }

            property real topLeftRadius: getWinRadius(wsRow === 0 && wsCol === 0, x - cellX, y - cellY)
            property real topRightRadius: getWinRadius(wsRow === 0 && wsCol === safeCols - 1, (cellX + safeWsWidth) - (x + width), y - cellY)
            property real bottomLeftRadius: getWinRadius(wsRow === safeRows - 1 && wsCol === 0, x - cellX, (cellY + (overviewPanel ? overviewPanel.wsHeight : 100)) - (y + height))
            property real bottomRightRadius: getWinRadius(wsRow === safeRows - 1 && wsCol === safeCols - 1, (cellX + safeWsWidth) - (x + width), (cellY + (overviewPanel ? overviewPanel.wsHeight : 100)) - (y + height))

            // Background behind preview
            Primitives.SquircleMask {
                anchors.fill: parent
                topLeftRadius: winItem.topLeftRadius
                topRightRadius: winItem.topRightRadius
                bottomLeftRadius: winItem.bottomLeftRadius
                bottomRightRadius: winItem.bottomRightRadius
                color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12)
            }

            // Mask shape rendered to its own texture via ShaderEffectSource, the same technique
            // every other mask in this codebase uses (MediaPlayer's rootMask, GameLibrary's
            // clipMask, etc). The previous approach — layer.enabled directly on a SquircleMask,
            // which is itself built from an inner layered Rectangle/Shape — double-layers and
            // doesn't reliably produce a usable mask texture, so the live preview rendered with
            // hard rectangular corners instead of matching the tile's rounding.
            Primitives.SquircleMask {
                id: previewMaskShape
                anchors.fill: parent
                topLeftRadius: winItem.topLeftRadius
                topRightRadius: winItem.topRightRadius
                bottomLeftRadius: winItem.bottomLeftRadius
                bottomRightRadius: winItem.bottomRightRadius
                color: "white"
                visible: true // kept visible; hidden from the scene by the ShaderEffectSource below
            }

            ShaderEffectSource {
                id: previewMask
                sourceItem: previewMaskShape
                anchors.fill: parent
                hideSource: true
                visible: false
                // Oversample so small corner radii (inner grid tiles use Vars.radiusSmall, just
                // a few px) survive the mask texture at full crispness instead of being smoothed
                // away — the same fix MediaPlayer.qml's maskContainer already uses for this.
                textureSize: Qt.size(Math.max(1, width) * 2, Math.max(1, height) * 2)
            }

            // Live screen capture
            ScreencopyView {
                id: preview
                anchors.fill: parent
                captureSource: (rootContainer && rootContainer.visibleState) ? winItem.modelData : null
                live: rootContainer && rootContainer.visibleState
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: preview
                maskEnabled: true
                maskSource: previewMask
                maskThresholdMin: 0.0
                maskSpreadAtMin: 1.0
            }

            // Simple Hover interaction overlay
            Primitives.SquircleMask {
                anchors.fill: parent
                topLeftRadius: winItem.topLeftRadius
                topRightRadius: winItem.topRightRadius
                bottomLeftRadius: winItem.bottomLeftRadius
                bottomRightRadius: winItem.bottomRightRadius
                color: dragArea.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : "transparent"
            }

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
                        root.closeRequested();
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

    // === FOCUSED WORKSPACE INDICATOR ===
    Rectangle {
        antialiasing: true
        id: focusedIndicator
        readonly property int activeWsId: Hyprland.focusedWorkspace?.id ?? 1
        readonly property int safeCols: (rootContainer && rootContainer.gridColumns > 0) ? rootContainer.gridColumns : 5
        readonly property int safeRows: (rootContainer && rootContainer.gridRows > 0) ? rootContainer.gridRows : 2
        readonly property int localActiveIndex: {
            let localWs = Math.max(0, activeWsId - baseWorkspaceId);
            let total = overviewPanel ? overviewPanel.totalWorkspaces : 10;
            if (!rootContainer || localWs >= total) return localWs;
            
            if (!rootContainer.isVertical) {
                let logicalRow = Math.floor(localWs / safeCols);
                let logicalCol = localWs % safeCols;
                let visualRow = Vars.pillPosition === "Bottom" ? (safeRows - 1 - logicalRow) : logicalRow;
                return visualRow * safeCols + logicalCol;
            }
            
            let logicalCol = Math.floor(localWs / safeRows);
            let logicalRow = localWs % safeRows;
            let visualCol = Vars.pillPosition === "Right" ? (safeCols - 1 - logicalCol) : logicalCol;
            return logicalRow * safeCols + visualCol;
        }
        readonly property int activeRow: rootContainer ? Math.floor(localActiveIndex / rootContainer.gridColumns) : 0
        readonly property int activeCol: rootContainer ? localActiveIndex % rootContainer.gridColumns : 0

        x: Math.round(root.x + activeCol * (overviewPanel.wsWidth + overviewPanel.wsSpacing))
        y: Math.round(root.y + activeRow * (overviewPanel.wsHeight + overviewPanel.wsSpacing))
        width: Math.round(overviewPanel.wsWidth)
        height: Math.round(overviewPanel.wsHeight)
        z: 99999
        color: "transparent"
        property real rOuter: Math.max(0, Vars.radiusExtraLarge - overviewPanel.bgPadding)
        property real rInner: Vars.radiusSmall
        topLeftRadius: (activeRow === 0 && activeCol === 0) ? rOuter : rInner
        topRightRadius: (activeRow === 0 && activeCol === safeCols - 1) ? rOuter : rInner
        bottomLeftRadius: (activeRow === safeRows - 1 && activeCol === 0) ? rOuter : rInner
        bottomRightRadius: (activeRow === safeRows - 1 && activeCol === safeCols - 1) ? rOuter : rInner
        border.width: 2
        border.color: Theme.primary

        visible: activeWsId >= baseWorkspaceId && activeWsId < (baseWorkspaceId + (overviewPanel ? overviewPanel.totalWorkspaces : 10))

        Behavior on x {
            enabled: !root.gameMode
            NumberAnimation {
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customExpressiveSpatialSlow
            }
        }
        Behavior on y {
            enabled: !root.gameMode
            NumberAnimation {
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customExpressiveSpatialSlow
            }
        }
    }
}

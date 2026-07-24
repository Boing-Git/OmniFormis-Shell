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
import "../../theme/variables.js" as Vars

Item {
    id: root

    property var overviewContainer
    property var overviewPanel
    property bool gameMode: false

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

            property int safeCols: (overviewContainer && overviewContainer.gridColumns > 0) ? overviewContainer.gridColumns : 5
            property int localWsIndex: Math.max(0, (wsId - 1) % (overviewPanel ? overviewPanel.totalWorkspaces : 10))
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
            z: dragArea.drag.active ? 99999 : index
            clip: true

            property string windowAddress: address

            Drag.keys: ["window"]
            Drag.source: winItem
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2

            // Background behind preview
            Rectangle {
                anchors.fill: parent
                radius: Vars.radiusMedium
                color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12)
                border.width: 1
                border.color: winItem.winData?.floating ? Theme.tertiary_container : Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.2)
            }

            // Live screen capture - FORCED ON for all workspaces
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

            // Simple Hover interaction overlay (ICONS COMPLETELY REMOVED)
            Rectangle {
                anchors.fill: parent
                radius: Vars.radiusMedium
                color: dragArea.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : "transparent"
                border.width: 1
                border.color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.1)
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
        id: focusedIndicator
        readonly property int activeWsId: Hyprland.focusedWorkspace?.id ?? 1
        readonly property int localActiveIndex: Math.max(0, (activeWsId - 1) % (overviewPanel ? overviewPanel.totalWorkspaces : 10))
        readonly property int activeRow: overviewContainer ? Math.floor(localActiveIndex / overviewContainer.gridColumns) : 0
        readonly property int activeCol: overviewContainer ? localActiveIndex % overviewContainer.gridColumns : 0

        x: Math.round(root.x + activeCol * (overviewPanel.wsWidth + overviewPanel.wsSpacing))
        y: Math.round(root.y + activeRow * (overviewPanel.wsHeight + overviewPanel.wsSpacing))
        width: Math.round(overviewPanel.wsWidth)
        height: Math.round(overviewPanel.wsHeight)
        z: 99999
        color: "transparent"
        radius: Vars.radiusSmall
        border.width: 2
        border.color: Theme.on_primary_container

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

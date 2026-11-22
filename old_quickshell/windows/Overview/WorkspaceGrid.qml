import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."
import "../../theme"
import "../../core/primitives" as Primitives
import Quickshell.Hyprland

GridLayout {
    id: root

    property int totalWorkspaces: 10
    property real wsWidth: 100
    property real wsHeight: 100
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false

    property var overviewPanel
    property var rootContainer

    signal closeRequested

    // ==========================================
    // DUAL MONITOR WORKSPACE CALCULATION
    // ==========================================
    readonly property int baseWorkspaceId: {
        if (!overviewPanel || !overviewPanel.hyprMonitor || !overviewPanel.hyprMonitor.activeWorkspace)
            return 1;
        return Math.floor((overviewPanel.hyprMonitor.activeWorkspace.id - 1) / root.totalWorkspaces) * root.totalWorkspaces + 1;
    }

    rowSpacing: overviewPanel.wsSpacing
    columnSpacing: overviewPanel.wsSpacing

    Repeater {
        model: root.totalWorkspaces

        Item {
            id: wsContainer
            readonly property int visualCol: index % (rootContainer ? rootContainer.gridColumns : 5)
            readonly property int visualRow: Math.floor(index / (rootContainer ? rootContainer.gridColumns : 5))
            readonly property int wsId: {
                if (!rootContainer) return root.baseWorkspaceId + index;
                if (!rootContainer.isVertical) {
                    let mappedRow = Vars.pillPosition === "Bottom" ? (rootContainer.gridRows - 1 - visualRow) : visualRow;
                    return root.baseWorkspaceId + (mappedRow * rootContainer.gridColumns + visualCol);
                }
                let mappedCol = Vars.pillPosition === "Right" ? (rootContainer.gridColumns - 1 - visualCol) : visualCol;
                return root.baseWorkspaceId + (mappedCol * rootContainer.gridRows + visualRow);
            }
            readonly property bool isFocused: Hyprland.focusedWorkspace?.id === wsId
            property bool hoveredWhileDragging: false

            Layout.preferredWidth: root.wsWidth
            Layout.preferredHeight: root.wsHeight

            Primitives.SquircleMask {
                id: wsTile
                anchors.fill: parent
                property real rOuter: Math.max(0, Vars.radiusExtraLarge - overviewPanel.bgPadding)
                property real rInner: Vars.radiusSmall

                topLeftRadius: (wsContainer.visualRow === 0 && wsContainer.visualCol === 0) ? rOuter : rInner
                topRightRadius: (wsContainer.visualRow === 0 && wsContainer.visualCol === (rootContainer ? rootContainer.gridColumns : 5) - 1) ? rOuter : rInner
                bottomLeftRadius: (wsContainer.visualRow === (rootContainer ? rootContainer.gridRows : 2) - 1 && wsContainer.visualCol === 0) ? rOuter : rInner
                bottomRightRadius: (wsContainer.visualRow === (rootContainer ? rootContainer.gridRows : 2) - 1 && wsContainer.visualCol === (rootContainer ? rootContainer.gridColumns : 5) - 1) ? rOuter : rInner
                clip: true

                color: wsContainer.hoveredWhileDragging ? (Vars.tColor(Theme.on_surface, Vars.componentOpacity)) : wsContainer.isFocused ? (Vars.tColorSelected(Theme.primary)) : (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity))
                // border.width: (wsContainer.isFocused || wsContainer.hoveredWhileDragging) ? 2 : 0
                // border.color: (wsContainer.isFocused || wsContainer.hoveredWhileDragging) ? Theme.primary : "transparent"

                Behavior on color {
                    enabled: !root.gameMode
                    ColorAnimation {
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.customExpressiveSpatialSlow
                    }
                }


                // Workspace number watermark
                QsText {
                    anchors.centerIn: parent
                    text: wsContainer.wsId
                    font.family: Vars.fontFamily
                    font.pixelSize: Math.round(root.wsHeight * 0.6) | 0
                    setWeight: 600
                    color: wsContainer.isFocused ? Theme.on_primary : Theme.on_surface_variant
                    opacity: wsContainer.isFocused ? 0.85 : 0.15
                }

                // Click workspace to switch
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Hyprland.dispatch(`hl.dsp.focus({workspace = '${wsContainer.wsId}'})`);
                        root.closeRequested();
                    }

                    Primitives.SquircleMask {
                        anchors.fill: parent
                        topLeftRadius: wsTile.topLeftRadius
                        topRightRadius: wsTile.topRightRadius
                        bottomLeftRadius: wsTile.bottomLeftRadius
                        bottomRightRadius: wsTile.bottomRightRadius
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
                        root.overviewPanel.draggingTargetWorkspace = wsContainer.wsId;
                        if (root.overviewPanel.draggingFromWorkspace === wsContainer.wsId)
                            return;
                        wsContainer.hoveredWhileDragging = true;
                    }
                    onExited: {
                        wsContainer.hoveredWhileDragging = false;
                        if (root.overviewPanel.draggingTargetWorkspace === wsContainer.wsId)
                            root.overviewPanel.draggingTargetWorkspace = -1;
                    }
                    onDropped: drop => {
                        wsContainer.hoveredWhileDragging = false;
                        root.overviewPanel.draggingTargetWorkspace = -1;
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

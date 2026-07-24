import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."
import "../../theme"
import "../.."
import Quickshell.Hyprland
import "../../theme/variables.js" as Vars

GridLayout {
    id: root

    property int totalWorkspaces: 10
    property real wsWidth: 100
    property real wsHeight: 100
    property bool gameMode: false

    property var overviewPanel

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
            // Adjusted wsId to apply the base offset (e.g. index 0 becomes Workspace 11 on Monitor 2)
            readonly property int wsId: root.baseWorkspaceId + index
            readonly property bool isFocused: Hyprland.focusedWorkspace?.id === wsId
            property bool hoveredWhileDragging: false

            Layout.preferredWidth: root.wsWidth
            Layout.preferredHeight: root.wsHeight

            Rectangle {
                id: wsTile
                anchors.fill: parent
                radius: Vars.radiusSmall
                clip: true

                color: wsContainer.hoveredWhileDragging ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.15) : wsContainer.isFocused ? "#429be1" : Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.06)
                border.width: (wsContainer.isFocused || wsContainer.hoveredWhileDragging) ? 2 : 0
                border.color: (wsContainer.isFocused || wsContainer.hoveredWhileDragging) ? "#429be1" : "transparent"

                Behavior on color {
                    enabled: !root.gameMode
                    ColorAnimation {
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.customExpressiveSpatialSlow
                    }
                }
                Behavior on border.color {
                    enabled: !root.gameMode
                    ColorAnimation {
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.customExpressiveSpatialSlow
                    }
                }

                // Workspace number watermark
                Text {
                    anchors.centerIn: parent
                    text: wsContainer.wsId
                    font.family: Vars.fontFamily
                    font.pixelSize: Math.round(root.wsHeight * 0.6) | 0
                    font.weight: 600
                    color: wsContainer.isFocused ? "#ffffff" : Theme.on_surface_variant
                    opacity: wsContainer.isFocused ? 0.35 : 0.15
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

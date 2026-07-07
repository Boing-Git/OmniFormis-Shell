import QtQuick
import QtQuick.Effects
import ".."
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../Variables/variables.js" as Vars

Item {
    id: mainContainer

    width: bg.width
    height: 40

    property bool gameMode: false

    property var currentWorkspace: Hyprland.focusedWorkspace
    property int activeWsId: currentWorkspace ? currentWorkspace.id : 1
    property int currentPage: Math.floor(Math.max(0, activeWsId - 1) / 5)

    // Overlay visibility for morph effect
    property bool overlayVisible: false
    Timer {
        id: overlayTimer
        interval: 2000
        repeat: false
        onTriggered: overlayVisible = false
    }

    // When the focused workspace changes, show overlay briefly
    onCurrentWorkspaceChanged: {
        overlayVisible = true
        overlayTimer.restart()
    }

    function handleScroll(delta) {
        let nextWs = activeWsId;
        if (delta > 0) {
            nextWs = Math.max(1, activeWsId - 1);
        } else if (delta < 0) {
            nextWs = activeWsId + 1;
        }
        if (nextWs !== activeWsId) {
            Hyprland.dispatch("hl.dsp.focus { workspace = " + nextWs + " }");
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            handleScroll(wheel.angleDelta.y);
        }
    }

    Rectangle {
        id: bg
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: !mainContainer.gameMode; shadowBlur: 1.0; shadowColor: Qt.rgba(0,0,0,0.25); shadowVerticalOffset: 4; shadowHorizontalOffset: 0 }
        anchors.centerIn: parent
        color: Theme.primary
        radius: height / 2
        clip: true
        opacity: overlayVisible ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { enabled: !mainContainer.gameMode; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        width: overlayVisible ? workspaceLayout.implicitWidth + Vars.spacingLarge : 100
        height: 40
        Behavior on width { enabled: !mainContainer.gameMode; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        RowLayout {
            id: workspaceLayout
            anchors.centerIn: parent
            spacing: Vars.spacingSmall / 2

            Repeater {
                model: 5
                delegate: Rectangle {
                    id: wsItem
                    readonly property int wsId: (mainContainer.currentPage * 5) + index + 1
                    property bool isFocused: Hyprland.focusedWorkspace?.id === wsId

                    radius: height / 2
                    implicitWidth: isFocused ? 50 : 32
                    implicitHeight: 32

                    Behavior on implicitWidth {
                        enabled: !mainContainer.gameMode
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Vars.m3ExpressiveSpatialFast
                        }
                    }

                    color: isFocused ? Theme.primary_container : (wsMouseArea.pressed ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.12) : (wsMouseArea.containsMouse ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08) : "transparent"))

                    Behavior on color {
                        enabled: !mainContainer.gameMode
                        ColorAnimation {
                            duration: 250
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Vars.m3ExpressiveSpatialFast
                        }
                    }

                    Text {
                        font.family: Vars.fontFamily
                        font.pixelSize: 14
                        font.weight: isFocused ? 600 : 500
                        anchors.centerIn: parent
                        text: wsId

                        color: isFocused ? Theme.on_primary_container : Theme.on_primary
                        opacity: isFocused ? 1.0 : 0.5
                    }
                    MouseArea {
                        id: wsMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Hyprland.dispatch("hl.dsp.focus { workspace = " + wsId + " }");
                        }
                    }
                }
            }
        }
    }
}

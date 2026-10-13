import QtQuick
import QtQuick.Effects
import ".."
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../theme"
import "../core/primitives" as Primitives
Item {
    id: mainContainer

    property bool isVertical: Vars.pillPosition === "Left" || Vars.pillPosition === "Right"
    width: isVertical ? 40 : (overlayVisible ? workspaceLayout.implicitWidth + Vars.spacingLarge : 100)
    height: isVertical ? (overlayVisible ? workspaceLayout.implicitHeight + Vars.spacingLarge : 100) : Vars.clockPillThickness

    Behavior on width {
        enabled: !mainContainer.gameMode
        NumberAnimation {
            duration: Vars.animationDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Vars.customExpressiveSpatialSlow
        }
    }
    Behavior on height {
        enabled: !mainContainer.gameMode
        NumberAnimation {
            duration: Vars.animationDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Vars.customExpressiveSpatialSlow
        }
    }

    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false
    property bool forceHidePill: false
    property alias panel: bg
    property alias panelMask: panelMask

    // Emitted when the workspace pill becomes visible so TopPills can close other panels
    signal requestCloseAll

    Item {
        id: panelMask
        anchors.centerIn: bg
        width: (overlayVisible && !mainContainer.forceHidePill) ? (bg.width + 40) : 0
        height: (overlayVisible && !mainContainer.forceHidePill) ? (bg.height + 40) : 0
    }

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

    // Dismiss the workspace overlay (called by TopPills.closeAll)
    function cancelOverlay() {
        overlayTimer.stop();
        overlayVisible = false;
    }

    // When the focused workspace changes, show overlay briefly
    onCurrentWorkspaceChanged: {
        overlayVisible = true;
        overlayTimer.restart();
        // Only request other panels to close when the pill will actually be visible
        if (!forceHidePill) {
            requestCloseAll();
        }
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
        // Only active while the overlay is open; otherwise it sits over the clock pill
        // position and steals hover from TopPills' clockHoverZone (breaks Auto Hide).
        enabled: mainContainer.overlayVisible
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            handleScroll(wheel.angleDelta.y);
        }
    }

    Primitives.SquircleMask {
        id: bg
        layer.enabled: false
        layer.samples: Vars.layerSamples
        anchors.fill: parent
        color: Vars.tColor(Theme.surface, Vars.panelOpacity)
        property real targetRad: Math.min(mainContainer.width, mainContainer.height) / 2
        topLeftRadius: Vars.getTopLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        topRightRadius: Vars.getTopRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomLeftRadius: Vars.getBottomLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomRightRadius: Vars.getBottomRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)

        opacity: (overlayVisible && !mainContainer.forceHidePill) ? (Vars.isTranslucent() ? 0.85 : 1.0) : 0.0
        visible: opacity > 0
        Behavior on opacity {
            enabled: !mainContainer.gameMode
            NumberAnimation {
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customStandard
            }
        }
    }

    GridLayout {
        id: workspaceLayout
        anchors.centerIn: bg
        columns: mainContainer.isVertical ? 1 : 5
        rows: mainContainer.isVertical ? 5 : 1
        rowSpacing: Vars.spacingSmall / 2
        columnSpacing: Vars.spacingSmall / 2
        opacity: (overlayVisible && !mainContainer.forceHidePill) ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity {
            enabled: !mainContainer.gameMode
            NumberAnimation {
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customStandard
            }
        }

        Repeater {
            model: 5
            delegate: Primitives.SquircleMask {
                id: wsItem
                readonly property int wsId: (mainContainer.currentPage * 5) + index + 1
                property bool isFocused: Hyprland.focusedWorkspace?.id === wsId

                property real targetRad: Math.min(width, height) / 2
                topLeftRadius: targetRad
                topRightRadius: targetRad
                bottomLeftRadius: targetRad
                bottomRightRadius: targetRad
                // Scaled to the same ratio ClockPill grew by (Vars.clockPillThickness / the old
                // fixed 40px pill height), so the dots fill the taller pill instead of leaving
                // a lot of empty padding around unchanged 32/50px dots.
                readonly property real sizeScale: Vars.clockPillThickness / 40
                implicitWidth: mainContainer.isVertical ? 32 * sizeScale : (isFocused ? 50 * sizeScale : 32 * sizeScale)
                implicitHeight: mainContainer.isVertical ? (isFocused ? 50 * sizeScale : 32 * sizeScale) : 32 * sizeScale

                Behavior on implicitWidth {
                    enabled: !mainContainer.gameMode
                    NumberAnimation {
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.customExpressiveSpatialSlow
                    }
                }
                Behavior on implicitHeight {
                    enabled: !mainContainer.gameMode
                    NumberAnimation {
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.customExpressiveSpatialSlow
                    }
                }

                color: isFocused ? Vars.tColor(Theme.primary, 0.85) : (wsMouseArea.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (wsMouseArea.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent"))

                Behavior on color {
                    enabled: !mainContainer.gameMode
                    ColorAnimation {
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.customStandard
                    }
                }

                QsText {
                    font.family: Vars.fontFamily
                    font.pixelSize: 14 * wsItem.sizeScale
                    setWeight: isFocused ? 600 : 500
                    anchors.centerIn: parent
                    text: wsId

                    color: isFocused ? Theme.on_primary : Theme.on_surface_variant
                    opacity: isFocused ? 1.0 : 0.5

                    Behavior on color {
                        enabled: !mainContainer.gameMode
                        ColorAnimation {
                            duration: Vars.animationDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Vars.customStandard
                        }
                    }
                }

                MouseArea {
                    id: wsMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        Hyprland.dispatch("hl.dsp.focus { workspace = " + wsId + " }");
                    }
                }
            }
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Wayland
import QtCore
import "../.."
import "../../theme"

PanelWindow {
    id: window
    color: "transparent"
    property bool calenderEnabled: Vars.desktopCalenderEnabled !== undefined ? Vars.desktopCalenderEnabled : false
    property bool anchorEnabled: Vars.desktopCalenderAnchorEnabled !== undefined ? Vars.desktopCalenderAnchorEnabled : false
    property string anchorPoint: Vars.desktopCalenderAnchorPoint !== undefined ? Vars.desktopCalenderAnchorPoint : "Center"
    property int anchorCurve: Vars.desktopCalenderAnchorCurve !== undefined ? Vars.desktopCalenderAnchorCurve : 0
    property string maskShape: Vars.wallpaperMaskShape !== undefined ? Vars.wallpaperMaskShape : "9SidedCookie"
    property real maskScale: Vars.wallpaperMaskScale !== undefined ? Vars.wallpaperMaskScale : 1.05
    property int maskOffsetX: Vars.wallpaperMaskOffsetX !== undefined ? Vars.wallpaperMaskOffsetX : 0
    property int maskOffsetY: Vars.wallpaperMaskOffsetY !== undefined ? Vars.wallpaperMaskOffsetY : 0
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false
    property bool active: window.calenderEnabled && !window.gameMode

    visible: window.active

    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Bottom
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    mask: Region {
        item: clockContainer
    }

    Settings {
        id: clockSettings
        category: "DesktopCalender_" + (window.screen ? window.screen.name : "")
        property int posX: 500
        property int posY: 100
    }

    M3Shapes { id: m3 }
    property var peaks: m3.getShapePeaks(window.maskShape)

    property int computedX: {
        if (window.anchorEnabled && window.anchorCurve >= 0 && window.anchorCurve < peaks.length) {
            var peak = peaks[window.anchorCurve];
            var maskSize = Math.min(window.width, window.height) * window.maskScale;
            var centerX = window.width / 2 + window.maskOffsetX;
            var targetX = centerX - maskSize / 2 + (peak.x / 100.0) * maskSize;
            
            var widgetX = targetX;
            var pt = window.anchorPoint;
            if (pt === "TopCenter" || pt === "Center" || pt === "BottomCenter") widgetX -= clockContainer.width / 2;
            else if (pt === "TopRight" || pt === "MiddleRight" || pt === "BottomRight") widgetX -= clockContainer.width;
            return widgetX;
        }
        return clockSettings.posX;
    }

    property int computedY: {
        if (window.anchorEnabled && window.anchorCurve >= 0 && window.anchorCurve < peaks.length) {
            var peak = peaks[window.anchorCurve];
            var maskSize = Math.min(window.width, window.height) * window.maskScale;
            var centerY = window.height / 2 + window.maskOffsetY;
            var targetY = centerY - maskSize / 2 + (peak.y / 100.0) * maskSize;
            
            var widgetY = targetY;
            var pt = window.anchorPoint;
            if (pt === "MiddleLeft" || pt === "Center" || pt === "MiddleRight") widgetY -= clockContainer.height / 2;
            else if (pt === "BottomLeft" || pt === "BottomCenter" || pt === "BottomRight") widgetY -= clockContainer.height;
            return widgetY;
        }
        return clockSettings.posY;
    }

    Item {
        id: clockContainer
        // Calender is a fixed 320x320, so this doesn't need to read it back from the Loader
        // (whose .item is null while inactive, i.e. in game mode)
        width: 320
        height: 320
        x: computedX
        y: computedY

        Behavior on x { enabled: window.anchorEnabled; NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: window.anchorEnabled; NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

        Loader {
            anchors.centerIn: parent
            active: window.active
            sourceComponent: Calender {}
        }

        DragHandler {
            id: dragHandler
            target: clockContainer
            enabled: !window.anchorEnabled

            xAxis.minimum: 0
            xAxis.maximum: window.width > 0 ? window.width - clockContainer.width : 9999
            yAxis.minimum: 0
            yAxis.maximum: window.height > 0 ? window.height - clockContainer.height : 9999

            onActiveChanged: {
                if (!active) {
                    clockSettings.posX = clockContainer.x;
                    clockSettings.posY = clockContainer.y;
                }
            }
        }
    }
}

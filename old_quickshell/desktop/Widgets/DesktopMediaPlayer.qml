import QtQuick
import Quickshell
import Quickshell.Wayland
import QtCore
import "../.."
import "../../panels/ControlCenter" as CC
import "../../theme"

PanelWindow {
    id: window
    color: "transparent"
    property bool playerEnabled: Vars.desktopMediaPlayerEnabled !== undefined ? Vars.desktopMediaPlayerEnabled : false
    property bool anchorEnabled: Vars.desktopMediaPlayerAnchorEnabled !== undefined ? Vars.desktopMediaPlayerAnchorEnabled : false
    property string anchorPoint: Vars.desktopMediaPlayerAnchorPoint !== undefined ? Vars.desktopMediaPlayerAnchorPoint : "Center"
    property int anchorCurve: Vars.desktopMediaPlayerAnchorCurve !== undefined ? Vars.desktopMediaPlayerAnchorCurve : 0
    property string maskShape: Vars.wallpaperMaskShape !== undefined ? Vars.wallpaperMaskShape : "9SidedCookie"
    property real maskScale: Vars.wallpaperMaskScale !== undefined ? Vars.wallpaperMaskScale : 1.05
    property int maskOffsetX: Vars.wallpaperMaskOffsetX !== undefined ? Vars.wallpaperMaskOffsetX : 0
    property int maskOffsetY: Vars.wallpaperMaskOffsetY !== undefined ? Vars.wallpaperMaskOffsetY : 0
    property bool anchorExpandFix: Vars.desktopMediaPlayerAnchorExpandFix !== undefined ? Vars.desktopMediaPlayerAnchorExpandFix : false
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false
    // Hidden AND torn down in game mode — CC.MediaPlayer polls lyric sync and playback position on
    // its own timers, which a merely-hidden PanelWindow wouldn't stop
    property bool active: window.playerEnabled && !window.gameMode

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
        item: playerContainer
    }

    Settings {
        id: playerSettings
        category: "DesktopMediaPlayer_" + (window.screen ? window.screen.name : "")
        property int posX: 100
        property int posY: 500
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
            var refWidth = window.anchorExpandFix ? ((playerLoader.item && playerLoader.item.isVertical ? 300 : 500) + 48) : playerContainer.width;
            if (pt === "TopCenter" || pt === "Center" || pt === "BottomCenter") widgetX -= refWidth / 2;
            else if (pt === "TopRight" || pt === "MiddleRight" || pt === "BottomRight") widgetX -= refWidth;
            return widgetX;
        }
        return playerSettings.posX;
    }

    property int computedY: {
        if (window.anchorEnabled && window.anchorCurve >= 0 && window.anchorCurve < peaks.length) {
            var peak = peaks[window.anchorCurve];
            var maskSize = Math.min(window.width, window.height) * window.maskScale;
            var centerY = window.height / 2 + window.maskOffsetY;
            var targetY = centerY - maskSize / 2 + (peak.y / 100.0) * maskSize;
            
            var widgetY = targetY;
            var pt = window.anchorPoint;
            var refHeight = window.anchorExpandFix ? ((playerLoader.item && playerLoader.item.isVertical ? 300 : 180) + 48) : playerContainer.height;
            if (pt === "MiddleLeft" || pt === "Center" || pt === "MiddleRight") widgetY -= refHeight / 2;
            else if (pt === "BottomLeft" || pt === "BottomCenter" || pt === "BottomRight") widgetY -= refHeight;
            return widgetY;
        }
        return playerSettings.posY;
    }

    Item {
        id: playerContainer
        width: (playerLoader.item && playerLoader.item.isExpanded && playerLoader.item.isHorizontalExpansion ? 900 : 500) + 48
        height: (playerLoader.item && playerLoader.item.isExpanded && !playerLoader.item.isHorizontalExpansion ? 650 : (playerLoader.item && playerLoader.item.isVertical ? 300 : 180)) + 48
        x: computedX
        y: computedY

        Behavior on width { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutCubic } }
        Behavior on x { enabled: window.anchorEnabled; NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: window.anchorEnabled; NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

        Loader {
            id: playerLoader
            anchors.fill: parent
            anchors.margins: 24 // Give space for shadow
            active: window.active
            sourceComponent: CC.MediaPlayer {
                // Same surface as every desktop widget (clock, visualizer, vitals)
                cardColor: Theme.surface_container_high
            }
        }

        DragHandler {
            id: dragHandler
            target: playerContainer
            enabled: !window.anchorEnabled

            xAxis.minimum: 0
            xAxis.maximum: window.width > 0 ? window.width - playerContainer.width : 9999
            yAxis.minimum: 0
            yAxis.maximum: window.height > 0 ? window.height - playerContainer.height : 9999

            onActiveChanged: {
                if (!active) {
                    playerSettings.posX = playerContainer.x;
                    playerSettings.posY = playerContainer.y;
                }
            }
        }
    }
}

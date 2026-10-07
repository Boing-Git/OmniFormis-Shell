import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtCore
import "../.."
import "../../theme"
import "../../core/primitives" as Primitives

// A bar spectrum on the wallpaper, fed by a second, dedicated cava instance running in "raw"
// output mode (quickshell keeps it alive only while this widget is enabled/visible; the
// terminal visualizer's own ncurses instance, if any, is untouched). Positioned the same way as
// the other desktop widgets: either dragged freely or snapped to a wallpaper-mask peak.
PanelWindow {
    id: window
    color: "transparent"

    // Off in low-spec mode: cava's 60 fps analysis plus a shape per bar redrawn every frame
    property bool visualizerEnabled: (Vars.desktopAudioVisualizerEnabled !== undefined ? Vars.desktopAudioVisualizerEnabled : false) && !Vars.lowSpec
    property bool anchorEnabled: Vars.desktopAudioVisualizerAnchorEnabled !== undefined ? Vars.desktopAudioVisualizerAnchorEnabled : false
    property string anchorPoint: Vars.desktopAudioVisualizerAnchorPoint !== undefined ? Vars.desktopAudioVisualizerAnchorPoint : "Center"
    property int anchorCurve: Vars.desktopAudioVisualizerAnchorCurve !== undefined ? Vars.desktopAudioVisualizerAnchorCurve : 0
    property int barsCount: Vars.desktopAudioVisualizerBars !== undefined ? Vars.desktopAudioVisualizerBars : 24
    property string shapeName: Vars.desktopAudioVisualizerShape !== undefined ? Vars.desktopAudioVisualizerShape : "Sunny"
    property string shapeMode: Vars.desktopAudioVisualizerShapeMode !== undefined ? Vars.desktopAudioVisualizerShapeMode : "Single"
    property string colorMode: Vars.desktopAudioVisualizerColorMode !== undefined ? Vars.desktopAudioVisualizerColorMode : "Theme"
    property string colorChoice: Vars.desktopAudioVisualizerColor !== undefined ? Vars.desktopAudioVisualizerColor : "primary"
    property string gradientStart: Vars.desktopAudioVisualizerGradientStart !== undefined ? Vars.desktopAudioVisualizerGradientStart : "primary"
    property string gradientEnd: Vars.desktopAudioVisualizerGradientEnd !== undefined ? Vars.desktopAudioVisualizerGradientEnd : "tertiary"

    function resolveThemeColor(name) {
        if (name === "secondary") return Theme.secondary;
        if (name === "tertiary") return Theme.tertiary;
        if (name === "surface_variant") return Theme.surface_variant;
        if (name === "error") return Theme.error;
        if (name === "background") return Theme.background;
        return Theme.primary;
    }
    property string layoutMode: Vars.desktopAudioVisualizerLayout !== undefined ? Vars.desktopAudioVisualizerLayout : "Circular"
    property string positionShape: Vars.desktopAudioVisualizerPositionShape !== undefined ? Vars.desktopAudioVisualizerPositionShape : "Circle"
    property real shapeSize: Vars.desktopAudioVisualizerShapeSize !== undefined ? Vars.desktopAudioVisualizerShapeSize : 26
    property real itemSpacing: Vars.desktopAudioVisualizerSpacing !== undefined ? Vars.desktopAudioVisualizerSpacing : 8
    property real circleRadius: Vars.desktopAudioVisualizerRadius !== undefined ? Vars.desktopAudioVisualizerRadius : 42
    property string maskShape: Vars.wallpaperMaskShape !== undefined ? Vars.wallpaperMaskShape : "9SidedCookie"
    property real maskScale: Vars.wallpaperMaskScale !== undefined ? Vars.wallpaperMaskScale : 1.05
    property int maskOffsetX: Vars.wallpaperMaskOffsetX !== undefined ? Vars.wallpaperMaskOffsetX : 0
    property int maskOffsetY: Vars.wallpaperMaskOffsetY !== undefined ? Vars.wallpaperMaskOffsetY : 0
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false

    visible: window.visualizerEnabled

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
        item: visualizerContainer
    }

    Settings {
        id: visualizerSettings
        category: "DesktopAudioVisualizer_" + (window.screen ? window.screen.name : "")
        property int posX: 180
        property int posY: 180
    }

    M3Shapes { id: m3 }
    property var peaks: m3.getShapePeaks(window.maskShape)
    // Where each bar sits when arranged in Circular mode — evenly spaced by angle around
    // positionShape's own silhouette (a plain Circle by default, but any M3 shape traces that
    // shape's outline instead), recomputed only when the shape or bar count changes.
    property var outlinePoints: m3.getOutlinePoints(window.positionShape, Math.max(1, window.barsCount))

    property int computedX: {
        if (window.anchorEnabled && window.anchorCurve >= 0 && window.anchorCurve < peaks.length) {
            var peak = peaks[window.anchorCurve];
            var maskSize = Math.min(window.width, window.height) * window.maskScale;
            var centerX = window.width / 2 + window.maskOffsetX;
            var targetX = centerX - maskSize / 2 + (peak.x / 100.0) * maskSize;

            var widgetX = targetX;
            var pt = window.anchorPoint;
            if (pt === "TopCenter" || pt === "Center" || pt === "BottomCenter") widgetX -= visualizerContainer.width / 2;
            else if (pt === "TopRight" || pt === "MiddleRight" || pt === "BottomRight") widgetX -= visualizerContainer.width;
            return widgetX;
        }
        return visualizerSettings.posX;
    }

    property int computedY: {
        if (window.anchorEnabled && window.anchorCurve >= 0 && window.anchorCurve < peaks.length) {
            var peak = peaks[window.anchorCurve];
            var maskSize = Math.min(window.width, window.height) * window.maskScale;
            var centerY = window.height / 2 + window.maskOffsetY;
            var targetY = centerY - maskSize / 2 + (peak.y / 100.0) * maskSize;

            var widgetY = targetY;
            var pt = window.anchorPoint;
            if (pt === "MiddleLeft" || pt === "Center" || pt === "MiddleRight") widgetY -= visualizerContainer.height / 2;
            else if (pt === "BottomLeft" || pt === "BottomCenter" || pt === "BottomRight") widgetY -= visualizerContainer.height;
            return widgetY;
        }
        return visualizerSettings.posY;
    }

    // ---- Audio data ----
    // cava's latest frame, 0-1 per bar
    property var targetLevels: []
    // What's drawn. Every display frame each bar eases toward its target, rising fast and falling
    // slower, so motion stays fluid at any refresh rate instead of stepping at cava's 60 fps.
    property var levels: []
    // Each bar's spin, advanced by a speed that follows its level so it never jumps. A quiet bar
    // stops where it is.
    property var angles: []
    property string lastFrame: ""

    readonly property string generatedConfigPath: Quickshell.env("HOME") + "/.cache/quickshell/cava-raw-generated.ini"
    readonly property string sourceConfigPath: Quickshell.env("HOME") + "/Dotfiles/cava/cava-raw.ini"

    // True once cava has failed to keep running (not installed, or crashes on start) — shown as a
    // message instead of a flat, unexplained bar row.
    property bool cavaMissing: false

    function restartVisualizer() {
        cavaMissing = false;
        lastFrame = "";
        cavaProc.running = false;
        configGenProc.running = false;
        configGenProc.running = true;
    }

    // Regenerates the per-bar-count config (cava only reads its bar count at startup, there's no
    // CLI override), then hands off to cavaProc once the file is ready.
    Process {
        id: configGenProc
        command: ["bash", "-c", "mkdir -p \"$HOME/.cache/quickshell\" && sed 's/^bars = .*/bars = " + window.barsCount + "/' " + JSON.stringify(window.sourceConfigPath) + " > " + JSON.stringify(window.generatedConfigPath)]
        running: false
        onExited: (code) => {
            if (code === 0 && window.visualizerEnabled) {
                cavaProc.running = true;
                cavaWatchdog.restart();
            }
        }
    }

    // cava failing to start (missing binary, bad config) exits almost immediately; if it isn't
    // still running shortly after we asked it to start, treat it as unavailable rather than
    // silently showing a flat, zero-height bar row with no explanation.
    Timer {
        id: cavaWatchdog
        interval: 1200
        repeat: false
        onTriggered: {
            if (window.visualizerEnabled && !cavaProc.running) {
                window.cavaMissing = true;
            }
        }
    }

    Process {
        id: cavaProc
        command: ["cava", "-p", window.generatedConfigPath]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                // Silence repeats one all-zero frame 60 times a second, there's nothing to redraw
                if (data === window.lastFrame) return;
                window.lastFrame = data;
                var parts = data.split(";");
                var vals = [];
                for (var i = 0; i < parts.length; i++) {
                    var n = parseInt(parts[i]);
                    if (!isNaN(n)) vals.push(Math.max(0, Math.min(100, n)) / 100);
                }
                if (vals.length > 0) {
                    window.targetLevels = vals;
                    window.cavaMissing = false;
                    smoother.start();
                }
            }
        }
    }

    // Runs only while something moves, and stops once every bar has settled and none is spinning
    FrameAnimation {
        id: smoother
        // Time since the last update. Frames closer than 5 ms apart are skipped, so a 240 Hz
        // screen updates at 120 Hz and slower screens on every frame.
        property real pending: 0
        onTriggered: {
            var target = window.targetLevels;
            if (window.gameMode) {
                window.levels = target;
                smoother.stop();
                return;
            }
            smoother.pending += smoother.frameTime;
            if (smoother.pending < 0.005)
                return;
            // Capped so a stall doesn't turn into one big jump
            var dt = Math.min(smoother.pending, 0.05);
            smoother.pending = 0;
            var rise = 1 - Math.exp(-dt / 0.03);
            var fall = 1 - Math.exp(-dt / 0.14);
            var current = window.levels, spin = window.angles;
            var nextLevels = [], nextAngles = [];
            var moving = false;
            for (var i = 0; i < target.length; i++) {
                var t = target[i];
                var v = current[i] !== undefined ? current[i] : 0;
                v += (t - v) * (t > v ? rise : fall);
                if (Math.abs(t - v) < 0.002) v = t;
                else moving = true;
                nextLevels.push(v);
                // One turn per 2.6 s when barely audible, down to 0.4 s at full volume
                var a = spin[i] !== undefined ? spin[i] : 0;
                if (v > 0.04) {
                    a = (a + dt * 360000 / Math.max(260, 2600 - v * 2200)) % 360;
                    moving = true;
                }
                nextAngles.push(a);
            }
            window.levels = nextLevels;
            window.angles = nextAngles;
            if (!moving) smoother.stop();
        }
    }

    onVisualizerEnabledChanged: {
        if (visualizerEnabled) restartVisualizer();
        else cavaProc.running = false;
    }
    onBarsCountChanged: {
        if (visualizerEnabled) restartVisualizer();
    }
    Component.onCompleted: {
        if (window.visualizerEnabled) restartVisualizer();
    }

    Item {
        id: visualizerContainer
        width: card.width
        height: card.height
        x: computedX
        y: computedY

        Behavior on x { enabled: window.anchorEnabled && !window.gameMode; NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: window.anchorEnabled && !window.gameMode; NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

        Item {
            id: card
            property bool backgroundEnabled: Vars.desktopAudioVisualizerBackgroundEnabled !== undefined ? Vars.desktopAudioVisualizerBackgroundEnabled : true
            // Each bar is its own square M3 shape rather than a stretched rectangle — a fixed
            // shapeSize keeps the shape's aspect 1:1 no matter how loud it gets; only scale,
            // position, color and rotation move, never the shape's own width vs. height.
            readonly property bool isCircular: window.layoutMode === "Circular"
            readonly property real shapeSize: Math.max(6, window.shapeSize)
            readonly property real itemGap: Math.max(0, window.itemSpacing)
            readonly property real cellSize: shapeSize + itemGap
            readonly property real barMaxHeight: Math.max(shapeSize * 1.4, shapeSize * 2.6)
            // How far out a bar's shape sits when quiet; it pulses further out from there as it
            // gets louder, so the ring's total footprint needs headroom past ringRadius*1.5.
            readonly property real ringRadius: Math.max(shapeSize * 0.9, window.circleRadius)
            // True max reach from center: outline points can sit up to ~50/45 of ringRadius from
            // center (spiky shapes), plus a full pulse-out of 0.5×ringRadius at max amplitude,
            // plus half the shape's own size at its loudest scale (0.55 + 0.65 = 1.2 max).
            // This keeps the container tight rather than the old fixed-multiplier over-estimate.
            readonly property real actualRingExtent: ringRadius * 1.65 + shapeSize * 0.65
            readonly property real ringDiameter: actualRingExtent * 2 + shapeSize
            width: (isCircular ? ringDiameter : Math.max(1, window.barsCount) * cellSize - itemGap) + (backgroundEnabled ? Vars.spacingLarge * 2 : 0)
            height: (isCircular ? ringDiameter : barMaxHeight + shapeSize) + (backgroundEnabled ? Vars.spacingLarge * 2 : 8)
            // Background radius hugs the actual shape ring: in Circular mode it equals the ring's
            // true outer edge plus a medium padding gap — so the card clips tightly around the
            // shapes rather than leaving a large empty band. Capped at half the card size so it
            // never exceeds a perfect circle. Linear mode keeps the shell's normal rounding.
            readonly property real backgroundRadius: isCircular
                ? Math.min(actualRingExtent + Vars.spacingMedium, Math.min(width, height) / 2)
                : Vars.radiusLarge

            Primitives.SquircleMask {
                anchors.fill: parent
                visible: card.backgroundEnabled
                antialiasing: true
                // Same surface as every desktop widget (clock, media player, vitals)
                color: Vars.tColor(Theme.surface_container_high, Vars.panelOpacity)
                topLeftRadius: card.backgroundRadius
                topRightRadius: card.backgroundRadius
                bottomLeftRadius: card.backgroundRadius
                bottomRightRadius: card.backgroundRadius

                Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
            }

            // Shown instead of a flat, misleading zero-height bar row when cava can't run at all
            // (not installed, or exits immediately) rather than leaving that unexplained.
            QsText {
                anchors.centerIn: parent
                visible: window.cavaMissing
                text: "cava not found"
                font.family: Vars.fontFamily
                font.pixelSize: 12
                color: Theme.on_surface_variant
            }

            // A plain Item rather than a Row/positioner — Circular mode needs to place shapes by
            // angle, which a linear positioner can't do, so both layouts compute their own
            // absolute x/y on the shape itself instead.
            Item {
                id: barsArea
                anchors.centerIn: parent
                width: card.isCircular ? card.ringDiameter : Math.max(1, window.barsCount) * card.cellSize - card.itemGap
                height: card.isCircular ? card.ringDiameter : card.barMaxHeight + card.shapeSize
                visible: !window.cavaMissing

                Repeater {
                    model: window.barsCount
                    delegate: Item {
                        id: bar
                        required property int index
                        readonly property real percent: window.levels[index] !== undefined ? window.levels[index] : 0

                        // Theme mode: the bars blend from the primary to the secondary accent around
                        // the ring. Accent roles rather than fixed or container tones, which nearly
                        // vanish against the card in dark or light mode. Custom mode: a single
                        // user-chosen color for every bar instead. Either way, warmed toward the
                        // tertiary accent as this bar gets louder (tintLayer below).
                        readonly property real stopPos: window.barsCount > 1 ? index / (window.barsCount - 1) : 0
                        readonly property color gradientColor: Qt.rgba(Theme.primary.r + (Theme.secondary.r - Theme.primary.r) * stopPos,
                                                                       Theme.primary.g + (Theme.secondary.g - Theme.primary.g) * stopPos,
                                                                       Theme.primary.b + (Theme.secondary.b - Theme.primary.b) * stopPos, 1)
                        readonly property color customColor: window.resolveThemeColor(window.colorChoice)
                        readonly property color stopColor: window.colorMode === "Custom" ? customColor : gradientColor

                        // Gradient mode: every shape is filled with a two-color blend instead of a
                        // flat fill — the same "bake it into the SVG, colorize via string stops"
                        // approach used for the system vitals needle.
                        readonly property color gradStartColor: window.resolveThemeColor(window.gradientStart)
                        readonly property color gradEndColor: window.resolveThemeColor(window.gradientEnd)

                        // Single: every bar uses the one configured Bar Shape. All Shapes: each
                        // bar cycles through the full M3 shape catalog instead, index by index.
                        readonly property string barShape: window.shapeMode === "All Shapes"
                            ? m3.allShapeNames[index % m3.allShapeNames.length]
                            : window.shapeName

                        // Circular: sits on positionShape's own silhouette (a plain circle by
                        // default, or any other M3 shape's outline), pushed further out along that
                        // same direction as this band gets louder — a sunburst spectrum traced
                        // around whatever shape was chosen, not just a perfect ring. Linear: rises
                        // up a fixed-height track, as before. Either way only position/scale/
                        // rotation move; the shape itself always stays shapeSize x shapeSize.
                        readonly property var outlinePt: window.outlinePoints[index] !== undefined ? window.outlinePoints[index] : { x: 50, y: 8 }
                        readonly property real rawDX: outlinePt.x - 50
                        readonly property real rawDY: outlinePt.y - 50
                        readonly property real rawLen: Math.max(0.0001, Math.hypot(rawDX, rawDY))
                        // M3 shapes are drawn to roughly fill their 0-100 viewBox, reaching ~45
                        // from center at their widest — this normalizes that to card.ringRadius
                        // regardless of which shape is chosen, so the overall size stays controlled
                        // by the Radius setting while each shape's own silhouette is preserved.
                        readonly property real shapeToRingScale: card.ringRadius / 45.0
                        readonly property real pulseOut: percent * card.ringRadius * 0.5
                        readonly property real circX: barsArea.width / 2 + rawDX * shapeToRingScale + (rawDX / rawLen) * pulseOut - width / 2
                        readonly property real circY: barsArea.height / 2 + rawDY * shapeToRingScale + (rawDY / rawLen) * pulseOut - height / 2
                        readonly property real linX: index * card.cellSize
                        readonly property real linY: (1 - percent) * card.barMaxHeight

                        // Motion comes from `levels` and `angles`, which the smoother eases every
                        // display frame, so there are no per-property animations to restart and stutter
                        x: card.isCircular ? circX : linX
                        y: card.isCircular ? circY : linY
                        width: card.shapeSize
                        height: card.shapeSize
                        scale: 0.55 + percent * 0.65
                        rotation: window.angles[index] !== undefined ? window.angles[index] : 0

                        property string currentPath: m3.getPath(barShape)

                        function toRgb(c) {
                            return "rgb(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + ")";
                        }
                        function shapeSvg(fill) {
                            return "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + currentPath + "' fill='" + fill + "'/></svg>";
                        }

                        // The SVGs depend only on the shape and theme, never on the level, so each is
                        // rasterised once rather than on every cava frame
                        Image {
                            anchors.fill: parent
                            smooth: true
                            antialiasing: true
                            mipmap: true
                            source: window.colorMode === "Gradient"
                                ? "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'>" +
                                  "<defs><linearGradient id='g' x1='0%25' y1='0%25' x2='100%25' y2='100%25'>" +
                                  "<stop offset='0%25' stop-color='" + bar.toRgb(bar.gradStartColor) + "'/>" +
                                  "<stop offset='100%25' stop-color='" + bar.toRgb(bar.gradEndColor) + "'/>" +
                                  "</linearGradient></defs>" +
                                  "<path d='" + bar.currentPath + "' fill='url(%23g)'/></svg>"
                                : bar.shapeSvg(bar.toRgb(bar.stopColor))
                        }

                        // The warm-up toward tertiary: the same shape in tertiary fading in on top,
                        // which blends exactly like mixing the two colors
                        Image {
                            id: tintLayer
                            anchors.fill: parent
                            visible: window.colorMode !== "Gradient"
                            opacity: bar.percent * 0.65
                            smooth: true
                            antialiasing: true
                            mipmap: true
                            source: visible ? bar.shapeSvg(bar.toRgb(Theme.tertiary)) : ""
                        }
                    }
                }
            }
        }

        DragHandler {
            id: dragHandler
            target: visualizerContainer
            enabled: !window.anchorEnabled

            xAxis.minimum: 0
            xAxis.maximum: window.width > 0 ? window.width - visualizerContainer.width : 9999
            yAxis.minimum: 0
            yAxis.maximum: window.height > 0 ? window.height - visualizerContainer.height : 9999

            onActiveChanged: {
                if (!active) {
                    visualizerSettings.posX = visualizerContainer.x;
                    visualizerSettings.posY = visualizerContainer.y;
                }
            }
        }
    }
}

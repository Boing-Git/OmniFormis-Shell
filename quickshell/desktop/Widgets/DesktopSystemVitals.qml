import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtCore
import "../.."
import "../../theme"
import "../../core/primitives" as Primitives

// Small floating CPU/RAM/GPU radial gauges, positioned the same way as DesktopClock/DesktopCalender:
// either dragged freely or snapped to a peak of the wallpaper-mask silhouette.
PanelWindow {
    id: window
    color: "transparent"

    property bool vitalsEnabled: Vars.desktopSystemVitalsEnabled !== undefined ? Vars.desktopSystemVitalsEnabled : false
    property bool anchorEnabled: Vars.desktopSystemVitalsAnchorEnabled !== undefined ? Vars.desktopSystemVitalsAnchorEnabled : false
    property string anchorPoint: Vars.desktopSystemVitalsAnchorPoint !== undefined ? Vars.desktopSystemVitalsAnchorPoint : "Center"
    property int anchorCurve: Vars.desktopSystemVitalsAnchorCurve !== undefined ? Vars.desktopSystemVitalsAnchorCurve : 0
    property string maskShape: Vars.wallpaperMaskShape !== undefined ? Vars.wallpaperMaskShape : "9SidedCookie"
    property real maskScale: Vars.wallpaperMaskScale !== undefined ? Vars.wallpaperMaskScale : 1.05
    property int maskOffsetX: Vars.wallpaperMaskOffsetX !== undefined ? Vars.wallpaperMaskOffsetX : 0
    property int maskOffsetY: Vars.wallpaperMaskOffsetY !== undefined ? Vars.wallpaperMaskOffsetY : 0
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false
    // Hidden AND stopped polling in game mode — spawning top/free/nvidia-smi every 2s to show
    // system load is exactly the overhead a game-focused mode should be cutting, not keeping
    property bool active: window.vitalsEnabled && !window.gameMode

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
        item: vitalsContainer
    }

    Settings {
        id: vitalsSettings
        category: "DesktopSystemVitals_" + (window.screen ? window.screen.name : "")
        property int posX: 140
        property int posY: 140
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
            if (pt === "TopCenter" || pt === "Center" || pt === "BottomCenter") widgetX -= vitalsContainer.width / 2;
            else if (pt === "TopRight" || pt === "MiddleRight" || pt === "BottomRight") widgetX -= vitalsContainer.width;
            return widgetX;
        }
        return vitalsSettings.posX;
    }

    property int computedY: {
        if (window.anchorEnabled && window.anchorCurve >= 0 && window.anchorCurve < peaks.length) {
            var peak = peaks[window.anchorCurve];
            var maskSize = Math.min(window.width, window.height) * window.maskScale;
            var centerY = window.height / 2 + window.maskOffsetY;
            var targetY = centerY - maskSize / 2 + (peak.y / 100.0) * maskSize;

            var widgetY = targetY;
            var pt = window.anchorPoint;
            if (pt === "MiddleLeft" || pt === "Center" || pt === "MiddleRight") widgetY -= vitalsContainer.height / 2;
            else if (pt === "BottomLeft" || pt === "BottomCenter" || pt === "BottomRight") widgetY -= vitalsContainer.height;
            return widgetY;
        }
        return vitalsSettings.posY;
    }

    // ---- Data: reuses the exact commands TaskManagerPage.qml polls for its CPU/RAM/GPU readouts ----
    property real cpuPercent: 0
    property real ramPercent: 0
    // -1 means "no GPU data" (e.g. no nvidia-smi) rather than "0% used" — hides that gauge instead of
    // showing a misleading full-red one.
    property real gpuPercent: -1

    Process {
        id: cpuProc
        command: ["sh", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseFloat(this.text.trim());
                if (!isNaN(v)) window.cpuPercent = Math.max(0, Math.min(100, v));
            }
        }
    }

    Process {
        id: ramProc
        command: ["free", "-m"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split('\n');
                if (lines.length > 1) {
                    var parts = lines[1].split(/\s+/);
                    if (parts.length >= 3) {
                        var total = parseFloat(parts[1]);
                        var used = parseFloat(parts[2]);
                        if (total > 0) window.ramPercent = Math.max(0, Math.min(100, (used / total) * 100));
                    }
                }
            }
        }
    }

    Process {
        id: gpuProc
        command: ["nvidia-smi", "--query-gpu=utilization.gpu", "--format=csv,noheader,nounits"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseFloat(this.text.trim());
                if (!isNaN(v)) window.gpuPercent = Math.max(0, Math.min(100, v));
            }
        }
    }

    Timer {
        interval: 2000
        running: window.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running = true;
            ramProc.running = true;
            gpuProc.running = true;
        }
    }

    Item {
        id: vitalsContainer
        width: card.width
        height: card.height
        x: computedX
        y: computedY

        Behavior on x { enabled: window.anchorEnabled && !window.gameMode; NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: window.anchorEnabled && !window.gameMode; NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

        Item {
            id: card
            property bool backgroundEnabled: Vars.desktopSystemVitalsBackgroundEnabled !== undefined ? Vars.desktopSystemVitalsBackgroundEnabled : true
            width: gaugeRow.implicitWidth + (backgroundEnabled ? Vars.spacingLarge * 2 : 0)
            height: gaugeRow.implicitHeight + (backgroundEnabled ? Vars.spacingLarge * 2 : 0)

            Primitives.ShapeDropShadow {
                targetWidth: card.width
                targetHeight: card.height
                shadowEnabled: card.backgroundEnabled
                topLeftRadius: Vars.radiusLarge
                topRightRadius: Vars.radiusLarge
                bottomLeftRadius: Vars.radiusLarge
                bottomRightRadius: Vars.radiusLarge
            }

            // A plain rounded rect, like every other card in the shell — an M3-shape image (the
            // "Puffy" cookie used for small square icon badges elsewhere) stretches and distorts
            // when forced into a non-square card, which is what happened here before.
            Primitives.SquircleMask {
                anchors.fill: parent
                visible: card.backgroundEnabled
                antialiasing: true
                // Same surface as every desktop widget (clock, media player, visualizer)
                color: Vars.tColor(Theme.surface_container_high, Vars.panelOpacity)
                topLeftRadius: Vars.radiusLarge
                topRightRadius: Vars.radiusLarge
                bottomLeftRadius: Vars.radiusLarge
                bottomRightRadius: Vars.radiusLarge
            }

            RowLayout {
                id: gaugeRow
                anchors.centerIn: parent
                spacing: Vars.spacingMedium

                GaugeArc {
                    label: "CPU"
                    percent: window.cpuPercent
                    accentColor: Theme.primary
                    containerColor: Theme.primary_container
                    dialShape: "4SidedCookie"
                    gameMode: window.gameMode
                }
                GaugeArc {
                    label: "RAM"
                    percent: window.ramPercent
                    accentColor: Theme.secondary
                    containerColor: Theme.secondary_container
                    dialShape: "Gem"
                    gameMode: window.gameMode
                }
                GaugeArc {
                    label: "GPU"
                    percent: window.gpuPercent
                    accentColor: Theme.tertiary
                    containerColor: Theme.tertiary_container
                    dialShape: "Sunny"
                    gameMode: window.gameMode
                    visible: window.gpuPercent >= 0
                }
            }
        }

        DragHandler {
            id: dragHandler
            target: vitalsContainer
            enabled: !window.anchorEnabled

            xAxis.minimum: 0
            xAxis.maximum: window.width > 0 ? window.width - vitalsContainer.width : 9999
            yAxis.minimum: 0
            yAxis.maximum: window.height > 0 ? window.height - vitalsContainer.height : 9999

            onActiveChanged: {
                if (!active) {
                    vitalsSettings.posX = vitalsContainer.x;
                    vitalsSettings.posY = vitalsContainer.y;
                }
            }
        }
    }

    // A gauge in one M3 color family per metric (primary, secondary, tertiary), following the
    // color roles: the reading on top in the accent, a dial plate in that family's container tone,
    // a solid Arrow in the accent pointing at the reading, and the label in on-surface-variant.
    // At 90% and over the gauge switches to the error family, so the color carries meaning.
    component GaugeArc: ColumnLayout {
        id: gauge
        property string label: ""
        property real percent: 0
        property color accentColor: Theme.primary
        property color containerColor: Theme.primary_container
        property string dialShape: "Circle"
        property bool gameMode: false
        spacing: 4

        readonly property real clampedPercent: Math.max(0, Math.min(100, percent))
        readonly property bool critical: clampedPercent >= 90
        readonly property color accent: critical ? Theme.error : accentColor
        readonly property color plate: critical ? Theme.error_container : containerColor
        // A 240° speedometer sweep centered on top: 0% points to the lower-left, 100% to the lower-right.
        readonly property real needleAngle: -120 + (clampedPercent / 100) * 240

        // Clamped so a color with a channel outside 0-1 can't produce an invalid "rgb(280,...)"
        function toRgb(c) {
            var r = Math.max(0, Math.min(255, Math.round(c.r * 255)));
            var g = Math.max(0, Math.min(255, Math.round(c.g * 255)));
            var b = Math.max(0, Math.min(255, Math.round(c.b * 255)));
            return "rgb(" + r + "," + g + "," + b + ")";
        }

        M3Shapes { id: gaugeM3 }

        QsText {
            Layout.alignment: Qt.AlignHCenter
            text: Math.round(gauge.clampedPercent) + "%"
            font.family: Vars.fontFamily
            font.pixelSize: 18
            setWeight: 800
            color: gauge.accent
            Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
        }

        Item {
            id: dial
            Layout.preferredWidth: 76
            Layout.preferredHeight: 76
            Layout.alignment: Qt.AlignHCenter

            Image {
                id: dialPlate
                anchors.fill: parent
                smooth: true
                antialiasing: true
                mipmap: true
                source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + gaugeM3.getPath(gauge.dialShape) + "' fill='" + gauge.toRgb(gauge.plate) + "'/></svg>"
            }

            // Usage reading as an orbiting dot (same technique as AnalogClock's "Orbiting Dot"
            // second hand) instead of a speedometer needle: an Item rotated to the reading's
            // angle, with the dot pushed outward from its pivot via anchors.
            Item {
                id: needle
                anchors.fill: parent
                // needleAngle's own convention already matches a plain top-anchored dot (0deg =
                // straight up = the 50% mark at the dial's top), unlike the old Arrow image,
                // which pointed up by default and needed a +180deg correction to read correctly.
                rotation: gauge.needleAngle

                Behavior on rotation {
                    enabled: !gauge.gameMode
                    RotationAnimation { direction: RotationAnimation.Shortest; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow }
                }

                Rectangle {
                    width: 12 + (gauge.clampedPercent / 100) * 4
                    height: width
                    radius: width / 2
                    antialiasing: true
                    color: gauge.accent

                    anchors.bottom: parent.verticalCenter
                    anchors.bottomMargin: dial.width * 0.28
                    anchors.horizontalCenter: parent.horizontalCenter

                    Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                    Behavior on width {
                        enabled: !gauge.gameMode
                        NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow }
                    }
                }
            }
        }

        QsText {
            Layout.alignment: Qt.AlignHCenter
            text: gauge.label
            font.family: Vars.fontFamily
            font.pixelSize: 13
            setWeight: 600
            color: Theme.on_surface_variant
        }
    }
}

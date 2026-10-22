import QtQuick
import "../../theme"

// A soft, wide drop shadow that traces a widget's own exact outline — whether that's an M3
// abstract path (the clock face) or a plain rounded-rect/squircle card (media player, vitals,
// calendar, visualizer). Builds a stack of thin "rings", each one a raster SVG whose fill is
// "a slightly enlarged copy of the real outline MINUS the exact, unscaled outline" (evenodd
// fill-rule) — the same donut-via-subtraction trick WallpaperOverlay.qml uses for its own mask
// shadow. Because every ring shares the one real (unscaled) outline, the halo always follows the
// widget's true silhouette — spikes, petals, rounded corners and all — rather than an
// approximation, and the real widget content painted on top is never covered or dimmed.
Item {
    id: root

    // Give m3ShapeName a value to trace an M3 abstract path; leave it empty to trace a rounded
    // rect/squircle instead, built from the four corner radii below.
    property string m3ShapeName: ""
    property real topLeftRadius: 0
    property real topRightRadius: 0
    property real bottomLeftRadius: 0
    property real bottomRightRadius: 0

    property real targetWidth: parent ? parent.width : 0
    property real targetHeight: parent ? parent.height : 0
    property real shapeRotation: 0

    property color shadowColor: "black"
    property real peakOpacity: 0.35 // darkest opacity, right at the gap's outer edge
    property real reach: 0.16 // how far outward the halo extends, as a fraction of the shape size
    // A tiny clearance between the real outline and where the halo starts, just enough for the
    // edge's raster antialiasing to fully decay before touching a translucent card's own boundary
    // (surface_container_high at panelOpacity, which every desktop widget card uses) — too much
    // and it reads as a visible gap between the widget and its shadow instead of a seam.
    property real gap: 0.004
    property int steps: 36 // ring count — more steps means a smoother, less banded gradient
    property bool shadowEnabled: true
    readonly property real margin: 1.0 + reach * 1.4 // headroom so the outermost ring never clips

    M3Shapes { id: m3 }

    readonly property string innerPath: m3ShapeName.length > 0 ? m3.pathForBox(m3ShapeName, targetWidth, targetHeight) : m3.roundedRectPath(targetWidth, targetHeight, topLeftRadius, topRightRadius, bottomRightRadius, bottomLeftRadius)

    // A rounded rect's "scale the whole shape up from center" is a fair stand-in for a true
    // offset (every corner is defined by the same radius parameter, so regenerating one scaled up
    // keeps corners round in proportion). An arbitrary M3 path has no such parameter — scaling a
    // sharp corner or notch radially from the shape's center moves it far more than it moves a
    // flat edge nearby (more so the closer that corner sits to the center), producing a spiky
    // overshoot right at corners/notches instead of an even halo. So M3 shapes get a true
    // per-point normal offset instead; rounded rects keep the cheaper scale-based path.
    function bandPath(s) {
        if (m3ShapeName.length > 0) {
            var refSize = Math.min(targetWidth, targetHeight) / 2;
            return m3.offsetPathForBox(m3ShapeName, targetWidth, targetHeight, (s - 1.0) * refSize);
        }
        return m3.scaleCentered(innerPath, s);
    }

    // Each ring is an independent, non-overlapping thin band between two scaled copies of the
    // shape (innerS -> outerS), not "the real edge out to some radius" — the latter would make
    // every ring share the same inner boundary, so they'd all stack on top of each other right at
    // the edge (compounding via alpha blending into near-solid black) while only the single
    // outermost ring actually faded out, leaving a hard cutoff at the halo's far edge instead of a
    // gradual fade.
    readonly property var rings: {
        var arr = [];
        var n = Math.max(1, steps);
        var stepSize = reach / n;
        for (var i = 0; i < n; i++) {
            var t = (i + 0.5) / n; // midpoint of this band, for the opacity falloff curve
            arr.push({
                innerS: 1.0 + gap + i * stepSize,
                outerS: 1.0 + gap + (i + 1) * stepSize,
                o: peakOpacity * Math.pow(1.0 - t, 2)
            });
        }
        return arr;
    }

    anchors.centerIn: parent
    width: targetWidth * margin
    height: targetHeight * margin
    opacity: shadowEnabled ? 1.0 : 0.0
    visible: opacity > 0
    Behavior on opacity {
        NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutCubic }
    }

    Repeater {
        model: root.rings

        Item {
            anchors.centerIn: parent
            property real scaleFactor: Math.min(4, 4096 / Math.max(root.width, root.height, 1))
            width: root.width * scaleFactor
            height: root.height * scaleFactor
            scale: 1.0 / scaleFactor

            Image {
                anchors.fill: parent
                sourceSize.width: width
                sourceSize.height: height
                smooth: true
                antialiasing: true
                mipmap: true
                asynchronous: true
                property string outerBand: root.bandPath(modelData.outerS)
                property string innerBand: root.bandPath(modelData.innerS)
                source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='" + (-root.width / 2) + " " + (-root.height / 2) + " " + root.width + " " + root.height + "'><path d='" + outerBand + " " + innerBand + "' fill='black' fill-opacity='" + modelData.o + "' fill-rule='evenodd'/></svg>"
                rotation: root.shapeRotation
            }
        }
    }
}

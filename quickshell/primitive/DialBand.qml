import QtQuick
import QtQuick.Shapes
import "../variables.js" as Vars

// A band (film strip) that follows a ring, drawn behind the ring's items. Optional
// sprocket holes along each edge turn together with the dial.
Item {
    id: root

    // the ring's centre and radius (same coordinates as the thumbnails)
    property real cx: width
    property real cy: height
    property real radius: 350

    // thickness of the items on the ring (measured across the ring)
    property real frameHeight: 64   // degrees between two items, and how far the dial has turned
    property real stepDeg: 10
    property real scroll: 0

    // look
    required property var bandColor
    property bool showHoles: false
    required property var holeColor
    Component.onCompleted: {
        if (bandColor === undefined) console.error("DialBand: no bandColor was passed; there is no default, set it")
        if (holeColor === undefined) console.error("DialBand: no holeColor was passed; there is no default, set it")
    }
    property real edgeMargin: 16        // film border on each side of the frames
    property real holeSize: 6           // hole height, across the ring
    property real holeLength: 6      // hole width, along the ring
    property int holesPerFrame: 2

    // part of the circle that is drawn: a bit more than the visible quarter
    property real startDeg: 165
    property real sweepDeg: 120

    readonly property real stepRad: stepDeg * Math.PI / 180
    readonly property real bandWidth: frameHeight + 1 * edgeMargin

    // the holes sit in the middle of each border
    readonly property real innerHoleRadius: radius - frameHeight / 2 - edgeMargin / 2
    readonly property real outerHoleRadius: radius + frameHeight / 2 + edgeMargin / 2

    // dash patterns are measured in multiples of the stroke width
    function holeDash(r) {
        const pitch = stepRad * r / holesPerFrame            // px between two hole starts
        return [holeLength / holeSize, Math.max(0.2, (pitch - holeLength) / holeSize)]
    }

    // slide the pattern along with the dial (px travelled / stroke width)
    function holeOffset(r) {
        return -(scroll * Math.PI / 180) * r / holeSize
    }

    // liquid glass is on but not on rings: a flat wash with hairline edges instead
    readonly property bool flat: Prefs.liquidOn && !Prefs.liquidRings

    // liquid glass in the band's place (Settings → Liquid glass), over the dial's own: it
    // sees the wallpaper through the dial's colour under it
    LiquidGlass {
        id: glass
        anchors.fill: parent
        shape: "arc"
        cx: root.cx
        cy: root.cy
        radius: root.radius
        thickness: root.bandWidth
        startDeg: root.startDeg
        sweepDeg: root.sweepDeg
        roundEnds: false
        allowed: Prefs.liquidRings
        tint: Prefs.liquidBody(root.bandColor, "ring")
        under: host ? Prefs.liquidBody(host.color, host.glassKind) : "transparent"
    }

    Shape {
        anchors.fill: parent

        // analytic antialiasing on the GPU: smooth at any size, no offscreen layer
        preferredRendererType: Shape.CurveRenderer

        // the dark film band (glass when the shell is translucent: a step up from the dial
        // behind it either way, as the two layers of glass add up; liquid glass draws it
        // itself, above)
        ShapePath {
            strokeColor: glass.active ? "transparent" : root.flat ? Qt.rgba(1, 1, 1, Vars.design.flatBandWash) : Prefs.glass(root.bandColor, "ring")
            strokeWidth: root.bandWidth
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: root.cx; centerY: root.cy
                radiusX: root.radius; radiusY: root.radius
                startAngle: root.startDeg
                sweepAngle: root.sweepDeg
            }
        }

        // the flat band's hairline edges
        ShapePath {
            strokeColor: root.flat ? Qt.rgba(1, 1, 1, Vars.design.flatBandHairline) : "transparent"
            strokeWidth: 1
            fillColor: "transparent"
            PathAngleArc {
                centerX: root.cx; centerY: root.cy
                radiusX: root.radius + root.bandWidth / 2 - 0.5; radiusY: radiusX
                startAngle: root.startDeg
                sweepAngle: root.sweepDeg
            }
        }
        ShapePath {
            strokeColor: root.flat ? Qt.rgba(1, 1, 1, Vars.design.flatBandHairline) : "transparent"
            strokeWidth: 1
            fillColor: "transparent"
            PathAngleArc {
                centerX: root.cx; centerY: root.cy
                radiusX: root.radius - root.bandWidth / 2 + 0.5; radiusY: radiusX
                startAngle: root.startDeg
                sweepAngle: root.sweepDeg
            }
        }

        // sprocket holes, inner edge
        ShapePath {
            strokeColor: root.showHoles ? root.holeColor : "transparent"
            strokeWidth: root.holeSize
            strokeStyle: ShapePath.DashLine
            dashPattern: root.holeDash(root.innerHoleRadius)
            dashOffset: root.holeOffset(root.innerHoleRadius)
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: root.cx; centerY: root.cy
                radiusX: root.innerHoleRadius; radiusY: root.innerHoleRadius
                startAngle: root.startDeg
                sweepAngle: root.sweepDeg
            }
        }

        // sprocket holes, outer edge
        ShapePath {
            strokeColor: root.showHoles ? root.holeColor : "transparent"
            strokeWidth: root.holeSize
            strokeStyle: ShapePath.DashLine
            dashPattern: root.holeDash(root.outerHoleRadius)
            dashOffset: root.holeOffset(root.outerHoleRadius)
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: root.cx; centerY: root.cy
                radiusX: root.outerHoleRadius; radiusY: root.outerHoleRadius
                startAngle: root.startDeg
                sweepAngle: root.sweepDeg
            }
        }
    }
}

import QtQuick
import QtQuick.Shapes
import "../../theme"
import "../.."

Item {
    id: root
    property string side: "left" // "left", "right", "top-left", "top-right", "bottom-left", "bottom-right"
    property real radius: Vars.radiusExtraLarge
    property color color: Theme.surface

    width: radius
    height: radius

    property bool isRightSolid: (side === "left" || side === "top-right" || side === "bottom-right" || side === "bottom-left-attach" || side === "right-top" || side === "right-bottom")
    property bool isBottomSolid: (side === "bottom-left" || side === "bottom-right" || side === "bottom-left-attach" || side === "bottom-right-attach" || side === "right-top" || side === "left-top" || side === "left-bottom" || side === "right-bottom")

    property real power: Vars.cornerPower

    // No Behavior here: radius tracks the host panel's actual width/height (see TopPills.qml),
    // and most panels resize instantly with no matching behavior of their own. An animated
    // radius here would lag a frame-instant panel resize, leaving a stale corner at the old
    // size briefly visible until the animation caught up.

    // The fill runs this far past the solid edges, under the panel and past the screen edge, so
    // the curve is the only anti-aliased edge. Two anti-aliased edges meeting at a fractional
    // position would leave a hairline or a 1px step where the corner joins its panel.
    // (Skipped for translucent panels, where the overlap would show as a darker strip.)
    property real overlap: Vars.isTranslucent() ? 0 : 2
    property var _points: []

    // One outline: the extended solid corner, then along the solid vertical edge to where the
    // curve starts, the quarter superellipse (a circle at power 2) around the empty quarter, and
    // back along the solid horizontal edge. Points are offset by `overlap`, where the Shape starts.
    function updatePoints() {
        if (radius <= 0) {
            _points = [];
            return;
        }
        var R = radius;
        var ov = overlap;
        var hcx = isRightSolid ? 0 : R; // centre of the empty quarter
        var hcy = isBottomSolid ? 0 : R;
        var xe = isRightSolid ? R + ov : -ov; // solid edges, pushed under their neighbours
        var ye = isBottomSolid ? R + ov : -ov;
        var p = Math.max(2.0, power);

        var pts = [Qt.point(xe + ov, ye + ov), Qt.point(xe + ov, hcy + ov)];
        var steps = 64;
        for (var i = 0; i <= steps; i++) {
            var t = (i / steps) * (Math.PI / 2);
            var cx = Math.pow(Math.cos(t), 2.0 / p);
            var cy = Math.pow(Math.sin(t), 2.0 / p);
            var x = (hcx === 0) ? (R * cx) : (R - R * cx);
            var y = (hcy === 0) ? (R * cy) : (R - R * cy);
            pts.push(Qt.point(x + ov, y + ov));
        }
        pts.push(Qt.point(hcx + ov, ye + ov));
        _points = pts;
    }

    onRadiusChanged: updatePoints()
    onSideChanged: updatePoints()
    onPowerChanged: updatePoints()
    onOverlapChanged: updatePoints()
    Component.onCompleted: updatePoints()

    // Anti-aliased by multisampling its layer, which covers the overlap too so it isn't clipped
    Shape {
        x: -root.overlap
        y: -root.overlap
        width: root.radius + root.overlap * 2
        height: root.radius + root.overlap * 2
        antialiasing: true
        layer.enabled: true
        layer.smooth: true
        layer.samples: Vars.layerSamples

        ShapePath {
            fillColor: root.color
            strokeWidth: -1
            PathPolyline { path: root._points }
        }
    }
}

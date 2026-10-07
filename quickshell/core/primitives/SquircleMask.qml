import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import "../../theme"
Item {
    id: root
    property real topLeftRadius: 0
    property real topRightRadius: 0
    property real bottomLeftRadius: 0
    property real bottomRightRadius: 0
    property real power: Vars.cornerPower
    property color color: "black"
    property color borderColor: "transparent"
    property real borderWidth: 0

    property var _points: []

    Behavior on topLeftRadius { enabled: !Vars.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
    Behavior on topRightRadius { enabled: !Vars.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
    Behavior on bottomLeftRadius { enabled: !Vars.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
    Behavior on bottomRightRadius { enabled: !Vars.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

    function updatePoints() {
        if (power <= 2.0 || width <= 0 || height <= 0) return;
        var w = width;
        var h = height;
        var steps = 36; // Increased steps for much smoother curves
        var pts = [];

        var tl = Math.max(0, root.topLeftRadius);
        var tr = Math.max(0, root.topRightRadius);
        var br = Math.max(0, root.bottomRightRadius);
        var bl = Math.max(0, root.bottomLeftRadius);
        
        // TR
        pts.push(Qt.point(w - tr, 0));
        if (tr > 0) {
            for (var i = steps - 1; i >= 0; i--) {
                var u = (i / steps) * (Math.PI / 2);
                var ox = Math.pow(Math.cos(u), 2.0 / root.power) * tr;
                var oy = Math.pow(Math.sin(u), 2.0 / root.power) * tr;
                pts.push(Qt.point(w - tr + ox, tr - oy));
            }
        }
        
        // BR
        pts.push(Qt.point(w, h - br));
        if (br > 0) {
            for (var i = 1; i <= steps; i++) {
                var u = (i / steps) * (Math.PI / 2);
                var ox = Math.pow(Math.cos(u), 2.0 / root.power) * br;
                var oy = Math.pow(Math.sin(u), 2.0 / root.power) * br;
                pts.push(Qt.point(w - br + ox, h - br + oy));
            }
        }
        
        // BL
        pts.push(Qt.point(bl, h));
        if (bl > 0) {
            for (var i = steps - 1; i >= 0; i--) {
                var u = (i / steps) * (Math.PI / 2);
                var ox = Math.pow(Math.cos(u), 2.0 / root.power) * bl;
                var oy = Math.pow(Math.sin(u), 2.0 / root.power) * bl;
                pts.push(Qt.point(bl - ox, h - bl + oy));
            }
        }
        
        // TL
        pts.push(Qt.point(0, tl));
        if (tl > 0) {
            for (var i = 1; i <= steps; i++) {
                var u = (i / steps) * (Math.PI / 2);
                var ox = Math.pow(Math.cos(u), 2.0 / root.power) * tl;
                var oy = Math.pow(Math.sin(u), 2.0 / root.power) * tl;
                pts.push(Qt.point(tl - ox, tl - oy));
            }
        }
        
        // Close path
        pts.push(Qt.point(w - tr, 0));
        
        _points = pts;
    }

    onWidthChanged: updatePoints()
    onHeightChanged: updatePoints()
    onPowerChanged: updatePoints()
    onTopLeftRadiusChanged: updatePoints()
    onTopRightRadiusChanged: updatePoints()
    onBottomLeftRadiusChanged: updatePoints()
    onBottomRightRadiusChanged: updatePoints()
    Component.onCompleted: updatePoints()

    // The default cornerPower is 2 (a plain circular corner), which every card background in the
    // app — settings rows, desktop widgets, panels — renders through here. It only had the scene
    // graph's own single-pass edge antialiasing; the power>2.0 "expressive squircle" path below got
    // the much crisper layered multisampling. Giving this path the same layer brings every ordinary
    // rounded corner up to that same quality instead of just the squircle ones.
    Rectangle {
        anchors.fill: parent
        color: root.color
        border.color: root.borderColor
        border.width: root.borderWidth
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
        visible: root.power <= 2.0
        antialiasing: true
        smooth: true
        layer.enabled: true
        layer.smooth: true
        layer.samples: Vars.layerSamples
    }
    


    Shape {
        anchors.fill: parent
        visible: root.power > 2.0
        antialiasing: true
        smooth: true
        layer.enabled: true
        layer.smooth: true
        layer.samples: Vars.layerSamples
        
        ShapePath {
            fillColor: root.color
            strokeColor: root.borderColor
            strokeWidth: root.borderWidth
            PathPolyline { path: root._points }
        }
    }


}

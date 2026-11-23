import QtQuick
import QtQuick.Shapes

// A curved slider: a band along the arc where a group's circles fan out round the circle
// you hold (shell.qml places it). Drag the held circle onto the band: where it sits is the
// level (live while you move along it, kept when you let go). Its node (Tree.qml: slider())
// gives `label`, `icon`, `value` (0..1) and `set(v)`.
Item {
    id: root

    property var node: ({})

    // the arc: round (cx, cy) at `radius`, from angle a0 (radians, value 0) over `sweep`
    // (signed: the way value grows)
    property real cx: 0
    property real cy: 0
    property real radius: 170
    property real a0: 0
    property real sweep: 1
    property real thick: 40

    // how far off the band (px) or past its ends (share of it) still counts as on it
    property real reach: 12
    property real past: 0.12

    // what it shows; follows the node unless a circle is on it
    property real value: node.value || 0
    property bool hot: false

    // 0 → 1 as it comes out (the band draws itself from its start), back to 0 as it goes
    property real reveal: 0
    Component.onCompleted: reveal = 1
    Behavior on reveal { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

    anchors.fill: parent

    // the level at (x, y), or NaN when that's not on the band
    function valueAt(x, y) {
        if (Math.abs(Math.hypot(x - cx, y - cy) - radius) > thick / 2 + reach) return NaN
        let d = Math.atan2(y - cy, x - cx) - a0
        while (d > Math.PI) d -= 2 * Math.PI
        while (d <= -Math.PI) d += 2 * Math.PI
        const t = d / sweep
        return t < -past || t > 1 + past ? NaN : Math.max(0, Math.min(1, t))
    }

    // a circle on it at `v`: shown at once, set at most every 120 ms (ddcutil is slow)
    function slide(v) {
        value = v
        if (!throttle.running) { node.set(v); throttle.start() }
        else throttle.pending = true
    }
    // let go on it: set where it is now
    function commit() {
        throttle.stop()
        throttle.pending = false
        node.set(value)
        hot = false
        knob.kick()
    }
    Timer {
        id: throttle
        property bool pending: false
        interval: 120
        onTriggered: if (pending) { pending = false; root.node.set(root.value); start() }
    }

    // told to go: it draws itself back in, then is destroyed
    function leave() {
        hot = false
        reveal = 0
        goner.start()
    }
    Timer {
        id: goner
        interval: 340
        onTriggered: root.destroy()
    }

    readonly property real deg: 180 / Math.PI
    readonly property real at: a0 + sweep * value * reveal

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        opacity: Math.min(1, root.reveal * 1.6)

        // the band
        ShapePath {
            strokeColor: root.hot ? Colors.tertiary_container : Colors.secondary_container
            strokeWidth: root.thick
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.cx; centerY: root.cy
                radiusX: root.radius; radiusY: root.radius
                startAngle: root.a0 * root.deg
                sweepAngle: root.sweep * root.reveal * root.deg
            }
        }

        // the level so far
        ShapePath {
            strokeColor: root.hot ? Colors.tertiary : Colors.primary
            strokeWidth: root.thick - 10
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.cx; centerY: root.cy
                radiusX: root.radius; radiusY: root.radius
                startAngle: root.a0 * root.deg
                sweepAngle: root.sweep * root.value * root.reveal * root.deg
            }
        }
    }

    // the knob at the level, with the node's symbol
    Rectangle {
        id: knob
        readonly property real d: root.thick + 8
        x: root.cx + root.radius * Math.cos(root.at) - d / 2
        y: root.cy + root.radius * Math.sin(root.at) - d / 2
        width: d
        height: d
        radius: d / 2
        color: root.hot ? Colors.tertiary : Colors.primary
        border.width: 3
        border.color: Colors.surface_container
        opacity: root.reveal
        scale: 1 + bump
        property real bump: 0
        function kick() { pop.restart() }
        SequentialAnimation on bump {
            id: pop
            running: false
            NumberAnimation { to: 0.25; duration: 90; easing.type: Easing.OutCubic }
            NumberAnimation { to: 0; duration: 320; easing.type: Easing.OutBack }
        }
        Text {
            anchors.centerIn: parent
            text: root.node.icon || ""
            font.family: "Material Symbols Rounded"
            font.pixelSize: parent.d * 0.5
            color: root.hot ? Colors.on_tertiary : Colors.on_primary
        }
    }

    // its name and level, outside the middle of the band
    Rectangle {
        readonly property real mid: root.a0 + root.sweep / 2
        readonly property real out: root.radius + root.thick / 2 + 22
        x: root.cx + out * Math.cos(mid) - width / 2
        y: root.cy + out * Math.sin(mid) - height / 2
        width: words.implicitWidth + 18
        height: words.implicitHeight + 7
        radius: height / 2
        color: Colors.surface_container
        opacity: root.reveal
        Text {
            id: words
            anchors.centerIn: parent
            text: (root.node.label || "") + "  ·  " + Math.round(root.value * 100) + "%"
            font.pixelSize: 12
            font.weight: 600
            color: Colors.on_surface
        }
    }
}

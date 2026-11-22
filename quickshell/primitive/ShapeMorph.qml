import QtQuick
import QtQuick.Shapes
import "../variables.js" as Vars

// An M3 shape that morphs into another one when `shape` changes.
//
//   ShapeMorph { width: 40; height: 40; shape: on ? "Sunny" : "Circle"; color: Roles.primary }
//
// Two M3 paths are built from different curves, so they can't be blended curve by curve.
// Instead every shape is measured the same way: its distance from the centre at `detail`
// angles spread evenly around it (M3Shapes.getOutlinePoints). Any two shapes then line up
// angle by angle, and the morph blends those distances. The blend runs on an M3E spring,
// so the outline pops a little past the new shape and settles, and a new `shape` set
// mid-morph carries on from wherever the outline is, with no jump.
Item {
    id: root

    // the M3Shapes name to show (see primitive/M3Shapes.qml)
    property string shape: "Circle"

    // primitives never pick a colour: always pass one in
    required property color color

    // points around the outline: more is smoother, but slower to measure (once per shape)
    property int detail: 96

    // the morph's spring (M3E numbers: see Vars.springs)
    property real stiffness: Vars.springs.expressive.default.spatial.stiffness
    property real dampingRatio: Vars.springs.expressive.default.spatial.dampingRatio

    // distances from the centre (in M3Shapes' 0..box square) at each angle: the outline
    // the morph starts from, and the one it's heading to
    property var fromRadii: []
    property var toRadii: []

    // each shape's distances, measured once (keyed by name)
    property var _measured: ({})

    // the outline right now, in this item's pixels; closed (the last point is the first)
    readonly property var points: {
        const n = toRadii.length
        if (n === 0 || fromRadii.length !== n) return []
        const t = progress.value
        const c = Vars.m3ShapeBox / 2
        const sx = width / Vars.m3ShapeBox, sy = height / Vars.m3ShapeBox
        const out = []
        for (let k = 0; k <= n; k++) {
            const i = k % n
            const r = Math.max(0, fromRadii[i] + (toRadii[i] - fromRadii[i]) * t)
            const a = i / n * 2 * Math.PI
            out.push(Qt.point((c + Math.sin(a) * r) * sx, (c - Math.cos(a) * r) * sy))
        }
        return out
    }

    function radiiOf(name) {
        if (!_measured[name]) {
            const c = Vars.m3ShapeBox / 2
            _measured[name] = shapes.getOutlinePoints(name, detail).map(p => Math.hypot(p.x - c, p.y - c))
        }
        return _measured[name]
    }

    // where the outline is right now, as distances (mid-morph: part way between the two)
    function currentRadii() {
        const t = progress.value
        return toRadii.map((b, i) => fromRadii[i] + (b - fromRadii[i]) * t)
    }

    // `shape` as the design draws it: switching Shapes morphs every shape to its new form
    readonly property string _shown: shapes.styled(shape)

    // show `shape` straight away, with no morph
    function snap() {
        toRadii = radiiOf(_shown)
        fromRadii = toRadii
        progress.snap(1)
    }

    on_ShownChanged: {
        if (toRadii.length === 0) { snap(); return }
        fromRadii = currentRadii()
        toRadii = radiiOf(_shown)
        progress.snap(0)
        progress.start()
    }
    onDetailChanged: { _measured = {}; snap() }
    Component.onCompleted: snap()

    M3Shapes { id: shapes }

    // 0 = the outline it started from .. 1 = the new shape (overshoots a little past 1)
    SpringValue {
        id: progress
        to: 1
        value: 1
        stiffness: root.stiffness
        dampingRatio: root.dampingRatio
        epsilon: 0.001
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            PathPolyline { path: root.points }
        }
    }
}

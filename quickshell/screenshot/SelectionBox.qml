import QtQuick
import QtQuick.Shapes
import ".."
import "../primitive"
import "../variables.js" as Vars

// The screenshot tool's rectangle, drawn over the whole screen: everything outside it is
// darkened, and it has M3 handles (L-shaped brackets on the corners, capsules on the
// edges). Drag inside it to move it, drag a corner or an edge to resize it, or drag
// anywhere outside it to draw a new one. Double-click inside it to take the shot.
//
// `sel` is the rectangle (this item's px) and is what gets captured. The drawn rectangle
// springs to it when it's set from code (opening, full screen, arrow keys) and follows it
// exactly while you drag.
Item {
    id: root

    // ScreenshotSettings
    required property var cfg

    // the rectangle, in this item's px
    property rect sel: Qt.rect(0, 0, 0, 0)

    // 0..1: fades the darkening, the line and the handles in and out
    property real shown: 1

    // true while the mouse moves, resizes or draws it
    readonly property bool busy: mouse.pressed && mouse.mode !== ""

    // a double-click inside it
    signal accepted()

    // ── the drawn rectangle ── springs (M3E default spatial) to `sel`
    SpringValue {
        id: sx
        to: root.sel.x
        stiffness: Vars.springs.expressive.default.spatial.stiffness
        dampingRatio: Vars.springs.expressive.default.spatial.dampingRatio
        epsilon: 0.1
    }
    SpringValue {
        id: sy
        to: root.sel.y
        stiffness: Vars.springs.expressive.default.spatial.stiffness
        dampingRatio: Vars.springs.expressive.default.spatial.dampingRatio
        epsilon: 0.1
    }
    SpringValue {
        id: sw
        to: root.sel.width
        stiffness: Vars.springs.expressive.default.spatial.stiffness
        dampingRatio: Vars.springs.expressive.default.spatial.dampingRatio
        epsilon: 0.1
    }
    SpringValue {
        id: sh
        to: root.sel.height
        stiffness: Vars.springs.expressive.default.spatial.stiffness
        dampingRatio: Vars.springs.expressive.default.spatial.dampingRatio
        epsilon: 0.1
    }

    // where it's drawn right now (never negative while a spring overshoots below 0)
    readonly property real dx: sx.value
    readonly property real dy: sy.value
    readonly property real dw: Math.max(0, sw.value)
    readonly property real dh: Math.max(0, sh.value)

    // set the rectangle and draw it there at once, with no spring (dragging)
    function place(r) {
        sel = r
        sx.snap(r.x); sy.snap(r.y); sw.snap(r.width); sh.snap(r.height)
    }

    // grow it out of the point (x, y) into r, on the spring (opening)
    function growFrom(x, y, r) {
        sx.snap(x); sy.snap(y); sw.snap(0); sh.snap(0)
        sel = r

        // (started by hand: a spring only starts by itself when its target changes)
        sx.start(); sy.start(); sw.start(); sh.start()
    }

    // a rectangle kept on the screen and at least minSize, from any two corners
    function normalized(l, t, r, b) {
        const W = width, H = height
        let L = Math.max(0, Math.min(l, r)), R = Math.min(W, Math.max(l, r))
        let T = Math.max(0, Math.min(t, b)), B = Math.min(H, Math.max(t, b))
        return Qt.rect(L, T, R - L, B - T)
    }

    // what's under (x, y): "nw" "n" "ne" "e" "se" "s" "sw" "w" (a handle), "move" (inside),
    // or "new" (outside: drawing a new rectangle)
    function hitAt(x, y) {
        const r = sel, reach = cfg.handleReach
        if (r.width <= 0 || r.height <= 0) return "new"
        const L = r.x, T = r.y, R = r.x + r.width, B = r.y + r.height
        const nL = Math.abs(x - L) <= reach, nR = Math.abs(x - R) <= reach
        const nT = Math.abs(y - T) <= reach, nB = Math.abs(y - B) <= reach
        const inX = x >= L - reach && x <= R + reach, inY = y >= T - reach && y <= B + reach
        if (nL && nT) return "nw"
        if (nR && nT) return "ne"
        if (nL && nB) return "sw"
        if (nR && nB) return "se"
        if (nT && inX) return "n"
        if (nB && inX) return "s"
        if (nL && inY) return "w"
        if (nR && inY) return "e"
        if (x > L && x < R && y > T && y < B) return "move"
        return "new"
    }

    // the handle under the mouse (or the one held), for the hover look
    readonly property string hot: mouse.pressed ? mouse.mode : mouse.containsMouse ? hitAt(mouse.mouseX, mouse.mouseY) : ""

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: {
            switch (root.hot) {
            case "nw": case "se": return Qt.SizeFDiagCursor
            case "ne": case "sw": return Qt.SizeBDiagCursor
            case "n": case "s": return Qt.SizeVerCursor
            case "e": case "w": return Qt.SizeHorCursor
            case "move": return mouse.pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            default: return Qt.CrossCursor
            }
        }

        // what the press is doing ("" until a new rectangle has moved far enough to count)
        property string mode: ""
        property string pending: ""
        property real pressX: 0
        property real pressY: 0
        property rect start

        onPressed: m => {
            pressX = m.x
            pressY = m.y
            start = root.sel
            pending = root.hitAt(m.x, m.y)

            // a new rectangle starts once the mouse moves (a plain click outside changes nothing)
            mode = pending === "new" ? "" : pending
        }
        onPositionChanged: m => {
            if (!pressed) return
            if (mode === "" && pending === "new") {
                if (Math.hypot(m.x - pressX, m.y - pressY) < Qt.styleHints.startDragDistance) return
                mode = "new"
            }
            if (mode === "") return
            const dx = m.x - pressX, dy = m.y - pressY
            const s = start
            let L = s.x, T = s.y, R = s.x + s.width, B = s.y + s.height
            switch (mode) {
            case "move": {
                // slides, but never off the screen
                const nx = Math.max(0, Math.min(root.width - s.width, s.x + dx))
                const ny = Math.max(0, Math.min(root.height - s.height, s.y + dy))
                root.place(Qt.rect(nx, ny, s.width, s.height))
                return
            }
            case "new": L = pressX; T = pressY; R = m.x; B = m.y; break
            case "nw": L += dx; T += dy; break
            case "n": T += dy; break
            case "ne": R += dx; T += dy; break
            case "e": R += dx; break
            case "se": R += dx; B += dy; break
            case "s": B += dy; break
            case "sw": L += dx; B += dy; break
            case "w": L += dx; break
            }

            // dragging past the opposite side just turns it inside out
            root.place(root.normalized(L, T, R, B))
        }
        onReleased: {
            // too small to be a shot: grow it to minSize round its middle
            const r = root.sel, min = root.cfg.minSize
            if (mode !== "" && (r.width < min || r.height < min)) {
                const w = Math.max(min, r.width), h = Math.max(min, r.height)
                const cx = r.x + r.width / 2, cy = r.y + r.height / 2
                root.sel = root.normalized(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2)
            }
            mode = ""
            pending = ""
        }
        onDoubleClicked: m => { if (root.hitAt(m.x, m.y) === "move") root.accepted() }
    }

    // ── the darkening outside the rectangle (M3 scrim) ──
    Item {
        anchors.fill: parent
        opacity: root.shown

        readonly property color scrim: Qt.rgba(Roles.scrim.r, Roles.scrim.g, Roles.scrim.b, root.cfg.scrimOpacity)
        Rectangle { x: 0; y: 0; width: parent.width; height: root.dy; color: parent.scrim }
        Rectangle { x: 0; y: root.dy + root.dh; width: parent.width; height: parent.height - y; color: parent.scrim }
        Rectangle { x: 0; y: root.dy; width: root.dx; height: root.dh; color: parent.scrim }
        Rectangle { x: root.dx + root.dw; y: root.dy; width: parent.width - x; height: root.dh; color: parent.scrim }
    }

    // ── the line round it, just outside the shot ──
    Rectangle {
        x: root.dx - root.cfg.borderWidth
        y: root.dy - root.cfg.borderWidth
        width: root.dw + root.cfg.borderWidth * 2
        height: root.dh + root.cfg.borderWidth * 2
        color: "transparent"
        border.width: root.cfg.borderWidth
        border.color: Roles.primary
        opacity: root.shown
        visible: root.dw > 0 && root.dh > 0
    }

    // ── the handles ── each sits on its point (a corner or an edge's middle), grows under
    // the mouse, and shows the M3 state layer (a soft primary circle) behind it
    component Handle: Item {
        id: handle

        // which one: "nw" "n" "ne" "e" "se" "s" "sw" "w"
        required property string kind
        readonly property bool corner: kind.length === 2

        // its point on the rectangle
        readonly property real fx: kind.indexOf("w") >= 0 ? 0 : kind.indexOf("e") >= 0 ? 1 : 0.5
        readonly property real fy: kind.indexOf("n") >= 0 ? 0 : kind.indexOf("s") >= 0 ? 1 : 0.5
        x: root.dx + root.dw * fx
        y: root.dy + root.dh * fy

        readonly property bool hot: root.hot === kind
        readonly property bool held: hot && mouse.pressed

        // edge capsules only fit on a rectangle long enough for them
        visible: root.dw > 0 && root.dh > 0
            && (corner || ((kind === "n" || kind === "s") ? root.dw : root.dh) > root.cfg.edgeLength * 2.5)
        opacity: root.shown

        // the state layer
        Rectangle {
            width: root.cfg.handleHaloSize
            height: width
            x: -width / 2
            y: -height / 2
            radius: width / 2
            color: Roles.primary
            opacity: handle.held ? root.cfg.pressedOpacity : handle.hot ? root.cfg.hoverOpacity : 0
            Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
        }

        Item {
            scale: handle.hot ? root.cfg.handleHoverScale : 1
            Behavior on scale { NumberAnimation { duration: Prefs.fastSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier } }

            // a corner: an L hugging the outside of the corner (its arms run along the two
            // sides, so they point into the rectangle)
            Shape {
                id: bracket
                visible: handle.corner
                preferredRendererType: Shape.CurveRenderer
                readonly property real t: root.cfg.cornerThickness
                readonly property real a: root.cfg.cornerArm

                // +1 / -1: which way the arms run from the corner (into the rectangle)
                readonly property real sxSign: handle.fx === 0 ? 1 : -1
                readonly property real sySign: handle.fy === 0 ? 1 : -1

                // the corner of the L, out by half its thickness so it sits on the line
                readonly property real ox: -sxSign * (t / 2 - root.cfg.borderWidth)
                readonly property real oy: -sySign * (t / 2 - root.cfg.borderWidth)
                ShapePath {
                    strokeColor: Roles.primary
                    strokeWidth: bracket.t
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathPolyline {
                        path: [
                            Qt.point(bracket.ox, bracket.oy + bracket.sySign * bracket.a),
                            Qt.point(bracket.ox, bracket.oy),
                            Qt.point(bracket.ox + bracket.sxSign * bracket.a, bracket.oy)
                        ]
                    }
                }
            }

            // an edge: a capsule across the middle of the side
            Rectangle {
                visible: !handle.corner
                readonly property bool across: handle.kind === "n" || handle.kind === "s"
                width: across ? root.cfg.edgeLength : root.cfg.edgeThickness
                height: across ? root.cfg.edgeThickness : root.cfg.edgeLength
                x: -width / 2
                y: -height / 2
                radius: Math.min(width, height) / 2
                antialiasing: true
                color: Roles.primary
            }
        }
    }

    Handle { kind: "nw" }
    Handle { kind: "n" }
    Handle { kind: "ne" }
    Handle { kind: "e" }
    Handle { kind: "se" }
    Handle { kind: "s" }
    Handle { kind: "sw" }
    Handle { kind: "w" }
}

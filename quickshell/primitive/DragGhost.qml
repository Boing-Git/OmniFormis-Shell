import QtQuick
import "../variables.js" as Vars

// The thing you're dragging: an M3 shape that springs after the cursor, leans into the way
// it moves, morphs (and grows a little) over somewhere it can be dropped, and flies to
// wherever it lands, back where it came from, or off the way it was thrown when you let go.
// Whatever you put inside it (an icon, a picture) rides along.
//
//   DragGhost {
//       id: ghost
//       color: Roles.primary; shadowColor: Roles.shadow
//       hot: overSomewhere                     // morphs to hotShape while true
//       SymbolIcon { anchors.centerIn: parent; ... }
//       onDone: phase => ...                   // a flight ended: "land" | "back" | "fling"
//   }
//   ghost.pick(fromX, fromY, x, y)             // lifted: starts on its place, pill-sized
//   ghost.follow(x, y)                         // every move of the cursor
//   ghost.land(x, y)   ghost.back()   ghost.fling()      // let go
//
// Coordinates are the parent's px. It takes no mouse itself: feed it from whatever holds
// the drag (DialDelegate's claimedMoved / claimedReleased).
Item {
    id: root

    // its size, shape, and the shape it morphs into while `hot` (M3Shapes names)
    property real size: 64
    property string shape: "Circle"
    property string hotShape: "12SidedCookie"
    property bool hot: false

    // primitives never pick a colour: always pass them in (the shadow at full strength:
    // it's drawn at shadowOpacity)
    required property color color
    required property color shadowColor
    property real shadowOpacity: 0.28

    // its size when picked up, and over somewhere it can be dropped (1 = `size`)
    property real pickScale: 0.6
    property real hotScale: 1.12

    // it leans into the way it moves: degrees per 1000 px/s, never more than tiltMax
    property real tilt: 6
    property real tiltMax: 16

    // thrown: how far it flies on (seconds of its speed) and its size by the time it's gone
    property real flingCarry: 0.18
    property real flingEndScale: 0.4

    // ms the speed is smoothed over, and ms without a move after which a let-go counts as
    // still (you stopped, then let go: no throw)
    property real speedSmoothing: 40
    property int stillAfter: 80

    // "" (put away) | "drag" | "land" | "back" | "fling"
    property string phase: ""
    readonly property bool active: phase !== ""

    // a flight ended: "land" | "back" | "fling" (it's put away just after)
    signal done(string phase)

    default property alias content: holder.data

    // where the cursor is, where the drag started, and where a flight is heading
    property real cursorX: 0
    property real cursorY: 0
    property real homeX: 0
    property real homeY: 0
    property point target: Qt.point(0, 0)

    // the cursor's speed (px per second), and whether it was still when asked
    property real velX: 0
    property real velY: 0
    property real lastMove: 0
    readonly property real speed: Math.hypot(velX, velY)
    function still() { return Date.now() - lastMove > stillAfter }

    function pick(fromX, fromY, x, y) {
        flight.stop()
        homeX = fromX
        homeY = fromY
        cursorX = x
        cursorY = y
        velX = 0
        velY = 0
        lastMove = Date.now()

        // starts on its place, small, and springs to the cursor (started by hand: a spring
        // only starts by itself when its target changes)
        gx.snap(fromX)
        gy.snap(fromY)
        gs.snap(pickScale)
        phase = "drag"
        gx.start()
        gy.start()
        gs.start()
    }

    function follow(x, y) {
        const now = Date.now(), dt = Math.max(1, now - lastMove)
        const k = Math.min(1, dt / speedSmoothing)
        velX += ((x - cursorX) * 1000 / dt - velX) * k
        velY += ((y - cursorY) * 1000 / dt - velY) * k
        lastMove = now
        cursorX = x
        cursorY = y
    }

    // flies into (x, y) and shrinks away there
    function land(x, y) {
        if (phase !== "drag") return
        target = Qt.point(x, y)
        phase = "land"
        flight.restart()
    }

    // flies back to where it was picked up
    function back() {
        if (phase !== "drag") return
        phase = "back"
        flight.restart()
    }

    // keeps flying the way it was thrown
    function fling() {
        if (phase !== "drag") return
        target = Qt.point(cursorX + velX * flingCarry, cursorY + velY * flingCarry)
        gx.velocity = velX
        gy.velocity = velY
        phase = "fling"
        flight.restart()
    }

    // gone at once, no flight (e.g. so a screenshot doesn't catch it)
    function putAway() {
        flight.stop()
        phase = ""
    }

    Timer {
        id: flight
        interval: Prefs.defaultSpatial.duration
        onTriggered: {
            const p = root.phase
            root.phase = ""
            root.done(p)
        }
    }

    SpringValue {
        id: gx
        to: root.phase === "land" || root.phase === "fling" ? root.target.x : root.phase === "back" ? root.homeX : root.cursorX
        stiffness: Vars.springs.standard.fast.spatial.stiffness
        dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
        epsilon: 0.1
    }
    SpringValue {
        id: gy
        to: root.phase === "land" || root.phase === "fling" ? root.target.y : root.phase === "back" ? root.homeY : root.cursorY
        stiffness: Vars.springs.standard.fast.spatial.stiffness
        dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
        epsilon: 0.1
    }
    SpringValue {
        id: gs
        to: root.phase === "land" ? 0
            : root.phase === "fling" ? root.flingEndScale
            : root.phase === "back" ? root.pickScale
            : root.hot ? root.hotScale : 1
        stiffness: Vars.springs.expressive.fast.spatial.stiffness
        dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
        epsilon: 0.005
    }

    width: size
    height: size
    x: gx.value - width / 2
    y: gy.value - height / 2
    visible: active
    scale: Math.max(0, gs.value)
    rotation: Math.max(-tiltMax, Math.min(tiltMax, gx.velocity / 1000 * tilt))
    opacity: phase === "back" || phase === "fling" ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: Vars.expressiveDefaultEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveDefaultEffects.bezier } }

    // a soft shadow under it, so it reads as lifted
    ShapeMorph {
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.bottomMargin: -4
        shape: root.hot ? root.hotShape : root.shape
        color: Qt.rgba(root.shadowColor.r, root.shadowColor.g, root.shadowColor.b, root.shadowOpacity)
    }
    ShapeMorph {
        anchors.fill: parent
        shape: root.hot ? root.hotShape : root.shape
        color: root.color
    }
    Item {
        id: holder
        anchors.fill: parent
    }
}

import QtQuick
import "primitive"
import "variables.js" as Vars

// The launcher's dragging layer, drawn over the whole screen above the dial: the app you
// pulled off the ring and, just past the dial's edge, an arc of your workspaces to drop it
// on (it opens there, and you stay where you are). Dropped on another app on the ring it
// moves there instead (your own order).
//
// The launcher feeds it the drag (begin / move / release / cancel) and does what it reports
// (launchOn / reorder). It never takes the mouse itself: the dial keeps the drag while the
// button is held.
Item {
    id: root

    // the launcher's dial (a DialDelegate with tileAt / tileCenter, see AppLauncher.qml)
    required property var dial

    // the app was dropped on a workspace; on another app on the ring (apps indexes)
    signal launchOn(int workspace, var app)
    signal reorder(int from, int to)

    // ── settings ── sizes are px
    // the workspaces sit this far past the dial's edge (to their middle), with this many
    // degrees kept clear at each end of the arc
    property real arcGap: 50
    property real arcPad: 6

    // a workspace's size (smaller when they don't all fit), the space between two, and the
    // smallest they may get (fewer are shown before they get smaller than this)
    property real spotSize: 44
    property real spotGap: 10
    property real spotMinSize: 26

    // a drop within this many px of a workspace's middle lands on it
    property real spotReach: 38

    // ms between one workspace popping in and the next, and how much the one under the
    // app grows (it "inhales", like a tile taking a drop in the control center)
    property int spotStagger: 18
    property real inhaleScale: 1.25

    // the app while it's held: its size, its icon's size, and its M3 shapes (at rest, and
    // over somewhere it can be dropped)
    property real ghostSize: 72
    property real ghostIconSize: 40
    property string ghostShape: "Circle"
    property string ghostHotShape: Vars.selectedAppShape

    // how far past the workspaces the hint sits
    property real hintGap: 44

    // ── the drag ──
    // what's held: its entry in the launcher's `apps`, and its place there
    property var app: null
    property int appIndex: -1
    readonly property bool active: ghost.active

    function begin(app_, index, x, y, fromX, fromY) {
        app = app_
        appIndex = index
        ghost.pick(fromX, fromY, x, y)
        if (Hints.wants("app")) { hint = Hints.text("app"); Hints.shown("app"); hintTimer.restart() }
    }
    function move(x, y) { ghost.follow(x, y) }

    function release(x, y) {
        if (ghost.phase !== "drag") return
        ghost.follow(x, y)

        // read before the ghost flies off: both are only set while it's held
        const ws = hotWorkspace, tile = hotTile
        if (ws > 0) {
            const p = spotPoint(ws)
            landed = ws
            ghost.land(p.x, p.y)
            Hints.used("app")
            launchOn(ws, app)
            return
        }
        if (tile >= 0) {
            const c = dial.tileCenter(dial.tileAt(x - dial.x, y - dial.y))
            ghost.land(dial.x + c.x, dial.y + c.y)
            Hints.used("app")
            reorder(appIndex, tile)
            return
        }
        ghost.back()
    }

    // the drag was called off (e.g. the window lost the mouse): fly back
    function cancel() { ghost.back() }

    // the workspace the app is flying into (0: none), so it stays lit until it has landed
    property int landed: 0

    // ── hints ── (Hints.qml) what a held app can do, the first few times
    property string hint: ""
    Timer {
        id: hintTimer
        interval: Vars.hintHold
        onTriggered: root.hint = ""
    }

    // ── the workspaces ── an arc of them just past the dial's edge
    readonly property real cx: dial.x + dial.pivotX
    readonly property real cy: dial.y + dial.pivotY
    readonly property real arcRadius: dial.expandedSize + arcGap
    readonly property real arcSweep: Math.max(1, dial.sweepDeg - arcPad * 2)
    readonly property real arcLength: arcRadius * arcSweep * Math.PI / 180

    // how many fit (never smaller than spotMinSize), and how big each is
    readonly property int count: Math.max(1, Math.min(Workspaces.lastId, Math.floor(arcLength / (spotMinSize + spotGap))))
    readonly property real size: Math.min(spotSize, arcLength / count - spotGap)

    // they read left to right: towards larger angles where the arc runs that way on
    // screen, smaller ones otherwise (the same rule CurvedText follows)
    readonly property bool towardsLarger: Math.sin(dial.midDeg * Math.PI / 180) < 0
    function spotDeg(id) {
        const t = (id - 0.5) / count * arcSweep
        return towardsLarger ? dial.startDeg + arcPad + t : dial.startDeg + dial.sweepDeg - arcPad - t
    }
    function spotPoint(id) {
        const a = spotDeg(id) * Math.PI / 180
        return Qt.point(cx + arcRadius * Math.cos(a), cy + arcRadius * Math.sin(a))
    }

    // the workspace under the held app (0: none)
    readonly property int hotWorkspace: {
        if (ghost.phase !== "drag") return 0
        let best = 0, bestD = spotReach
        for (let id = 1; id <= count; id++) {
            const p = spotPoint(id)
            const d = Math.hypot(ghost.cursorX - p.x, ghost.cursorY - p.y)
            if (d < bestD) { best = id; bestD = d }
        }
        return best
    }

    // the other app on the ring under the held one (apps index, -1: none)
    readonly property int hotTile: {
        if (ghost.phase !== "drag" || hotWorkspace > 0) return -1
        const n = dial.tileAt(ghost.cursorX - dial.x, ghost.cursorY - dial.y)
        if (n === null) return -1
        const i = dial.wrapApp(n)
        return i === appIndex ? -1 : i
    }

    Repeater {
        model: root.count

        Item {
            id: spot
            required property int index
            readonly property int wsId: index + 1
            readonly property point at: root.spotPoint(wsId)
            readonly property bool hot: root.hotWorkspace === wsId || (ghost.phase === "land" && root.landed === wsId)
            readonly property bool here: Workspaces.focusedId === wsId
            readonly property bool occupied: Workspaces.windowCount(wsId) > 0

            // shown while an app is held (or landing), popping in one after another
            readonly property bool wanted: ghost.phase === "drag" || ghost.phase === "land"
            property bool shown: false
            onWantedChanged: {
                if (wanted) appear.restart()
                else { appear.stop(); shown = false }
            }
            Timer {
                id: appear
                interval: spot.index * root.spotStagger
                onTriggered: spot.shown = spot.wanted
            }

            // springs out from nothing, and grows while the app is over it
            SpringValue {
                id: grow
                to: spot.shown ? (spot.hot ? root.inhaleScale : 1) : 0
                stiffness: Vars.springs.expressive.fast.spatial.stiffness
                dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
                epsilon: 0.002
            }
            width: root.size
            height: root.size
            x: at.x - width / 2
            y: at.y - height / 2
            scale: Math.max(0, grow.value)
            visible: scale > 0.01

            // M3E roles, as on the workspace OSD: primary where it will land, primary-
            // container where you are, secondary-container where windows live, a surface
            // step for an empty one
            ShapeMorph {
                anchors.fill: parent
                shape: Workspaces.shapeOf(spot.wsId)
                color: spot.hot ? Roles.primary
                     : spot.here ? Roles.primary_container
                     : spot.occupied ? Roles.secondary_container
                     : Roles.surface_container_highest
                Behavior on color { ColorAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
            }
            SmoothText {
                anchors.centerIn: parent
                text: spot.wsId
                font.pixelSize: Math.max(10, root.size * 0.32)
                font.weight: 700
                color: spot.hot ? Roles.on_primary
                     : spot.here ? Roles.on_primary_container
                     : spot.occupied ? Roles.on_secondary_container
                     : Roles.on_surface_variant
            }
        }
    }

    // ── the hint ── past the workspaces, on the dial's middle line
    HintPill {
        text: root.active ? root.hint : ""
        readonly property real d: root.arcRadius + root.size / 2 + root.hintGap
        readonly property real midRad: root.dial.midDeg * Math.PI / 180
        centerX: root.cx + d * Math.cos(midRad)
        centerY: root.cy + d * Math.sin(midRad)
        z: 2

        // M3E: an inverse surface, as a tooltip / snackbar
        color: Roles.inverse_surface
        textColor: Roles.inverse_on_surface
    }

    // ── the held app ── its icon on a primary shape that follows the cursor
    DragGhost {
        id: ghost
        size: root.ghostSize
        shape: root.ghostShape
        hotShape: root.ghostHotShape
        hot: root.hotWorkspace > 0 || root.hotTile >= 0
        color: Roles.primary
        shadowColor: Roles.shadow
        z: 3
        onDone: { root.landed = 0; root.app = null; root.appIndex = -1; root.hint = ""; hintTimer.stop() }

        Image {
            anchors.centerIn: parent
            width: root.ghostIconSize
            height: width
            source: root.app ? root.app.icon : ""
            sourceSize: Qt.size(root.ghostIconSize * 2, root.ghostIconSize * 2)
            smooth: true

            // drawn at half its pixels, and tilting: mipmaps keep its edges smooth
            mipmap: true
        }
    }
}

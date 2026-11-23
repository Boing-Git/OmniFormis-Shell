import QtQuick
import QtQuick.Shapes

// One circle of the circle shell: an icon in a disc with its name under it.
//
// It behaves like a drop of liquid. It buds out of the circle it belongs to (`from`): it
// starts inside that one, travels to its place on a loose spring, stretched along the way
// it moves, and the liquid between the two (Goo) thins and pinches off as it gets there.
// Landing, being touched, being connected: each makes it wobble like jelly and settle. In
// its place it drifts a little, as if afloat. Connected, the liquid to its parent stays as
// a thread: the chain. Told to leave, it is drawn back into where it came from.
//
// The last circle of the chain is the one you hold: `grabbed`, it follows the hand, and
// the liquid between it and the circles round it reaches out as it nears them.
Item {
    id: root

    // what it stands for: { label, icon, leaf, note, on, image, art, ... } (see Tree.qml)
    property var node: ({})

    // the circle it came out of (null: the seed, which comes out of the screen's edge)
    property var from: null

    // where its middle is heading: its own place, or the hand while it is held
    property real toX: 0
    property real toY: 0

    // its own place (set when it's made): where it sits, and comes back to when let go
    property real homeX: toX
    property real homeY: toY

    // true while it is held and dragged: it keeps close to the hand, and doesn't drift
    property bool grabbed: false

    // its radius, px
    property real r: 34

    // "seed"       the first circle of every chain
    // "candidate"  can be connected to next
    // "chain"      connected
    // "done"       the chain was completed: the task ran
    // "gone"       leaving (it destroys itself once it has been drawn back in)
    property string role: "candidate"

    // true while the cursor is on it (set by the shell)
    property bool hot: false

    // ms before it starts out (so a group comes out one after another, not as one)
    property int delay: 0

    // its travel spring: looser than M3E's (380 / 0.7), so it swings a little past its
    // place and comes back; stiffer while it follows the hand
    property real stiffness: grabbed ? 720 : 300
    property real damping: grabbed ? 0.64 : 0.58

    // ── afloat ── in its place it drifts a few px round it, each circle on its own beat
    property real drift: 2.6
    property real driftPhase: 0
    readonly property real beat: (homeX * 0.013 + homeY * 0.007) % (Math.PI * 2)
    readonly property bool drifting: started && !grabbed && role !== "gone" && role !== "seed"
    NumberAnimation on driftPhase {
        from: 0; to: Math.PI * 2
        duration: 5200
        loops: Animation.Infinite
        running: root.drifting
    }
    readonly property real driftX: drifting ? drift * Math.sin(driftPhase + beat) : 0
    readonly property real driftY: drifting ? drift * Math.cos(driftPhase * 2 + beat) * 0.7 : 0

    // where its middle is right now, and how big it is right now (0..1 and a little over)
    readonly property real cx: sx.value + driftX
    readonly property real cy: sy.value + driftY
    readonly property real size: Math.max(0, grow.value)

    // ── the wobble ── a very bouncy spring round 0: pushed, it swings the disc long and
    // thin, then short and wide, and rings out. jiggle(0.2) is a swing of about 20%
    SpringValue {
        id: wob
        stiffness: 300
        dampingRatio: 0.2
        epsilon: 0.002
    }
    function jiggle(amount) { wob.kick(amount * Math.sqrt(wob.stiffness)) }

    // landing squashes it; a touch, joining the chain and the chain being done each push it
    onArrivedChanged: if (arrived) jiggle(-0.2)
    onHotChanged: if (hot) jiggle(0.1)
    onRoleChanged: {
        if (role === "chain") jiggle(0.26)
        else if (role === "done") jiggle(0.22)
    }

    // picked up, it gives a little; let go, it wobbles as it swings back to its place
    onGrabbedChanged: jiggle(grabbed ? 0.12 : -0.18)

    // true once it is (as good as) in its place: only then can it be dragged onto
    property bool started: false
    readonly property bool arrived: started && Math.hypot(cx - homeX, cy - homeY) < 14

    SpringValue { id: sx; to: root.toX; stiffness: root.stiffness; dampingRatio: root.damping; epsilon: 0.1 }
    SpringValue { id: sy; to: root.toY; stiffness: root.stiffness; dampingRatio: root.damping; epsilon: 0.1 }

    // the pop: M3E expressive fast (800 / 0.6), so it overshoots a little and settles
    SpringValue {
        id: grow
        to: root.fixedSize ? 1
            : !root.started || root.role === "gone" ? 0
            : root.role === "chain" || root.role === "done" ? 1.12
            : root.hot ? 1.1 : 1
        stiffness: 800
        dampingRatio: 0.6
        epsilon: 0.002
    }

    // one size always (the drop out of the edge): no pop, no grow on joining or hover; it
    // still squashes and wobbles, which changes its shape, not its size
    property bool fixedSize: false

    // it starts inside the circle it comes out of, at nothing
    Component.onCompleted: {
        sx.snap(from ? from.cx : toX)
        sy.snap(from ? from.cy : toY)
        grow.snap(fixedSize ? 1 : 0)
        if (delay > 0) starter.start()
        else begin()
    }
    function begin() {
        started = true
        sx.start()
        sy.start()
    }
    Timer {
        id: starter
        interval: root.delay
        onTriggered: root.begin()
    }

    // there at once, no travel (the seed, before it is pulled out from somewhere else)
    function jumpTo(x, y) {
        sx.snap(x)
        sy.snap(y)
    }

    // told to go: drawn back into (x, y) (where it came from) as it shrinks, then destroyed
    function leaveInto(x, y) {
        role = "gone"
        hot = false
        toX = x
        toY = y
        goner.restart()
    }
    Timer {
        id: goner
        interval: 360
        onTriggered: root.destroy()
    }

    // a ring that runs out from it (it was just connected, or the chain was completed)
    function pulse() { ring.restart() }

    // a task that stays out was just done: it lights up for a moment, with a ring and a wobble
    property bool lit: false
    function flash() {
        lit = true
        unlight.restart()
        pulse()
        jiggle(0.24)
    }
    Timer {
        id: unlight
        interval: 520
        onTriggered: root.lit = false
    }

    // the way it last travelled (degrees): the wobble swings along it
    property real heading: 0

    x: cx - r
    y: cy - r
    width: r * 2
    height: r * 2
    z: role === "chain" || role === "done" || role === "seed" ? 2 : 1

    // M3E roles: connected is primary, a finished chain tertiary; a task waiting to be
    // reached is tertiary-container, anything else to pass through secondary-container
    readonly property color fill: role === "done" || lit ? Colors.tertiary
        : role === "chain" ? Colors.primary
        : role === "seed" ? Colors.primary
        : node.leaf ? Colors.tertiary_container
        : Colors.secondary_container
    readonly property color ink: role === "done" || lit ? Colors.on_tertiary
        : role === "chain" ? Colors.on_primary
        : role === "seed" ? Colors.on_primary
        : node.leaf ? Colors.on_tertiary_container
        : Colors.on_secondary_container

    // ── the liquid to the circle it came out of ── under both discs. A candidate's
    // pinches off as it arrives; a connected one keeps a thread
    Goo {
        visible: !!root.from
        x: -root.x
        y: -root.y
        z: -1
        ax: root.from ? root.from.cx : 0
        ay: root.from ? root.from.cy : 0

        // (a little inside the parent's rim, so the neck's root never pokes out past a
        // parent that is squashed by its wobble)
        ar: root.from ? root.from.r * root.from.size * 0.94 : 0
        bx: root.cx
        by: root.cy
        br: root.r * root.size
        color: root.fill

        // a fatter neck than two plain circles would make, and it holds on longer: thick liquid
        spread: 0.62
        snapAt: 2.45

        // connected, a thread stays (px thick; a finished chain's swells)
        thread: root.role === "done" ? 13 : root.role === "chain" ? 9 : 0
        Behavior on thread { NumberAnimation { duration: 420; easing.type: Easing.OutBack } }
    }

    // the ring
    Rectangle {
        id: ringItem
        anchors.centerIn: parent
        width: root.r * 2
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 3
        border.color: root.fill
        opacity: 0
        ParallelAnimation {
            id: ring
            NumberAnimation { target: ringItem; property: "scale"; from: 1; to: 2.1; duration: 460; easing.type: Easing.OutCubic }
            NumberAnimation { target: ringItem; property: "opacity"; from: 0.55; to: 0; duration: 460; easing.type: Easing.OutCubic }
        }
    }

    // ── the disc ── stretched along the way it is moving (and squeezed across), like a
    // drop: the faster, the more
    Item {
        id: body
        anchors.fill: parent
        scale: root.size

        readonly property real speed: Math.hypot(sx.velocity, sy.velocity)
        onSpeedChanged: if (speed > 60) root.heading = Math.atan2(sy.velocity, sx.velocity) * 180 / Math.PI

        // long and thin along the way it moves (speed), times the wobble; what it gains
        // one way it gives up the other way, as a drop does
        readonly property real stretch: Math.min(0.26, speed / 3000)
        readonly property real along: (1 + stretch) * (1 + wob.value)
        readonly property real across: 1 / Math.sqrt(Math.max(0.5, along))
        transform: [
            Rotation { origin.x: root.r; origin.y: root.r; angle: -root.heading },
            Scale { origin.x: root.r; origin.y: root.r; xScale: body.along; yScale: body.across },
            Rotation { origin.x: root.r; origin.y: root.r; angle: root.heading }
        ]

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            antialiasing: true
            color: root.fill
            Behavior on color { ColorAnimation { duration: 180 } }

            // the state layer: a wash of the icon's colour while the cursor is on it
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: root.ink
                opacity: root.hot && root.role === "candidate" ? 0.1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        // a cover fills the circle (what's playing), a rim of the circle's own colour left
        // round it so it still shows what the circle is (on offer, connected, done). The
        // picture is the fill of a plain round Shape: no layers, no effects
        Image {
            id: cover
            source: root.node.art || ""
            asynchronous: true
            sourceSize: Qt.size(256, 256)
            visible: false
        }
        readonly property bool covered: cover.status === Image.Ready && root.role !== "done" && !root.lit
        Shape {
            anchors.fill: parent
            visible: body.covered
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "transparent"
                fillColor: "transparent"
                fillItem: body.covered ? cover : null

                // the picture is laid out at its own size from the top-left: fit it to the
                // circle (covering it, centred)
                readonly property real tw: Math.max(1, cover.implicitWidth)
                readonly property real th: Math.max(1, cover.implicitHeight)
                readonly property real fit: Math.max(root.r * 2 / tw, root.r * 2 / th)
                fillTransform: PlanarTransform.fromAffineMatrix(fit, 0, 0, fit, root.r - tw * fit / 2, root.r - th * fit / 2)
                PathAngleArc {
                    centerX: root.r
                    centerY: root.r
                    radiusX: root.r - 3.5
                    radiusY: root.r - 3.5
                    startAngle: 0
                    sweepAngle: 360
                }
            }
        }

        // an app shows its own icon instead of a symbol
        Image {
            anchors.centerIn: parent
            visible: !!root.node.image && root.role !== "done" && !root.lit && !body.covered
            width: root.r * 1.15
            height: width
            source: root.node.image || ""
            sourceSize: Qt.size(96, 96)
            smooth: true
        }
        Text {
            anchors.centerIn: parent
            visible: !body.covered && (!root.node.image || root.role === "done" || root.lit)
            text: (root.role === "done" || root.lit) && root.node.leaf ? "check" : (root.node.icon || "circle")
            font.family: "Material Symbols Rounded"
            font.pixelSize: root.r * 0.82
            color: root.ink
            Behavior on color { ColorAnimation { duration: 180 } }
        }

        // a dot on the rim: it is on (switched on, connected, playing, the one in use)
        Rectangle {
            readonly property bool shown: !!root.node.on && root.role !== "done" && root.role !== "gone"
            x: root.r * 1.42
            y: root.r * 0.14
            width: 14
            height: 14
            radius: 7
            color: root.role === "chain" ? Colors.tertiary : Colors.primary
            border.width: 2.5
            border.color: Colors.surface_container
            scale: shown ? 1 : 0
            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
        }
    }

    // its name, under it, on a pill of the surface so it reads over any wallpaper, with
    // its note (if it has one) smaller below: it comes up once the circle is in its place,
    // and goes along with it while it is held
    Rectangle {
        id: plate
        readonly property string note: root.role === "done" || root.role === "seed" ? "" : (root.node.note || "")
        visible: root.role !== "seed" && label.text !== "" && opacity > 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 6 + (1 - opacity) * 8
        width: Math.max(label.width, sub.visible ? sub.width : 0) + 18
        height: words.implicitHeight + 7
        radius: Math.min(height / 2, 13)
        color: Colors.surface_container
        opacity: root.arrived && root.role !== "gone" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Column {
            id: words
            anchors.centerIn: parent
            Text {
                id: label
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.role === "done" && root.node.done ? root.node.done : (root.node.label || "")
                width: Math.min(implicitWidth, 150)
                elide: Text.ElideRight
                font.pixelSize: 12
                font.weight: 600
                color: Colors.on_surface
            }
            Text {
                id: sub
                anchors.horizontalCenter: parent.horizontalCenter
                visible: text !== ""
                text: plate.note
                width: Math.min(implicitWidth, 150)
                elide: Text.ElideRight
                font.pixelSize: 11
                font.weight: 500
                color: Colors.on_surface_variant
            }
        }
    }
}

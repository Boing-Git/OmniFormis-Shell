import QtQuick
import QtQuick.Shapes
import "m3shapes.js" as M3

// The shells' mascots, drawn (they scale and take the theme's colours), M3E-chunky and
// springy:
//   "dial-e"   an M3E 12-sided cookie with googly eyes: the pupils hang loose and swing after
//              the point it looks at, like real googly eyes; little feet when it runs
//   "puffy"    a pufferfish in M3E's Puffy shape: it puffs up (bigger, spikes out) when poked
//              or held, breathes slowly at rest
//   "droplet"  a water drop: wobbles when touched, with a glassy shine and ripples under it
//
//   Mascot { kind: "dial-e"; width: 120; height: 120; body: Roles.primary_container; ... }
//
// It feels with everything it has: each feeling has its own M3 shape (the body morphs into it
// on a spring), its own colour (happyColor, sadColor, angryColor: pass the roles in), its own
// size, brows, eyes and mouth. Sized to how often it happens (lively-ux):
//   react("type")    a small bob (every letter: kept tiny)
//   react("delete")  a flinch
//   react("wrong")   sad: it droops (GhostIsh), cries, brows up, cooler colour (rare: big)
//   react("right")   happy: Sunny, a hop, a big smile, squinting eyes
//   react("name")    it heard its name: happy, with a hop and a turn
//   react("dizzy")   flung too hard: SoftBoom, its eyes go round and round
//   react("land")    put down: a squash
//   poke()           startled; cheer() a happy hop; puffTo(v) / puffBy(v) Puffy's puff (0..1)
// By itself it blinks and breathes; `look` (-1..1 on each axis) is where it looks; `asleep`
// closes its eyes (Arch: curled up) and lets small z's rise; `shy` looks away (a password is
// being typed), with a blink; `run` makes it run (a hamster in its wheel: the feet patter, it
// bobs and leans into it; the sign is the way). With `calm` (reduced motion) every feeling
// still shows (shape, colour, face) but nothing travels, bounces or idles.
//
// With `interactive` it has a mouse of its own: a click pokes it, resting the pointer on it
// pets it, and with `draggable` it can be picked up (`held`): it says grabbed(), dragTo(p) (p
// in its parent: the host decides where it may go) and dropped(vx, vy) (px / s).
//
// Hidden in it (CLAUDE.md, Spoilers): poke it five times quickly and it gets cross; pet it and
// it loves you; fling it and it gets dizzy; say its name to it; wake it in the small hours and
// it yawns.
Item {
    id: root

    property string kind: "dial-e"

    required property color body
    required property color ink
    required property color eyeWhite

    // the pupils and the eyes' rims: dark on the eye's white in light and dark themes alike
    required property color pupil
    required property color accent

    // the feelings' colours (without one, the body keeps its colour for that feeling)
    property color happyColor: body
    property color sadColor: body
    property color angryColor: body

    // where it looks: (-1, -1) top left .. (1, 1) bottom right
    property point look: Qt.point(0, 0)
    property bool asleep: false

    // ── shy ── it looks away, up and to `shySide` (-1 left, 1 right), and turns a little
    // (narrower): a password is being typed. A blink as it turns away and back
    property bool shy: false
    property real shySide: -1
    onShyChanged: blink.restart()

    // ── running ── a hamster in its wheel: 0 still, ±1 a jog, ±3 flat out (the sign: which way)
    property real run: 0
    readonly property bool running: Math.abs(run) > 0.05

    // reduced motion (Dial-E: Bounce 0, Prefs.calm): no wobble, no swing, nothing idles. A
    // property, so Puffy and Droplet can use this same file (they link it) without Dial-E's Prefs
    property bool calm: false
    readonly property real s: Math.min(width, height)

    // ── how it feels ── "", "happy", "sad", "angry", "love" or "dizzy", for a moment
    property string mood: ""
    Timer { id: moodClock; onTriggered: { root.mood = ""; if (root.held) return; blink.restart() } }
    function feel(m, ms) { mood = m; moodClock.interval = ms; moodClock.restart() }

    function react(kind) {
        if (kind === "type") {
            if (!calm) { sy.kick(-0.9); sx.kick(0.5) }
            if (mood === "sad") mood = ""
        } else if (kind === "delete") {
            if (!calm) { sx.kick(-0.9); sy.kick(0.7) }
            blink.restart()
        } else if (kind === "wrong") {
            feel("sad", 2400)
            puffTo(0)
            if (!calm) { wobble.kick(120); sx.kick(1.6); sy.kick(1.2) }
        } else if (kind === "right" || kind === "name") {
            feel("happy", kind === "name" ? 2200 : 1800)
            cheer()
            spin.to += 30
        } else if (kind === "dizzy") {
            feel("dizzy", 2600)
            if (!calm) { wobble.kick(200); spin.to += 360 }
        } else if (kind === "land") {
            if (!calm) { sy.kick(3.2); sx.kick(-2.4) }
        } else if (kind === "poke") {
            poke()
        }
    }

    // ── what each feeling looks like ── its M3 shape (rest first; a drop for Droplet), and
    // its size
    readonly property var shapes: ({
        "dial-e":  { "": "12SidedCookie", happy: "Sunny", sad: "GhostIsh", angry: "Burst", love: "Heart", dizzy: "SoftBoom", asleep: "Arch" },
        "puffy":   { "": "Puffy", happy: "Flower", sad: "GhostIsh", angry: "Boom", love: "Heart", dizzy: "SoftBurst", asleep: "Puffy" },
        "droplet": { "": "M50 5C50 5 16 47 16 64C16 83 31 95 50 95C69 95 84 83 84 64C84 47 50 5 50 5Z",
                     happy: "8LeafClover", sad: "GhostIsh", angry: "Burst", love: "Heart", dizzy: "Puffy", asleep: "Semicircle" }
    })
    readonly property string feeling: mood !== "" ? mood : asleep ? "asleep" : ""
    readonly property string shapeNow: (shapes[kind] || shapes["dial-e"])[feeling] || (shapes[kind] || shapes["dial-e"])[""]
    readonly property real feelingSize: ({ happy: 1.06, love: 1.08, angry: 1.14, sad: 0.9, asleep: 0.97 })[feeling] || 1

    // the body's colour: the feeling's (a quick crossfade, never a bounce)
    readonly property color bodyNow: mood === "happy" || mood === "love" ? happyColor : mood === "sad" ? sadColor : mood === "angry" ? angryColor : body
    property color shownBody: bodyNow
    Behavior on shownBody { ColorAnimation { duration: 260 } }

    // ── the morph ── every shape measured the same way (its distance from the centre at
    // `detail` angles, m3shapes.js), so any two blend angle by angle, on a spring that pops a
    // little past the new shape; a new feeling mid-morph carries on from where the outline is
    readonly property int detail: 72
    property var _measured: ({})
    function _radii(name) { if (!_measured[name]) _measured[name] = M3.radii(name, detail); return _measured[name] }
    property var _from: []
    property var _to: []
    SpringValue { id: morph; to: 1; value: 1; stiffness: 260; dampingRatio: root.calm ? 1 : 0.5; epsilon: 0.002 }
    onShapeNowChanged: {
        const t = morph.value
        _from = _to.length === 0 ? _radii(shapeNow) : _to.map((b, i) => _from[i] + (b - _from[i]) * t)
        _to = _radii(shapeNow)
        morph.snap(0)
        morph.start()
    }
    Component.onCompleted: { _to = _radii(shapeNow); _from = _to }

    // the outline now, in a w × w box: closed (the last point is the first)
    function outline(w) {
        const n = _to.length
        if (n === 0 || _from.length !== n) return []
        const t = morph.value, k = w / 100, out = []
        for (let j = 0; j <= n; j++) {
            const i = j % n, a = i / n * 2 * Math.PI
            const r = Math.max(0, _from[i] + (_to[i] - _from[i]) * t)
            out.push(Qt.point((50 + Math.sin(a) * r) * k, (50 - Math.cos(a) * r) * k))
        }
        return out
    }

    // where the eyes go: down when sad, up when happy, round and round when dizzy, away when
    // shy, down at the ground while held, else where it's told to look
    readonly property point gaze: mood === "dizzy" ? Qt.point(Math.cos(dizzy.t), Math.sin(dizzy.t))
        : mood === "sad" ? Qt.point(look.x * 0.3, 0.9) : mood === "happy" || mood === "love" ? Qt.point(look.x * 0.3, -0.7)
        : held ? Qt.point(0, 1) : shy ? Qt.point(shySide, -0.9)
        : running ? Qt.point(run > 0 ? 1 : -1, 0.2) : look
    NumberAnimation {
        id: dizzy
        target: dizzy
        property: "t"
        from: 0
        to: Math.PI * 2
        duration: 520
        loops: Animation.Infinite
        running: root.mood === "dizzy" && !root.calm && root.visible
        property real t: 0
    }

    // the mouth: -1 a frown .. 0 flat .. 1 a big smile (resting: a small one); an "o" while
    // held, and for a yawn
    SpringValue { id: smileS; to: root.mood === "happy" || root.mood === "love" ? 1 : root.mood === "sad" ? -1 : root.mood === "angry" ? -0.7 : root.mood === "dizzy" ? 0 : 0.35; stiffness: 300; dampingRatio: root.calm ? 1 : 0.5; epsilon: 0.005 }
    property bool yawning: false
    readonly property bool mouthO: held || yawning

    // ── the body's squash and stretch ── one spring per axis; sad, it droops; held, it hangs
    SpringValue { id: sx; to: root.mood === "sad" ? 1.06 : root.held ? 0.92 : root.shy && root.mood === "" ? 0.93 : 1; value: 1; stiffness: 520; dampingRatio: root.calm ? 1 : 0.35; epsilon: 0.001 }
    SpringValue { id: sy; to: root.mood === "sad" ? 0.9 : root.held ? 1.1 : 1; value: 1; stiffness: 520; dampingRatio: root.calm ? 1 : 0.35; epsilon: 0.001 }
    SpringValue { id: grow; to: root.feelingSize * (root.held ? 1.04 : 1); value: 1; stiffness: 300; dampingRatio: root.calm ? 1 : 0.45; epsilon: 0.001 }
    SpringValue { id: hop; to: 0; value: 0; stiffness: 260; dampingRatio: root.calm ? 1 : 0.45; epsilon: 0.1 }
    // the body turns in twelfths (30°): Dial-E's cookie always lands on itself
    SpringValue { id: spin; to: 0; value: 0; stiffness: 160; dampingRatio: root.calm ? 1 : 0.55; epsilon: 0.05 }
    function poke() {
        if (calm) return
        sx.kick(2.2); sy.kick(-2.6)
        for (const e of [pupilL, pupilR, puffyEye, dropL, dropR]) { e.springX.kick(Math.random() * 600 - 300); e.springY.kick(Math.random() * 600 - 300) }
        puffBy(0.6)
        wobble.kick(160)
        ripples.start()
    }
    function cheer() { if (!calm) { hop.kick(-900); sy.kick(-2) } }

    // cross: it shakes (the angry shape and colour come with the mood)
    SpringValue { id: shake; to: 0; value: 0; stiffness: 900; dampingRatio: root.calm ? 1 : 0.12; epsilon: 0.05 }
    onMoodChanged: if (mood === "angry" && !calm) shake.kick(400)

    // ── running ── the feet patter and the body bobs, faster the faster it runs; it leans into it
    property real stride: 0
    FrameAnimation {
        running: root.running && !root.calm && root.visible
        onTriggered: root.stride += frameTime * Math.max(-3, Math.min(3, root.run)) * 14
    }
    readonly property real bob: running && !calm ? Math.abs(Math.sin(stride)) : 0
    SpringValue { id: lean; to: root.calm ? 0 : Math.max(-14, Math.min(14, root.run * 7)); value: 0; stiffness: 200; dampingRatio: 0.7; epsilon: 0.05 }

    // ── blinking ── every few seconds, never in step with another mascot
    property real lid: 1
    Timer {
        interval: 2600 + Math.random() * 3200
        running: !root.asleep && !root.calm && root.visible
        repeat: true
        onTriggered: { interval = 2600 + Math.random() * 3200; blink.restart() }
    }
    SequentialAnimation {
        id: blink
        NumberAnimation { target: root; property: "lid"; to: 0.08; duration: 70 }
        NumberAnimation { target: root; property: "lid"; to: 1; duration: 110 }
    }
    // happy or in love, it squints; asleep, the eyes are shut; held, they're wide
    readonly property real eyeOpen: asleep ? 0.06 : mood === "happy" || mood === "love" ? Math.min(lid, 0.4) : lid

    // woken in the small hours (midnight to five), it yawns
    onAsleepChanged: if (!asleep && new Date().getHours() < 5) { yawning = true; yawnEnd.restart() }
    Timer { id: yawnEnd; interval: 1300; onTriggered: root.yawning = false }

    // ── breathing ── a slow swell at rest (not with reduced motion)
    property real breath: 0
    SequentialAnimation on breath {
        loops: Animation.Infinite
        running: !root.calm && root.visible
        NumberAnimation { to: 1; duration: 1900; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: 1900; easing.type: Easing.InOutSine }
    }

    // the whole body's motion, shared by the three: squash and stretch from the feet, the
    // feeling's size, the hop, the shake, the run's bob and lean
    component Body: Item {
        anchors.fill: parent
        transform: [
            Scale { origin.x: root.s / 2; origin.y: root.s; xScale: sx.value * grow.value * (1 + root.breath * 0.02); yScale: sy.value * grow.value * (1 + root.breath * 0.03) },
            Rotation { origin.x: root.s / 2; origin.y: root.s; angle: lean.value },
            Translate { x: shake.value * root.s / 900; y: hop.value * root.s / 400 - root.bob * root.s * 0.06 }
        ]
    }

    // ── a googly eye ── its pupil swings after `gaze` on a loose spring, and hangs a little
    // low at rest (gravity)
    component GooglyEye: Item {
        id: eye
        property real size
        readonly property real travel: size * 0.22
        // the pupil's two springs (poke kicks them)
        readonly property alias springX: px
        readonly property alias springY: py
        SpringValue { id: px; to: root.gaze.x * eye.travel; stiffness: root.mood === "dizzy" ? 400 : 140; dampingRatio: root.calm ? 1 : 0.22; epsilon: 0.05 }
        SpringValue { id: py; to: root.gaze.y * eye.travel + eye.travel * 0.35; stiffness: root.mood === "dizzy" ? 400 : 140; dampingRatio: root.calm ? 1 : 0.22; epsilon: 0.05 }
        width: size
        height: size
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: root.eyeWhite
            border.width: Math.max(1, eye.size * 0.06)
            border.color: root.pupil
            transform: Scale { origin.x: eye.size / 2; origin.y: eye.size / 2; yScale: root.eyeOpen }
        }
        Rectangle {
            width: eye.size * (root.held ? 0.34 : 0.46)
            height: width
            radius: width / 2
            color: root.pupil
            visible: root.eyeOpen > 0.3
            x: eye.size / 2 - width / 2 + Math.max(-eye.travel, Math.min(eye.travel, px.value))
            y: eye.size / 2 - height / 2 + Math.max(-eye.travel, Math.min(eye.travel, py.value))
        }
        // a tear, while it's sad: it wells up under the eye and falls (still, with calm)
        Rectangle {
            width: Math.max(3, eye.size * 0.42)
            height: width * 1.35
            radius: width / 2
            x: eye.size * 0.55
            y: eye.size * 0.75 + fall.t * eye.size * 1.6
            // light, so it reads as a tear on any of the three bodies
            color: root.eyeWhite
            visible: root.mood === "sad"
            opacity: root.calm ? 0.9 : 1 - fall.t
        }
        NumberAnimation {
            id: fall
            target: fall
            property: "t"
            from: 0
            to: 1
            duration: 760
            loops: Animation.Infinite
            running: root.mood === "sad" && !root.calm && root.visible
            easing.type: Easing.InQuad
            property real t: 0
            onRunningChanged: if (!running) t = 0
        }
    }

    // a brow over an eye at (x, y) `w` wide: down at the middle when cross, up at the middle
    // when sad (`side` -1 for the left eye, 1 for the right)
    component Brow: Shape {
        id: brow
        property real x0
        property real y0
        property real w
        property real side: -1
        readonly property real tilt: root.mood === "angry" ? 1 : root.mood === "sad" ? -0.8 : 0
        visible: tilt !== 0
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: root.ink
            strokeWidth: root.s * 0.05
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            // the end nearest the middle drops (cross) or rises (sad)
            startX: brow.x0; startY: brow.y0 + (brow.side < 0 ? -1 : 1) * brow.tilt * root.s * 0.04
            PathLine { x: brow.x0 + brow.w; y: brow.y0 + (brow.side < 0 ? 1 : -1) * brow.tilt * root.s * 0.04 }
        }
    }

    // a mouth: a curve from x0 to x1 at height y0, bent by the smile (x0 / x1: Item has left /
    // right); an "o" instead while held or yawning
    component Mouth: Item {
        id: mouth
        property real x0
        property real x1
        property real y0
        property real bend: root.s * 0.09
        anchors.fill: parent
        Shape {
            anchors.fill: parent
            visible: !root.mouthO
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: root.ink
                strokeWidth: root.s * 0.045
                capStyle: ShapePath.RoundCap
                fillColor: "transparent"
                startX: mouth.x0; startY: mouth.y0
                PathQuad { x: mouth.x1; y: mouth.y0; controlX: (mouth.x0 + mouth.x1) / 2; controlY: mouth.y0 + mouth.bend * smileS.value + root.s * 0.02 * root.breath }
            }
        }
        Rectangle {
            visible: root.mouthO
            width: (mouth.x1 - mouth.x0) * (root.yawning ? 0.75 : 0.55)
            height: width * (root.yawning ? 1.3 : 1)
            radius: width / 2
            x: (mouth.x0 + mouth.x1) / 2 - width / 2
            y: mouth.y0 - height / 2
            color: root.ink
        }
    }

    // z's rising while it sleeps (it means something: it's asleep); one still z with calm
    Repeater {
        model: root.asleep ? 2 : 0
        Text {
            required property int index
            readonly property real t: root.calm ? 0.3 : (zz.t + index * 0.5) % 1
            text: "z"
            font.pixelSize: Math.max(7, root.s * (0.18 + 0.1 * t))
            font.weight: 700
            color: root.accent
            x: root.s * (0.78 + 0.12 * t)
            y: root.s * (0.05 - 0.3 * t)
            opacity: root.calm ? 0.8 : Math.sin(t * Math.PI)
        }
    }
    NumberAnimation {
        id: zz
        target: zz
        property: "t"
        from: 0
        to: 1
        duration: 2600
        loops: Animation.Infinite
        running: root.asleep && !root.calm && root.visible
        property real t: 0
    }

    // hearts rising while it's in love; one still heart with calm
    Repeater {
        model: root.mood === "love" ? 3 : 0
        Text {
            required property int index
            readonly property real t: root.calm ? 0.4 : (hearts.t + index / 3) % 1
            text: "♥"
            font.pixelSize: Math.max(8, root.s * (0.16 + 0.08 * t))
            color: root.accent
            x: root.s * (0.15 + 0.35 * index + 0.06 * Math.sin(t * 6))
            y: root.s * (0.1 - 0.4 * t)
            opacity: root.calm ? 0.9 : Math.sin(t * Math.PI)
        }
    }
    NumberAnimation {
        id: hearts
        target: hearts
        property: "t"
        from: 0
        to: 1
        duration: 1800
        loops: Animation.Infinite
        running: root.mood === "love" && !root.calm && root.visible
        property real t: 0
    }

    // ── Dial-E ── the cookie (or the feeling's shape), two googly eyes, brows, a mouth, and
    // feet that come out when it runs or dangles
    Body {
        visible: root.kind === "dial-e"

        // the feet, under the body
        Repeater {
            model: root.kind === "dial-e" ? 2 : 0
            Rectangle {
                required property int index
                readonly property real phase: root.stride + index * Math.PI
                width: root.s * 0.16
                height: root.s * 0.1
                radius: height / 2
                color: root.ink
                x: root.s * (index === 0 ? 0.3 : 0.54) + (root.running && !root.calm ? Math.cos(phase) * root.s * 0.05 * (root.run > 0 ? 1 : -1) : 0)
                y: root.s * 0.86 - (root.running && !root.calm ? Math.max(0, Math.sin(phase)) * root.s * 0.07 : 0) + (root.held && !root.calm ? Math.sin(root.stride * 2 + index) * root.s * 0.02 : 0)
                opacity: root.running || root.held ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 140 } }
            }
        }
        Shape {
            id: cookie
            width: root.s * 0.96
            height: width
            anchors.centerIn: parent
            preferredRendererType: Shape.CurveRenderer
            rotation: spin.value + root.breath * 3
            ShapePath {
                fillColor: root.shownBody
                strokeColor: "transparent"
                PathPolyline { path: root.kind === "dial-e" ? root.outline(cookie.width) : [] }
            }
        }
        GooglyEye { id: pupilL; size: root.s * 0.28; x: root.s * 0.21; y: root.s * 0.25 }
        GooglyEye { id: pupilR; size: root.s * 0.28; x: root.s * 0.51; y: root.s * 0.25 }
        Brow { x0: root.s * 0.22; y0: root.s * 0.2; w: root.s * 0.24; side: -1 }
        Brow { x0: root.s * 0.54; y0: root.s * 0.2; w: root.s * 0.24; side: 1 }
        Mouth { x0: root.s * 0.40; x1: root.s * 0.60; y0: root.s * 0.68 }
    }

    // ── Puffy ── a fish in M3E's Puffy shape (or the feeling's) that grows as it puffs up
    // (puff 0..1: its scale), spikes out behind it; one big eye, a tail and a little "o" mouth
    SpringValue { id: puffSpring; to: 0; value: 0; stiffness: 170; dampingRatio: root.calm ? 1 : 0.4; epsilon: 0.002 }
    readonly property real puff: Math.max(0, Math.min(1.2, puffSpring.value + (kind === "puffy" ? breath * 0.12 : 0) + (mood === "angry" ? 0.6 : 0)))
    function puffBy(v) { if (kind === "puffy" && !calm) puffSpring.kick(v * 12) }
    function puffTo(v) { puffSpring.to = v }

    Body {
        id: fish
        visible: root.kind === "puffy"
        // its scale: the body grows a quarter as it puffs all the way up
        readonly property real bloat: 1 + 0.25 * root.puff
        readonly property real r: root.s * 0.31 * bloat
        readonly property real cx: root.s * 0.54
        readonly property real cy: root.s * 0.52

        // the tail, behind the body: it wags as Puffy swims (runs)
        Shape {
            id: tail
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            readonly property real wag: root.running && !root.calm ? Math.sin(root.stride * 1.5) * root.s * 0.06 : 0
            ShapePath {
                fillColor: root.accent
                strokeColor: root.accent
                strokeWidth: root.s * 0.04
                joinStyle: ShapePath.RoundJoin
                startX: fish.cx - fish.r * 0.8; startY: fish.cy
                PathLine { x: root.s * 0.06; y: fish.cy - root.s * 0.14 + tail.wag }
                PathLine { x: root.s * 0.10; y: fish.cy + tail.wag }
                PathLine { x: root.s * 0.06; y: fish.cy + root.s * 0.14 + tail.wag }
                PathLine { x: fish.cx - fish.r * 0.8; y: fish.cy }
            }
        }

        // the spikes: a star round the body, out only as it puffs (soft tips: a thick,
        // round-joined stroke)
        Shape {
            id: spikes
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            opacity: Math.min(1, root.puff * 2.5)
            readonly property int n: 14
            readonly property string path: {
                const cx = fish.cx, cy = fish.cy, r = fish.r * 0.9, tip = fish.r * (0.95 + 0.3 * root.puff)
                let d = ""
                for (let i = 0; i <= n * 2; i++) {
                    const a = i / (n * 2) * Math.PI * 2, rr = i % 2 ? tip : r
                    d += (i ? " L " : "M ") + (cx + rr * Math.cos(a)).toFixed(2) + " " + (cy + rr * Math.sin(a)).toFixed(2)
                }
                return d + " Z"
            }
            ShapePath {
                fillColor: root.accent
                strokeColor: root.accent
                strokeWidth: root.s * 0.035
                joinStyle: ShapePath.RoundJoin
                PathSvg { path: spikes.path }
            }
        }
        Shape {
            id: puffyBody
            width: fish.r * 2.1
            height: width
            x: fish.cx - width / 2
            y: fish.cy - height / 2
            preferredRendererType: Shape.CurveRenderer
            rotation: spin.value
            ShapePath {
                fillColor: root.shownBody
                strokeColor: "transparent"
                PathPolyline { path: root.kind === "puffy" ? root.outline(puffyBody.width) : [] }
            }
        }
        GooglyEye { id: puffyEye; size: root.s * 0.24; x: fish.cx + fish.r * 0.05; y: fish.cy - fish.r * 0.62 }
        Brow { x0: fish.cx + fish.r * 0.05; y0: fish.cy - fish.r * 0.78; w: root.s * 0.22; side: 1 }
        // the little "o" mouth: rounder when puffed, a frown when sad or cross
        Rectangle {
            visible: root.mood !== "sad" && root.mood !== "angry"
            width: root.s * (0.07 + 0.03 * root.puff)
            height: width
            radius: width / 2
            x: fish.cx + fish.r * 0.78 - width / 2
            y: fish.cy + fish.r * 0.18
            color: root.ink
        }
        Mouth { visible: root.mood === "sad" || root.mood === "angry"; x0: fish.cx + fish.r * 0.62; x1: fish.cx + fish.r * 0.94; y0: fish.cy + fish.r * 0.34; bend: root.s * 0.06 }
    }

    // ── Droplet ── a drop (or the feeling's shape) with a shine; it wobbles when touched, and
    // rings ripple out under it
    SpringValue { id: wobble; to: 0; value: 0; stiffness: 300; dampingRatio: root.calm ? 1 : 0.18; epsilon: 0.05 }
    Item {
        visible: root.kind === "droplet"
        anchors.fill: parent

        // ripples on the "water" under the drop
        Repeater {
            model: 3
            Rectangle {
                required property int index
                readonly property real t: Math.max(0, Math.min(1, ripples.t - index * 0.18))
                width: root.s * (0.3 + 0.7 * t)
                height: width * 0.22
                radius: height / 2
                x: root.s / 2 - width / 2
                y: root.s * 0.93 - height / 2
                color: "transparent"
                border.width: Math.max(1, root.s * 0.015)
                border.color: root.accent
                opacity: t > 0 && t < 1 ? 1 - t : 0
            }
        }
        Body {
            // a drop that runs sloshes (a little wobble at each step)
            Item {
                anchors.fill: parent
                transform: Rotation { origin.x: root.s / 2; origin.y: root.s * 0.95; angle: wobble.value + (root.running && !root.calm ? Math.sin(root.stride) * 5 : 0) }
                Shape {
                    id: drop
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        fillColor: root.shownBody
                        strokeColor: "transparent"
                        PathPolyline { path: root.kind === "droplet" ? root.outline(drop.width) : [] }
                    }
                }
                // the shine: glass, like the shell's liquid glass
                Rectangle {
                    width: root.s * 0.11
                    height: root.s * 0.2
                    radius: width / 2
                    rotation: 24
                    x: root.s * 0.27
                    y: root.s * 0.42
                    color: root.eyeWhite
                    opacity: 0.55
                }
                GooglyEye { id: dropL; size: root.s * 0.17; x: root.s * 0.33; y: root.s * 0.56 }
                GooglyEye { id: dropR; size: root.s * 0.17; x: root.s * 0.52; y: root.s * 0.56 }
                Brow { x0: root.s * 0.32; y0: root.s * 0.52; w: root.s * 0.15; side: -1 }
                Brow { x0: root.s * 0.53; y0: root.s * 0.52; w: root.s * 0.15; side: 1 }
                Mouth { x0: root.s * 0.43; x1: root.s * 0.57; y0: root.s * 0.81; bend: root.s * 0.06 }
            }
        }
    }
    NumberAnimation {
        id: ripples
        target: ripples
        property: "t"
        from: 0
        to: 1.4
        duration: 1300
        property real t: 0
    }

    // ── its own mouse (interactive) ── a click pokes it (five within three seconds and it's
    // cross); the pointer resting on it pets it (it loves you); with `draggable` a press and a
    // move picks it up (the host moves it: dragTo), and letting go puts it down (dropped):
    // thrown hard, it's dizzy
    property bool interactive: false
    property bool draggable: false
    property bool held: false
    // the pointer is on it / the button is down on it: a host that closes when the pointer
    // leaves it should wait meanwhile (a press here takes the hover from what's underneath)
    readonly property bool hovered: hover.hovered
    readonly property bool pressed: hand.pressed
    signal grabbed()
    signal dragTo(point p)
    signal dropped(real vx, real vy)
    property int _pokes: 0
    Timer { id: pokeWindow; interval: 3000; onTriggered: root._pokes = 0 }
    Timer { id: petting; interval: 1500; onTriggered: if (!root.held && root.mood === "") root.feel("love", 3000) }
    // (petting is a HoverHandler: it shares the hover, where a hovering MouseArea would take it
    // from whatever the mascot sits on, e.g. a dial that closes when the pointer leaves it)
    HoverHandler {
        id: hover
        enabled: root.interactive
        cursorShape: root.held ? Qt.ClosedHandCursor : root.draggable ? Qt.OpenHandCursor : Qt.PointingHandCursor
        onHoveredChanged: if (!hovered) petting.stop()
        onPointChanged: if (hovered && !hand.pressed && root.mood === "") petting.restart()
    }
    MouseArea {
        id: hand
        anchors.fill: parent
        enabled: root.interactive
        preventStealing: true
        property point from
        property point last
        property real lastT: 0
        property real vx: 0
        property real vy: 0
        onPressed: mouse => { from = mapToItem(root.parent, mouse.x, mouse.y); last = from; lastT = Date.now(); vx = 0; vy = 0; petting.stop() }
        onPositionChanged: mouse => {
            const p = mapToItem(root.parent, mouse.x, mouse.y)
            if (!root.held && root.draggable && Math.hypot(p.x - from.x, p.y - from.y) > 6) { root.held = true; root.grabbed() }
            if (!root.held) return
            const now = Date.now(), dt = Math.max(1, now - lastT)
            vx = vx * 0.5 + (p.x - last.x) / dt * 1000 * 0.5
            vy = vy * 0.5 + (p.y - last.y) / dt * 1000 * 0.5
            last = p
            lastT = now
            root.dragTo(p)
        }
        onReleased: {
            if (root.held) {
                root.held = false
                const speed = Date.now() - lastT > 80 ? 0 : Math.hypot(vx, vy)
                root.react(speed > 1500 ? "dizzy" : "land")
                root.dropped(vx, vy)
                return
            }
            root.react("poke")
            root._pokes++
            pokeWindow.restart()
            if (root._pokes >= 5) { root._pokes = 0; root.feel("angry", 3500) }
        }
        onCanceled: root.held = false
    }
}

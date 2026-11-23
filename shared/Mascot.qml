import QtQuick
import QtQuick.Shapes

// The shells' mascots, drawn (they scale and take the theme's colours), M3E-chunky and
// springy:
//   "dial-e"   an M3E 12-sided cookie with googly eyes: the pupils hang loose and swing after
//              the point it looks at, like real googly eyes; it turns a notch when it's happy
//   "puffy"    a pufferfish in M3E's Puffy shape: it puffs up (bigger, spikes out) when poked
//              or held, breathes slowly at rest
//   "droplet"  a water drop: wobbles when touched, with a glassy shine and ripples under it
//
//   Mascot { kind: "dial-e"; width: 120; height: 120; body: Roles.primary_container; ... }
//
// Colours are passed in (primitives never default them). It answers what you do, sized to how
// often you do it (lively-ux):
//   react("type")    a small bob and a glance (every letter: kept tiny)
//   react("delete")  a flinch
//   react("wrong")   it cries: a frown, tears, a droop (rare: the big one)
//   react("right")   joy: a hop, a big smile, squinting eyes (Dial-E's cookie turns a notch)
//   poke()           startled; cheer() a happy hop; puffTo(v) / puffBy(v) Puffy's puff (0..1)
// By itself it blinks and breathes; `look` (-1..1 on each axis) is where it looks; `asleep`
// closes its eyes and lets small z's rise; `shy` looks away (a password is being typed), with a
// blink as it turns; `turn` (degrees) turns Dial-E's cookie from outside, the pupils swinging
// after it (the control center's rings turn it like a gear). With `calm` (reduced motion) every answer still
// shows (the mouth, the tears, the eyes) but nothing travels or idles.
Item {
    id: root

    property string kind: "dial-e"

    required property color body
    required property color ink
    required property color eyeWhite

    // the pupils and the eyes' rims: dark on the eye's white in light and dark themes alike
    required property color pupil
    required property color accent

    // where it looks: (-1, -1) top left .. (1, 1) bottom right
    property point look: Qt.point(0, 0)
    property bool asleep: false

    // ── shy ── it looks away, up and to `shySide` (-1 left, 1 right), and turns a little
    // (narrower): a password is being typed. A blink as it turns away and back
    property bool shy: false
    property real shySide: -1
    onShyChanged: blink.restart()

    // ── turned from outside ── degrees; Dial-E's cookie turns with it, and its googly pupils
    // lag behind the turn (inertia), so a fast spin swings them
    property real turn: 0
    property real _lastTurn: 0
    onTurnChanged: {
        // clamped: a ring that jumps (a new control) mustn't fling them off
        const d = Math.max(-12, Math.min(12, turn - _lastTurn))
        _lastTurn = turn
        if (!calm && kind === "dial-e") for (const e of [pupilL, pupilR]) e.springX.kick(-d * 5)
    }

    // reduced motion (Dial-E: Bounce 0, Prefs.calm): no wobble, no swing, nothing idles. A
    // property, so Puffy and Droplet can use this same file (they link it) without Dial-E's Prefs
    property bool calm: false
    readonly property real s: Math.min(width, height)

    // ── how it feels ── "" (at ease), "happy" or "sad", for a moment after react()
    property string mood: ""
    Timer { id: moodClock; onTriggered: root.mood = "" }
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
        } else if (kind === "right") {
            feel("happy", 1800)
            cheer()
            spin.to += 30
        } else if (kind === "poke") {
            poke()
        }
    }

    // where the eyes go: down when sad, up when happy, else where it's told to look
    readonly property point gaze: mood === "sad" ? Qt.point(look.x * 0.3, 0.9) : mood === "happy" ? Qt.point(look.x * 0.3, -0.7)
        : shy ? Qt.point(shySide, -0.9) : look

    // the mouth: -1 a frown .. 0 flat .. 1 a big smile (resting: a small one)
    SpringValue { id: smileS; to: root.mood === "happy" ? 1 : root.mood === "sad" ? -1 : 0.35; stiffness: 300; dampingRatio: root.calm ? 1 : 0.5; epsilon: 0.005 }

    // ── the body's squash and stretch ── one spring per axis; sad, it droops
    SpringValue { id: sx; to: root.mood === "sad" ? 1.06 : root.shy && root.mood === "" ? 0.93 : 1; value: 1; stiffness: 520; dampingRatio: root.calm ? 1 : 0.35; epsilon: 0.001 }
    SpringValue { id: sy; to: root.mood === "sad" ? 0.9 : 1; value: 1; stiffness: 520; dampingRatio: root.calm ? 1 : 0.35; epsilon: 0.001 }
    SpringValue { id: hop; to: 0; value: 0; stiffness: 260; dampingRatio: root.calm ? 1 : 0.45; epsilon: 0.1 }
    // Dial-E's cookie turns in twelfths (30°), so it always lands on itself
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
    // happy, it squints; asleep, the eyes are shut
    readonly property real eyeOpen: asleep ? 0.06 : mood === "happy" ? Math.min(lid, 0.4) : lid

    // ── breathing ── a slow swell at rest (not with reduced motion)
    property real breath: 0
    SequentialAnimation on breath {
        loops: Animation.Infinite
        running: !root.calm && root.visible
        NumberAnimation { to: 1; duration: 1900; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: 1900; easing.type: Easing.InOutSine }
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
        SpringValue { id: px; to: root.gaze.x * eye.travel; stiffness: 140; dampingRatio: root.calm ? 1 : 0.22; epsilon: 0.05 }
        SpringValue { id: py; to: root.gaze.y * eye.travel + eye.travel * 0.35; stiffness: 140; dampingRatio: root.calm ? 1 : 0.22; epsilon: 0.05 }
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
            width: eye.size * 0.46
            height: width
            radius: width / 2
            color: root.pupil
            visible: root.eyeOpen > 0.3
            x: eye.size / 2 - width / 2 + Math.max(-eye.travel, Math.min(eye.travel, px.value))
            y: eye.size / 2 - height / 2 + Math.max(-eye.travel, Math.min(eye.travel, py.value))
        }
        // a tear, while it's sad: it wells up under the eye and falls (still, with calm)
        Rectangle {
            id: tear
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

    // a mouth: a curve from x0 to x1 at height y0, bent by the smile (x0 / x1: Item has left / right)
    component Mouth: Shape {
        id: mouth
        property real x0
        property real x1
        property real y0
        property real bend: root.s * 0.09
        anchors.fill: parent
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

    // ── Dial-E ── the M3E 12-sided cookie, two googly eyes, a mouth that smiles or frowns
    Item {
        visible: root.kind === "dial-e"
        anchors.fill: parent
        transform: [
            Scale { origin.x: root.s / 2; origin.y: root.s; xScale: sx.value * (1 + root.breath * 0.02); yScale: sy.value * (1 + root.breath * 0.03) },
            Translate { y: hop.value * root.s / 400 }
        ]
        Shape {
            id: cookie
            width: root.s * 0.96
            height: width
            anchors.centerIn: parent
            preferredRendererType: Shape.CurveRenderer
            rotation: spin.value + root.turn + root.breath * 3
            ShapePath {
                fillColor: root.body
                strokeColor: "transparent"
                scale: Qt.size(cookie.width / 100, cookie.height / 100)
                PathSvg { path: "M43.87 10.49C44.01 10.35 44.08 10.28 44.14 10.22C47.43 7.12 52.57 7.12 55.86 10.22C55.92 10.28 55.99 10.35 56.13 10.49C56.22 10.57 56.26 10.61 56.30 10.65C58.41 12.66 61.39 13.46 64.22 12.77C64.27 12.76 64.33 12.74 64.45 12.71C64.64 12.66 64.74 12.64 64.82 12.62C69.22 11.58 73.66 14.15 74.96 18.48C74.99 18.56 75.01 18.65 75.07 18.85C75.10 18.96 75.12 19.02 75.13 19.07C75.95 21.87 78.13 24.05 80.93 24.87C80.98 24.88 81.04 24.90 81.15 24.93C81.35 24.99 81.44 25.01 81.52 25.04C85.85 26.34 88.42 30.78 87.38 35.18C87.36 35.26 87.34 35.36 87.29 35.55C87.26 35.67 87.24 35.73 87.23 35.78C86.54 38.61 87.34 41.59 89.35 43.70C89.39 43.74 89.43 43.78 89.51 43.87C89.65 44.01 89.72 44.08 89.78 44.14C92.88 47.43 92.88 52.57 89.78 55.86C89.72 55.92 89.65 55.99 89.51 56.13C89.43 56.22 89.39 56.26 89.35 56.30C87.34 58.41 86.54 61.39 87.23 64.22C87.24 64.27 87.26 64.33 87.29 64.45C87.34 64.64 87.36 64.74 87.38 64.82C88.42 69.22 85.85 73.66 81.52 74.96C81.44 74.99 81.35 75.01 81.15 75.07C81.04 75.10 80.98 75.12 80.93 75.13C78.13 75.95 75.95 78.13 75.13 80.93C75.12 80.98 75.10 81.04 75.07 81.15C75.01 81.35 74.99 81.44 74.96 81.52C73.66 85.85 69.22 88.42 64.82 87.38C64.74 87.36 64.64 87.34 64.45 87.29C64.33 87.26 64.27 87.24 64.22 87.23C61.39 86.54 58.41 87.34 56.30 89.35C56.26 89.39 56.22 89.43 56.13 89.51C55.99 89.65 55.92 89.72 55.86 89.78C52.57 92.88 47.43 92.88 44.14 89.78C44.08 89.72 44.01 89.65 43.87 89.51C43.78 89.43 43.74 89.39 43.70 89.35C41.59 87.34 38.61 86.54 35.78 87.23C35.73 87.24 35.67 87.26 35.55 87.29C35.36 87.34 35.26 87.36 35.18 87.38C30.78 88.42 26.34 85.85 25.04 81.52C25.01 81.44 24.99 81.35 24.93 81.15C24.90 81.04 24.88 80.98 24.87 80.93C24.05 78.13 21.87 75.95 19.07 75.13C19.02 75.12 18.96 75.10 18.85 75.07C18.65 75.01 18.56 74.99 18.48 74.96C14.15 73.66 11.58 69.22 12.62 64.82C12.64 64.74 12.66 64.64 12.71 64.45C12.74 64.33 12.76 64.27 12.77 64.22C13.46 61.39 12.66 58.41 10.65 56.30C10.61 56.26 10.57 56.22 10.49 56.13C10.35 55.99 10.28 55.92 10.22 55.86C7.12 52.57 7.12 47.43 10.22 44.14C10.28 44.08 10.35 44.01 10.49 43.87C10.57 43.78 10.61 43.74 10.65 43.70C12.66 41.59 13.46 38.61 12.77 35.78C12.76 35.73 12.74 35.67 12.71 35.55C12.66 35.36 12.64 35.26 12.62 35.18C11.58 30.78 14.15 26.34 18.48 25.04C18.56 25.01 18.65 24.99 18.85 24.93C18.96 24.90 19.02 24.88 19.07 24.87C21.87 24.05 24.05 21.87 24.87 19.07C24.88 19.02 24.90 18.96 24.93 18.85C24.99 18.65 25.01 18.56 25.04 18.48C26.34 14.15 30.78 11.58 35.18 12.62C35.26 12.64 35.36 12.66 35.55 12.71C35.67 12.74 35.73 12.76 35.78 12.77C38.61 13.46 41.59 12.66 43.70 10.65C43.74 10.61 43.78 10.57 43.87 10.49Z" }
            }
        }
        GooglyEye { id: pupilL; size: root.s * 0.28; x: root.s * 0.21; y: root.s * 0.25 }
        GooglyEye { id: pupilR; size: root.s * 0.28; x: root.s * 0.51; y: root.s * 0.25 }
        Mouth { x0: root.s * 0.40; x1: root.s * 0.60; y0: root.s * 0.68 }
    }

    // ── Puffy ── a fish in M3E's Puffy shape that grows as it puffs up (puff 0..1: its scale),
    // spikes out behind it; one big eye, a tail and a little "o" mouth
    SpringValue { id: puffSpring; to: 0; value: 0; stiffness: 170; dampingRatio: root.calm ? 1 : 0.4; epsilon: 0.002 }
    readonly property real puff: Math.max(0, Math.min(1.2, puffSpring.value + (kind === "puffy" ? breath * 0.12 : 0)))
    function puffBy(v) { if (kind === "puffy" && !calm) puffSpring.kick(v * 12) }
    function puffTo(v) { puffSpring.to = v }

    Item {
        id: fish
        visible: root.kind === "puffy"
        anchors.fill: parent
        transform: [
            Scale { origin.x: root.s / 2; origin.y: root.s / 2; xScale: sx.value; yScale: sy.value },
            Translate { y: hop.value * root.s / 400 }
        ]
        // its scale: the body grows a quarter as it puffs all the way up
        readonly property real grow: 1 + 0.25 * root.puff
        readonly property real r: root.s * 0.31 * grow
        readonly property real cx: root.s * 0.54
        readonly property real cy: root.s * 0.52

        // the tail, behind the body
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: root.accent
                strokeColor: root.accent
                strokeWidth: root.s * 0.04
                joinStyle: ShapePath.RoundJoin
                startX: fish.cx - fish.r * 0.8; startY: fish.cy
                PathLine { x: root.s * 0.06; y: fish.cy - root.s * 0.14 }
                PathLine { x: root.s * 0.10; y: fish.cy }
                PathLine { x: root.s * 0.06; y: fish.cy + root.s * 0.14 }
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
            ShapePath {
                fillColor: root.body
                strokeColor: "transparent"
                scale: Qt.size(puffyBody.width / 100, puffyBody.height / 100)
                PathSvg { path: "M97.89 49.36C97.81 43.55 93.04 38.90 87.22 38.98C86.90 38.98 86.58 39.00 86.27 39.04C86.52 38.84 86.75 38.63 86.98 38.41C91.15 34.36 91.24 27.69 87.18 23.53C86.94 23.28 86.70 23.04 86.46 22.81C82.30 18.76 75.63 18.84 71.57 23.01C71.35 23.24 71.14 23.47 70.94 23.72C70.98 23.41 71.00 23.09 71.00 22.77C71.09 16.96 66.43 12.19 60.62 12.11C60.45 12.11 60.28 12.11 60.11 12.11H59.76C55.46 12.11 51.76 14.69 50.13 18.40C48.50 14.69 44.80 12.11 40.50 12.11H40.15C39.98 12.11 39.81 12.11 39.64 12.11C33.83 12.18 29.18 16.96 29.26 22.77C29.26 23.09 29.28 23.41 29.31 23.72C29.11 23.47 28.91 23.24 28.69 23.01C24.63 18.84 17.96 18.76 13.80 22.81C13.55 23.05 13.31 23.28 13.08 23.53C9.02 27.69 9.11 34.35 13.28 38.41C13.50 38.63 13.74 38.84 13.99 39.04C13.68 39.00 13.36 38.98 13.04 38.98C7.23 38.90 2.45 43.55 2.37 49.36C2.37 49.53 2.37 49.70 2.37 49.87C2.37 50.04 2.37 50.21 2.37 50.38C2.45 56.19 7.22 60.84 13.04 60.76C13.36 60.76 13.68 60.74 13.99 60.70C13.74 60.90 13.50 61.11 13.28 61.33C9.11 65.38 9.02 72.05 13.08 76.21C13.32 76.45 13.55 76.70 13.80 76.93C17.96 80.98 24.63 80.89 28.69 76.73C28.91 76.50 29.11 76.26 29.31 76.02C29.28 76.33 29.26 76.65 29.26 76.97C29.18 82.78 33.83 87.55 39.64 87.63C39.81 87.63 39.98 87.63 40.15 87.63H40.50C44.81 87.63 48.50 85.04 50.13 81.34C51.76 85.04 55.46 87.63 59.76 87.63H60.11C60.28 87.63 60.45 87.63 60.62 87.63C66.43 87.55 71.09 82.78 71.01 76.97C71.01 76.65 70.98 76.33 70.95 76.02C71.15 76.26 71.35 76.50 71.58 76.73C75.63 80.89 82.30 80.98 86.47 76.93C86.71 76.69 86.95 76.45 87.19 76.21C91.24 72.05 91.15 65.39 86.99 61.33C86.76 61.11 86.52 60.90 86.28 60.70C86.59 60.74 86.90 60.76 87.23 60.76C93.04 60.84 97.82 56.19 97.89 50.38C97.89 50.21 97.89 50.04 97.89 49.87C97.89 49.70 97.89 49.53 97.89 49.36H97.89Z" }
            }
        }
        GooglyEye { id: puffyEye; size: root.s * 0.24; x: fish.cx + fish.r * 0.05; y: fish.cy - fish.r * 0.62 }
        // the little "o" mouth: rounder when puffed, a frown when sad
        Rectangle {
            visible: root.mood !== "sad"
            width: root.s * (0.07 + 0.03 * root.puff)
            height: width
            radius: width / 2
            x: fish.cx + fish.r * 0.78 - width / 2
            y: fish.cy + fish.r * 0.18
            color: root.ink
        }
        Mouth { visible: root.mood === "sad"; x0: fish.cx + fish.r * 0.62; x1: fish.cx + fish.r * 0.94; y0: fish.cy + fish.r * 0.34; bend: root.s * 0.06 }
    }

    // ── Droplet ── a drop with a shine; it wobbles when touched, and rings ripple out under it
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
        Item {
            anchors.fill: parent
            transform: [
                Scale { origin.x: root.s / 2; origin.y: root.s * 0.95; xScale: sx.value * (1 + root.breath * 0.02); yScale: sy.value * (1 - root.breath * 0.015) },
                Rotation { origin.x: root.s / 2; origin.y: root.s * 0.95; angle: wobble.value },
                Translate { y: hop.value * root.s / 400 }
            ]
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: root.body
                    strokeColor: "transparent"
                    PathSvg {
                        readonly property real k: root.s
                        path: "M " + 0.5 * k + " " + 0.05 * k
                            + " C " + 0.5 * k + " " + 0.05 * k + " " + 0.16 * k + " " + 0.47 * k + " " + 0.16 * k + " " + 0.64 * k
                            + " C " + 0.16 * k + " " + 0.83 * k + " " + 0.31 * k + " " + 0.95 * k + " " + 0.5 * k + " " + 0.95 * k
                            + " C " + 0.69 * k + " " + 0.95 * k + " " + 0.84 * k + " " + 0.83 * k + " " + 0.84 * k + " " + 0.64 * k
                            + " C " + 0.84 * k + " " + 0.47 * k + " " + 0.5 * k + " " + 0.05 * k + " " + 0.5 * k + " " + 0.05 * k + " Z"
                    }
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
            Mouth { x0: root.s * 0.43; x1: root.s * 0.57; y0: root.s * 0.81; bend: root.s * 0.06 }
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
}

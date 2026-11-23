import QtQuick
import QtQuick.Shapes
import "../variables.js" as Vars

// The shells' mascots, drawn (they scale and take the theme's colours), M3E-chunky and
// springy:
//   "dial-e"   a perfect circle with googly eyes: the pupils hang loose and swing after the
//              point it looks at, like real googly eyes
//   "puffy"    a pufferfish: puffs up (spikes out) when poked or held, breathes slowly at rest
//   "droplet"  a water drop: wobbles when touched, with a glassy shine and ripples under it
//
//   Mascot { kind: "dial-e"; width: 120; height: 120; body: Roles.primary_container; ... }
//
// Colours are passed in (primitives never default them). States: blinks and breathes by
// itself; `look` (-1..1 on each axis) is where it looks; poke() startles it; `asleep` closes
// its eyes; puff(1) inflates Puffy, cheer() is a happy hop.
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

    // reduced motion (Bounce 0): no wobble, no swing, nothing idles
    readonly property bool calm: Prefs.calm
    readonly property real s: Math.min(width, height)

    // ── the body's squash and stretch ── one spring per axis; a poke squashes it
    SpringValue { id: sx; to: 1; value: 1; stiffness: 520; dampingRatio: root.calm ? 1 : 0.35; epsilon: 0.001 }
    SpringValue { id: sy; to: 1; value: 1; stiffness: 520; dampingRatio: root.calm ? 1 : 0.35; epsilon: 0.001 }
    SpringValue { id: hop; to: 0; value: 0; stiffness: 260; dampingRatio: root.calm ? 1 : 0.45; epsilon: 0.1 }
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
    readonly property real eyeOpen: asleep ? 0.06 : lid

    // ── breathing ── a slow swell at rest (not with reduced motion)
    property real breath: 0
    SequentialAnimation on breath {
        loops: Animation.Infinite
        running: !root.calm && root.visible
        NumberAnimation { to: 1; duration: 1900; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: 1900; easing.type: Easing.InOutSine }
    }

    // ── a googly eye ── its pupil swings after `look` on a loose spring, and hangs a little
    // low at rest (gravity)
    component GooglyEye: Item {
        id: eye
        property real size
        readonly property real travel: size * 0.22
        // the pupil's two springs (poke kicks them)
        readonly property alias springX: px
        readonly property alias springY: py
        SpringValue { id: px; to: root.look.x * eye.travel; stiffness: 140; dampingRatio: root.calm ? 1 : 0.22; epsilon: 0.05 }
        SpringValue { id: py; to: root.look.y * eye.travel + eye.travel * 0.35; stiffness: 140; dampingRatio: root.calm ? 1 : 0.22; epsilon: 0.05 }
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
    }

    // ── Dial-E ── a perfect circle (the shell's one shape), two googly eyes, a small smile
    Item {
        visible: root.kind === "dial-e"
        anchors.fill: parent
        transform: [
            Scale { origin.x: root.s / 2; origin.y: root.s; xScale: sx.value * (1 + root.breath * 0.02); yScale: sy.value * (1 + root.breath * 0.03) },
            Translate { y: hop.value * root.s / 400 }
        ]
        Rectangle {
            width: root.s * 0.92
            height: width
            radius: width / 2
            anchors.centerIn: parent
            color: root.body
        }
        GooglyEye { id: pupilL; size: root.s * 0.3; x: root.s * 0.20; y: root.s * 0.24 }
        GooglyEye { id: pupilR; size: root.s * 0.3; x: root.s * 0.50; y: root.s * 0.24 }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: root.ink
                strokeWidth: root.s * 0.045
                capStyle: ShapePath.RoundCap
                fillColor: "transparent"
                startX: root.s * 0.40; startY: root.s * 0.70
                PathQuad { x: root.s * 0.60; y: root.s * 0.70; controlX: root.s * 0.50; controlY: root.s * (0.78 + 0.04 * root.breath) }
            }
        }
    }

    // ── Puffy ── a round fish whose spikes come out as it puffs up (puff 0..1); one big eye,
    // a tail and a little "o" mouth
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
        readonly property real r: root.s * (0.30 + 0.06 * root.puff)
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

        // the spikes: a star round the body, their tips further out the more it's puffed,
        // drawn with a thick round-joined stroke so every tip is soft (M3E: chunky, round)
        Shape {
            id: spikes
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            readonly property int n: 14
            readonly property string path: {
                const cx = fish.cx, cy = fish.cy, r = fish.r, tip = r * (1 + 0.32 * root.puff)
                let d = ""
                for (let i = 0; i <= n * 2; i++) {
                    const a = i / (n * 2) * Math.PI * 2, rr = i % 2 ? tip : r * 0.96
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
        Rectangle {
            width: fish.r * 2
            height: width
            radius: width / 2
            x: fish.cx - width / 2
            y: fish.cy - height / 2
            color: root.body
        }
        GooglyEye { id: puffyEye; size: root.s * 0.24; x: fish.cx + fish.r * 0.05; y: fish.cy - fish.r * 0.62 }
        Rectangle {
            width: root.s * (0.07 + 0.03 * root.puff)
            height: width
            radius: width / 2
            x: fish.cx + fish.r * 0.78 - width / 2
            y: fish.cy + fish.r * 0.18
            color: root.ink
        }
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
            GooglyEye { id: dropL; size: root.s * 0.17; x: root.s * 0.33; y: root.s * 0.58 }
            GooglyEye { id: dropR; size: root.s * 0.17; x: root.s * 0.52; y: root.s * 0.58 }
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

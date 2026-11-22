import QtQuick
import Quickshell.Io
import "../variables.js" as Vars

// A dial's rotation: wheel input, momentum and snapping. No visuals.
//
//   scroll   - how far the dial has turned, in degrees (unbounded)
//   pos      - the same as a whole number of steps
//   scrollBy - call with -1 / +1 for one wheel notch
QtObject {
    id: root

    // degrees between two items
    property real stepDeg: 10

    // how long the settle-onto-an-item animation takes
    property int snapDuration: Vars.snapDuration

    // the glide hands over to the snap below this share of one notch's speed
    property real snapThreshold: Vars.snapThreshold

    // 0 = no momentum (one item per notch), up to 0.995 = very long glide
    property real momentum: 0.98

    // multiplier for how much speed one wheel notch adds
    property real energy: 1

    property real scroll: 0
    readonly property int pos: Math.round(-scroll / stepDeg)

    // ── tick sound ── one tick each time the dial passes an item, so a fast spin
    // rattles. How loud each one is comes from Prefs.tickGain (the Ticks, Tick volume and
    // Soft ticks settings): quieter the faster they come, and while music plays.
    readonly property string _tickFile: Qt.resolvedUrl("../sounds/tick.mp3").toString().replace(/^file:\/\//, "")
    property real _lastTick: 0
    property int _nextPlayer: 0

    // a few players, so ticks close together can overlap instead of cutting each other off
    property list<Process> _players: [ Process {}, Process {}, Process {}, Process {} ]

    // true: no tick sound (e.g. while the dial is closed and only follows a value)
    property bool silent: false

    onPosChanged: {
        if (silent) return
        const now = Date.now()
        if (now - _lastTick < 25) return          // at most ~40 ticks a second
        const gain = Prefs.tickGain(now - _lastTick)
        _lastTick = now
        if (gain <= 0) return
        const p = _players[_nextPlayer]
        _nextPlayer = (_nextPlayer + 1) % _players.length
        p.exec(["pw-play", "--volume", String(Math.round(gain * 1000) / 1000), _tickFile])
    }

    readonly property real friction: Math.max(0, Math.min(momentum, 0.995))

    // degrees per second
    property real velocity: 0

    // velocity added per notch: sized so a lone notch glides about one item
    readonly property real kick: stepDeg * 60 * (energy - friction)

    // ── snap motion ── a spring (Vars.springs) or a curve (snapDuration + fast spatial bezier)
    property bool useSpring: Vars.useSprings
    property var spring: Vars.springs.expressive.default.spatial

    // the spring takes over the glide's speed, so there's no "catch" at the handover
    property SpringValue _snapSpring: SpringValue {
        stiffness: root.spring.stiffness
        dampingRatio: root.spring.dampingRatio
        epsilon: 0.01
        onValueChanged: if (running) root.scroll = value
        onSettled: root.settled()
    }

    property NumberAnimation _snap: NumberAnimation {
        target: root
        property: "scroll"
        duration: root.snapDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Prefs.fastSpatial.bezier   // M3E expressive fast spatial
        onFinished: root.settled()
    }

    // true while a snap or a glide is moving the dial
    readonly property bool settling: _snapSpring.running || _snap.running || _glide.running

    // the item the dial is heading for: the snap's end, or `pos` when it's still
    readonly property int heading: _snapSpring.running ? Math.round(-_snapSpring.to / stepDeg)
        : _snap.running ? Math.round(-_snap.to / stepDeg)
        : pos

    // a snap finished (the dial sits exactly on an item)
    signal settled()

    property FrameAnimation _glide: FrameAnimation {
        onTriggered: {
            root.scroll += root.velocity * frameTime
            root.velocity *= Math.pow(root.friction, frameTime * 60)   // frame-rate independent
            if (Math.abs(root.velocity) < root.kick * root.snapThreshold) {
                root.velocity = 0
                stop()
                root.snapTo(Math.round(-root.scroll / root.stepDeg))
            }
        }
    }

    // The step can change while the dial resizes (e.g. a bigger dial for one control).
    // scroll is in degrees, so rescale it (and any glide / snap in flight) to keep the
    // ring on the same item; otherwise every item slides and the selection can flip.
    property real _lastStep: 0
    Component.onCompleted: _lastStep = stepDeg
    onStepDegChanged: {
        const old = _lastStep
        _lastStep = stepDeg
        if (old <= 0 || stepDeg <= 0) return
        const r = stepDeg / old
        velocity *= r
        if (_snapSpring.running) {
            _snapSpring.to *= r
            _snapSpring.velocity *= r
            _snapSpring.value *= r          // also moves scroll (onValueChanged)
        } else if (_snap.running) {
            const p = Math.round(-_snap.to / old)
            _snap.stop()
            scroll *= r
            snapTo(p)
        } else {
            scroll *= r
        }
    }

    function snapTo(p) {
        // the speed to carry into the snap: a glide's, or, when a snap is already running,
        // the spring's own. Starting every snap from rest meant quick changes in a row
        // (volume keys held) barely moved the dial until they stopped, then it crawled
        // after: the dial got left behind
        const v = _snapSpring.running ? _snapSpring.velocity : velocity

        // stop a glide still running, or it would keep pushing scroll after the snap
        velocity = 0
        _glide.stop()
        _snap.stop()
        if (useSpring) {
            _snapSpring.stop()
            _snapSpring.value = scroll
            _snapSpring.velocity = v
            _snapSpring.to = -p * stepDeg
            _snapSpring.start()
        } else {
            _snapSpring.stop()
            _snap.to = -p * stepDeg
            _snap.start()
        }
    }

    // dragging: the dial follows the mouse exactly (stops any glide / snap)
    function dragBy(deg) {
        velocity = 0
        _glide.stop()
        _snap.stop()
        _snapSpring.stop()
        scroll += deg
    }

    // let go of a drag at `v` degrees per second: glide on (momentum) or settle onto an item
    function fling(v) {
        const cap = stepDeg * 40
        velocity = Math.max(-cap, Math.min(cap, v))
        if (friction > 0 && Math.abs(velocity) >= kick * snapThreshold) _glide.start()
        else snapTo(pos)
    }

    function scrollBy(dir) {
        if (friction <= 0) {            // momentum off: exactly one item per notch
            snapTo(pos - dir)
            return
        }
        _snap.stop()
        _snapSpring.stop()          // a new notch takes over from any snap
        const cap = stepDeg * 40        // top speed: ~40 items per second
        velocity = Math.max(-cap, Math.min(cap, velocity + dir * kick))
        _glide.start()
    }
}

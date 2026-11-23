import QtQuick

// A number that moves toward `to` like a real M3E spring (stiffness + damping
// ratio, the same numbers as Vars.springs), instead of along a fixed curve.
// Unlike a curve it keeps its speed when `to` changes mid-move, and it can
// start with a speed (set `velocity` before `to`). Read `value`.
QtObject {
    id: root

    // where it's heading; changing it starts the motion
    property real to: 0
    property real value: 0

    // current speed, in units per second
    property real velocity: 0

    // M3E spring: higher stiffness = faster; dampingRatio 1 = no bounce, lower = bouncier
    property real stiffness: 380
    property real dampingRatio: 0.8

    // close enough to stop (in the value's own units)
    property real epsilon: 0.01
    readonly property bool running: _frames.running
    signal settled()

    function start() { _frames.start() }

    // push it with a speed (units per second), e.g. a shake round where it rests
    function kick(speed) { velocity += speed; start() }
    function stop() { _frames.stop() }

    // jump straight to v with no motion (doesn't touch `to`, so a binding on it keeps working)
    function snap(v) { stop(); velocity = 0; value = v }

    onToChanged: if (value !== to) start()

    property FrameAnimation _frames: FrameAnimation {
        onTriggered: {
            const k = root.stiffness
            const c = 2 * root.dampingRatio * Math.sqrt(k)

            // small fixed steps, so stiff springs stay steady even on a slow frame
            const dt = Math.min(frameTime, 0.1)
            const steps = Math.max(1, Math.ceil(dt / 0.004))
            const h = dt / steps
            let x = root.value, v = root.velocity
            for (let i = 0; i < steps; i++) {
                v += (k * (root.to - x) - c * v) * h
                x += v * h
            }
            if (Math.abs(root.to - x) < root.epsilon && Math.abs(v) < root.epsilon * 10) {
                stop()
                root.velocity = 0
                root.value = root.to
                root.settled()
                return
            }
            root.velocity = v
            root.value = x
        }
    }
}

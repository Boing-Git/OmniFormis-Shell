import QtQuick
import QtQuick.Shapes
import Quickshell
import ".."
import "../primitive"
import "../variables.js" as Vars

// Lock face: Eclipse (LockSurface.qml shows it in place of the clock and the ring's beads).
// The time fills the dial as dot-matrix digits made of beads, leaning a little towards the
// pointer. Each letter typed pulls one bead out of the digits into the password ring, left to
// right, so the clock thins as the password grows without showing a single character. A
// wrong password sends them back (the ring's rattle shakes them first); the right one sends
// every bead off to the dials' spots as the sheet goes back.
Item {
    id: eclipse

    // the LockSurface: the lock's state, its settings, its colours
    required property var host
    readonly property var lock: host.lock
    readonly property LockSettings cfg: host.cfg

    // the dial's middle, and the pointer, on this item
    required property real cx
    required property real cy
    required property point pointer

    // ── the digits ── 5 × 7, a string per row, "#" lit
    readonly property var glyphs: ({
        "0": [" ### ", "#   #", "#  ##", "# # #", "##  #", "#   #", " ### "],
        "1": ["  #  ", " ##  ", "  #  ", "  #  ", "  #  ", "  #  ", " ### "],
        "2": [" ### ", "#   #", "    #", "   # ", "  #  ", " #   ", "#####"],
        "3": ["#####", "   # ", "  #  ", "   # ", "    #", "#   #", " ### "],
        "4": ["   # ", "  ## ", " # # ", "#  # ", "#####", "   # ", "   # "],
        "5": ["#####", "#    ", "#### ", "    #", "    #", "#   #", " ### "],
        "6": ["  ## ", " #   ", "#    ", "#### ", "#   #", "#   #", " ### "],
        "7": ["#####", "    #", "   # ", "  #  ", " #   ", " #   ", " #   "],
        "8": [" ### ", "#   #", "#   #", " ### ", "#   #", "#   #", " ### "],
        "9": [" ### ", "#   #", "#   #", " ####", "    #", "   # ", " ##  "],
        ":": [" ", " ", "#", " ", "#", " ", " "]
    })

    M3Shapes { id: shapes }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // "9:41" or "21:41", as the control center's clock (Clock format)
    readonly property string time: {
        const d = clock.date, h = d.getHours()
        const twelve = cfg.clockFormat === "12h" || cfg.clockFormat === "12hAmPm"
        return (twelve ? String(h % 12 || 12) : String(h).padStart(2, "0")) + ":" + String(d.getMinutes()).padStart(2, "0")
    }

    // the lit beads, as offsets from the dial's middle, column by column from the left: the
    // order letters take them in, so the clock darkens from the left like an eclipse
    readonly property var dots: {
        const chars = Array.from(time).filter(c => glyphs[c])
        const cols = chars.reduce((n, c) => n + glyphs[c][0].length, 0) + chars.length - 1
        const out = []
        let left = 0
        for (const c of chars) {
            const g = glyphs[c]
            for (let col = 0; col < g[0].length; col++) {
                for (let row = 0; row < 7; row++) {
                    if (g[row][col] === "#")
                        out.push(Qt.point((left + col - (cols - 1) / 2) * cfg.eclipsePitch, (row - 3) * cfg.eclipsePitch))
                }
            }
            left += g[0].length + 1
        }
        return out
    }

    // the spots the beads leave for as the lock opens: where the hot-corner dials are now
    readonly property var homes: Dials.homes.map(n => Dials.spotPoint(Dials.spotOf(n), width, height))

    // A bead per lit dot, and one more per letter past them (a password longer than the
    // clock's dots still gets a bead each: those come straight out on the ring)
    Repeater {
        model: Math.max(eclipse.dots.length, eclipse.lock.peak)

        Item {
            id: bead
            required property int index

            // its dot in the digits (none: a bead only for the ring)
            readonly property point dot: index < eclipse.dots.length ? eclipse.dots[index] : Qt.point(0, 0)
            readonly property bool inDigits: index < eclipse.dots.length

            // on the ring: this bead's letter is typed
            readonly property bool out: index < eclipse.lock.count

            // ── where it rests ── in the digits, leaning towards the pointer
            readonly property real homeX: {
                const x = eclipse.cx + dot.x, y = eclipse.cy + dot.y
                const dx = eclipse.pointer.x - x, dy = eclipse.pointer.y - y, d = Math.hypot(dx, dy)
                return x + (d < 1 ? 0 : dx / d * eclipse.cfg.eclipseDrift * Math.max(0, 1 - d / eclipse.cfg.eclipseDriftReach))
            }
            readonly property real homeY: {
                const x = eclipse.cx + dot.x, y = eclipse.cy + dot.y
                const dx = eclipse.pointer.x - x, dy = eclipse.pointer.y - y, d = Math.hypot(dx, dy)
                return y + (d < 1 ? 0 : dy / d * eclipse.cfg.eclipseDrift * Math.max(0, 1 - d / eclipse.cfg.eclipseDriftReach))
            }

            // ── its place on the ring ── as LockSurface's beads: the newest at the mark
            readonly property real deg: eclipse.cfg.markDeg + index * eclipse.cfg.stepDeg + eclipse.lock.turn
            readonly property real along: eclipse.cfg.markDeg - deg
            readonly property real near: Math.max(0, 1 - Math.abs(along) / eclipse.cfg.stepDeg)
            readonly property real fade: along <= eclipse.cfg.beadFadeFrom ? 1
                : Math.max(0, 1 - (along - eclipse.cfg.beadFadeFrom) / (eclipse.cfg.beadFadeTo - eclipse.cfg.beadFadeFrom))
            readonly property real ringX: eclipse.cx + eclipse.cfg.ringRadius * Math.cos(deg * Math.PI / 180)
            readonly property real ringY: eclipse.cy + eclipse.cfg.ringRadius * Math.sin(deg * Math.PI / 180)

            // 0 in the digits .. 1 on the ring: the expressive fast spring, so it lands with
            // a little overshoot (none under Bounce 0)
            SpringValue {
                id: flight
                to: 0
                stiffness: Vars.springs.expressive.fast.spatial.stiffness
                dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
                epsilon: 0.002
            }

            // typed: out at once; cleared (a wrong password, Ctrl+U): back newest first, the
            // rest one by one after it, as the ring's beads leave
            onOutChanged: {
                if (out) { back.stop(); flight.to = 1; return }
                const from = eclipse.lock.clearedFrom
                back.interval = from > index ? Math.max(1, (from - 1 - index) * eclipse.cfg.beadStagger) : 1
                back.restart()
            }
            Component.onCompleted: if (out) flight.snap(1)
            Timer {
                id: back
                onTriggered: flight.to = 0
            }

            // 0 .. 1 as the lock opens: off to its dial, a few ms after the bead before it
            SpringValue {
                id: launch
                to: 0
                stiffness: Vars.springs.standard.fast.spatial.stiffness
                dampingRatio: Vars.springs.standard.fast.spatial.dampingRatio
                epsilon: 0.002
            }
            readonly property bool leaving: eclipse.lock.unlocking
            onLeavingChanged: if (leaving) launchTimer.restart(); else { launchTimer.stop(); launch.snap(0) }
            Timer {
                id: launchTimer
                interval: Math.max(1, bead.index * eclipse.cfg.eclipseLaunchStagger)
                onTriggered: launch.to = 1
            }
            readonly property point dialSpot: eclipse.homes[index % eclipse.homes.length]

            readonly property real t: flight.value
            readonly property real l: launch.value
            readonly property real px: (homeX + (ringX - homeX) * t) * (1 - l) + dialSpot.x * l
            readonly property real py: (homeY + (ringY - homeY) * t) * (1 - l) + dialSpot.y * l

            // a dot in the digits, an M3 bead on the ring (by its place, as LockSurface's)
            readonly property real size: eclipse.cfg.eclipseDotSize
                + (eclipse.cfg.beadSize * (1 + (eclipse.cfg.beadSelectedScale - 1) * near) - eclipse.cfg.eclipseDotSize) * Math.max(0, t)
            readonly property color ringFill: eclipse.host.mix(eclipse.host.mix(eclipse.host.mix(Roles.secondary, Roles.primary, near),
                                                                                      Roles.primary, eclipse.host.done),
                                                                  Roles.error, eclipse.host.alarm)

            width: size
            height: size
            x: px - width / 2
            y: py - height / 2

            // a ring-only bead is there only while it is on the ring; far round the ring
            // they fade as LockSurface's do; leaving, they fade as they reach their dial
            opacity: (inDigits ? 1 : Math.min(1, Math.max(0, t))) * (1 + (fade - 1) * Math.min(1, Math.max(0, t))) * (1 - l * l)
            visible: opacity > 0.01

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                antialiasing: true
                opacity: 1 - Math.min(1, Math.max(0, bead.t))
                color: eclipse.host.mix(Roles.on_surface, Roles.primary, eclipse.host.done)
            }

            Loader {
                anchors.fill: parent
                active: bead.t > 0.01
                opacity: Math.min(1, Math.max(0, bead.t))
                rotation: (bead.deg + 90) * Math.min(1, Math.max(0, bead.t))
                sourceComponent: Shape {
                    id: beadShape
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: "transparent"
                        fillColor: bead.ringFill
                        scale: shapes.fitScale(beadShape)
                        PathSvg { path: shapes.getPath(eclipse.cfg.beadShapes[bead.index % eclipse.cfg.beadShapes.length]) }
                    }
                }
            }
        }
    }
}

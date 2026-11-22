import QtQuick
import QtQuick.Shapes
import ".."
import "../primitive"
import "../variables.js" as Vars

// The wavy timeline ring of the control center (controls with a `timeline`).
// Like the volume knob: a ring of ticks turns through a fixed gem at the middle, and
// the tick under the gem is the value. The played ticks ride a travelling sine wave
// (primary), the rest lie flat (outline-variant), like an M3 wavy progress bar.
Item {
    id: root

    // set by the dial
    required property var dial
    required property var shapes

    // the timeline's rotation (DialRotation)
    required property var spin

    // buttons on the ring either side of the gem (e.g. previous / next):
    // [{ icon, act }], first one on the reading-left side. The dial calls `act` on a
    // click (see sideAt): they have no MouseArea of their own, which would count as the
    // mouse leaving the dial and close it.
    property var sides: []

    // The look comes from the control's `timeline.style` (e.g. MediaSettings); anything
    // it doesn't set uses the default given here
    readonly property var style: dial.timeline && dial.timeline.style ? dial.timeline.style : null
    function st(key, fallback) { return style && style[key] !== undefined ? style[key] : fallback }

    readonly property real sideSize: st("sideSize", 32)

    // the ring reads towards smaller angles, or larger ones where text would flip
    readonly property bool flipped: Math.sin(dial.midDeg * Math.PI / 180) < 0

    // degrees from the gem to a side button's centre
    readonly property real sideDeg: (gem.width / 2 + st("sideGap", 6) + sideSize / 2) / Math.max(1, ring.radius) * 180 / Math.PI
    function sideAngle(i) { return dial.midDeg + (i === 0 ? 1 : -1) * (flipped ? -1 : 1) * sideDeg }
    function sidePos(i) {
        const a = sideAngle(i) * Math.PI / 180
        return Qt.point(dial.centerX + ring.radius * Math.cos(a), dial.centerY + ring.radius * Math.sin(a))
    }

    // the side button under (x, y), or -1
    function sideAt(x, y) {
        if (!visible) return -1
        for (let i = 0; i < sides.length; i++) {
            const p = sidePos(i)
            if (Math.hypot(x - p.x, y - p.y) <= sideSize / 2 + 3) return i
        }
        return -1
    }
    readonly property int hoveredSide: dial.hovered ? sideAt(dial.hoverX, dial.hoverY) : -1

    // ── scrubbing ──
    // true while the user seeks (scrolling the timeline), and while the mouse is on it
    // when the style sets `scrubOnHover`. The line, the gem and the wave react to it.
    readonly property bool scrubbing: dial.scrubbing || (st("scrubOnHover", false) && dial.overTimeline && dial.tlTicks > 0)

    // ── the wave ──
    // M3 keeps the wave flat near the start and end (progress ≤ 10% or ≥ 95%)
    readonly property real tlProgress: dial.tlTicks > 0 ? dial.tlTick / dial.tlTicks : 0
    readonly property bool waveAllowed: tlProgress > 0.1 && tlProgress < 0.95

    // how tall the wave is (px); calmer while the control isn't animated, and flat while
    // scrubbing when the style sets `scrubFlatten` (a flat line is easier to aim along)
    property real waveAmp: !waveAllowed || Prefs.trackStyle === "straight" || (scrubbing && st("scrubFlatten", false)) ? 0
        : dial.tlAnimated ? st("waveHeight", 6) : st("pausedWaveHeight", 0)

    // the wave grows and flattens on the slow effects spring; with Vars.useSprings off,
    // on M3 wavy progress's own curves (one for growing, one for flattening) over `waveFade`
    readonly property bool waveFlattening: !waveAllowed || scrubbing && st("scrubFlatten", false) || !dial.tlAnimated
    Behavior on waveAmp {
        NumberAnimation {
            duration: Vars.useSprings ? Vars.expressiveSlowEffects.duration : root.st("waveFade", 500)
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Vars.useSprings ? Vars.expressiveSlowEffects.bezier
                : root.waveFlattening ? [0.3, 0, 0.8, 0.15, 1, 1] : [0.2, 0, 0, 1, 1, 1]
        }
    }

    // radians per tick: the wavelength is in px, so divide by the px between ticks
    readonly property real waveK: 2 * Math.PI * dial.timelineStep / Math.max(1, st("wavelength", 80))

    // how far tick n sits off the ring, towards the corner (px): the full wave on the played
    // part, easing flat over the last `waveEase` ticks before the gem, flat after it
    function liftAt(n) {
        const amp = waveAmp * Math.max(0, Math.min(1, (dial.tlTick - n) / Math.max(1, st("waveEase", 5))))
        return amp * Math.sin(n * waveK + wavePhase)
    }

    // how many straight bits draw the line between two ticks: enough that none is longer
    // than `wavePiece` px, so the wave stays round
    readonly property int wavePieces: Math.max(1, Math.ceil(dial.timelineStep / Math.max(0.5, st("wavePiece", 3))))

    // the wave travels while the control is animated
    property real wavePhase: 0
    NumberAnimation on wavePhase {
        from: 0; to: Math.PI * 2
        duration: root.st("waveSpeed", 1800)
        loops: Animation.Infinite
        running: root.dial.open && root.dial.hasTimeline && root.dial.tlAnimated
    }

    // how far (degrees) from the gem the line stays hidden. With side buttons: past them,
    // plus `controlGap` px of empty space, plus room for the line's round end. Without: 8°.
    readonly property real lineCap: (st("playedThickness", 5.5) + (scrubbing ? st("scrubThicken", 0) : 0)) / 2
    readonly property real gemGap: sides.length > 0
        ? sideDeg + (sideSize / 2 + st("controlGap", 4) + lineCap) / Math.max(1, ring.radius) * 180 / Math.PI
        : 8

    opacity: dial.hasTimeline ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

    DialRing {
        id: ring
        active: root.dial.hasTimeline && root.dial.tlTicks > 0
        count: Math.max(1, root.dial.tlTicks)     // listIndex (not itemIndex) is used, so it never loops
        anchors.fill: parent
        cx: root.dial.centerX
        cy: root.dial.centerY
        startDeg: root.dial.startDeg
        sweepDeg: root.dial.sweepDeg
        radius: root.dial.timelineRadius
        stepDeg: root.spin.stepDeg
        scroll: root.spin.scroll
        preload: 2
        itemWidth: root.dial.timelineStep + 4
        itemHeight: 28

        delegate: Item {
            // filled in by DialRing: the raw tick number (doesn't wrap), whether it's
            // the one at the middle, and this slot's angle on the ring (every frame)
            property int listIndex
            property bool selected
            property real ringDeg

            id: tick
            readonly property bool played: listIndex <= root.dial.tlTick

            // this tick's point on the wave (for the stop dot)
            readonly property real lift: root.liftAt(listIndex)

            // the point a fraction t (0..1) of the way to the next tick, on the wave, in
            // this slot's own coordinates (x along the ring, y across it towards the corner)
            readonly property bool hasNext: listIndex + 1 < root.dial.tlTicks
            readonly property real stepRad: root.spin.stepDeg * Math.PI / 180
            function pointAt(t) {
                const r = ring.radius - root.liftAt(listIndex + t)
                const a = t * stepRad
                return Qt.point(r * Math.sin(a), ring.radius - r * Math.cos(a))
            }

            // nothing before the first tick or after the last, or under the gem and its
            // buttons: the line stops there at full thickness with a round end (no fade or
            // thinning, which made the end look a different colour / thin)
            visible: listIndex >= 0 && listIndex < root.dial.tlTicks

                // both ends of this piece clear of the gem / buttons (it runs to the next tick)
                && Math.abs(ringDeg - root.dial.midDeg) > root.gemGap
                && Math.abs(ringDeg + ring.stepDeg - root.dial.midDeg) > root.gemGap

            // the line from this tick to the next, as `wavePieces` short straight bits that
            // follow the wave (one per tick looked jagged). Their round ends sit right on the
            // points, so neighbouring bits always meet (no gaps where the line bends)
            Repeater {
                model: tick.hasNext ? root.wavePieces : 1

                Rectangle {
                    required property int index
                    readonly property point a: tick.pointAt(index / root.wavePieces)
                    readonly property point b: tick.hasNext ? tick.pointAt((index + 1) / root.wavePieces) : a
                    readonly property real dx: b.x - a.x
                    readonly property real dy: b.y - a.y

                    // thicker while scrubbing (`scrubThicken` px), with a little overshoot
                    height: (tick.played ? root.st("playedThickness", 5.5) : root.st("restThickness", 3.5))
                        + (root.scrubbing ? root.st("scrubThicken", 0) : 0)
                    Behavior on height {
                        NumberAnimation {
                            duration: Prefs.fastSpatial.duration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Prefs.fastSpatial.bezier
                        }
                    }
                    width: Math.hypot(dx, dy) + height
                    rotation: Math.atan2(dy, dx) * 180 / Math.PI
                    radius: height / 2
                    antialiasing: true
                    x: tick.width / 2 + (a.x + b.x) / 2 - width / 2
                    y: tick.height / 2 + (a.y + b.y) / 2 - height / 2

                    // played: primary, or tertiary while scrubbing (`scrubTertiary`); the rest:
                    // outline-variant, or secondary-container (`trackContainer`, the M3 track colour)
                    color: tick.played ? (root.scrubbing && root.st("scrubTertiary", false) ? Roles.tertiary : Roles.primary)
                        : (root.st("trackContainer", false) ? Roles.secondary_container : Roles.outline_variant)
                    Behavior on color { ColorAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
                }
            }

            // the M3 stop dot: a small dot in the played colour on the very end of the track
            Rectangle {
                visible: !parent.played && parent.listIndex === root.dial.tlTicks - 1 && width > 0
                width: root.st("stopSize", 0)
                height: width
                radius: width / 2
                antialiasing: true
                x: parent.width / 2 - width / 2
                y: parent.height / 2 + parent.lift - height / 2
                color: Roles.primary
            }
        }
    }

    // the gem on the middle mark, drawn above every tick, with the timeline's icon.
    // While animated (e.g. playing) it can spin (`gemSpin`); while not, it can turn
    // tertiary (`gemPausedTertiary`); and it bounces when its icon changes.
    readonly property string gemIcon: root.dial.timeline && root.dial.timeline.icon ? root.dial.timeline.icon() : ""
    readonly property bool gemCalm: root.st("gemPausedTertiary", false) && !root.dial.tlAnimated

    // the gem's own turn on top of facing the ring
    property real gemTurn: 0
    NumberAnimation on gemTurn {
        from: 0; to: 360
        duration: Math.max(1, root.st("gemSpin", 0))
        loops: Animation.Infinite
        running: root.dial.open && root.dial.hasTimeline && root.st("gemSpin", 0) > 0
        paused: running && !root.dial.tlAnimated
    }

    // the bounce when the icon changes (e.g. play ⇄ pause)
    property real gemPop: 1
    SequentialAnimation {
        id: gemBounce
        NumberAnimation { target: root; property: "gemPop"; to: root.st("gemPopScale", 1); duration: root.st("gemPopIn", 90); easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier }
        NumberAnimation { target: root; property: "gemPop"; to: 1; duration: root.st("gemPopOut", 400); easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier }
    }
    onGemIconChanged: gemBounce.restart()

    // bigger while scrubbing (`scrubGemScale`), with a little overshoot
    property real gemGrow: scrubbing ? st("scrubGemScale", 1) : 1
    Behavior on gemGrow {
        NumberAnimation {
            duration: Prefs.fastSpatial.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Prefs.fastSpatial.bezier
        }
    }

    Shape {
        id: gem
        width: root.st("gemSize", 46)
        height: width
        x: root.dial.centerX + ring.radius * Math.cos(root.dial.midRad) - width / 2
        y: root.dial.centerY + ring.radius * Math.sin(root.dial.midRad) - height / 2

        // rolls along the ring as it turns, like a wheel (`gemRoll` turns per ring turn)
        rotation: root.dial.midDeg + 90 + root.gemTurn - root.spin.scroll * root.st("gemRoll", 0)
        scale: root.gemPop * root.gemGrow
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillColor: root.gemCalm ? Roles.tertiary : Roles.primary
            scale: root.shapes.fitScale(gem)
            PathSvg { path: root.shapes.getPath(root.st("gemShape", "12SidedCookie")) }
            Behavior on fillColor { ColorAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
        }
    }

    SymbolIcon {
        anchors.centerIn: gem
        text: root.gemIcon
        size: root.st("gemIconSize", 28)
        scale: root.gemPop * root.gemGrow
        filled: true
        color: root.gemCalm ? Roles.on_tertiary : Roles.on_primary
        Behavior on color { ColorAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
    }

    // the side buttons, upright, on the ring either side of the gem
    Repeater {
        model: root.sides

        Item {
            id: side
            required property var modelData
            required property int index
            readonly property point at: root.sidePos(index)
            readonly property bool hot: root.hoveredSide === index
            width: root.sideSize
            height: root.sideSize
            x: at.x - width / 2
            y: at.y - height / 2
            scale: hot ? (root.dial.pressed ? root.st("sidePressScale", 0.88) : root.st("sideHoverScale", 1.12)) : 1
            Behavior on scale { NumberAnimation { duration: Prefs.fastSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier } }

            // on hover: swaps to `sideHotShape`, turns tertiary and gives a turn (the icon stays upright)
            Shape {
                id: sideShape
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                rotation: side.hot ? (side.index === 0 ? -1 : 1) * root.st("sideHotTurn", 0) : 0
                Behavior on rotation { NumberAnimation { duration: root.st("sideTurnDuration", 400); easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier } }
                ShapePath {
                    strokeColor: "transparent"
                    fillColor: side.hot ? Roles.tertiary_container : Roles.secondary_container
                    scale: root.shapes.fitScale(sideShape)
                    PathSvg { path: root.shapes.getPath(side.hot ? root.st("sideHotShape", root.st("sideShape", "Circle")) : root.st("sideShape", "Circle")) }
                    Behavior on fillColor { ColorAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
                }
            }

            SymbolIcon {
                anchors.centerIn: parent
                text: side.modelData.icon
                size: root.st("sideIconSize", 20)
                filled: true
                color: side.hot ? Roles.on_tertiary_container : Roles.on_secondary_container
                Behavior on color { ColorAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
            }
        }
    }
}

import QtQuick
import QtQuick.Shapes
import ".."
import "../primitive"
import "../variables.js" as Vars

// One of the control center's level knobs (volume, brightness): a ring of ticks like the
// volume OSD's that turns through a fixed gem on the dial's middle mark. The tick under
// the gem is the value, and the ticks up to it are lit. The control center sends the
// wheel here (scrollBy) and drags to `spin`; the knob turns the level, and turns by
// itself when the level changes somewhere else (keys, other apps).
Item {
    id: root

    // set by the control center
    required property var dial
    required property var shapes

    // the level it shows and sets (AudioLevel / BrightnessLevel):
    // value 0..1, muted, locked, available, icon, set(v)
    // A level can also bring: `steps` (how many steps it has; 100, one per percent, when it
    // doesn't say), `text` (the words on the gem instead of the number), `tickDeg` (degrees
    // between two ticks) and `major` (a long tick every this many). That's how the same
    // knob turns a setting's value or an app's notifications (the control's `value`).
    required property var level

    // shown at all (the two level knobs: the Knobs setting; a control's value knob: only
    // while there's a value to turn)
    property bool shown: cfg.knobsEnabled

    // its ring (px from the dial's centre), the gem's M3 shape, and its colours: the lit
    // ticks and the gem, and the icon / number on the gem
    required property real radius
    required property string gemShape
    required property color litColor
    required property color inkColor

    // true while the mouse is on this knob: the gem shows the number
    property bool hot: false

    // the settings (ControlCenterSettings, knobs section)
    readonly property var cfg: dial.settings

    // its rotation, for drags (dragBy / fling)
    readonly property alias spin: rot

    // the last tick's number: 100 (a tick per percent) unless the level brings its own steps
    readonly property int last: level.steps !== undefined ? Math.max(1, level.steps) : 100

    // a long tick every this many
    readonly property int major: level.major !== undefined ? Math.max(1, level.major) : 10

    // the value as a whole tick (a percent, for a level with 100 steps)
    readonly property int percent: Math.max(0, Math.min(last, Math.round(level.value * last)))

    // another level, or another number of steps: the knob jumps to it, no turning (the
    // ticks it would pass are another setting's, not a change)
    function resync() {
        rawScroll = NaN
        rot.following = -1
        jumping = true
        rot.jump(-percent * rot.stepDeg)
        jumping = false
    }
    property bool jumping: false
    onLastChanged: resync()

    // (only for a different level: the same one handed over again, as happens whenever the
    // control's entry is rebuilt, must not stop a turn that's under way)
    property var _level: null
    onLevelChanged: if (level !== _level) { _level = level; resync() }

    // what the level is about (a level can say, e.g. the setting's key): a new subject is a
    // jump too, even with the same number of steps
    readonly property string subject: level.subject !== undefined ? level.subject : ""
    onSubjectChanged: resync()

    // lit: the ticks and the gem in colour (not while muted, locked by the screen, or with
    // nothing to control)
    readonly property bool lit: level.available && !level.muted && !level.locked

    // one wheel notch turns knobNotch percent (from where it's heading, so quick notches
    // add up instead of each starting over)
    function scrollBy(dir) {
        rot.following = -1
        rot.snapTo(Math.max(0, Math.min(last, rot.heading - dir * (last === 100 ? cfg.knobNotch : 1))))
    }

    // a drag let go: settle on a tick between 0% and 100%. Let go while pulled far past
    // 0% on the volume knob: mute
    function settle() {
        if (armed && stretch < 0 && level.toggleMute && !level.muted) level.toggleMute()
        rawScroll = NaN
        rot.following = -1
        rot.snapTo(Math.max(0, Math.min(last, rot.pos)))
    }

    // ── the rubber band ── past 0% or 100% a drag meets more and more resistance, and
    // never pulls further than knobStretchMax degrees
    // where the drag would have the ring with no resistance (NaN: no drag going on)
    property real rawScroll: NaN

    // the ring's scroll at 0% and at 100%
    readonly property real scrollAtZero: 0
    readonly property real scrollAtFull: -last * rot.stepDeg

    // the resisted pull for `over` degrees of drag past the end: eases out towards the
    // max (stiffer with a higher knobStretchResistance)
    function rubber(over) {
        const max = cfg.knobStretchMax
        return max * (1 - Math.exp(-over * cfg.knobStretchResistance / max))
    }

    // the furthest the drag is followed past an end (where the pull is 95% of the max).
    // Past it the hand's movement is dropped, so turning back moves the knob at once
    // instead of first winding back a long invisible overshoot (that felt stuck)
    readonly property real overCap: 3 * cfg.knobStretchMax / cfg.knobStretchResistance

    function dragBy(deg) {
        rot.following = -1

        // inside 0..100% the ring is exactly where the hand is: start from there, so
        // nothing that moved it (a snap, the level changing) leaves the two out of step
        if (isNaN(rawScroll) || (rot.scroll <= scrollAtZero && rot.scroll >= scrollAtFull)) rawScroll = rot.scroll
        rawScroll = Math.max(scrollAtFull - overCap, Math.min(scrollAtZero + overCap, rawScroll + deg))
        const r = rawScroll
        const want = r > scrollAtZero ? scrollAtZero + rubber(r - scrollAtZero)
            : r < scrollAtFull ? scrollAtFull - rubber(scrollAtFull - r)
            : r
        rot.dragBy(want - rot.scroll)
    }

    // how far it's pulled past an end, as a share of knobStretchMax: below 0 past 0%,
    // above 0 past 100%, 0 in between (for the stretch / shake to follow)
    readonly property real stretch: rot.scroll > scrollAtZero ? -(rot.scroll - scrollAtZero) / cfg.knobStretchMax
        : rot.scroll < scrollAtFull ? (scrollAtFull - rot.scroll) / cfg.knobStretchMax
        : 0

    // pulled far enough to count (knobStretchTrigger); letting go then on the volume
    // knob's 0% end mutes
    readonly property bool armed: Math.abs(stretch) >= cfg.knobStretchTrigger

    // fired once each time a drag reaches the trigger: -1 at the 0% end, 1 at 100% (shake here)
    signal hitLimit(int end)
    onArmedChanged: if (armed) hitLimit(stretch < 0 ? -1 : 1)

    visible: shown

    DialRotation {
        id: rot
        stepDeg: root.level.tickDeg !== undefined ? root.level.tickDeg : root.cfg.knobTickDeg

        // moves the ring there at once: no snap (and, with root.jumping set, no ticks)
        function jump(to) {
            velocity = 0
            _glide.stop()
            _snap.stop()
            _snapSpring.stop()
            scroll = to
        }

        // one tick per notch; a level knob shouldn't glide
        momentum: 0

        // no ticking while the dial is closed and the knob only follows the level, or
        // while it jumps to another level
        silent: !root.dial.open || root.jumping || !root.shown

        // the tick the knob is turning to because the level changed somewhere else;
        // -1 while the user is the one turning it
        property int following: -1

        // the knob turned: the tick at the middle is the level, in percent
        onPosChanged: {
            if (following >= 0) {
                if (pos === following) following = -1
                return
            }
            const p = Math.max(0, Math.min(root.last, pos))

            // past 0% or 100%: spring back (after a drag)
            if (p !== pos) { if (!root.dial.pressed) snapTo(p); return }

            // (the hold starts first: a level that answers at once, like a setting, would
            // otherwise be followed back to its own echo before the hold is on)
            if (p !== root.percent) { userHold.restart(); root.level.set(p / root.last); root.bump() }
        }

        // a snap is over: whatever it was following is done with, and if the level moved
        // on meanwhile (quick ups and downs) the knob catches up now instead of staying
        // behind
        onSettled: { following = -1; root.sync() }
    }

    // ms after the user turns the knob during which the level's own reports (which echo
    // the knob's writes, a little late and sometimes out of order) are not chased
    Timer {
        id: userHold
        interval: 350
        onTriggered: root.sync()
    }

    // the level changed somewhere else: turn the knob to match, without the ticks it
    // passes on the way writing the level back. Not while the user is turning it (their
    // own writes echo back); the knob catches up once they stop
    function follow() {
        if (userHold.running || dial.pressed) return
        sync()
    }

    // turns the knob to the level unless it's already there or on its way there (compared
    // with where it's heading, not where it is mid-snap, which is how it got left behind)
    function sync() {
        const p = percent
        if (p === rot.heading) return
        if (!dial.open) { rot.following = -1; rot.scroll = -p * rot.stepDeg; return }
        rot.following = p
        rot.snapTo(p)
        bump()
    }
    onPercentChanged: follow()
    Component.onCompleted: rot.scroll = -percent * rot.stepDeg

    // the number shows for a moment after each change, and the gem bounces
    function bump() {
        numberHold.restart()
        if (dial.open) popAnim.restart()
    }
    Timer {
        id: numberHold
        interval: root.cfg.knobNumberHold
    }
    readonly property bool showNumber: hot || numberHold.running

    // ── the ticks ──
    DialRing {
        id: ring
        anchors.fill: parent
        count: root.last + 1    // 0% to 100%; listIndex (not itemIndex) is used, so it never loops
        cx: root.dial.centerX
        cy: root.dial.centerY
        startDeg: root.dial.startDeg
        sweepDeg: root.dial.sweepDeg
        radius: root.radius
        stepDeg: rot.stepDeg
        scroll: rot.scroll
        preload: 2
        itemWidth: root.cfg.knobTickWidth + 2
        itemHeight: root.cfg.knobTickLong

        delegate: Item {
            // filled in by DialRing: the raw tick number (doesn't wrap), and this slot's angle
            property int listIndex
            property real ringDeg

            // DialRing already turns each slot so its height points away from the centre,
            // so the ticks come out radial with no rotation here
            Rectangle {
                anchors.centerIn: parent
                width: root.cfg.knobTickWidth
                height: parent.listIndex % root.major === 0 ? root.cfg.knobTickLong : root.cfg.knobTickShort
                radius: width / 2

                // how far this tick is from the gem, measured on the ring itself, so it
                // follows the real movement and never drifts under the gem
                readonly property real fromGem: Math.abs(parent.ringDeg - root.dial.midDeg)

                // fades in as it moves away from the gem. Nothing past 0% or 100%
                visible: parent.listIndex >= 0 && parent.listIndex <= root.last
                opacity: Math.max(0, Math.min(1, (fromGem - root.cfg.knobGemGapDeg) / root.cfg.knobGemFadeDeg))
                color: root.lit && parent.listIndex <= root.percent ? root.litColor : Roles.outline_variant
                Behavior on color { ColorAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

                // smooth edges on the turned ticks
                antialiasing: true
            }
        }
    }

    // ── the gem on the middle mark ── drawn above every tick, with the icon (or the
    // number while you turn it), and it rolls along as the ring turns, like a gear
    property real popScale: 1.1
    SequentialAnimation {
        id: popAnim
        NumberAnimation { target: root; property: "popScale"; to: root.cfg.knobPopScale; duration: root.cfg.knobPopIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier }
        NumberAnimation { target: root; property: "popScale"; to: 1; duration: root.cfg.knobPopOut; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier }
    }

    // the gem's shake when a pull reaches the trigger (degrees, rings out round 0): a
    // bouncy spring kicked sideways, its first swing `knobShakeDeg`
    SpringValue {
        id: shaker
        stiffness: Vars.shakeSpring.stiffness
        dampingRatio: Vars.shakeSpring.dampingRatio
        epsilon: 0.05
    }
    readonly property real shake: shaker.value
    onHitLimit: shaker.kick(Vars.kickFor(cfg.knobShakeDeg, Vars.shakeSpring))

    // the gem swells as it's pulled past an end
    readonly property real stretchScale: 1 + Math.abs(stretch) * cfg.knobStretchSwell

    Shape {
        id: gem
        width: root.cfg.knobGemSize          // hoverArea.hovered ? root.cfg.knobGemSize + 10 : root.cfg.knobGemSize do this 
        height: width
        x: root.dial.centerX + root.radius * Math.cos(root.dial.midDeg * Math.PI / 180) - width / 2
        y: root.dial.centerY + root.radius * Math.sin(root.dial.midDeg * Math.PI / 180) - height / 2
        rotation: root.dial.midDeg + 90 - rot.scroll * root.cfg.knobGemRoll + root.shake
        scale: root.popScale * root.stretchScale
        preferredRendererType: Shape.CurveRenderer

        // Behavior on width {
        //     NumberAnimation { 
        //         duration: Vars.m3eCurves.fastEffects.duration
        //         easing.type: Easing.BezierSpline
        //         easing.bezierCurve: Vars.m3eCurves.fastEffects.bezier
        //     }
        // }

        // MouseArea {
        //     id: hoverArea
        //     anchors.fill: parent
        //     hoverEnabled: true
        //     property bool hovered: false
        //     onEntered: hovered = true
        //     onExited: hovered = false
        // }

        ShapePath {
            strokeColor: "transparent"
            fillColor: root.lit ? root.litColor : Roles.surface_container_highest
            scale: root.shapes.fitScale(gem)
            PathSvg { path: root.shapes.getPath(root.gemShape) }
            Behavior on fillColor { ColorAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
        }
    }

    // the icon and the number, upright, crossfading in the gem
    SymbolIcon {
        anchors.centerIn: gem
        text: root.level.icon
        size:  root.cfg.knobIconSize // hoverArea.hovered ? root.cfg.knobIconSize + 8 :
        filled: true
        rotation: root.shake
        scale: root.popScale * root.stretchScale
        opacity: root.showNumber ? 0 : 1
        color: root.lit ? root.inkColor : Roles.on_surface_variant
        Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
    }
    SmoothText {
        anchors.centerIn: gem
        text: root.level.muted ? "–" : root.level.text !== undefined ? root.level.text : root.percent
        font.pixelSize: root.cfg.knobNumberSize
        font.weight: 800
        rotation: root.shake
        scale: root.popScale * root.stretchScale
        opacity: root.showNumber ? 1 : 0
        color: root.lit ? root.inkColor : Roles.on_surface_variant
        Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
    }
}

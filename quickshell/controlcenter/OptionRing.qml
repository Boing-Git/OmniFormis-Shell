import QtQuick
import ".."
import "../primitive"
import "../variables.js" as Vars

// A control's choices, laid out as chips on a ring in the gap between the inner and the
// outer ring (where the volume / brightness knobs sit for the other controls): the chip
// at the middle mark is the one in use, and turning the ring picks another. A chip can
// carry colour dots (a colour scheme shows its own colours). The control center sends
// the wheel here (scrollBy) and drags to `spin`, as it does for the knobs.
//
// The level it shows and sets (the control's `value`, see ControlCenter.qml):
//   options    [{ label, colors: [color, ...] (optional) }]
//   index      which one is in use
//   setIndex(i)
//   subject    (optional) what it is about: a new subject jumps instead of turning
Item {
    id: root

    // set by the control center
    required property var dial
    required property var level
    required property real radius

    // shown at all (only while the selected pill has choices)
    property bool shown: true
    visible: shown

    // ── settings ── sizes are px
    // a chip's height, the room each has along the ring, and the space between two
    property real chipHeight: 34
    property real slotWidth: 156
    property real chipGap: 10

    // the words: their size, and the longest they get before they're cut with "…"
    property real labelSize: 12
    property real labelMax: 104

    // the colour dots: their size, and how far each overlaps the one before
    property real dotSize: 16
    property real dotOverlap: 5

    // how much bigger the chip at the mark is
    property real selectedScale: 1.14

    // its rotation, for drags (dragBy / settle)
    readonly property alias spin: rot

    readonly property var options: level.options || []
    readonly property int last: Math.max(0, options.length - 1)
    readonly property int index: level.index !== undefined ? Math.max(0, Math.min(last, level.index)) : 0
    function inRange(i) { return Math.max(0, Math.min(last, i)) }

    // one wheel notch is one choice (from where it's heading, so quick notches add up)
    function scrollBy(dir) { rot.snapTo(inRange(rot.heading - dir)) }
    function dragBy(deg) { rot.dragBy(deg) }

    // a drag let go: settle on a choice
    function settle() { rot.snapTo(inRange(rot.pos)) }

    DialRotation {
        id: rot

        // from the chip's room and gap, measured on the chips' inner edge
        stepDeg: (root.slotWidth + root.chipGap) / Math.max(1, root.radius - root.chipHeight / 2) * 180 / Math.PI

        // one choice per notch: it shouldn't glide past any
        momentum: 0

        // no ticking while it's hidden, or while it jumps to another setting's choices
        silent: !root.dial.open || !root.shown || root.jumping

        // the ring turned: the chip at the middle is the choice
        onPosChanged: {
            const p = root.inRange(pos)

            // past the first or the last: spring back (after a drag)
            if (p !== pos) { if (!root.dial.pressed) snapTo(p); return }
            if (root.jumping || !root.shown) return
            if (p !== root.index) { userHold.restart(); root.level.setIndex(p) }
        }
        onSettled: root.sync()
    }

    // ms after the user turns it during which the level's own answer (which comes back
    // at once) isn't chased: the ring is already on its way
    Timer {
        id: userHold
        interval: 350
        onTriggered: root.sync()
    }

    // the choice changed somewhere else (a click on the pill): turn to it
    function sync() {
        if (index === rot.heading) return
        if (!dial.open || !shown) { jump(); return }
        rot.snapTo(index)
    }
    onIndexChanged: if (!userHold.running && !dial.pressed) sync()

    // other choices (another setting came to the mark): there at once, no turning
    property bool jumping: false
    function jump() {
        jumping = true
        rot.dragBy(0)
        rot.scroll = -index * rot.stepDeg
        jumping = false
    }
    readonly property string subject: level.subject !== undefined ? level.subject : ""
    onSubjectChanged: jump()
    onShownChanged: if (shown) jump()
    Component.onCompleted: jump()

    DialRing {
        id: ring
        anchors.fill: parent
        cx: root.dial.centerX
        cy: root.dial.centerY
        startDeg: root.dial.startDeg
        sweepDeg: root.dial.sweepDeg
        radius: root.radius
        stepDeg: rot.stepDeg
        scroll: rot.scroll
        preload: 1
        itemWidth: root.slotWidth
        itemHeight: root.chipHeight

        delegate: Item {
            id: slot

            // filled in by DialRing: the raw slot number (doesn't wrap), its angle, and
            // whether it's the one at the mark
            property int listIndex
            property real ringDeg
            property bool selected

            readonly property var option: root.options[listIndex] || null

            // nothing before the first or after the last
            visible: listIndex >= 0 && listIndex <= root.last && !!option

            // the words run along the arc; half a turn more where that would read upside
            // down (decided by the dial's spot, as the pills do)
            rotation: {
                const a = ((root.dial.midDeg + 90) % 360 + 360) % 360
                return a > 90 && a < 270 ? 180 : 0
            }

            Rectangle {
                id: chip
                anchors.centerIn: parent
                width: content.width + 24
                height: parent.height
                radius: height / 2
                antialiasing: true

                // M3E: the choice in use is secondary (as the value knob's lit ticks), the
                // others a surface step
                color: slot.selected ? Roles.secondary : Roles.surface_container_high
                Behavior on color { ColorAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
                scale: slot.selected ? root.selectedScale : 1
                Behavior on scale { NumberAnimation { duration: Prefs.fastSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier } }

                Row {
                    id: content
                    anchors.centerIn: parent
                    spacing: 7

                    // the choice's own colours, as overlapping dots edged in the chip's colour
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !!slot.option && !!slot.option.colors && slot.option.colors.length > 0
                        spacing: -root.dotOverlap
                        Repeater {
                            model: slot.option && slot.option.colors ? slot.option.colors : []
                            Rectangle {
                                required property var modelData
                                width: root.dotSize
                                height: width
                                radius: width / 2
                                antialiasing: true
                                color: modelData

                                // edged in the dial's surface, so a dot close to the chip's
                                // own colour still reads as a dot
                                border.width: 1.5
                                border.color: Roles.surface_container
                            }
                        }
                    }
                    SmoothText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: slot.option ? slot.option.label : ""
                        width: Math.min(implicitWidth, root.labelMax)
                        elide: Text.ElideRight
                        font.pixelSize: root.labelSize
                        font.weight: 600
                        color: slot.selected ? Roles.on_secondary : Roles.on_surface_variant
                        Behavior on color { ColorAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
                    }
                }
            }
        }
    }
}

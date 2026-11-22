import QtQuick
import Quickshell
import ".."
import "../primitive"
import "../variables.js" as Vars

// One part of the control center's M3E clock (the hours, the minutes, or AM / PM) in its
// own M3 shape. When it changes, the shape morphs into the next one on a spring and the new
// digits drop in. The control center places the two numbers on either side of the date
// badge (on every spot) and keeps them upright.
Item {
    id: root

    // ControlCenterSettings (clock section)
    required property var cfg

    // "hours", "minutes" or "ampm"
    property string part: "hours"
    readonly property bool isHours: part === "hours"
    readonly property bool isAmPm: part === "ampm"

    // ControlCenterSettings.clockFormat: "24h", "12h" or "12hAmPm"
    readonly property bool twelve: cfg.clockFormat === "12h" || cfg.clockFormat === "12hAmPm"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property string current: isAmPm ? (clock.hours < 12 ? "AM" : "PM")
        : isHours ? (twelve ? String(clock.hours % 12 === 0 ? 12 : clock.hours % 12) : String(clock.hours).padStart(2, "0"))
        : String(clock.minutes).padStart(2, "0")

    // M3E: the hours on primary-container, the minutes on tertiary-container, AM / PM on
    // secondary-container
    readonly property color fill: isAmPm ? Roles.secondary_container : isHours ? Roles.primary_container : Roles.tertiary_container
    readonly property color ink: isAmPm ? Roles.on_secondary_container : isHours ? Roles.on_primary_container : Roles.on_tertiary_container
    readonly property var shapes: isAmPm ? cfg.clockAmPmShapes : isHours ? cfg.clockHourShapes : cfg.clockMinuteShapes

    // square, so the M3 shape is never stretched; big enough that the digits sit inside the
    // shape's middle (a cookie's scallops eat into its box)
    width: Math.max(isAmPm ? cfg.clockAmPmSize : cfg.clockSize, label.implicitWidth + cfg.clockPadding * 2)
    height: width

    // each change steps to the next shape in the list, so the shape morphs
    property int step: 0
    property string shown: current
    onCurrentChanged: {
        step++
        drop.snap(-cfg.clockDrop)
        shown = current
        drop.to = 0
        drop.start()
    }

    ShapeMorph {
        anchors.fill: parent
        shape: root.shapes[root.step % root.shapes.length]
        color: root.fill
    }

    // the new digits drop in from above and settle on a spring
    SpringValue {
        id: drop
        to: 0
        stiffness: Vars.springs.expressive.fast.spatial.stiffness
        dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
        epsilon: 0.05
    }

    SmoothText {
        id: label
        anchors.centerIn: parent
        anchors.verticalCenterOffset: drop.value
        text: root.shown
        font.pixelSize: root.isAmPm ? root.cfg.clockAmPmFontSize : root.cfg.clockFontSize
        font.weight: 800
        color: root.ink
        opacity: 1 - Math.min(1, Math.abs(drop.value) / root.cfg.clockDrop) * 0.8
    }
}

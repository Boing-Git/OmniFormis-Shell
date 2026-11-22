import QtQuick

// ─────────────────────────────────────────────────────────────────────────────
// READER SETTINGS: the dial while Notifications or Settings is selected. Both read the
// same way: the inner ring picks which (an app, a setting), one tick ring in the knobs'
// place turns it (which of the app's messages, the setting's value), and the middle of
// the dial is a card to read: a shape with a picture or a value in it, and words curved
// round it.
//
// Change the plain numbers in the top sections. The "worked out" section at the bottom
// follows them. Sizes are px unless it says otherwise; Quickshell reloads on save.
// ─────────────────────────────────────────────────────────────────────────────
QtObject {
    // the dial's size right now (set by the control; animates while it grows)
    required property real liveSize

    // how much of a circle the dial shows (set by the control): 90 in a corner, 180 on an edge
    required property real sweepDeg

    // ── the dial ──
    // how big the dial grows while one of them is selected (the other controls use 460):
    // big enough for a few lines to read in the middle
    property real dialSize: 560

    // ── the shape in the middle (a picture, or a setting's value) ──
    property real artSize: 72

    // space kept between it and the screen edges
    property real artEdgeMargin: 8

    // a setting's value inside it: its size at one or two letters, and at more (M3
    // headlineSmall / titleMedium), and the longest it can get before it's cut with "…"
    property real valueSize: 24
    property real valueSmallSize: 15
    property real valueMaxWidth: 54

    // ── the words ── the note (small, e.g. "Discord · 5 min"), the title and the body
    property real noteSize: 11                  // M3 labelSmall
    property real titleSize: 16                 // M3 titleMedium
    property int titleWeight: 700
    property real bodySize: 13                  // M3 bodyMedium

    // gap between the shape and the first arc of words, and from one arc to the next
    property real textGap: 22
    property real lineGap: 19

    // the longest a line may run along its arc (degrees), and the degrees kept clear of
    // each screen edge
    property real textMaxDeg: 110
    property real textEdgeDeg: 8

    // room kept clear between the last arc and the inner ring's band
    property real textClearance: 12

    // ── the dial round the card ──
    // Their own copy of ControlCenterSettings, used only while one of them is selected
    // (what each one does: see ControlCenterSettings.qml). The inner ring sits further out
    // to make room for the card, and the volume / brightness knobs make way for the one
    // knob that turns the selected pill's value
    readonly property var controlCenter: ControlCenterSettings {
        dialSize: liveSize
        ringRatio: 0.87
        innerRadiusRatio: 0.52
        knobsEnabled: false
    }

    // ─────────────────────────────────────────────────────────────────────────
    // worked out from the settings above (don't edit, they follow)
    // ─────────────────────────────────────────────────────────────────────────
    // the room inside the inner ring's band for the card
    readonly property real room: controlCenter.innerRadius - controlCenter.pillHeight / 2 - controlCenter.innerBandMarginUsed - textClearance

    // the shape sits on the dial's middle line, half the dial's angle away from each screen
    // edge, so its centre must be r / sin(that) out to clear them: r·√2 in a corner, just
    // r on an edge (as the media player's art)
    readonly property real edgeReach: 1 / Math.sin(Math.min(sweepDeg, 180) / 2 * Math.PI / 180)
    readonly property real artR: artSize / 2
    readonly property real artDistance: artR * edgeReach + artEdgeMargin

    // the first arc of words, and how many arcs fit before the inner ring's band
    readonly property real firstArc: artDistance + artR + textGap
    readonly property int arcs: Math.max(2, Math.floor((room - firstArc) / lineGap) + 1)

    // how far a line may run on this spot
    readonly property real maxDeg: Math.min(textMaxDeg, sweepDeg - textEdgeDeg * 2)
}

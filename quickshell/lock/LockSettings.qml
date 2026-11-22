import QtQuick
import "../primitive"

// The lock screen's sizes, shapes and timings (lock/LockSurface.qml has no magic numbers):
// plain settings on top, the values worked out from them at the bottom.
//
// The lock is the shell's one whole dial. The corners hold quarter circles and the edges
// half circles; locking grows a sheet out of the power dial's spot over the whole screen,
// and on it the dial is a full circle round the clock. Typing turns its ring like the dial
// of a safe: every letter is one notch, with a tick, and leaves an M3 shape (a bead) on
// the ring. The newest bead sits at the mark at the top.
QtObject {
    // ── the ring ── where the beads sit, round the clock
    // the middle of the ring, px from the centre of the screen
    property real ringRadius: 226

    // the room the beads have across the ring, and the border on each side of it (the
    // tick marks sit in the borders, like the numbers on a safe's dial)
    property real ringWidth: 46
    property real ringEdge: 14
    property real tickSize: 4

    // degrees between two beads (15: 24 of them round the ring)
    property real stepDeg: 15

    // ── the beads ── one M3 shape per typed letter, by its place in the password (never
    // by the letter, so the shapes say nothing about what was typed)
    property real beadSize: 30

    // the newest bead, at the mark: bigger and primary (the shell's "selected")
    property real beadSelectedScale: 1.4
    property var beadShapes: ["4SidedCookie", "Gem", "Sunny", "Pentagon", "6SidedCookie", "Clamshell",
                              "Flower", "PuffyDiamond", "SoftBurst", "Puffy", "9SidedCookie", "Arch"]

    // beads further round from the mark than this fade away (a long password never comes
    // back round to the mark)
    property real beadFadeFrom: 250
    property real beadFadeTo: 320

    // ms between two beads leaving when the ring is cleared (the newest goes first)
    property int beadStagger: 14

    // ── the mark ── the fixed point the ring turns to: a gem with the lock in it, just
    // outside the ring at the top
    property real markSize: 44
    property real markIconSize: 22
    property real markGap: 5
    property real markDeg: -90

    // the dial's edge, past the mark
    property real dialMargin: 10
    property real borderWidth: 3

    // ── the clock ── the control center's clock, bigger (controlcenter/ClockFace.qml)
    property real clockSize: 150
    property real clockPadding: 26
    property real clockFontSize: 76
    property real clockGap: 14
    property real clockAmPmSize: 62
    property real clockAmPmFontSize: 20
    property real clockDrop: 18
    property var clockHourShapes: ["Slanted", "Square", "Gem"]
    property var clockMinuteShapes: ["4SidedCookie", "6SidedCookie", "Puffy", "SoftBurst"]
    property var clockAmPmShapes: ["Pill", "Oval"]

    // ── the text on the inside of the ring ── the date along the bottom, what the lock
    // has to say (wrong password, Caps Lock, checking) along the top
    property real textInset: 24
    property real dateFontSize: 18
    property real statusFontSize: 14
    property real textMaxDeg: 120

    // ── the wallpaper on the sheet ── (blurred ahead of time: LockScreen.qml) under a
    // scrim of the surface colour: lighter at rest, darker while the ring is out (the world
    // steps back while you unlock), and darker still on a picture not blurred yet
    property real restScrim: 0.30
    property real awakeScrim: 0.48
    property real sharpScrimExtra: 0.2

    // ── timing ──
    // ms with no key and no move before the ring folds away and only the time is left
    // (only while nothing is typed)
    property int restAfter: 9000

    // ms the ring rattles after a wrong password before it spins back to the start
    property int wrongHold: 420

    // ms "Wrong password" stays once the ring is clear (typing again hides it at once)
    property int statusHold: 4000

    // ── worked out ──
    readonly property string clockFormat: Prefs.clockFormat

    // the ring from edge to edge
    readonly property real bandWidth: ringWidth + ringEdge * 2
    readonly property real ringInner: ringRadius - bandWidth / 2
    readonly property real ringOuter: ringRadius + bandWidth / 2

    // the tick marks sit in the middle of each border
    readonly property real tickInner: ringInner + ringEdge / 2
    readonly property real tickOuter: ringOuter - ringEdge / 2

    // the mark's middle, and the dial's radius round it
    readonly property real markRadius: ringOuter + markGap + markSize / 2
    readonly property real dialRadius: markRadius + markSize / 2 + dialMargin

    // the date and the status run along this circle, inside the ring
    readonly property real textRadius: ringInner - textInset
}

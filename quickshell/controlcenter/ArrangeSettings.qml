import QtQuick

// ─────────────────────────────────────────────────────────────────────────────
// ARRANGE SETTINGS: Edit in the control center's Dials control. The wiggle while you
// arrange, the icon you drag, the 8 spots a dial can be dropped on (the corners and
// the middle of each edge), and pulling the Screenshot pill off the ring.
//
// Sizes are px unless it says otherwise; Quickshell reloads on save.
// ─────────────────────────────────────────────────────────────────────────────
QtObject {
    // ── the wiggle (the dial pills and the Screenshot pill, while Edit is on) ──
    // how far a pill tilts each way (degrees), how far it bobs (px), ms for one wiggle
    property real jiggleDeg: 2.5
    property real jiggleLift: 1
    property int jigglePeriod: 280

    // the pill you're dragging is left behind this faint (0..1)
    property real liftedOpacity: 0.25

    // ── the icon you drag ──
    property real ghostSize: 64
    property real ghostIconSize: 28

    // its M3 shape, and the one it morphs into over a spot it can land on (M3Shapes names)
    property string ghostShape: "Circle"
    property string ghostHotShape: "12SidedCookie"

    // its shape off the dial when it can be flung away (a device pill): M3Shapes name
    property string ghostFlingShape: "12SidedCookie"

    // its size when picked up (from the pill), and over a spot it can land on (1 = ghostSize)
    property real ghostPickScale: 0.6
    property real ghostHotScale: 1.12

    // it leans into the way it moves: degrees per 1000 px/s, never more than ghostTiltMax
    property real ghostTilt: 6
    property real ghostTiltMax: 16

    // ── the 8 spots ──
    // a spot's size (its radius from the corner / the edge's middle), and while the
    // dragged icon is over it
    property real spotRadius: 64
    property real spotHotRadius: 92

    // a drop within this many px of a spot lands on it
    property real spotReach: 300

    // an empty spot's dashed outline: how thick, and the dash and gap (in outline widths)
    property real spotOutline: 2
    property real spotDash: 3
    property real spotDashGap: 2.5

    property real spotIconSize: 24

    // the spot's name, under the icon while you're over it (M3 labelMedium)
    property real spotLabelSize: 12

    // ms between one spot popping in and the next (they go round clockwise)
    property int spotStagger: 22

    // ── the Screenshot pill ──
    // Outside Edit, a drag on it only pulls it off the ring when it starts going away
    // from (or towards) the centre; along the ring it turns the ring as usual.
    // 1 = anything steeper than 45°; 2 = it must be much straighter out
    property real pullStraightness: 1

    // the dashed rectangle showing where the screenshot will start (it follows the icon
    // once it's off the dial): corner roundness and outline width
    property real previewRadius: 12
    property real previewOutline: 2

    // ── fling to dismiss ── let go of a device pill mid-flick and it flies off and does
    // its action (e.g. disconnects); slower than flingSpeed (px/s) it springs back
    property real flingSpeed: 1400

    // how far it flies on: this many seconds of its speed
    property real flingCarry: 0.18

    // its size by the time it's gone
    property real flingEndScale: 0.4

    // ms the speed is smoothed over, and ms without a move after which a let-go counts as
    // still (you stopped, then let go: no fling)
    property real flingSmoothing: 40
    property int flingStale: 80

    // ── reordering tiles / dropping a device on a tile ── how big the tile under it grows
    // (it "inhales"), and how faint the tile you lifted gets
    property real tileInhaleScale: 1.25
    property real tileLiftedOpacity: 0.3

    // ── hints ── the first-contact line by the dial (Hints.qml): its distance from the
    // dial's edge, the room round its words, its text size, and how close to the screen's
    // edges it may get
    property real hintGap: 36
    property real hintPadding: 14
    property real hintFontSize: 13
    property real hintMargin: 12
}

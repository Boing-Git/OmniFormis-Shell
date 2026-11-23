import QtQuick
import "../primitive"

// ─────────────────────────────────────────────────────────────────────────────
// MEDIA PLAYER SETTINGS: everything about the media control in one place: the
// dial size, the wavy timeline, the play / pause gem and its previous / next
// buttons, the album art and the curved title / artist.
//
// These only affect the media control. They don't touch the inner ring or the other
// controls, and the inner ring's settings don't move anything here.
//
// Change the plain numbers in the top sections. The "worked out" section at the
// bottom follows them. Sizes are px unless it says otherwise; Quickshell reloads on save.
// ─────────────────────────────────────────────────────────────────────────────
QtObject {
    id: cfgRoot

    // Settings → Advanced changes any plain setting below, live, in every copy of this file
    Component.onCompleted: Advanced.adopt(cfgRoot, "MediaSettings")
    Component.onDestruction: Advanced.release(cfgRoot, "MediaSettings")

    // the dial's size right now (set by MediaPlayer.qml; animates while it grows)
    required property real liveSize

    // how much of a circle the dial shows (set by MediaPlayer.qml): 90 in a corner, 180 on an edge
    required property real sweepDeg

    // ── the dial ──
    // how big the dial grows while Media is selected (the other controls use 460). Big
    // enough for the volume / brightness knobs between the timeline and the outer ring
    property real dialSize: 600

    // ── the timeline ring ──
    // The timeline sits on Media's inner ring (controlCenter → innerRadiusRatio /
    // innerRadiusOffset below), this much further out. Move the inner ring and the
    // timeline, its band, the gem, the art and the text all move with it.
    property real timelineOffset: 25

    // how wide the scroll-to-seek zone is on each side of the timeline
    property real timelineZone: 26

    // degrees between two ticks (smaller: finer, smoother line; more ticks to draw)
    property real tickDeg: 2

    // seconds per tick (how far one wheel notch seeks); the line's length follows the song
    property real seekStep: 5

    // line thickness: the played part, and the part still to play (M3: the same for both)
    property real playedThickness: 8
    property real restThickness: 8

    // the M3 stop dot at the very end of the track, in the played colour (px, 0: none)
    property real stopSize: 4

    // ── the wave (on the played part) ──
    // how tall the wave is (centre to peak, px) while playing, and while paused
    // (M3: 3/4 of the stroke, and no wave while paused)
    property real waveHeight: 6
    property real pausedWaveHeight: 0

    // how long one wave is (px; bigger: longer, gentler waves; M3: 10x the stroke)
    property real wavelength: 50

    // longest straight bit the wave is drawn with (px; smaller: smoother, more work)
    property real wavePiece: 3

    // ms for the wave to travel one wavelength (smaller: faster; M3: 1000)
    property int waveSpeed: 1000

    // ticks over which the wave flattens out before the gem
    property real waveEase: 1

    // ms for the wave to calm down / rise on pause / play (only with Vars.useSprings off:
    // with springs on it follows the slow effects spring)
    property int waveFade: 500

    // ── the play / pause gem ──
    property real gemSize: 63
    property string gemShape: "12SidedCookie"
    property real gemIconSize: gemSize - 30

    // ms for one turn while playing (0: no spin)
    property int gemSpin: 8000

    // true: the gem turns tertiary while paused
    property bool gemPausedTertiary: true

    // the bounce on play ⇄ pause: how big it gets, ms to grow and to settle
    // (the overshoot comes from the M3E fast spatial curve)
    property real gemPopScale: 1.18
    property int gemPopIn: 90
    property int gemPopOut: 400

    // ── scrubbing (seeking along the timeline) ──
    // also count the mouse just resting on the timeline as scrubbing (not only scrolling it)
    property bool scrubOnHover: true

    // the wave lies flat while scrubbing (easier to aim along), and grows back after
    property bool scrubFlatten: false

    // how much thicker the line gets (px), and the played part turns tertiary
    property real scrubThicken: 3
    property bool scrubTertiary: true

    // how much bigger the gem gets
    property real scrubGemScale: 1.15

    // how many times the gem turns per turn of the ring, so it rolls like a wheel (0: no roll)
    property real gemRoll: 4

    // the not-yet-played track in M3's secondary-container (false: outline-variant)
    property bool trackContainer: true

    // ── previous / next buttons (on the timeline either side of the gem) ──
    property real sideSize: 32

    // space between the gem and a button
    property real sideGap: 6
    property real sideIconSize: 20

    // empty space between the end of the timeline's line and the buttons (px)
    property real controlGap: 10
    property string sideShape: "Circle"
    property real sideHoverScale: 1.12
    property real sidePressScale: 0.88

    // on hover: the shape it swaps to, how far it turns (degrees, each one its own way), and how long (ms)
    property string sideHotShape: "4SidedCookie"
    property real sideHotTurn: 90
    property int sideTurnDuration: 400

    // ── the album art ──
    // any M3Shapes name, e.g. "Circle", "Sunny", "6SidedCookie", "Gem"
    property string artShape: "6SidedCookie"

    // spin while playing, and how long one turn takes (ms)
    property bool artSpin: true
    property int artSpinDuration: 16000

    // what spins: "whole" (the cover turns with the shape, like a record) or
    // "edge" (only the shape's outline turns; the cover stays upright)
    property string artSpinMode: "edge"

    // space kept between the art and the screen edges / the text
    property real artEdgeMargin: 6

    // pulls the art this much closer to the screen edge / corner the dial lives on, on every
    // spot (px; negative: further out). Past artEdgeMargin it runs off the screen edge
    property real artInset: 20

    // the art's size as a share of the room it has (1 = as big as fits)
    property real artFill: 1.1

    // how big the cover is inside the shape (1 = the whole cover, just filling it). Below 1
    // the cover's edge pixels stretch out to the shape's edge, so keep it close to 1
    property real artCoverScale: 1

    // how dark the art gets while the mouse is on the timeline (0..1), and the seek-time text
    property real seekShade: 0.55
    property real seekTimeSize: 16              // M3 titleMedium
    property real seekLengthSize: 12            // M3 labelMedium

    // the seek time's bounce each time it changes: how big, ms to grow and to settle
    property real seekPopScale: 1.15
    property int seekPopIn: 60
    property int seekPopOut: 300

    // ── title / artist (curved around the art) ──
    property real titleSize: 14                 // M3 titleSmall
    property int titleWeight: 600
    property real artistSize: 11                // M3 labelSmall

    // gap between the art and the first line, and between the two lines
    property real textGap: 30
    property real lineGap: 30

    // the longest a line may run along the arc before it's cut with "…" (degrees)
    property real textMaxDeg: 70

    // room kept clear between the text and the timeline
    property real textClearance: 10

    // moves both lines further out (px; negative: closer in). Unlike textGap, it doesn't resize the art
    property real textOffset: -10

    // turns both lines along their arc (degrees; positive: clockwise, negative: anticlockwise)
    property real textShiftDeg: 0

    // ── the dial around the media player ──
    // Media's own copy of ControlCenterSettings, used only while Media is selected: the
    // outer ring, the bands, the scrolling, and the inner ring the timeline sits on.
    // These only change the media player; the other controls keep ControlCenterSettings.qml.
    // (What each one does: see ControlCenterSettings.qml.)
    readonly property var controlCenter: ControlCenterSettings {
        dialSize: liveSize

        // the dial
        closeOnEnter: false

        // the outer ring (the control tiles)
        ringRatio: 0.87
        tileSize: 70
        tileGap: 16
        selectedTileSize: 100
        tileIconSize: 32

        // the outer band
        bandThickness: 80
        bandExtraDeg: 15
        bandSweep: 120
        bandEdgeMargin: 16

        // the volume / brightness knobs (between the timeline's band and the outer band)
        knobsEnabled: true
        knobThickness: 40
        knobSpacing: 8
        knobTickDeg: 3
        knobNotch: 1
        knobGemSize: 42
        knobIconSize: 22

        // scrolling feel (outer ring)
        snapThreshold: 0.3
        snapDuration: 300

        // the date badge (hidden on Media, but here if you turn it on with `dateIcon`)
        dateX: 0
        dateY: 60
        dateScale: 1
        dateRotation: -45
        dateInset: 20

        // the timeline's settle / follow timing
        timelineSnap: 400
        scrubHold: 800

        // the inner ring: Media has no pills, but the timeline sits on it (plus
        // timelineOffset), and its band (the track behind the timeline) follows it.
        // innerRadiusRatio: 0.52 = 52% of the dial out from the corner (312 px, as before
        // the knobs made the dial bigger)
        innerRadiusRatio: 0.52
        innerRadiusOffset: 0
        pillHeight: 40
        pillSlotWidth: 120
        pillGap: 12
        pillPadding: 24
        pillIconSize: 16
        pillLabelSize: 12
        pillIconSpacing: 4
        pillLabelMax: 80
        m3Pills: false

        // the selected pill
        selectedPillGrowW: 10
        selectedPillGrowH: 10
        selectedPillScale: 1.2

        // the badge on the selected pill
        badgeSize: 40
        badgeInset: 4
        badgeShape: "12SidedCookie"
        badgeIconSize: 20
        badgeNumberSize: 14
        spinnerSize: 28

        // the inner band
        innerBandMargin: 40
        innerBandExtraDeg: 2
        innerBandSweep: 120

        // scrolling feel (inner ring)
        innerSnapThreshold: 0.3
        innerSnapDuration: 300
    }

    // ─────────────────────────────────────────────────────────────────────────
    // worked out from the settings above (don't edit, they follow)
    // ─────────────────────────────────────────────────────────────────────────
    readonly property real timelineRadius: controlCenter.innerRadius + timelineOffset

    // the room inside the timeline for the art and the text
    readonly property real room: timelineRadius - timelineZone - textClearance

    // the art sits on the dial's middle line, half the dial's angle away from each screen
    // edge, so its centre must be r / sin(that) out to clear them: r·√2 in a corner (two
    // edges at 45°), just r on an edge (one edge at 90°, so it sits right down against it)
    readonly property real edgeReach: 1 / Math.sin(Math.min(sweepDeg, 180) / 2 * Math.PI / 180)

    // the art: as big as fits between the screen edges and the two lines of text
    readonly property real artR: Math.max(16, (room - textGap - lineGap - artistSize - artEdgeMargin) / (1 + edgeReach) * artFill)
    readonly property real artDistance: artR * edgeReach + artEdgeMargin

    // the two text arcs (the title reads "above" the artist)
    readonly property real nearTextR: artDistance + artR + textGap + textOffset
    readonly property real farTextR: nearTextR + lineGap
}

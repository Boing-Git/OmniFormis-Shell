import QtQuick

// ─────────────────────────────────────────────────────────────────────────────
// CONTROL CENTER SETTINGS: the dial itself, the outer ring (the control tiles),
// the volume / brightness knobs, the date badge, the default timeline and the corner card.
//
// Also the inner ring (the pills), further down. The media player has its own file:
//   MediaSettings.qml - the media player, plus its own copy of these settings
//                       used only while Media is selected
//
// Change the plain numbers in the top sections. The "worked out" section at the
// bottom follows them, so the band, the scroll step and the hover zones move with
// the ring. Sizes are px unless it says otherwise; Quickshell reloads on save.
// ─────────────────────────────────────────────────────────────────────────────
QtObject {
    // the dial's size right now (set by ControlCenter.qml; animates while it grows)
    required property real dialSize

    // ── the dial ──
    // the dial's size for controls that don't ask for their own (Media asks for its own).
    // Big enough for the volume / brightness knobs between the two rings
    property real baseSize: 460

    // true: Enter / Space closes the dial after using something; false: it stays open
    property bool closeOnEnter: false

    // ── the outer ring (the control tiles) ──
    // distance from the corner to the middle of the tiles, as a share of the dial size
    property real ringRatio: 0.828

    // a tile's size, and the empty space between two tiles (sets the scroll step)
    property real tileSize: 70
    property real tileGap: 16

    // the selected tile's size (it grows to this)
    property real selectedTileSize: 100
    property real tileIconSize: 32

    // ms for one turn of the selected tile's shape (0: no spin)
    property int tileSpin: 0

    // the wiggle when a tile becomes selected: how far it tilts (degrees), ms to tilt
    // and to settle back (the overshoot comes from the M3E fast spatial curve)
    property real tileWiggleDeg: 8
    property int tileWiggleIn: 90
    property int tileWiggleOut: 450

    // ── the outer band (the track behind the tiles) ──
    // how thick the band is (across the ring)
    property real bandThickness: 80

    // the band starts this many degrees before the visible quarter (hides its end)
    property real bandExtraDeg: 15

    // how many degrees of band are drawn (on a corner; an edge dial adds 90)
    property real bandSweep: 120

    // the strip of band each side of the tiles (the band is bandThickness + this)
    property real bandEdgeMargin: 16

    // ── scrolling feel (outer ring) ──
    // how soon it snaps to a tile after a scroll (0..1, lower = sooner), and the snap time (ms)
    property real snapThreshold: 0.3
    property int snapDuration: 300

    // ── the volume / brightness knobs ──
    // Two tick rings like the volume OSD, between the inner ring and the outer ring:
    // volume on the inner one, brightness on the outer one. Scroll (or drag) a ring to
    // turn it; the tick under the gem is the value. A click on the volume ring mutes.
    // They always sit in the middle of the gap between the two bands.
    property bool knobsEnabled: true

    // how much room one knob takes across the ring (its gem fits in it), and the space
    // between the two knobs
    property real knobThickness: 40
    property real knobSpacing: 8

    // degrees between two ticks (one tick = 1%), and how many percent one wheel notch turns
    property real knobTickDeg: 3
    property int knobNotch: 1

    // the ticks: how thick, and how long (a long one every 10%)
    property real knobTickWidth: 4
    property real knobTickShort: 12
    property real knobTickLong: 20

    // how far (degrees) from the gem the ticks stay hidden, and over how many more they fade in
    property real knobGemGapDeg: 7
    property real knobGemFadeDeg: 6

    // the gem on the middle mark: its size, the icon in it, its M3 shapes (any M3Shapes name)
    property real knobGemSize: 42
    property real knobIconSize: 22
    property real knobNumberSize: 13

    // how much the gem and its icon grow while the mouse is on the knob (px)
    property real knobGemHoverGrow: 10
    property real knobIconHoverGrow: 8
    property string volumeGemShape: "12SidedCookie"
    property string brightnessGemShape: "Sunny"

    // how many degrees the gem turns per degree the ring turns, so it rolls along (0: no roll)
    property real knobGemRoll: 1

    // the gem shows the number instead of the icon while the mouse is on the knob, and
    // for this long (ms) after the last change
    property int knobNumberHold: 900

    // the gem's bounce when the value changes: how big, ms to grow and to settle
    property real knobPopScale: 1.12
    property int knobPopIn: 60
    property int knobPopOut: 300

    // the rubber band past 0% / 100% on a drag: the furthest it can stretch (degrees), how
    // quickly it gets there (higher = less hand movement, and less to wind back), and the
    // share of the max that counts as pulled
    // (fires hitLimit; let go there past 0% on the volume knob to mute)
    property real knobStretchMax: 18
    property real knobStretchResistance: 2
    property real knobStretchTrigger: 0.8

    // how much the gem swells at a full stretch (0.15 = 15% bigger), and its shake when
    // the pull counts: degrees of the first swing (the swings after come from Vars.shakeSpring)
    property real knobStretchSwell: 0.15
    property real knobShakeDeg: 8

    // ── reach is precision ── a knob (or the timeline) dragged from further out than its
    // own ring turns finer: the turn is scaled by (ring radius / hand's distance) to this
    // power, on top of the longer lever the distance already is. So pull the hand away,
    // even off the dial, for exact steps. 0: off (it turns with the hand's angle); 1: at
    // twice the ring's radius each px of hand turns it a quarter as far; 2: an eighth
    property real knobReachPower: 1

    // ── the date badge (hidden on controls with `dateIcon: false`, e.g. Media) ──
    // where it sits from the dial's corner, its size and its tilt (degrees), as on a
    // top-left dial: on any other spot it's turned round with the dial, and kept upright
    property real dateX: 0
    property real dateY: 60
    property real dateScale: 1
    property real dateRotation: -45

    // pulls it this much closer to the screen edge / corner the dial lives on, on every
    // spot (px; negative: further out)
    property real dateInset: 20

    // ── the clock (hidden where the date badge is, e.g. Media) ──
    // the hours and the minutes sit on either side of the date badge. On an edge: this
    // many degrees round the dial from it, this many px from the dial's centre. Kept
    // upright on every spot
    property real clockSpread: 54
    property real clockDistance: 72

    // on a corner the numbers sit along the two screen edges from the badge instead (the
    // hours beside it, the minutes under / over it): px from the badge's middle to each
    property real clockCornerGap: 64
    property real clockScale: 1

    // "24h": 13:05;  "12h": 1:05 (no AM / PM);  "12hAmPm": 1:05 with an AM / PM shape
    // between the hours and the minutes (on a corner at 45°, between the two edges)
    property string clockFormat: "12h"

    // each number's shape: its smallest size, and the room round the digits
    property real clockSize: 44
    property real clockPadding: 11
    property real clockFontSize: 17

    // the M3 shapes each number steps through, one per change (they morph on a spring)
    property var clockHourShapes: ["Slanted", "Square", "Gem"]
    property var clockMinuteShapes: ["4SidedCookie", "6SidedCookie", "Puffy", "SoftBurst"]

    // how far (px) the new digits drop in from
    property real clockDrop: 10

    // the AM / PM shape ("12hAmPm"): px from the badge's middle (out from the screen edge
    // or corner, between the two numbers), its smallest size, text size, and the M3
    // shapes it steps through (AM ⇄ PM morphs)
    property real clockAmPmGap: 64
    property real clockAmPmSize: 34
    property real clockAmPmFontSize: 12
    property var clockAmPmShapes: ["Pill", "Oval"]

    // ── the default timeline (controls with a timeline but no style of their own) ──
    // Media has its own (MediaSettings.qml); these are for any other timeline.
    // between the rings: how wide the seek zone is on each side
    property real timelineZone: 14

    // in place of the inner ring (a control with no pills): how far out, and the zone
    property real timelinePush: 30
    property real timelineInnerZone: 26

    // degrees between ticks
    property real tickDeg: 2

    // how long the timeline takes to settle on a tick (ms), and how long after you stop
    // scrolling it starts following the control again (ms)
    property int timelineSnap: 400
    property int scrubHold: 800

    // ms the outer ring must be still before the wheel can reach the inner ring / timeline
    // again (so scrolling past Media never seeks the music)
    property int ringSettleDelay: 100

    // true: the selected control (and so Media's bigger dial, the inner ring's devices)
    // only changes once the outer ring stops; false: it changes as each tile passes
    property bool holdSelectionWhileTurning: true

    // ── the corner card (for controls with a `corner` that is scaled with the dial) ──
    // Media's card isn't scaled (it sizes itself from MediaSettings)
    // the card's scale is (inner ring radius - cornerOffset) / cornerBase, never below cornerMinScale
    property real cornerBase: 141
    property real cornerOffset: 30
    property real cornerMinScale: 0.6

    // how far from the corner a card sits if it doesn't say (cornerDistance)
    property real cornerDistance: 72

    // ══ the inner ring (the pills with devices / networks / actions) ══

    // ── where it sits ──
    // distance from the corner to the middle of the pills, as a share of the dial size.
    // 0.372 = 37% of the way out (171 px on the 460 px dial). Try 0.34 (closer to the
    // corner) or 0.4 (further out; the knobs then get less room)
    property real innerRadiusRatio: 0.372

    // a fixed nudge on top of that: + pushes the ring out, - pulls it in
    property real innerRadiusOffset: 0

    // ── the pills ──
    // height of a pill (across the ring). The band, the hover zone and the badge follow it.
    property real pillHeight: 40

    // the room each pill gets along the ring, and the empty space between two pills.
    // Together they set how far one wheel notch turns the ring.
    property real pillSlotWidth: 120
    property real pillGap: 12

    // space added around the icon + name (both sides together)
    property real pillPadding: 24
    property real pillIconSize: 16
    property real pillLabelSize: 12

    // space between the icon and the name
    property real pillIconSpacing: 4

    // the longest a name can get before it's cut with "…"
    property real pillLabelMax: 80

    // true: the pills use the M3 "Pill" shape; false: a plain rounded rectangle
    property bool m3Pills: false

    // the M3 shape behind each pill's icon, and the one it swaps to on the selected pill
    // (any M3Shapes name, e.g. "Pill", "Circle", "Sunny", "8SidedCookie", "Gem")
    property string pillIconShape: "Pill"
    property string selectedPillIconShape: "Pill"

    // degrees that shape is turned (the "Pill" is diagonal at 0; 45 lays it level, but then it looks almost round)
    property real pillIconShapeTurn: 0

    // how much wider that shape is than the icon
    property real pillIconShapePad: 14

    // ms for one turn of the selected pill's icon shape (0: no spin)
    property int pillIconSpin: 0

    // ── the wiggle when a pill becomes selected ──
    // how far it tilts (degrees), ms to tilt and to settle back (M3E fast spatial curve)
    property real pillWiggleDeg: 6
    property int pillWiggleIn: 90
    property int pillWiggleOut: 400

    // ── the selected pill (the one in the middle) ──
    // how much longer and taller it gets, then how much it is scaled on top of that
    property real selectedPillGrowW: 10
    property real selectedPillGrowH: 10
    property real selectedPillScale: 1.2

    // ── the badge on the selected pill (number / spinner / check / link) ──
    property real badgeSize: 40

    // how far its centre sits in from the pill's top-right corner
    property real badgeInset: 4

    // any M3Shapes name, e.g. "Circle", "Sunny", "8SidedCookie"
    property string badgeShape: "12SidedCookie"
    property real badgeIconSize: 20
    property real badgeNumberSize: 14
    property real spinnerSize: 28

    // it twirls in when a pill is selected: from this many degrees back, popping up from 0 size (ms)
    property real badgeSpinInDeg: 120
    property int badgePopDuration: 350
    property int badgeSpinDuration: 450

    // ── the inner band (the track behind the pills) ──
    // space between the pills and the band's edges (each side). It never gets smaller
    // than what the grown selected pill needs, so the pill can't stick out of it.
    property real innerBandMargin: 40

    // the band starts this many degrees before the visible quarter (hides its end)
    property real innerBandExtraDeg: 2

    // how many degrees of band are drawn (on a corner; an edge dial adds 90)
    property real innerBandSweep: 120

    // ── scrolling feel (inner ring) ──
    property real innerSnapThreshold: 0.3
    property int innerSnapDuration: 300

    // ─────────────────────────────────────────────────────────────────────────
    // worked out from the settings above (don't edit, they follow)
    // ─────────────────────────────────────────────────────────────────────────
    readonly property real ringRadius: dialSize * ringRatio

    // the tiles' inner edge, and the selected tile's inner edge
    readonly property real tileInner: ringRadius - tileSize / 2
    readonly property real selectedTileInner: ringRadius - selectedTileSize / 2

    // degrees between two tiles, measured on their inner edge so they never touch
    readonly property real stepDeg: (tileSize + tileGap) / Math.max(1, tileInner) * 180 / Math.PI

    // the inner ring
    readonly property real innerRadius: dialSize * innerRadiusRatio + innerRadiusOffset

    // the selected pill's height once grown and scaled
    readonly property real selectedPillHeight: (pillHeight + selectedPillGrowH) * selectedPillScale

    // the inner band's margin: as set, but always enough for the selected pill
    readonly property real innerBandMarginUsed: Math.max(innerBandMargin, (selectedPillHeight - pillHeight) / 2 + 4)

    // the pills' outer edge
    readonly property real pillOuter: innerRadius + pillHeight / 2

    // degrees between two pills, measured on the pills' inner edge so they never touch
    readonly property real innerStepDeg: (pillSlotWidth + pillGap) / Math.max(1, innerRadius - pillHeight / 2) * 180 / Math.PI

    // the gap the knobs live in: from the inner band's outer edge to the outer band's inner edge
    readonly property real innerBandOuter: innerRadius + pillHeight / 2 + innerBandMarginUsed
    readonly property real outerBandInner: ringRadius - (bandThickness + bandEdgeMargin) / 2

    // the two knobs, side by side in the middle of that gap
    readonly property real knobsMid: (innerBandOuter + outerBandInner) / 2
    readonly property real volumeRadius: knobsMid - (knobThickness + knobSpacing) / 2
    readonly property real brightnessRadius: knobsMid + (knobThickness + knobSpacing) / 2

    // where the mouse switches from one ring to the next: halfway across each gap
    readonly property real knobZoneInner: (innerBandOuter + volumeRadius - knobThickness / 2) / 2
    readonly property real knobZoneMid: knobsMid
    readonly property real knobZoneOuter: (brightnessRadius + knobThickness / 2 + outerBandInner) / 2
}

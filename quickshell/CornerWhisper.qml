import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import Quickshell.Services.Pipewire
import "primitive"
import "variables.js" as Vars

// What one closed corner (or edge middle) says. A dial that is put away is a 20 px corner
// that says nothing; this draws one true thing on the spots that have something to tell:
//
//   - where the volume lives (its pop-up's spot; the control center's when the pop-up is
//     off): a small arc filled to the level, empty while muted, which waves slowly while
//     music plays
//   - on the control center's spot: a bead per notification you haven't looked at yet
//
// It fades away while a dial is open (or peeking) on its spot, and it is a tiny window of
// its own (so a waving arc repaints 40 px, not the screen) that takes no mouse at all.
// shell.qml makes one per spot; a spot with nothing to say has no window.
//
// settings: the Corners group in the control center's Settings control (cornerVolume /
// cornerUnread in variables.js)
PanelWindow {
    id: win
    // the screen the shell lives on (Dials.screen): when the monitor goes away and comes
    // back (a DisplayPort monitor does as it sleeps) the window follows it back
    screen: Dials.screen


    // "topLeft" | "top" | ... the spot this one speaks for
    required property string spot

    // ── settings ── sizes are px
    // the volume arc, drawn like M3E's wavy progress indicator: the level, then a small
    // gap, then the track for the rest. Its distance from the corner, how thick the level
    // and the track are, the gap (px) and the degrees kept clear at each end
    property real arcRadius: 20
    property real arcWidth: 4
    property real trackWidth: 4
    property real trackGap: 5
    property real arcPad: 10

    // the wave while music plays: how far it swings (px), its length (px, the same on any
    // arc) and ms for it to travel one whole wave; it eases flat over `waveEase` px at both
    // ends, so the round caps sit on the arc
    property real waveHeight: 1.6
    property real waveLength: 18
    property real waveEase: 6
    property int wavePeriod: 2600

    // the beads: their distance from the corner, their size, the degrees between two, and
    // how many at most (more than that still shows this many)
    property real beadRadius: 28
    property real beadSize: 4.5
    property real beadStepDeg: 15
    property int beadMax: 5

    // ── what this spot has to say ──
    readonly property bool volumeSpot: spot === (Dials.popups.indexOf("volume") >= 0 ? Dials.spotOf("volume") : Dials.spotOf("center"))

    // the arc (Prefs.cornerVolume): always for "level" and "both", only while music plays
    // for "music"
    readonly property bool hasVolume: volumeSpot && (Prefs.cornerVolume === "level" || Prefs.cornerVolume === "both"
        || (Prefs.cornerVolume === "music" && Prefs.musicPlaying))
    readonly property int beads: Prefs.cornerUnread && spot === Dials.spotOf("center") ? Math.min(beadMax, Notifs.unseen) : 0

    // quiet while a dial is out on this spot
    readonly property bool busy: Dials.busyAt(spot)
    readonly property bool speaks: hasVolume || beads > 0

    // ── the window: just the corner ── a square in a corner, twice as long along an edge
    readonly property bool isCorner: Dials.isCorner(spot)
    readonly property bool alongX: spot === "top" || spot === "bottom"
    readonly property bool alongY: spot === "left" || spot === "right"
    readonly property real reach: 34
    anchors {
        top: spot === "topLeft" || spot === "top" || spot === "topRight"
        bottom: spot === "bottomLeft" || spot === "bottom" || spot === "bottomRight"
        left: spot === "topLeft" || spot === "left" || spot === "bottomLeft"
        right: spot === "topRight" || spot === "right" || spot === "bottomRight"
    }
    implicitWidth: reach * (alongX ? 2 : 1)
    implicitHeight: reach * (alongY ? 2 : 1)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "dial-whisper"

    // no window at all while there's nothing to say; never takes the mouse
    visible: speaks || fader.opacity > 0.01
    mask: Region {}

    // the point the dial grows out of, and the part of the circle that shows (as DialDelegate)
    readonly property real cx: alongX ? width / 2 : (spot === "topRight" || spot === "right" || spot === "bottomRight") ? width : 0
    readonly property real cy: alongY ? height / 2 : (spot === "bottomLeft" || spot === "bottom" || spot === "bottomRight") ? height : 0
    readonly property real startDeg: Dials.spotStartDeg(spot)
    readonly property real sweepDeg: Dials.spotSweepDeg(spot)
    readonly property real midDeg: startDeg + sweepDeg / 2

    // an arc reads left to right: from its high-angle end where that end is the left one
    readonly property bool fromHigh: Math.sin(midDeg * Math.PI / 180) > 0
    readonly property real usable: sweepDeg - arcPad * 2

    // the angle `t` (0..1) of the way along the arc, in reading order
    function degAt(t) { return fromHigh ? startDeg + sweepDeg - arcPad - t * usable : startDeg + arcPad + t * usable }

    // ── the volume ──
    readonly property var sink: Pipewire.defaultAudioSink

    // Pipewire only reports a node's volume while something tracks it
    PwObjectTracker { objects: [win.sink] }
    readonly property bool muted: !!(sink && sink.audio && sink.audio.muted)
    readonly property real level: sink && sink.audio && !muted ? Math.max(0, Math.min(1, sink.audio.volume)) : 0

    // the level slides to a new value instead of jumping
    SpringValue {
        id: levelSpring
        to: win.level
        stiffness: Vars.springs.standard.fast.spatial.stiffness
        dampingRatio: Vars.springs.standard.fast.spatial.dampingRatio
        epsilon: 0.002
        Component.onCompleted: snap(to)
    }

    // the wave travels while music plays; it lies flat (and nothing repaints) otherwise
    readonly property bool waving: (Prefs.cornerVolume === "music" || Prefs.cornerVolume === "both")
        && Prefs.musicPlaying && hasVolume && !busy && level > 0
    property real wavePhase: 0
    NumberAnimation on wavePhase {
        from: 0; to: Math.PI * 2
        duration: win.wavePeriod
        loops: Animation.Infinite
        running: win.waving
    }
    property real waveAmp: waving ? waveHeight : 0
    Behavior on waveAmp { NumberAnimation { duration: Vars.expressiveSlowEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveSlowEffects.bezier } }

    // px along the arc ↔ the share of it, at the arc's radius
    readonly property real arcLength: usable * Math.PI / 180 * arcRadius

    // a point `s` px along the arc (reading order), pushed out by `dr` px
    function arcPoint(s, dr) {
        const a = degAt(s / arcLength) * Math.PI / 180
        return Qt.point(cx + (arcRadius + dr) * Math.cos(a), cy + (arcRadius + dr) * Math.sin(a))
    }

    // the level's line: a point every 1.5 px along the filled part, pushed in and out by
    // the wave
    readonly property real levelLength: Math.max(0, levelSpring.value) * arcLength
    readonly property var levelPoints: {
        const L = levelLength
        const n = Math.max(2, Math.ceil(L / 1.5))
        const out = []
        for (let i = 0; i <= n; i++) {
            const s = L * i / n
            const ease = Math.max(0, Math.min(1, s / waveEase, (L - s) / waveEase))
            out.push(arcPoint(s, waveAmp * ease * Math.sin(2 * Math.PI * s / waveLength - wavePhase)))
        }
        return out
    }

    // the track: the rest of the arc, after the gap (all of it while muted)
    readonly property var trackPoints: {
        const from = levelLength > 0.5 ? levelLength + arcWidth / 2 + trackGap + trackWidth / 2 : 0
        if (from >= arcLength) return []
        const n = Math.max(2, Math.ceil((arcLength - from) / 2))
        const out = []
        for (let i = 0; i <= n; i++) out.push(arcPoint(from + (arcLength - from) * i / n, 0))
        return out
    }

    Item {
        id: fader
        anchors.fill: parent
        opacity: win.speaks && !win.busy ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

        Shape {
            anchors.fill: parent
            visible: win.hasVolume
            preferredRendererType: Shape.CurveRenderer

            // the track: secondary-container, as M3's progress indicators
            ShapePath {
                strokeColor: win.trackPoints.length > 1 ? Roles.secondary_container : "transparent"
                strokeWidth: win.trackWidth
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: win.trackPoints }
            }

            // the level: primary, as on the volume knob and its pop-up
            ShapePath {
                strokeColor: levelSpring.value > 0.005 ? Roles.primary : "transparent"
                strokeWidth: win.arcWidth
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                PathPolyline { path: win.levelPoints }
            }
        }

        // the beads: tertiary, so they read apart from the level (as the two knobs do), each
        // on a dot of the dial's surface
        Repeater {
            model: win.beads

            Rectangle {
                required property int index
                // the group sits round the middle of the arc, the first bead on the reading-left
                readonly property real a: win.degAt(0.5 + (index - (win.beads - 1) / 2) * win.beadStepDeg / win.usable) * Math.PI / 180
                width: win.beadSize + 4
                height: width
                radius: width / 2
                x: win.cx + win.beadRadius * Math.cos(a) - width / 2
                y: win.cy + win.beadRadius * Math.sin(a) - height / 2
                color: Roles.surface_container
                antialiasing: true

                // pops in on the fast spring as it arrives
                scale: 0
                Component.onCompleted: scale = 1
                Behavior on scale { NumberAnimation { duration: Prefs.fastSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier } }

                Rectangle {
                    anchors.centerIn: parent
                    width: win.beadSize
                    height: width
                    radius: width / 2
                    color: Roles.tertiary
                    antialiasing: true
                }
            }
        }
    }
}

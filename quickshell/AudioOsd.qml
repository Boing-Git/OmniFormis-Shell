import Quickshell
import Quickshell.Wayland
import QtQuick
import Quickshell.Io
import QtQuick.Shapes
import Quickshell.Services.Pipewire
import "primitive"
import "variables.js" as Vars

// The volume OSD: a corner dial that springs open whenever the volume or mute
// changes, shows the level as an arc, and closes itself again a moment later.
// While it's open you can scroll on it to change the volume, or click to mute.
//
// It only exists on screen while it's open (the window hides when it's
// collapsed), so it never adds a hot corner on top of the dial that already
// lives in that corner.
//
// keybinds:  qs -p <this folder> ipc call volume up | down | mute | toggle
PanelWindow {
    id: win
    // the screen the shell lives on (Dials.screen): when the monitor goes away and comes
    // back (a DisplayPort monitor does as it sleeps) the window follows it back
    screen: Dials.screen

    // its own layer name, so its frost is its own (Prefs: Pop-up frost, Look settings)
    WlrLayershell.namespace: "quickshell-popup"

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: dial }

    // shown only while the dial is open or still shrinking
    visible: dial.open || dial.currentSize > dial.collapsedSize + 0.5

    // ── audio ──
    readonly property var sink: Pipewire.defaultAudioSink

    // Pipewire only reports a node's volume while something tracks it
    PwObjectTracker { objects: [win.sink] }

    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: !!(sink && sink.audio && sink.audio.muted)

    // how much one wheel notch or one `up` / `down` call changes the volume
    readonly property real step: 0.05

    function setVolume(v) {
        if (!sink || !sink.audio) return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(1, v))
    }

    function toggleMute() {
        if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
    }

    // so the control center can open it, and Edit can move it (Dials.qml)
    Component.onCompleted: Dials.register("volume", dial)
    Component.onDestruction: Dials.unregister("volume", dial)

    // ── showing and hiding ──
    // how long the OSD stays after the last change, ms
    readonly property int holdTime: 1500

    // changes in the first moments after startup are Pipewire reporting the
    // current level, not the user changing it: ignore those
    property bool armed: false
    Timer { interval: 1500; running: true; onTriggered: win.armed = true }

    function show() {
        if (!armed) return

        // the control center has its own volume knob: no OSD while it's open
        if (Dials.dials.center && Dials.dials.center.open) return

        // not over a dial that's open on this spot; another OSD there hands over to this
        // one (it's put away, and this one carries on from its size)
        const from = Dials.popUpAt("volume")
        if (from < 0) return
        if (!dial.open) { if (from > 0) dial.openFrom(from); else dial.open = true }
        hideTimer.interval = win.holdTime
        hideTimer.restart()
    }

    // closes the OSD once the hold time passes, unless the mouse is on it
    Timer {
        id: hideTimer
        interval: win.holdTime
        onTriggered: if (dial.hovered) restart(); else dial.open = false
    }

    onVolumeChanged: show()
    onMutedChanged: show()

    // keybinds:  qs -p <this folder> ipc call volume up
    IpcHandler {
        target: "volume"
        function up(): void { win.setVolume(win.volume + win.step); win.show() }
        function down(): void { win.setVolume(win.volume - win.step); win.show() }
        function mute(): void { win.toggleMute(); win.show() }
        function toggle(): void { if (dial.open) dial.open = false; else { win.armed = true; win.show() } }
        function open(): void { win.armed = true; win.show() }
        function close(): void { dial.open = false }
    }

    DialDelegate {
        id: dial

        // glass as a pop-up (Prefs: Pop-ups, Look settings)
        glassKind: "popup"
        corner: Dials.spotOf("volume")

        // opened from the Dials control: stays a while longer than a volume change
        function popUp() {
            win.armed = true
            win.show()
            hideTimer.interval = win.holdTime * 3
            hideTimer.restart()
        }
        expandedSize: 220

        // an OSD shouldn't close the moment the mouse passes over it: the hold
        // timer closes it instead
        closeOnExit: false
        autoClose: false

        // M3E roles: the dial is a surface container, edged with outline-variant
        color: Roles.surface_container
        borderColor: Roles.outline_variant

        // scrolling turns the knob one tick (1%) per notch, from where it's heading (quick
        // notches add up); the knob sets the volume
        onScrolled: dir => { spin.following = -1; spin.snapTo(Math.max(0, Math.min(100, spin.heading - dir))); win.show() }
        onDragged: deg => { spin.following = -1; spin.dragBy(deg); win.show() }

        // the knob doesn't glide: settle on a tick between 0% and 100%
        onFlung: { spin.following = -1; spin.snapTo(Math.max(0, Math.min(100, spin.pos))) }

        // a click mutes / unmutes (DialDelegate closes on click; the mute change reopens it)
        onActivated: win.toggleMute()

        M3Shapes { id: shapes }

        // ── the level arc ──
        // the track runs along the quarter, a little in from both edges, and the
        // fill grows along it with the volume
        readonly property real arcRadius: expandedSize * 0.78
        readonly property real arcWidth: 16
        readonly property real arcPad: 10                     // degrees kept clear at each end
        readonly property real arcSweep: 90 - arcPad * 2
        readonly property real level: win.muted ? 0 : Math.min(1, win.volume)

        // the fill's sweep, on a spring so a change slides instead of jumping, and quick
        // changes in a row keep their speed instead of each starting over
        readonly property real fillSweep: fillSpring.value
        SpringValue {
            id: fillSpring
            to: dial.arcSweep * dial.level
            stiffness: Vars.springs.standard.fast.spatial.stiffness
            dampingRatio: Vars.springs.standard.fast.spatial.dampingRatio
            epsilon: 0.05
            Component.onCompleted: snap(to)
        }

        DialRotation {
            id: spin
            stepDeg: 3          // degrees between ticks; try 2 for denser, 5 for sparser
            momentum: 0         // one tick per notch; a volume knob shouldn't glide

            // the tick the knob is turning to because the volume changed somewhere
            // else (keys, wpctl); -1 while the user is the one turning it
            property int following: -1

            // the knob turned: the tick at the middle is the volume, in percent
            onPosChanged: {
                if (following >= 0) {
                    if (pos === following) following = -1
                    return
                }
                const p = Math.max(0, Math.min(100, pos))
                if (p !== pos) { if (!dial.pressed) snapTo(p); return }       // past 0% or 100%: spring back (after a drag)
                if (p !== Math.round(win.volume * 100)) { win.setVolume(p / 100); userHold.restart() }
            }

            // a snap is over: if the volume moved on meanwhile (quick ups and downs), catch
            // up now instead of staying behind
            onSettled: { following = -1; dial.sync() }
        }

        // ms after the user turns the knob during which Pipewire's reports (which echo the
        // knob's writes, a little late and sometimes out of order) are not chased
        Timer {
            id: userHold
            interval: 350
            onTriggered: dial.sync()
        }

        // turns the knob to the volume unless it's already there or on its way there
        // (compared with where it's heading, not where it is mid-snap)
        function sync() {
            const p = Math.max(0, Math.min(100, Math.round(win.volume * 100)))
            if (p === spin.heading) return
            if (!dial.open) { spin.following = -1; spin.scroll = -p * spin.stepDeg; return }
            spin.following = p
            spin.snapTo(p)
        }

        // the volume changed somewhere else: turn the knob to match, without the ticks
        // it passes on the way writing the volume back. Not while the user is turning
        // it; the knob catches up once they stop
        Connections {
            target: win
            function onVolumeChanged() { if (!userHold.running && !dial.pressed) dial.sync() }
        }

        DialRing {
            id: ring
            count: 101          // 0% to 100%; listIndex (not itemIndex) is used, so it never loops
            anchors.fill: parent
            cx: dial.centerX
            cy: dial.centerY
            startDeg: dial.startDeg
            sweepDeg: dial.sweepDeg
            radius: dial.expandedSize * 0.8
            stepDeg: spin.stepDeg
            scroll: spin.scroll
            preload: 2
            itemWidth: 6
            itemHeight: 40

            delegate: Item {
                // filled in by DialRing: the raw tick number (doesn't wrap) and
                // whether it's the one at the middle
                property int listIndex
                property bool selected

                // this slot's angle on the ring, filled in by DialRing every frame
                property real ringDeg

                // DialRing already turns each slot so its height points away from
                // the centre, so the ticks come out radial with no rotation here
                Rectangle {
                    anchors.centerIn: parent
                    width: 4
                    height: parent.listIndex % 10 === 0 ? 28 : 18      // longer ticks every 10%
                    radius: width / 2

                    // how far (degrees) from the gem a tick stays hidden, and how far past
                    // that it takes to fade fully in
                    readonly property real gapDeg: 10
                    readonly property real fadeDeg: 6

                    // how far this tick is from the gem, measured on the ring itself, so
                    // it follows the real movement and never drifts under the gem
                    readonly property real fromGem: Math.abs(parent.ringDeg - dial.midDeg)

                    // fades in as it moves away from the gem. Nothing past 0% or 100%.
                    visible: parent.listIndex >= 0 && parent.listIndex <= 100
                    opacity: Math.max(0, Math.min(1, (fromGem - gapDeg) / fadeDeg))
                    color: parent.listIndex <= Math.round(win.volume * 100) && !win.muted ? Roles.primary : Roles.outline_variant

                    // smooth edges on the turned ticks (they were jagged without)
                    antialiasing: true
                }
            }
        }

        // The gem sits outside the ring, on the middle mark, so it is drawn above
        // every tick. Inside a tick's slot it was hidden by the ticks of later
        // slots when scrolling fast.
        Shape {
            id: gem
            width: 50
            height: 50
            x: dial.centerX + ring.radius * Math.cos(dial.midRad) - width / 2
            y: dial.centerY + ring.radius * Math.sin(dial.midRad) - height / 2
            rotation: dial.midDeg + 90          // the turn each tick's slot gets
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: "transparent"
                fillColor: Roles.primary
                scale: shapes.fitScale(gem)

                PathSvg { path: shapes.getPath("12SidedCookie") }
            }
        }

        // ── the icon and the percentage, as one group centred in the empty space ──
        // The ticks sit at 0.8 of the dial and are about 28 px long, so the empty
        // space is a quarter disc (a half disc on an edge) of this radius. Its middle is
        // 0.6 of the radius out along the diagonal on a quarter disc (4/3π × √2), 0.42
        // on a half disc (4/3π): 2·sin(a) / 3a, for a slice of half-angle a
        readonly property real emptyRadius: expandedSize * 0.8 - 14
        readonly property real halfSweepRad: dial.sweepDeg / 2 * Math.PI / 180
        readonly property real groupRadius: emptyRadius * 2 * Math.sin(halfSweepRad) / (3 * halfSweepRad)
        readonly property real midRad: dial.midDeg * Math.PI / 180

        Column {
            id: group
            spacing: 4

            // as wide as the icon tile, so the percentage centres under it
            width: 64
            x: dial.centerX + dial.groupRadius * Math.cos(dial.midRad) - width / 2
            y: dial.centerY + dial.groupRadius * Math.sin(dial.midRad) - height / 2

            Item {
                id: iconTile
                width: 64; height: 64

                Shape {
                    id: tileShape
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        fillColor: win.muted ? Roles.surface_container_high : Roles.primary_container
                        strokeColor: "transparent"
                        scale: shapes.fitScale(tileShape)
                        PathSvg { path: shapes.getPath(win.muted ? "Circle" : "12SidedCookie") }
                        Behavior on fillColor { ColorAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
                    }
                }

                SymbolIcon {
                    anchors.centerIn: parent
                    text: win.muted || win.volume <= 0 ? "volume_off"
                        : win.volume < 0.34 ? "volume_mute"
                        : win.volume < 0.67 ? "volume_down" : "volume_up"
                    size: 32
                    filled: true
                    color: win.muted ? Roles.on_surface_variant : Roles.on_primary_container
                }
            }

            SmoothText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: win.muted ? "Muted" : Math.round(win.volume * 100) + "%"
                font.pixelSize: 16                 // M3 titleMedium
                font.weight: 700
                color: win.muted ? Roles.on_surface_variant : Roles.on_surface
            }
        }
    }
}

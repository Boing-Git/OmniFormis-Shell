import Quickshell
import Quickshell.Wayland
import QtQuick
import Quickshell.Io
import QtQuick.Shapes
import "primitive"
import "variables.js" as Vars

// The brightness OSD: a corner dial that springs open whenever the brightness changes,
// shows the level as an arc, and closes itself again a moment later. While it's open
// you can scroll on it to change the brightness.
//
// It turns the same level as the control center's brightness knob (Brightness.qml), so
// the two never disagree. On a laptop the backlight file is watched, so the brightness
// keys pop it up too; a desktop monitor (DDC) can't be read back, so there it pops up
// for changes made through the shell: the knob, the OSD, or
//
// keybinds:  qs -p <this folder> ipc call brightness up | down | set 40 | toggle
//
// It only exists on screen while it's open (the window hides when it's collapsed), so
// it never adds a hot corner on top of the dial that already lives in that corner.
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

    // ── the level ── (controlcenter/BrightnessLevel through Brightness.qml):
    // value 0..1, available, locked, icon, set(v)
    readonly property var level: Brightness.level
    readonly property real brightness: level.value

    // how much one wheel notch or one `up` / `down` call changes it
    readonly property real step: Vars.brightnessStep

    function setBrightness(v) { level.set(Math.max(0, Math.min(1, v))) }

    // so the control center can open it, and Edit can move it (Dials.qml)
    Component.onCompleted: Dials.register("brightness", dial)
    Component.onDestruction: Dials.unregister("brightness", dial)

    // ── showing and hiding ──
    // how long the OSD stays after the last change, ms
    readonly property int holdTime: 1500

    // the level found at startup isn't the user changing it: ignore those first moments
    property bool armed: false
    Timer { interval: 1500; running: true; onTriggered: win.armed = true }

    function show() {
        if (!armed) return

        // the control center has its own brightness knob: no OSD while it's open
        if (Dials.dials.center && Dials.dials.center.open) return

        // not over a dial that's open on this spot; another OSD there hands over to this
        // one (it's put away, and this one carries on from its size)
        const from = Dials.popUpAt("brightness")
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

    onBrightnessChanged: show()

    // keybinds:  qs -p <this folder> ipc call brightness up
    IpcHandler {
        target: "brightness"
        function up(): void { win.setBrightness(win.brightness + win.step); win.show() }
        function down(): void { win.setBrightness(win.brightness - win.step); win.show() }

        // a percentage, 0..100
        function set(percent: int): void { win.setBrightness(percent / 100); win.show() }
        function toggle(): void { if (dial.open) dial.open = false; else { win.armed = true; win.show() } }
        function open(): void { win.armed = true; win.show() }
        function close(): void { dial.open = false }
    }

    DialDelegate {
        id: dial

        // glass as a pop-up (Prefs: Pop-ups, Look settings)
        glassKind: "popup"
        corner: Dials.spotOf("brightness")

        // opened from the Dials control: stays a while longer than a change
        function popUp() {
            win.armed = true
            win.show()
            hideTimer.interval = win.holdTime * 3
            hideTimer.restart()
        }
        expandedSize: 220

        // an OSD shouldn't close the moment the mouse passes over it: the hold timer
        // closes it instead; and a click has nothing to switch, so it doesn't close either
        closeOnExit: false
        autoClose: false

        // M3E roles: the dial is a surface container, edged with outline-variant
        color: Roles.surface_container
        borderColor: Roles.outline_variant

        // scrolling turns the knob one tick (1%) per notch, from where it's heading (quick
        // notches add up); the knob sets the brightness
        onScrolled: dir => { spin.following = -1; spin.snapTo(Math.max(0, Math.min(100, spin.heading - dir))); win.show() }
        onDragged: deg => { spin.following = -1; spin.dragBy(deg); win.show() }

        // the knob doesn't glide: settle on a tick between 0% and 100%
        onFlung: { spin.following = -1; spin.snapTo(Math.max(0, Math.min(100, spin.pos))) }

        M3Shapes { id: shapes }

        readonly property int percent: Math.max(0, Math.min(100, Math.round(win.brightness * 100)))

        // lit: the ticks and the gem in colour (not with nothing to control, or locked)
        readonly property bool lit: win.level.available && !win.level.locked

        DialRotation {
            id: spin
            stepDeg: 3          // degrees between ticks
            momentum: 0         // one tick per notch; a level knob shouldn't glide

            // no ticking while the dial is closed and the knob only follows the level
            silent: !dial.open

            // the tick the knob is turning to because the brightness changed somewhere
            // else; -1 while the user is the one turning it
            property int following: -1

            // the knob turned: the tick at the middle is the brightness, in percent
            onPosChanged: {
                if (following >= 0) {
                    if (pos === following) following = -1
                    return
                }
                const p = Math.max(0, Math.min(100, pos))
                if (p !== pos) { if (!dial.pressed) snapTo(p); return }       // past 0% or 100%: spring back (after a drag)
                if (p !== dial.percent) { win.setBrightness(p / 100); userHold.restart() }
            }

            // a snap is over: if the level moved on meanwhile, catch up now
            onSettled: { following = -1; dial.sync() }
        }

        // ms after the user turns the knob during which the level's own reports are not chased
        Timer {
            id: userHold
            interval: 350
            onTriggered: dial.sync()
        }

        // turns the knob to the level unless it's already there or on its way there
        function sync() {
            const p = dial.percent
            if (p === spin.heading) return
            if (!dial.open) { spin.following = -1; spin.scroll = -p * spin.stepDeg; return }
            spin.following = p
            spin.snapTo(p)
        }

        // the brightness changed somewhere else: turn the knob to match
        Connections {
            target: win
            function onBrightnessChanged() { if (!userHold.running && !dial.pressed) dial.sync() }
        }
        Component.onCompleted: spin.scroll = -percent * spin.stepDeg

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
                // filled in by DialRing: the raw tick number (doesn't wrap) and this slot's angle
                property int listIndex
                property real ringDeg

                // DialRing already turns each slot so its height points away from the
                // centre, so the ticks come out radial with no rotation here
                Rectangle {
                    anchors.centerIn: parent
                    width: 4
                    height: parent.listIndex % 10 === 0 ? 28 : 18      // longer ticks every 10%
                    radius: width / 2

                    // how far (degrees) from the gem a tick stays hidden, and how far past
                    // that it takes to fade fully in
                    readonly property real gapDeg: 10
                    readonly property real fadeDeg: 6

                    // how far this tick is from the gem, measured on the ring itself
                    readonly property real fromGem: Math.abs(parent.ringDeg - dial.midDeg)

                    // fades in as it moves away from the gem. Nothing past 0% or 100%.
                    visible: parent.listIndex >= 0 && parent.listIndex <= 100
                    opacity: Math.max(0, Math.min(1, (fromGem - gapDeg) / fadeDeg))

                    // M3E: tertiary, as the control center's brightness knob
                    color: parent.listIndex <= dial.percent && dial.lit ? Roles.tertiary : Roles.outline_variant
                    antialiasing: true
                }
            }
        }

        // the gem on the middle mark, drawn above every tick
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
                fillColor: dial.lit ? Roles.tertiary : Roles.surface_container_highest
                scale: shapes.fitScale(gem)
                PathSvg { path: shapes.getPath("Sunny") }
            }
        }

        // ── the icon and the percentage, centred in the empty space ── (the same
        // placing as the volume OSD: see AudioOsd.qml)
        readonly property real emptyRadius: expandedSize * 0.8 - 14
        readonly property real halfSweepRad: dial.sweepDeg / 2 * Math.PI / 180
        readonly property real groupRadius: emptyRadius * 2 * Math.sin(halfSweepRad) / (3 * halfSweepRad)
        readonly property real midRad: dial.midDeg * Math.PI / 180

        Column {
            id: group
            spacing: 4
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
                        fillColor: dial.lit ? Roles.tertiary_container : Roles.surface_container_high
                        strokeColor: "transparent"
                        scale: shapes.fitScale(tileShape)
                        PathSvg { path: shapes.getPath(dial.lit ? "Sunny" : "Circle") }
                        Behavior on fillColor { ColorAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
                    }
                }

                SymbolIcon {
                    anchors.centerIn: parent
                    text: win.level.icon
                    size: 32
                    filled: true
                    color: dial.lit ? Roles.on_tertiary_container : Roles.on_surface_variant
                }
            }

            SmoothText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: win.level.locked ? "Locked" : !win.level.available ? "–" : dial.percent + "%"
                font.pixelSize: 16                 // M3 titleMedium
                font.weight: 700
                color: dial.lit ? Roles.on_surface : Roles.on_surface_variant
            }
        }
    }
}

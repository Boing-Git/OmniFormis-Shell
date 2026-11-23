import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Wayland
import QtQuick.Shapes
import "primitive"
import "controlcenter"
import "screenshot"

// The control center: a corner dial. The outer ring picks a control (Wi-Fi, Bluetooth,
// Audio, Dials, Media, Notifications, Settings), the inner ring shows what's inside it,
// two knobs between the rings turn the volume and the brightness, and a control can add a
// wavy timeline ring, a corner card, and a value of its own to turn in the knobs' place.
// The controls themselves live in controlcenter/.
PanelWindow {
    id: center
    // the screen the shell lives on (Dials.screen): when the monitor goes away and comes
    // back (a DisplayPort monitor does as it sleeps) the window follows it back
    screen: Dials.screen


    // the dial, under a name the controlcenter/ parts can be given (inside them `dial: dial`
    // would point at their own `dial` property)
    readonly property var dialItem: dial

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    // the window only takes the mouse inside the dial; bound to its geometry (not `item:`)
    // so the area follows the dial as it grows, e.g. to the media player's bigger size.
    // While arranging (Edit) or while a pill is dragged off the dial it takes the whole
    // screen, so every spot can be reached and a click anywhere else ends Edit
    // (and while the dial shrank away from a still mouse, e.g. leaving Media: see `stranded`
    // in DialDelegate, so the next move can tell whether the mouse went off it)
    readonly property bool wholeScreen: dial.arranging || arranger.active || dial.stranded
    mask: Region {
        x: center.wholeScreen ? 0 : dial.x
        y: center.wholeScreen ? 0 : dial.y
        width: center.wholeScreen ? arranger.width : dial.width
        height: center.wholeScreen ? arranger.height : dial.height
    }

    // take the keyboard while the dial is open, so it can be used with keys
    WlrLayershell.keyboardFocus: dial.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // open / close from a keybind:  qs -p <this folder> ipc call center toggle
    // straight to one control:      qs -p <this folder> ipc call center go notify
    //   (wifi | bluetooth | audio | dials | media | notify | settings)
    IpcHandler {
        target: "center"
        function toggle(): void { dial.open = !dial.open }
        function open(): void { dial.open = true }
        function close(): void { dial.open = false }
        function go(key: string): void { dial.showControl(key) }
    }

    // Super + A (scripts/shell ipc call assistant toggle): the control center on Ask, ready to
    // type (Settings → Extras → Ask the AI)
    IpcHandler {
        target: "assistant"
        function toggle(): void { if (Prefs.assistant) askControl.summon() }
        function ask(text: string): void { if (Prefs.assistant) { dial.showControl("ask"); askControl.askNow(text) } }
    }

    // so other dials can find it (Dials.qml)
    Component.onCompleted: Dials.register("center", dial)

    // a click anywhere off the dial while arranging: done, and the control center closes
    // (under the dial, so clicks on the dial still reach it)
    MouseArea {
        anchors.fill: parent
        enabled: dial.arranging && !arranger.active
        onClicked: { dial.arranging = false; dial.open = false }
    }

    // the dial shrank away from a still mouse (leaving Media): stays open until the mouse
    // really moves off it; a click off it closes it
    MouseArea {
        anchors.fill: parent
        enabled: dial.stranded
        hoverEnabled: true
        onPositionChanged: mouse => dial.strandedMoved(mouse.x, mouse.y)
        onClicked: dial.open = false

        // still scrolling where the mouse was: the dial keeps turning
        onWheel: event => dial.scrolled(event.angleDelta.y > 0 ? -1 : 1)
    }

    DialDelegate {
        id: dial
        corner: Dials.spotOf("center")

        // ★ settings: controlcenter/ControlCenterSettings.qml (dial, outer ring, knobs, date
        //   badge…, the inner ring too), MediaSettings.qml (the media player) and
        //   ArrangeSettings.qml (Edit in the Dials control) ★
        readonly property var baseSettings: ControlCenterSettings { dialSize: dial.expandedSize; clockFormat: Prefs.clockFormat }

        // a control can bring its own copy (`settings`, e.g. Media's in MediaSettings.qml),
        // used only while it's selected; every other control uses baseSettings
        readonly property var settings: currentControl && currentControl.settings ? currentControl.settings : baseSettings

        // Edit in the Dials control: the wiggle, the dragged icon, the spots
        readonly property var arrange: ArrangeSettings {}

        // The dial's size follows the selected control (its `size` field, see `controls`),
        // and grows / shrinks smoothly when you switch between controls.
        readonly property real baseSize: baseSettings.baseSize
        property real liveSize: baseSize
        Behavior on liveSize {
            NumberAnimation {
                duration: Prefs.defaultSpatial.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Prefs.defaultSpatial.bezier
            }
        }
        expandedSize: liveSize

        // set from a handler (not a binding) on purpose: the ring's layout depends on
        // the size, and the selected control depends on the ring
        function applySize() {
            liveSize = (currentControl && currentControl.size) ? currentControl.size : baseSize
        }
        onCurrentControlChanged: {
            applySize()

            // a control's first-contact line, the first few times it's selected with the dial open
            if (open && currentControl && currentControl.hint) arranger.showHint(currentControl.hint)
        }

        // M3E roles: the dial is a surface container, edged with outline-variant
        color: Roles.surface_container
        borderColor: Roles.outline_variant

        autoClose: false

        // Enter / Space: stay open after using something, like a click does (settings)
        closeOnEnter: settings.closeOnEnter

        // while arranging it stays open when the mouse leaves (you go round the screen to
        // the spots), and Esc leaves Edit instead of closing
        closeOnExit: !arranging
        closeOnEscape: !arranging
        onEscaped: arranging = false

        // closing ends Edit; opening reads the brightness (it isn't polled: DDC is slow)
        onOpenChanged: {
            if (!open) arranging = false
            else dial.brightness.refresh()
        }

        // ── ring geometry ──
        // Four rings: the mouse picks which one the wheel (and a click) goes to. Over the
        // inner ring (closer to the corner than innerZone) it's the devices ring; then the
        // volume knob, the brightness knob, and anywhere further out the controls ring.
        readonly property real outerRadius: settings.ringRadius

        readonly property real innerRadius: settings.innerRadius

        // the hover line between the inner ring and what's next: the volume knob, or without
        // knobs halfway from the pills' outer edge to the outer tiles
        readonly property real innerZone: knobs || hasValue ? settings.knobZoneInner : (settings.pillOuter + settings.tileInner) / 2

        // ── the optional timeline ring: sits in the gap between the two rings ──
        // (inner pills end at ~0.53 of the size, the selected outer tile starts at ~0.67)
        // A control with a timeline but no pills (media) puts the timeline where the inner
        // ring would be, a little further out (timelinePush px)
        readonly property real timelinePush: settings.timelinePush
        readonly property bool timelineInner: hasTimeline && subItems.length === 0

        // a timeline with its own style (media: MediaSettings) sets its own radius and zone;
        // otherwise it follows the rings
        readonly property var tlStyle: timeline && timeline.style ? timeline.style : null
        readonly property real timelineRadius: tlStyle ? tlStyle.timelineRadius
            : timelineInner ? innerRadius + timelinePush
            : (settings.pillOuter + 10 + settings.selectedTileInner) / 2

        // the mouse zones: inside timelineIn = inner ring, between = timeline, outside timelineOut = controls
        readonly property real timelineZone: tlStyle ? tlStyle.timelineZone : (timelineInner ? settings.timelineInnerZone : settings.timelineZone)
        readonly property real timelineIn: timelineRadius - timelineZone
        readonly property real timelineOut: timelineRadius + timelineZone

        // px between two ticks of the timeline
        readonly property real timelineStep: timelineRadius * spin3.stepDeg * Math.PI / 180

        // the corner direction in radians (the volume dial does the same)
        readonly property real midRad: midDeg * Math.PI / 180

        // how much the corner card grows with the dial (1 at the base size)
        readonly property real cornerScale: Math.max(settings.cornerMinScale, (innerRadius - settings.cornerOffset) / settings.cornerBase)

        // ── what the selected control asks for ──
        // The selected control, settled after each change. When a control's own settings
        // change the ring's spacing, the ring can point at another tile for a moment while
        // it adjusts; settling after the change means that never switches the control
        // (and its settings) back and forth.
        property int selectedControl: 0
        readonly property var currentControl: controls[selectedControl]
        function settleSelection() {
            // while the outer ring is still turning, wait: outerSettle settles it once it stops
            if (outerBusy && settings.holdSelectionWhileTurning) return
            if (selectedControl !== ring.selectedIndex) selectedControl = ring.selectedIndex
        }

        // ── the outer ring is turning ──
        // True while the outer ring moves and for ringSettleDelay ms after. Meanwhile the
        // wheel stays on the outer ring wherever the mouse is, so passing over Media (which
        // grows the dial and puts the timeline under the mouse) can't seek the music.
        property bool outerBusy: false
        Timer {
            id: outerSettle
            interval: dial.settings.ringSettleDelay
            onTriggered: { dial.outerBusy = false; dial.settleSelection() }
        }
        Connections {
            target: spin
            function onScrollChanged() { dial.outerBusy = true; outerSettle.restart() }
        }
        readonly property bool inMedia: !!currentControl && currentControl.key === "media"
        readonly property bool inNotify: !!currentControl && currentControl.key === "notify"
        readonly property bool inSettings: !!currentControl && currentControl.key === "settings"

        // the inner ring's pill at the mark (a place in subItems), for the controls
        readonly property int innerIndex: ring2.selectedIndex
        readonly property bool badgesEnabled: !currentControl || currentControl.badges !== false
        readonly property bool dateIconShown: !currentControl || currentControl.dateIcon !== false

        // the timeline ring (null when the control has none) and what it reports
        readonly property var timeline: currentControl && currentControl.timeline ? currentControl.timeline : null
        readonly property bool hasTimeline: !!timeline
        readonly property int tlTicks: timeline ? timeline.ticks() : 0

        // while scrubbing: the tick under the gem (the player only seeks once you stop)
        readonly property int tlTick: timeline ? Math.max(0, Math.min(Math.max(0, tlTicks - 1), scrubbing ? spin3.pos : timeline.tick())) : 0
        readonly property bool tlAnimated: !!timeline && timeline.animated()
        readonly property bool tlCanSeek: !!timeline && timeline.canSeek()
        readonly property string tlKey: timeline && timeline.key ? timeline.key() : ""

        // ── the knobs (volume inside, brightness outside), between the inner and outer rings ──
        readonly property bool knobs: settings.knobsEnabled
        readonly property bool overVolume: knobs && hovered && !overTimeline && hoverRadius >= settings.knobZoneInner && hoverRadius < settings.knobZoneMid
        readonly property bool overBrightness: knobs && hovered && !overTimeline && hoverRadius >= settings.knobZoneMid && hoverRadius < settings.knobZoneOuter

        // ── a control's own value ── (its `value`: a level like the two knobs', see
        // KnobRing) one tick ring in the knobs' place that turns whatever the pill at the
        // mark is about: a setting's value, which of an app's notifications is showing
        readonly property var valueLevel: currentControl && currentControl.value ? currentControl.value : noLevel
        readonly property bool hasValue: valueLevel.available

        // a value that is a few choices is shown as chips (OptionRing), any other as ticks
        readonly property bool valueIsChoice: hasValue && !!valueLevel.options
        readonly property var valuePart: valueIsChoice ? optionRing : valueKnob
        readonly property bool overValue: hasValue && hovered && !overTimeline && hoverRadius >= settings.knobZoneInner && hoverRadius < settings.knobZoneOuter

        // the same gap while there's no value to turn, for a control that draws something
        // else there and takes a click on it (its `gapClick`)
        readonly property bool overGap: !hasValue && !knobs && hovered && !overTimeline && !!currentControl && !!currentControl.gapClick
            && hoverRadius >= settings.knobZoneInner && hoverRadius < settings.knobZoneOuter

        // what the value knob shows for a control with no value (it's hidden then)
        QtObject {
            id: noLevel
            readonly property real value: 0
            readonly property bool muted: false
            readonly property bool locked: false
            readonly property bool available: false
            readonly property string icon: ""
            function set(v) {}
        }

        // ── reach is precision ── how much of the hand's turn a knob on `ringRadius`
        // takes: all of it while the hand is on the ring (or nearer the centre), less the
        // further out it pulls, also past the dial's edge (settings: knobReachPower)
        function reachGear(ringRadius) {
            const p = settings.knobReachPower
            if (p <= 0 || hoverRadius <= ringRadius) return 1
            return Math.pow(ringRadius / hoverRadius, p)
        }

        // the hand pulled well out while turning a knob: that gesture was used (Hints.qml)
        function reached(ringRadius) { if (hoverRadius > ringRadius * 1.4) Hints.used("reach") }

        // what the knobs turn (controlcenter/AudioLevel.qml, BrightnessLevel.qml)
        AudioLevel { id: volume }

        // the one brightness level the whole shell shares (Brightness.qml), so the knob and
        // the brightness OSD never disagree
        readonly property var brightness: Brightness.level

        // (false while the mouse isn't on the dial, so the keyboard drives the outer ring)
        readonly property bool overTimeline: hasTimeline && hovered && hoverRadius >= timelineIn && hoverRadius < timelineOut
        readonly property bool overInner: hovered && hoverRadius < (hasTimeline ? timelineIn : innerZone)

        onScrolled: dir => (outerBusy ? spin
            : overTimeline ? spin3
            : overValue ? valuePart
            : overVolume ? volumeKnob
            : overBrightness ? brightnessKnob
            : overInner ? spin2 : spin).scrollBy(dir)

        // drag / flick: the ring under the press follows the mouse, and glides on when thrown
        property var dragSpin: spin
        onPressedChanged: if (pressed) dragSpin = overTimeline ? spin3
            : overValue ? valuePart.spin
            : overVolume ? volumeKnob.spin
            : overBrightness ? brightnessKnob.spin
            : overInner ? spin2 : spin

        // the knob being dragged (null: a ring of items, or the timeline)
        readonly property var dragKnob: dragSpin === valueKnob.spin ? valueKnob
            : dragSpin === optionRing.spin ? optionRing
            : dragSpin === volumeKnob.spin ? volumeKnob
            : dragSpin === brightnessKnob.spin ? brightnessKnob : null

        // the knobs and the timeline turn finer the further out the hand is (reachGear);
        // the rings of items always turn with the hand
        onDragged: deg => {
            if (dragKnob === optionRing) {
                // chips are few: they turn with the hand
                optionRing.dragBy(deg)
            } else if (dragKnob) {
                arranger.showHint("reach")
                reached(dragKnob.radius)
                dragKnob.dragBy(deg * reachGear(dragKnob.radius))
            } else if (dragSpin === spin3) {
                reached(timelineRadius)
                spin3.dragBy(deg * reachGear(timelineRadius))
            } else dragSpin.dragBy(deg)
        }
        onFlung: speed => {
            // the knobs don't glide: settle on a tick between 0% and 100%
            if (dragKnob) { dragKnob.settle(); return }
            if (dragSpin !== spin3) { dragSpin.fling(speed); return }

            // the timeline doesn't glide: settle on a tick inside the song
            spin3.snapTo(Math.max(0, Math.min(Math.max(0, tlTicks - 1), spin3.pos)))
            if (scrubbing) scrubTimer.restart()
        }

        // clicking a control flips it, and the dial stays open so you see it change
        onActivated: {
            const side = timelineRing.sideAt(hoverX, hoverY)
            if (hovered && side >= 0) timelineRing.sides[side].act()
            else if (overTimeline) { if (timeline.activate) timeline.activate() }
            else if (overValue) { if (valueLevel.activate) valueLevel.activate() }
            else if (overGap) currentControl.gapClick()
            else if (overVolume) volume.toggleMute()
            else if (overBrightness) { /* nothing to switch: scroll it */ }
            else if (overInner) { if (subItems.length > 0) subItems[ring2.wrap(spin2.heading)].activate() }
            else controls[selectedControl].toggle()
            dial.open = true
        }

        // right-click / Delete on the inner ring: the device's second action (e.g. forget)
        onSecondaryActivated: {
            if (!overInner && hovered) return
            const it = subItems[ring2.wrap(spin2.heading)]
            if (it && it.secondary) it.secondary()
        }

        // ── timeline: follow the control, or seek it ──
        // turn the timeline to the real value (not while the user is scrubbing it)
        property bool scrubbing: false
        function syncTimeline() {
            if (!hasTimeline || scrubbing || tlTicks <= 0) return
            if (tlTick === spin3.pos || tlTick === spin3.following) return
            spin3.following = tlTick
            followTimer.restart()
            spin3.snapTo(tlTick)
        }
        onHasTimelineChanged: syncTimeline()
        onTlTickChanged: syncTimeline()
        onTlTicksChanged: syncTimeline()
        onTlKeyChanged: syncTimeline()

        // after the user stops scrolling, let the timeline follow the control again
        Timer {
            id: scrubTimer
            interval: dial.settings.scrubHold
            onTriggered: {
                if (dial.pressed) { restart(); return }      // still holding the drag
                if (dial.timeline && dial.tlCanSeek) dial.timeline.seek(dial.tlTick)
                dial.scrubbing = false
                dial.syncTimeline()
            }
        }

        // safety: never stay stuck in "following"
        Timer {
            id: followTimer
            interval: 700
            onTriggered: spin3.following = -1
        }

        // ── date badge: hidden while the selected control has `dateIcon: false` ──
        // The settings place it on a top-left dial (middle direction 45°). On any other spot
        // that same layout is turned round the dial's centre to this dial's middle direction,
        // and half a turn more where it would read upside down
        DateStatusIcon {
            id: dateBadge

            // how far this dial's middle direction is turned from the top-left's
            readonly property real topLeftMidDeg: 45
            readonly property real turnDeg: dial.midDeg - topLeftMidDeg

            // its middle on a top-left dial, from the centre: the corner the settings give,
            // plus half its scaled size, tilted
            readonly property real tiltRad: dial.settings.dateRotation * Math.PI / 180
            readonly property real halfW: width * scale / 2
            readonly property real halfH: height * scale / 2
            readonly property real baseX: dial.settings.dateX + halfW * Math.cos(tiltRad) - halfH * Math.sin(tiltRad)
            readonly property real baseY: dial.settings.dateY + halfW * Math.sin(tiltRad) + halfH * Math.cos(tiltRad)

            // that middle turned to this dial's spot
            readonly property real turnRad: turnDeg * Math.PI / 180
            readonly property real midX: dial.centerX + baseX * Math.cos(turnRad) - baseY * Math.sin(turnRad)
            readonly property real midY: dial.centerY + baseX * Math.sin(turnRad) + baseY * Math.cos(turnRad)

            // the tilt it ends up with, -180..180
            readonly property real tilt: ((dial.settings.dateRotation + turnDeg) % 360 + 540) % 360 - 180

            // turned round its own middle, so x / y only place that middle; then pulled
            // dateInset px back along the middle line, towards the dial's centre (the screen
            // edge or corner it lives on)
            x: midX - width / 2 - dial.settings.dateInset * Math.cos(dial.midRad)
            y: midY - height / 2 - dial.settings.dateInset * Math.sin(dial.midRad)
            scale: dial.settings.dateScale
            z: 1
            rotation: 0

            opacity: dial.dateIconShown ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
        }

        // ── the clock ── the hours and the minutes on either side of the date badge. On an
        // edge: clockDistance px from the dial's centre and clockSpread° round the dial
        // either side of the badge; on a corner: along the two screen edges from it
        Item {
            id: clockPlace

            // the badge's middle, from the dial's centre
            readonly property real bx: dateBadge.x + dateBadge.width / 2 - dial.centerX
            readonly property real by: dateBadge.y + dateBadge.height / 2 - dial.centerY
            readonly property real dist: dial.settings.clockDistance
            readonly property real baseRad: Math.atan2(by, bx)
            readonly property real spreadRad: dial.settings.clockSpread * Math.PI / 180

            // on a corner the badge sits by the corner, so the numbers go along the two
            // screen edges from it instead: one beside it (into the screen), one under or
            // over it, clockCornerGap px away
            readonly property bool corner: dial.sweepDeg < 180
            readonly property real sx: Math.cos(dial.midRad) < 0 ? -1 : 1
            readonly property real sy: Math.sin(dial.midRad) < 0 ? -1 : 1
            readonly property real gap: dial.settings.clockCornerGap

            // the two places (the dial's px)
            readonly property point a: corner ? Qt.point(dial.centerX + bx + sx * gap, dial.centerY + by)
                : Qt.point(dial.centerX + dist * Math.cos(baseRad - spreadRad), dial.centerY + dist * Math.sin(baseRad - spreadRad))
            readonly property point b: corner ? Qt.point(dial.centerX + bx, dial.centerY + by + sy * gap)
                : Qt.point(dial.centerX + dist * Math.cos(baseRad + spreadRad), dial.centerY + dist * Math.sin(baseRad + spreadRad))

            // a reads first: on a corner the one beside the badge; on an edge the one further
            // left (when they sit side by side), or higher up
            readonly property bool aFirst: corner || (Math.abs(a.x - b.x) > Math.abs(a.y - b.y) ? a.x < b.x : a.y < b.y)

            // AM / PM, between the two: clockAmPmGap px from the badge along the dial's
            // middle direction (on a corner that's the 45° between the two screen edges)
            readonly property point c: Qt.point(dial.centerX + bx + dial.settings.clockAmPmGap * Math.cos(dial.midRad),
                                                dial.centerY + by + dial.settings.clockAmPmGap * Math.sin(dial.midRad))
        }

        Repeater {
            model: dial.settings.clockFormat === "12hAmPm" ? ["hours", "minutes", "ampm"] : ["hours", "minutes"]

            ClockFace {
                required property string modelData
                required property int index
                cfg: dial.settings
                part: modelData

                readonly property point at: modelData === "ampm" ? clockPlace.c
                    : (index === 0) === clockPlace.aFirst ? clockPlace.a : clockPlace.b
                x: at.x - width / 2
                y: at.y - height / 2
                scale: dial.settings.clockScale
                z: 1

                opacity: dial.dateIconShown ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
            }
        }

        DialRotation {
            id: spin

            // from the tile size and gap, so tiles never touch at any dial size (settings)
            stepDeg: dial.settings.stepDeg

            // scrolling feel is shared by every dial (variables.js)
            momentum: Prefs.scrollMomentum
            energy: Prefs.energy
            snapThreshold: dial.settings.snapThreshold
            snapDuration: dial.settings.snapDuration
        }

        // the inner ring's own rotation (shares the feel settings with the first one)
        DialRotation {
            id: spin2
            stepDeg: dial.settings.innerStepDeg
            momentum: Prefs.scrollMomentum
            energy: Prefs.energy
            snapThreshold: dial.settings.innerSnapThreshold
            snapDuration: dial.settings.innerSnapDuration
        }

        // the timeline's rotation: one tick per wheel notch, like the volume knob
        DialRotation {
            id: spin3
            stepDeg: dial.tlStyle ? dial.tlStyle.tickDeg : dial.settings.tickDeg     // degrees between ticks
            momentum: 0         // one tick per notch; seeking shouldn't glide
            snapDuration: dial.settings.timelineSnap

            // the tick the ring is turning to because the control moved on its own;
            // -1 while the user is the one turning it
            property int following: -1

            // the ring turned: the tick at the middle is the value
            onPosChanged: {
                if (following >= 0) {
                    if (pos === following) following = -1
                    return
                }
                const maxTick = Math.max(0, dial.tlTicks - 1)
                const p = Math.max(0, Math.min(maxTick, pos))
                if (p !== pos) { if (!dial.pressed) snapTo(p); return }     // past the ends: spring back (after a drag)
                if (!dial.scrubbing && p === dial.tlTick) return
                if (!dial.tlCanSeek) { snapTo(dial.tlTick); return }

                // only the line moves now; scrubTimer seeks (and plays) once you stop
                dial.scrubbing = true
                scrubTimer.restart()
            }
        }

        // one shared shape library for every tile
        M3Shapes { id: shapeLib }

        // the controls on the ring. Only `label`, `icon`, `shape`, `shapeSelected`, `on`,
        // `toggle` and `devices` are needed; the rest are options a control can opt into:
        //   key       - an id, so the dial can tell which control is selected
        //   label     - the name
        //   icon      - a Material Symbols icon name (changes with the state)
        //   shape     - the M3 shape behind it
        //   shapeSelected - the shape while it's the selected tile
        //   on        - true while it's switched on
        //   toggle    - flips it (also what Enter / a click on the tile does)
        //   devices   - a function returning what's inside it (the inner ring):
        //               [{ label, icon, shape, on, status, activate }]
        //               status is "loading" | "connected" | "paired" | "none"
        //               optional: badgeIcon (an icon for the selected pill's badge), and
        //               drag: "dial" | "screenshot" (the pill can be dragged off the ring)
        //   size      - the dial grows to this size (px) while it is selected (default 460)
        //   badges    - false: no number / status badge on its inner ring
        //   dateIcon  - false: hide the date badge while it is selected
        //   corner    - a Component shown in the corner of the dial (see MediaPlayer.qml)
        //   timeline  - a third, wavy ring between the other two that you scroll to seek:
        //                 ticks()    how many ticks it has
        //                 tick()     the current tick
        //                 key()      (optional) a string that changes when the content changes
        //                 animated() true: the wave travels, false: it calms down
        //                 icon()     the icon in the gem (Material Symbols name)
        //                 canSeek()  false: scrolling springs back
        //                 seek(t)    the user scrolled to tick t
        //                 activate() a click on the timeline
        // every control in its built-in order; `controls` is the order you arranged (Edit)
        readonly property var baseControls: [
            wifi.control,
            bluetooth.control,
            audioOut.control,
            {
                // a launcher for the other dials: nothing to switch, the inner ring does the work
                key: "dials",
                label: "Dials",
                icon: "apps",
                shape: "4LeafClover",
                shapeSelected: "8LeafClover",
                on: false,
                toggle: () => {},

                // each dial's pill opens it (this one closes; the OSDs pop up); while Edit is on,
                // drag it onto a spot to move that dial there (the control center and the OSDs
                // too). Screenshot opens the screenshot tool
                // (pull it off the ring to start it where you drop it). Edit / Done turns
                // arranging on and off
                devices: () => [
                    dial.dialPill("wallpaper"),
                    dial.dialPill("apps"),
                    dial.dialPill("power"),
                    dial.dialPill("center")
                ].concat(Dials.popups.map(n => dial.dialPill(n))).concat([
                    {
                        label: "Screenshot", icon: "screenshot_region", shape: "Circle", on: false, status: "none",
                        drag: "screenshot",
                        activate: () => { if (!dial.arranging) dial.takeScreenshot(NaN, NaN) }
                    },
                    {
                        label: dial.arranging ? "Done" : "Edit", icon: dial.arranging ? "check" : "edit",
                        shape: "Circle", on: dial.arranging, status: "none",
                        activate: () => { dial.arranging = !dial.arranging }
                    },
                    {
                        // the place to re-learn: replays the tour, and every gesture's hint
                        // shows once more the next time you meet it
                        label: "Help", icon: "help", shape: "Circle", on: false, status: "none",
                        activate: () => dial.showHelp()
                    },
                    {
                        // the shells' mascots: switch shells there (About.qml)
                        label: "About", icon: "info", shape: "Circle", on: false, status: "none",
                        activate: () => { dial.arranging = false; dial.open = false; if (Dials.about) Dials.about.open() }
                    }
                ])
            },
            media.control,
            notify.control,
            clipboardControl.control,
            settingsControl.control
        ].concat(Prefs.assistant ? [askControl.control] : [], Prefs.screenTime ? [screenTimeControl.control] : [])

        // the Help pill: the tour again (it closes this dial so the tour can point at it)
        function showHelp() {
            arranging = false
            Hints.revive()
            open = false
            if (Dials.onboarding) Dials.onboarding.begin()
        }

        // ── the tiles' order ── keys in the order you dragged them to (saved in
        // Vars.controlOrderPath); controls not in it keep their built-in place at the end
        property var controlOrder: []
        readonly property var controls: {
            const rank = k => { const i = controlOrder.indexOf(k); return i < 0 ? 1000 + baseControls.findIndex(c => c.key === k) : i }
            return baseControls.slice().sort((a, b) => rank(a.key) - rank(b.key))
        }

        // opens the dial on the control called `key`, turning the outer ring to it the
        // short way round
        function showControl(key) {
            const i = controls.findIndex(c => c.key === key)
            if (i < 0) return
            const n = controls.length
            let d = (((i - spin.pos) % n) + n) % n
            if (d > n / 2) d -= n
            spin.snapTo(spin.pos + d)
            open = true
        }

        // moves the tile at `from` to `to` (outer-ring indexes); the selected control stays
        // selected (the ring turns to its new place at once)
        function moveControl(from, to) {
            if (from === to || from < 0 || to < 0) return
            const keys = controls.map(c => c.key)
            const keep = currentControl ? currentControl.key : ""
            const k = keys.splice(from, 1)[0]
            keys.splice(to, 0, k)
            reordering = true
            controlOrder = keys
            orderWriter.exec(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s\\n" "$2" > "$1"',
                              "sh", Vars.controlOrderPath, JSON.stringify(keys)])
            const i = keys.indexOf(keep)
            if (i >= 0) { spin.scroll = -i * spin.stepDeg; selectedControl = i }

            // let the ring settle on its new place before a change of control can end Edit again
            Qt.callLater(() => { dial.reordering = false })
        }
        Process { id: orderWriter }
        FileView {
            path: Vars.controlOrderPath
            printErrors: false
            watchChanges: true
            onFileChanged: reload()
            onLoaded: {
                try {
                    const o = JSON.parse(text())
                    if (Array.isArray(o)) dial.controlOrder = o
                } catch (e) { /* empty or broken: the built-in order */ }
            }
        }

        // the controls that live in their own files (controlcenter/)
        WifiControl { id: wifi; dial: center.dialItem }
        BluetoothControl { id: bluetooth; dial: center.dialItem }
        AudioControl { id: audioOut; dial: center.dialItem }
        MediaPlayer { id: media; dial: center.dialItem; shapes: shapeLib; seekPos: spin3.pos }
        NotifyControl { id: notify; dial: center.dialItem }
        ClipboardControl { id: clipboardControl; dial: center.dialItem }
        SettingsControl { id: settingsControl; dial: center.dialItem; bar: valueBar }
        AskControl { id: askControl; dial: center.dialItem; bar: valueBar }
        ScreenTimeControl { id: screenTimeControl; dial: center.dialItem }

        // closes this dial and opens another one (an OSD pops up, see popUp in AudioOsd /
        // WorkspaceOsd)
        function openDial(target) {
            if (target === "center") return
            const d = Dials.dials[target]
            if (!d) return
            dial.open = false
            if (typeof d.popUp === "function") d.popUp()
            else d.open = true
        }

        // ── arranging the dials (Edit in the Dials control) ──
        // true while Edit is on: the dial pills wiggle, and dragging one onto a spot (a
        // corner or the middle of an edge) moves that dial there
        property bool arranging: false

        // the Dials control is the selected one (Edit only lives there)
        readonly property bool inDials: !!currentControl && currentControl.key === "dials"
        onInDialsChanged: if (!inDials && !reordering) arranging = false

        // Edit coming on: the first few times, a line on what you can drag
        onArrangingChanged: if (arranging) arranger.showHint("edit")

        // true while moveControl swaps the order: the selection points at another tile for a
        // moment then, which mustn't end Edit (only Done does)
        property bool reordering: false

        // the pill lifted off the inner ring right now (-1: none), for DevicePill
        readonly property int liftedIndex: arranger.active && arranger.kind !== "tile" ? arranger.itemIndex : -1

        // every dial that has a spot: its name and icon (its pill, and the spots)
        readonly property var dialInfo: ({
            wallpaper: { label: "Wallpaper", icon: "wallpaper" },
            apps: { label: "Apps", icon: "apps" },
            power: { label: "Power", icon: "power_settings_new" },
            center: { label: "Control center", icon: "tune" },
            volume: { label: "Volume", icon: "volume_up" },
            brightness: { label: "Brightness", icon: "brightness_6" },
            workspaces: { label: "Workspaces", icon: "space_dashboard" },
            notify: { label: "Alerts", icon: "notifications" }
        })

        // the arrow pointing at a spot (on the badge of a dial's pill: where it lives)
        readonly property var spotArrows: ({
            topLeft: "north_west", top: "north", topRight: "north_east", right: "east",
            bottomRight: "south_east", bottom: "south", bottomLeft: "south_west", left: "west"
        })

        // a dial's pill in the Dials control
        function dialPill(name) {
            return {
                label: dialInfo[name].label,
                icon: dialInfo[name].icon,
                shape: "Circle",
                on: false,
                status: "none",
                drag: "dial",
                dialName: name,
                badgeIcon: spotArrows[Dials.spotOf(name)] || "",
                activate: () => { if (!dial.arranging) dial.openDial(name) }
            }
        }

        // closes at once (so it isn't in the picture) and starts the screenshot tool with its
        // rectangle round (x, y) on the screen, or in the middle for NaN; with a window's
        // rect (not empty), the rectangle starts on that window
        function takeScreenshot(x, y, r) {
            arranging = false
            snapClose()
            if (Dials.screenshot) Dials.screenshot.start(x, y, r)
            else Quickshell.execDetached(["qs", "-p", Quickshell.shellDir, "ipc", "call", "screenshot", "open"])
        }

        // ── pulling a pill off the inner ring ── DialDelegate asks when a drag starts.
        // While arranging, a dial pill or the Screenshot pill comes off the ring and follows
        // the mouse (ArrangeLayer). Outside Edit only the Screenshot pill does, and only
        // when pulled out (away from or towards the centre); along the ring the drag turns
        // the ring as usual
        claimDrag: (px, py, x, y) => {
            if (arranger.active) return false

            // while arranging, a tile on the outer ring comes off and can be dropped on
            // another tile (the order changes)
            const t = arranging ? tileAt(px, py) : null
            if (t !== null) {
                const ti = ring.wrap(t)
                const tc = tileCenter(t)
                arranger.begin("tile", { icon: controls[ti].icon }, ti, dial.x + x, dial.y + y, dial.x + tc.x, dial.y + tc.y)
                return true
            }
            const n = pillAt(px, py)
            if (n === null) return false
            const i = ring2.wrap(n)
            const it = subItems[i]
            if (!it || !it.drag) return false

            // dial pills only come off while arranging (in the Dials control); the
            // Screenshot pill and the device pills (a Bluetooth device onto Media, or flung
            // off) only when pulled out (away from or towards the centre): along the ring
            // the drag turns the ring as usual
            if (it.drag === "dial" && !(arranging && inDials)) return false
            if (!arranging) {
                const a = Math.atan2(py - pivotY, px - pivotX)
                const mx = x - px, my = y - py
                const out = Math.abs(mx * Math.cos(a) + my * Math.sin(a))
                const along = Math.abs(my * Math.cos(a) - mx * Math.sin(a))
                if (out < along * arrange.pullStraightness) return false
            }
            const c = pillCenter(n)
            arranger.begin(it.drag, it, i, dial.x + x, dial.y + y, dial.x + c.x, dial.y + c.y)
            return true
        }

        // the outer ring's tile under (x, y) (the dial's px) as the ring's raw position (wrap
        // it with ring.wrap for controls), or null when there's no tile there
        function tileAt(x, y) {
            if (controls.length === 0) return null
            const dx = x - pivotX, dy = y - pivotY
            if (Math.abs(Math.hypot(dx, dy) - settings.ringRadius) > settings.tileSize / 2 + 4) return null
            const deg = ((Math.atan2(dy, dx) * 180 / Math.PI - midDeg) % 360 + 540) % 360 - 180
            const n = Math.round((deg - spin.scroll) / spin.stepDeg)
            const off = (deg - spin.scroll - n * spin.stepDeg) * Math.PI / 180 * settings.ringRadius
            return Math.abs(off) <= settings.tileSize / 2 + 4 ? n : null
        }

        // the middle of the tile at the ring's raw position n (the dial's px)
        function tileCenter(n) {
            const a = (midDeg + n * spin.stepDeg + spin.scroll) * Math.PI / 180
            return Qt.point(pivotX + settings.ringRadius * Math.cos(a), pivotY + settings.ringRadius * Math.sin(a))
        }

        onClaimedMoved: (x, y) => arranger.move(dial.x + x, dial.y + y)
        onClaimedReleased: (x, y) => arranger.release(dial.x + x, dial.y + y)
        onClaimCanceled: arranger.cancel()

        // the inner ring's pill under (x, y) (the dial's px) as the ring's raw position (wrap
        // it with ring2.wrap for subItems), or null when there's no pill there
        function pillAt(x, y) {
            if (subItems.length === 0) return null
            const dx = x - pivotX, dy = y - pivotY
            if (Math.abs(Math.hypot(dx, dy) - settings.innerRadius) > settings.pillHeight / 2 + 4) return null

            // its angle from the middle mark, -180 .. 180, then how far that is from the pill's middle
            const deg = ((Math.atan2(dy, dx) * 180 / Math.PI - midDeg) % 360 + 540) % 360 - 180
            const n = Math.round((deg - spin2.scroll) / spin2.stepDeg)
            const off = (deg - spin2.scroll - n * spin2.stepDeg) * Math.PI / 180 * settings.innerRadius
            return Math.abs(off) <= settings.pillSlotWidth / 2 ? n : null
        }

        // the middle of the pill at the ring's raw position n (the dial's px)
        function pillCenter(n) {
            const a = (midDeg + n * spin2.stepDeg + spin2.scroll) * Math.PI / 180
            return Qt.point(pivotX + settings.innerRadius * Math.cos(a), pivotY + settings.innerRadius * Math.sin(a))
        }

        // what the inner ring shows: the devices of the control selected on the outer ring
        // ([] while the ring isn't ready yet: selectedIndex is raw until `count` is set)
        readonly property var subItems: {
            const c = controls[selectedControl]
            return (c && typeof c.devices === "function") ? c.devices() : []
        }

        // a different control got selected: bring the inner ring back to its first device
        Connections {
            target: ring
            function onSelectedIndexChanged() { Qt.callLater(dial.settleSelection) }
        }
        onSelectedControlChanged: spin2.snapTo(0)

        // turns the inner ring to pill `to`, starting from `from`: for a control whose
        // pills change under it (Settings going into a group) to say where the ring lands
        function turnInner(from, to) {
            spin2.dragBy(0)
            spin2.scroll = -from * spin2.stepDeg
            spin2.snapTo(to)
        }
        Connections {
            target: ring
            function onCountChanged() { Qt.callLater(dial.settleSelection) }
        }

        DialBand {
            anchors.fill: parent
            cx: dial.centerX; cy: dial.centerY

            // all from the settings: it follows the ring (an edge dial shows 90° more)
            radius: dial.settings.ringRadius
            frameHeight: dial.settings.bandThickness
            edgeMargin: dial.settings.bandEdgeMargin
            startDeg: dial.startDeg - dial.settings.bandExtraDeg
            sweepDeg: dial.settings.bandSweep + dial.sweepDeg - 90

            // the track: one surface step above the dial
            bandColor: Roles.surface_container_high
            holeColor: Roles.outline_variant
            DialRing {
                id: ring
                count: dial.controls.length            // every control, looping
                pressed: dial.pressed                  // lets the selected tile know it's being clicked
                anchors.fill: parent
                cx: dial.centerX
                cy: dial.centerY
                startDeg: dial.startDeg
                sweepDeg: dial.sweepDeg
                radius: dial.settings.ringRadius
                stepDeg: spin.stepDeg
                scroll: spin.scroll
                itemWidth: dial.settings.tileSize
                itemHeight: dial.settings.tileSize

                delegate: ControlTile {
                    controls: dial.controls
                    dropHot: arranger.dropTile === itemIndex
                    lifted: arranger.kind === "tile" && arranger.itemIndex === itemIndex
                    jiggling: dial.arranging
                    jiggleDeg: dial.arrange.jiggleDeg
                    jiggleLift: dial.arrange.jiggleLift
                    jigglePeriod: dial.arrange.jigglePeriod
                    inhaleScale: dial.arrange.tileInhaleScale
                    liftedOpacity: dial.arrange.tileLiftedOpacity
                    cfg: dial.settings
                    shapes: shapeLib
                    shapeScale: ring.shapeScale
                }
            }
        }

        // ── inner ring: the devices of the selected control ──
        DialBand {
            anchors.fill: parent
            cx: dial.centerX; cy: dial.centerY

            // all from the settings (inner ring section): it follows the pills
            radius: dial.settings.innerRadius
            frameHeight: dial.settings.pillHeight
            edgeMargin: dial.settings.innerBandMarginUsed * 2
            startDeg: dial.startDeg - dial.settings.innerBandExtraDeg
            sweepDeg: dial.settings.innerBandSweep + dial.sweepDeg - 90

            // the track: one surface step above the dial, like the outer ring's
            bandColor: Roles.surface_container_high
            holeColor: Roles.outline_variant
        }

        DialRing {
            id: ring2
            active: dial.subItems.length > 0
            count: dial.subItems.length
            pressed: dial.pressed && dial.overInner
            anchors.fill: parent
            cx: dial.centerX
            cy: dial.centerY
            startDeg: dial.startDeg
            sweepDeg: dial.sweepDeg
            radius: dial.settings.innerRadius
            stepDeg: spin2.stepDeg
            scroll: spin2.scroll
            itemWidth: dial.settings.pillSlotWidth
            itemHeight: dial.settings.pillHeight

            delegate: DevicePill {
                dial: center.dialItem
                shapes: shapeLib
            }
        }

        // ── the volume and brightness knobs, between the inner ring and the outer ring ──
        // (faded back while arranging, so the wiggling pills stand out)
        KnobRing {
            id: volumeKnob
            anchors.fill: parent
            dial: center.dialItem
            shapes: shapeLib
            level: volume
            radius: dial.settings.volumeRadius
            gemShape: dial.settings.volumeGemShape

            // M3E: primary for the volume, as on the volume OSD
            litColor: Roles.primary
            inkColor: Roles.on_primary
            hot: dial.overVolume
            onHitLimit: arranger.showHint("knob")
            opacity: dial.arranging ? 0.35 : 1
            Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
        }
        KnobRing {
            id: brightnessKnob
            anchors.fill: parent
            dial: center.dialItem
            shapes: shapeLib
            level: dial.brightness
            radius: dial.settings.brightnessRadius
            gemShape: dial.settings.brightnessGemShape

            // M3E: tertiary, so the two knobs read apart at a glance
            litColor: Roles.tertiary
            inkColor: Roles.on_tertiary
            hot: dial.overBrightness
            opacity: dial.arranging ? 0.35 : 1
            Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
        }

        // ── a control's own value (`value`): one knob in the middle of the same gap ──
        KnobRing {
            id: valueKnob
            anchors.fill: parent
            dial: center.dialItem
            shapes: shapeLib
            level: dial.valueLevel
            radius: dial.settings.knobsMid
            gemShape: dial.settings.volumeGemShape

            // M3E: secondary, so it never reads as the volume (primary) or the brightness (tertiary)
            litColor: Roles.secondary
            inkColor: Roles.on_secondary
            hot: dial.overValue
            opacity: dial.hasValue && !dial.valueIsChoice ? 1 : 0
            shown: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
        }

        // ... or, when the value is one of a few choices, the choices themselves as chips
        OptionRing {
            id: optionRing
            anchors.fill: parent
            dial: center.dialItem
            level: dial.valueLevel
            radius: dial.settings.knobsMid
            opacity: dial.valueIsChoice ? 1 : 0
            shown: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
        }

        // ── typing a value ── (Settings: a click on a number or a text setting) the curved
        // bar the launcher searches with, in the gap between the rings where the value
        // sits; SettingsControl drives it
        SearchBar {
            id: valueBar
            anchors.fill: parent
            cx: dial.centerX; cy: dial.centerY
            radius: dial.settings.knobsMid
            sweep: Math.min(110, dial.sweepDeg - 20)
            fromDeg: dial.midDeg - sweep / 2
            placeholder: askControl.typing ? "Ask anything, then Enter" : "Type a value, then Enter"
            barColor: Roles.surface_container_high
            borderColor: Roles.primary
            letterColor: Roles.on_surface
            errorColor: Roles.error
            blobColor: Roles.primary
            blobLetterColor: Roles.on_primary
            counterColor: Roles.on_surface_variant
            searching: settingsControl.typing || askControl.typing
            matched: askControl.typing || settingsControl.typedOk
            opacity: settingsControl.typing || askControl.typing ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
            onAccepted: askControl.typing ? askControl.typed(true) : settingsControl.typed(true)
            onCancelled: askControl.typing ? askControl.typed(false) : settingsControl.typed(false)
        }

        // typing while a setting that takes typing is at the mark starts typing its value
        // (and with Ask at the mark, typing starts the question)
        onTyped: text => { if (inSettings) settingsControl.startTyping(text); else if (askControl.active && !askControl.typing) askControl.startTyping(text) }

        // ── Dial-E itself, hiding in plain sight ── (Settings → Extras → Mascots) small, in the
        // empty end of the inner disc where the dial meets the screen's edge. The rings turn it
        // like a gear meshed inside the inner ring (same way round, ring radius / its own
        // radius as fast), every frame of a drag or a fling, its googly pupils swinging after
        // the turn; it dozes while nothing happens, and a click startles it
        Mascot {
            id: hiding
            readonly property real deg: dial.startDeg + dial.sweepDeg - 9
            readonly property real r: dial.innerRadius - dial.settings.pillHeight / 2 - width / 2 - 9
            width: 46
            height: 46
            turn: (spin.scroll + spin2.scroll) * dial.innerRadius / (width * 0.48)
            onTurnChanged: { dozing.dozed = false; dozing.restart() }
            x: dial.centerX + r * Math.cos(deg * Math.PI / 180) - width / 2
            y: dial.centerY + r * Math.sin(deg * Math.PI / 180) - height / 2
            kind: "dial-e"
            calm: Prefs.calm
            body: Roles.primary_container
            ink: Roles.on_primary_container
            eyeWhite: Roles.primary_fixed
            pupil: Roles.on_primary_fixed
            accent: Roles.primary
            visible: Prefs.mascots && opacity > 0
            opacity: dial.open && dial.currentSize >= dial.expandedSize * 0.9 && !dial.arranging ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Vars.expressiveDefaultEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveDefaultEffects.bezier } }
            // it looks at the middle of the dial, where things happen, and dozes off after a while
            look: Qt.point(Math.cos((dial.midDeg + 180) * Math.PI / 180), Math.sin((dial.midDeg + 180) * Math.PI / 180))
            asleep: dozing.dozed
            Timer {
                id: dozing
                property bool dozed: false
                interval: 12000
                running: dial.open
                onTriggered: dozed = true
            }
            Connections {
                target: dial
                function onOpenChanged() { dozing.dozed = false }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { dozing.dozed = false; dozing.restart(); hiding.poke() }
            }
        }

        // ── the corner card of the selected control (`corner`), faded in and out ──
        Loader {
            id: cornerLoader

            readonly property var wanted: dial.currentControl && dial.currentControl.corner ? dial.currentControl.corner : null
            onWantedChanged: if (wanted) sourceComponent = wanted
            Component.onCompleted: if (wanted) sourceComponent = wanted

            // placed on the diagonal of the dial and scaled with it, so it fits any size and corner
            readonly property real distance: (item && item.cornerDistance !== undefined ? item.cornerDistance : dial.settings.cornerDistance) * dial.cornerScale

            // (uses the card's own size, not the Loader's, which would loop back into x / y)
            readonly property real cardW: item ? item.width : 0
            readonly property real cardH: item ? item.height : 0
            x: dial.centerX + distance * Math.cos(dial.midRad) - cardW / 2
            y: dial.centerY + distance * Math.sin(dial.midRad) - cardH / 2

            // a card with `scaled: false` sizes itself (e.g. the media card)
            scale: item && item.scaled === false ? 1 : dial.cornerScale

            opacity: wanted ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
            onVisibleChanged: if (!visible && !wanted) sourceComponent = null
        }

        // ── the wavy timeline ring and its gem (controls with a `timeline`) ──
        TimelineRing {
            id: timelineRing
            anchors.fill: parent
            dial: center.dialItem
            shapes: shapeLib
            spin: spin3
            sides: dial.inMedia ? media.gemSides : []
        }
    }

    // the dragged pill and the spots it can go to, over the whole screen above the dial
    ArrangeLayer {
        id: arranger
        anchors.fill: parent
        dial: center.dialItem
        cfg: dial.arrange
        shot: ScreenshotSettings {}
        info: dial.dialInfo
        onScreenshotDropped: (x, y, r) => dial.takeScreenshot(x, y, r)
    }
}

import Quickshell
import Quickshell.Wayland
import QtQuick
import Quickshell.Io
import QtQuick.Shapes
import "primitive"
import "controlcenter"
import "variables.js" as Vars

// The arrival dial: a notification comes out of its spot as a pill. The dial springs open
// with the new notification's pill at the middle mark (the same pill the control center's
// inner ring uses, wearing the sending app's shape), the app's picture in the middle and
// its words curved between the two; a thin arc along the rim runs down the time it stays.
// Then it goes back into its corner, where the notification waits (Notifs.qml; the
// corner shows a bead for it, CornerWhisper.qml).
//
// While it's out:   click         does what the notification is for (its default action)
//                   scroll        turns through everything that's waiting
//                   right-click   dismisses the one at the mark
//                   pull its pill off the ring and flick it away: dismissed
// The mouse on it keeps it out.
//
// It only exists on screen while it's out, so it never adds a hot corner. It lives on the
// control center's spot until you move it (Edit in the control center's Dials control).
//
//   qs -p <this folder> ipc call notify open | close
PanelWindow {
    id: win
    // the screen the shell lives on (Dials.screen): when the monitor goes away and comes
    // back (a DisplayPort monitor does as it sleeps) the window follows it back
    screen: Dials.screen

    // its own layer name, so its frost is its own (Prefs: Pop-up frost, Look settings)
    WlrLayershell.namespace: "quickshell-popup"


    // the dial, under a name DevicePill can't confuse with its own `dial` property
    readonly property var dialItem: dial

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: dial }

    // shown only while the dial is out, still shrinking, or a pill is flying off
    visible: dial.open || dial.currentSize > dial.collapsedSize + 0.5 || ghost.active

    // ── settings ── sizes are px
    // how big it opens. Everything on it (ring, words, picture) follows this
    readonly property real size: 300

    // the pill ring: its distance from the corner (a share of the size), the longest a
    // pill's words can get, and the room each pill has along the ring
    readonly property real ringRatio: 0.78
    readonly property real labelMax: 150
    readonly property real slotWidth: 214

    // the words (the notification's body): the first arc's distance from the corner (a
    // share of the size), the px between arcs, how many arcs at most, and their size
    readonly property real bodyRatio: 0.44
    readonly property real bodyLineGap: 18
    readonly property int bodyLines: 2
    readonly property real bodyMaxDeg: 96
    readonly property real bodySize: 13             // M3 bodyMedium

    // the app's picture in the middle: its size (a share of the dial's)
    readonly property real tileRatio: 0.24

    // the time-left arc along the rim: how far in from the edge, how thick, and the
    // degrees kept clear at each end
    readonly property real timeInset: 10
    readonly property real timeWidth: 3
    readonly property real timePad: 8

    // a pill let go faster than this (px/s), or off the dial, is flicked away
    readonly property real flingSpeed: 1400

    // 1 = a drag steeper than 45° to the ring pulls the pill off; 2 = much straighter out
    readonly property real pullStraightness: 1

    // ── what's on the ring ── everything that's waiting, newest first
    readonly property var items: Notifs.list
    readonly property int shownIndex: Math.max(0, Math.min(items.length - 1, spin.pos))
    readonly property var current: items.length > 0 ? items[shownIndex] : null
    readonly property var currentInfo: Notifs.info(current)

    // the pills, as the control center's DevicePill wants them
    readonly property var pills: items.map(n => {
        const i = Notifs.info(n)
        return { label: i.summary !== "" ? i.summary : i.app, icon: i.symbol, iconShape: i.shape, on: false, status: "none" }
    })

    // so the control center can open it, and Edit can move it (Dials.qml)
    Component.onCompleted: Dials.register("notify", dial)
    Component.onDestruction: Dials.unregister("notify", dial)

    // ── showing and hiding ──
    // how long it stays, ms (the Stay setting)
    readonly property int holdTime: Prefs.notifyHold * 1000

    Connections {
        target: Notifs
        function onArrived(n) { win.arrive(n) }
    }

    function arrive(n) {
        const urgent = Notifs.info(n).urgent

        // Do not disturb: it waits in the control center instead (an urgent one still comes out)
        if (Prefs.dnd && !urgent) return

        // the control center is open on Notifications: it's in front of you already
        const c = Dials.dials.center
        if (c && c.open && c.inNotify) return

        // not over a dial that's open on this spot; another OSD there hands over to this one
        const from = Dials.popUpAt("notify")
        if (from < 0) return
        if (dial.open) {
            // the new one is first on the ring now and the others moved one along: stay
            // on the one that was at the mark, then turn the new one in
            spin.scroll = -(spin.pos + 1) * spin.stepDeg
            spin.snapTo(0)
        } else {
            spin.scroll = 0
            if (from > 0) dial.openFrom(from); else dial.open = true
        }
        hold(urgent ? holdTime * 3 : holdTime)
    }

    // (re)starts the time it stays out, and the arc that shows it
    function hold(ms) {
        hideTimer.interval = ms
        hideTimer.restart()
        timeLeft.duration = ms
        timeLeft.restart()
    }

    // closes once the time passes, unless the mouse is on it (then it starts over)
    Timer {
        id: hideTimer
        onTriggered: if (dial.hovered || dial.pressed || ghost.active) win.hold(interval); else dial.open = false
    }

    // 1 → 0 over the time it stays (paused while the mouse is on it)
    property real left: 1
    NumberAnimation {
        id: timeLeft
        target: win; property: "left"; from: 1; to: 0
        paused: running && (dial.hovered || dial.pressed)
    }

    // opened on purpose (the Dials control, a keybind): stays a while longer
    function popUp() {
        const from = Dials.popUpAt("notify")
        if (from < 0) return
        if (!dial.open) { spin.scroll = 0; if (from > 0) dial.openFrom(from); else dial.open = true }
        hold(holdTime * 3)
    }

    // nothing left to show: back into the corner
    onItemsChanged: {
        if (items.length === 0 && dial.open && !ghost.active) closeSoon.restart()
        else if (spin.pos > items.length - 1) spin.snapTo(Math.max(0, items.length - 1))
    }
    Timer {
        id: closeSoon
        interval: 900
        onTriggered: if (win.items.length === 0) dial.open = false
    }

    IpcHandler {
        target: "notify"
        function open(): void { win.popUp() }
        function close(): void { dial.open = false }
    }

    DialDelegate {
        id: dial

        // glass as a pop-up (Prefs: Pop-ups, Look settings)
        glassKind: "popup"
        corner: Dials.spotOf("notify")
        expandedSize: win.size

        // opened from the Dials control (the control center calls it)
        function popUp() { win.popUp() }

        // like the other OSDs: the timer closes it, not the mouse passing over
        closeOnExit: false
        autoClose: false

        // M3E roles: the dial is a surface container, edged with outline-variant
        color: Roles.surface_container
        borderColor: Roles.outline_variant

        // going back in: a notification that asked not to be kept is let go now
        onOpenChanged: if (!open) for (const n of win.items.slice()) if (n.transient) n.expire()

        // scrolling turns through what's waiting, one per notch, and it stays out
        onScrolled: dir => {
            spin.snapTo(Math.max(0, Math.min(win.items.length - 1, spin.heading + dir)))
            win.hold(win.holdTime)
        }
        onDragged: deg => { spin.dragBy(deg); win.hold(win.holdTime) }
        onFlung: spin.snapTo(Math.max(0, Math.min(win.items.length - 1, spin.pos)))

        // a click does what the notification is for; right-click / Delete dismisses it
        onActivated: { if (win.current) Notifs.open(win.current); else dial.open = false }
        onSecondaryActivated: if (win.current) Notifs.dismiss(win.current)

        // ── sizes ── all from the dial's size
        readonly property real ringRadius: expandedSize * win.ringRatio
        readonly property real midRad: midDeg * Math.PI / 180

        M3Shapes { id: shapeLib }

        // the pill sizes: the control center's own (so the pills are the same pills), with
        // more room for the words
        ControlCenterSettings {
            id: pillCfg
            dialSize: dial.expandedSize
            pillLabelMax: win.labelMax
            pillSlotWidth: win.slotWidth
        }

        // what DevicePill reads from the dial it sits on
        QtObject {
            id: host
            readonly property var settings: pillCfg
            readonly property var subItems: win.pills
            readonly property int liftedIndex: ghost.active ? win.liftedIndex : -1
            readonly property bool arranging: false
            readonly property var arrange: ArrangeSettings {}
            readonly property real midDeg: dial.midDeg
            readonly property bool badgesEnabled: false
        }

        DialRotation {
            id: spin

            // from the pill's room and gap, measured on the pills' inner edge
            stepDeg: (win.slotWidth + pillCfg.pillGap) / Math.max(1, dial.ringRadius - pillCfg.pillHeight / 2) * 180 / Math.PI

            // one notification per notch: it shouldn't glide past any
            momentum: 0
        }

        // ── the time left ── a thin arc along the rim that runs down (M3: primary on an
        // outline-variant track)
        Shape {
            id: timeArc
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            visible: win.items.length > 0
            readonly property real r: dial.expandedSize - win.timeInset
            readonly property real sweep: dial.sweepDeg - win.timePad * 2

            ShapePath {
                strokeColor: Roles.outline_variant
                strokeWidth: win.timeWidth
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: dial.centerX; centerY: dial.centerY
                    radiusX: timeArc.r; radiusY: timeArc.r
                    startAngle: dial.startDeg + win.timePad
                    sweepAngle: timeArc.sweep
                }
            }
            ShapePath {
                strokeColor: win.left > 0.004 ? Roles.primary : "transparent"
                strokeWidth: win.timeWidth
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: dial.centerX; centerY: dial.centerY
                    radiusX: timeArc.r; radiusY: timeArc.r
                    startAngle: dial.startDeg + win.timePad
                    sweepAngle: timeArc.sweep * win.left
                }
            }
        }

        // ── the pills ── listIndex 0 is the newest, and the ring never loops
        DialRing {
            id: ring
            anchors.fill: parent
            cx: dial.centerX
            cy: dial.centerY
            startDeg: dial.startDeg
            sweepDeg: dial.sweepDeg
            radius: dial.ringRadius
            stepDeg: spin.stepDeg
            scroll: spin.scroll
            preload: 1
            itemWidth: win.slotWidth
            itemHeight: pillCfg.pillHeight

            delegate: Item {
                // filled in by DialRing: the raw slot number (doesn't wrap), its angle,
                // whether it's the one at the mark, and whether that one is being pressed
                property int listIndex
                property real ringDeg
                property bool selected
                property bool clicked

                // nothing before the first or after the last
                visible: listIndex >= 0 && listIndex < win.items.length

                DevicePill {
                    anchors.fill: parent
                    dial: host
                    shapes: shapeLib
                    itemIndex: parent.listIndex
                    ringDeg: parent.ringDeg
                    selected: parent.selected
                    clicked: parent.clicked
                }
            }
        }

        // ── the words ── the notification's body, curved between the pill and the picture
        CurvedParagraph {
            cx: dial.centerX
            cy: dial.centerY
            text: win.current ? win.currentInfo.body : "Nothing waiting"
            radius: dial.expandedSize * win.bodyRatio
            lineGap: win.bodyLineGap
            maxLines: win.bodyLines
            centerDeg: dial.midDeg

            // never a line so long that its ends stand on their heads
            maxDeg: Math.min(win.bodyMaxDeg, dial.sweepDeg - 24)
            font.pixelSize: win.bodySize
            color: Roles.on_surface_variant
        }

        // ── the picture ── the sending app's shape, filled with what the notification
        // brought (or the app's icon), in the middle of the empty space: 0.6 of its radius
        // out on a quarter disc, 0.42 on a half disc (as on the other OSDs)
        readonly property real emptyRadius: expandedSize * win.bodyRatio - 14
        readonly property real halfSweepRad: sweepDeg / 2 * Math.PI / 180
        readonly property real tileDistance: emptyRadius * 2 * Math.sin(halfSweepRad) / (3 * halfSweepRad)

        Item {
            id: tile
            width: dial.expandedSize * win.tileRatio
            height: width
            x: dial.centerX + dial.tileDistance * Math.cos(dial.midRad) - width / 2
            y: dial.centerY + dial.tileDistance * Math.sin(dial.midRad) - height / 2

            ShapeImage {
                id: picture
                anchors.fill: parent
                shape: win.currentInfo.shape
                source: win.currentInfo.image

                // M3E: primary-container, as the icon tile of the volume OSD
                color: win.currentInfo.urgent ? Roles.error_container : Roles.primary_container

                // an app's icon sits inside its shape; a photo fills it
                coverScale: 0.66
            }
            SymbolIcon {
                anchors.centerIn: parent
                visible: !picture.ready
                text: win.current ? win.currentInfo.symbol : "notifications_none"
                size: parent.width * 0.5
                filled: true
                color: win.currentInfo.urgent ? Roles.on_error_container : Roles.on_primary_container
            }
        }

        // ── pulling the pill off the ring ── DialDelegate asks when a drag starts. A
        // drag that starts on the pill at the mark and goes out from the ring (away from
        // or towards the centre) lifts it; along the ring it turns the ring as usual
        claimDrag: (px, py, x, y) => {
            if (ghost.active || !win.current) return false
            const dx = px - pivotX, dy = py - pivotY
            if (Math.abs(Math.hypot(dx, dy) - ringRadius) > pillCfg.pillHeight / 2 + 8) return false
            const off = ((Math.atan2(dy, dx) * 180 / Math.PI - midDeg) % 360 + 540) % 360 - 180
            if (Math.abs(off) > spin.stepDeg / 2) return false
            const a = Math.atan2(dy, dx)
            const mx = x - px, my = y - py
            const out = Math.abs(mx * Math.cos(a) + my * Math.sin(a))
            const along = Math.abs(my * Math.cos(a) - mx * Math.sin(a))
            if (out < along * win.pullStraightness) return false
            win.lifted = win.current
            win.liftedIndex = win.shownIndex
            ghost.pick(dial.x + pivotX + ringRadius * Math.cos(midRad), dial.y + pivotY + ringRadius * Math.sin(midRad),
                       dial.x + x, dial.y + y)
            if (Hints.wants("notify")) { win.hint = Hints.text("notify"); Hints.shown("notify"); hintTimer.restart() }
            return true
        }
        onClaimedMoved: (x, y) => ghost.follow(dial.x + x, dial.y + y)
        onClaimedReleased: (x, y) => {
            ghost.follow(dial.x + x, dial.y + y)
            const off = Math.hypot(ghost.cursorX - (dial.x + pivotX), ghost.cursorY - (dial.y + pivotY)) > currentSize

            // thrown, or let go off the dial: gone. Let go slowly on the dial: back on the ring
            if (off || (!ghost.still() && ghost.speed >= win.flingSpeed)) {
                ghost.fling()
                Hints.used("notify")
                Notifs.dismiss(win.lifted)
            } else ghost.back()
        }
        onClaimCanceled: ghost.back()
    }

    // the notification that's lifted off the ring, and its place there
    property var lifted: null
    property int liftedIndex: -1

    // ── hints ── (Hints.qml) what a lifted pill can do, the first few times
    property string hint: ""
    Timer {
        id: hintTimer
        interval: Vars.hintHold
        onTriggered: win.hint = ""
    }
    HintPill {
        text: ghost.active ? win.hint : ""
        readonly property real d: dial.currentSize + 36
        centerX: dial.x + dial.pivotX + d * Math.cos(dial.midRad)
        centerY: dial.y + dial.pivotY + d * Math.sin(dial.midRad)
        z: 2

        // M3E: an inverse surface, as a tooltip / snackbar
        color: Roles.inverse_surface
        textColor: Roles.inverse_on_surface
    }

    // ── the lifted pill ── the app's shape with its icon, following the cursor
    DragGhost {
        id: ghost
        size: 56
        shape: win.lifted ? Notifs.info(win.lifted).shape : "Circle"
        hotShape: shape
        color: Roles.primary
        shadowColor: Roles.shadow
        z: 3
        onDone: { win.lifted = null; win.liftedIndex = -1; win.hint = ""; hintTimer.stop() }

        SymbolIcon {
            anchors.centerIn: parent
            text: win.lifted ? Notifs.info(win.lifted).symbol : ""
            size: 26
            filled: true
            color: Roles.on_primary
        }
    }
}

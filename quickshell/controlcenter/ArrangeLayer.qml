import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import ".."
import "../primitive"
import "../variables.js" as Vars

// The control center's arranging layer, drawn over the whole screen above the dial: the
// icon you drag off the Dials control's inner ring and, while it's a dial, the 8 spots
// it can be dropped on (the corners and the middle of each edge). The control center
// feeds it the drag (begin / move / release / cancel); a dial dropped on a spot moves
// there (Dials.moveTo, swapping with the dial that lived there), and the Screenshot pill
// dropped off the dial asks for a screenshot there (screenshotDropped).
//
// It never takes the mouse itself: the dial keeps the drag while the button is held.
Item {
    id: root

    // set by the control center
    required property var dial

    // ArrangeSettings, and ScreenshotSettings (the size a new screenshot starts at)
    required property var cfg
    required property var shot

    // name → { label, icon } for every dial that has a spot (the control center too)
    required property var info

    // the Screenshot pill was dropped off the dial, at (x, y) in this item's px; `rect` is
    // the window it was dropped on (this item's px), or an empty rect for none
    signal screenshotDropped(real x, real y, rect rect)

    // ── hints ── (Hints.qml) a short line off the dial's edge, on its middle line, the
    // first few times a drag starts or Edit comes on; gone after Vars.hintHold ms, or
    // when the drag ends
    property string hint: ""
    function showHint(key) {
        if (!Hints.wants(key)) return
        hint = Hints.text(key)
        Hints.shown(key)
        hintTimer.restart()
    }
    Timer {
        id: hintTimer
        interval: Vars.hintHold
        onTriggered: root.hint = ""
    }

    // ── the drag ──
    // "dial": a dial pill (drop it on a spot);  "screenshot": the Screenshot pill (drop it
    // anywhere off the dial);  "device": a device pill (drop it on an outer-ring tile it
    // has an action for, `dropOn`, or fling it off: `fling`);  "tile": an outer-ring tile
    // while arranging (drop it on another tile to move it there, or off the dial on a free
    // spot: the control moves out to a dial of its own there);  "": nothing held
    property string kind: ""
    readonly property bool active: kind !== ""

    // "drag" while held; "land" while the icon flies into its new spot (or tile); "fling"
    // while it's thrown off; "back" while it flies back to its pill (dropped nowhere)
    property string phase: ""

    // what's held: the dial's name (kind "dial"), its icon, and the pill it came from
    property string dialName: ""
    property string icon: ""
    property int itemIndex: -1

    // the held pill's entry (its dropOn / fling actions)
    property var entry: null

    // the cursor, and where the drag started (the pill), in this item's px
    property real cursorX: 0
    property real cursorY: 0
    property real homeX: 0
    property real homeY: 0

    // the spot a dropped dial is flying into, and the dial it swapped with ("" if none)
    property string landSpot: ""
    property string swapped: ""

    function begin(kind_, entry_, index, x, y, fromX, fromY) {
        flight.stop()
        kind = kind_
        dialName = entry_.dialName || ""
        icon = entry_.icon || ""
        itemIndex = index
        entry = entry_

        // the first few times: a line on what this pill can do
        showHint(kind_ === "device" ? (entry_.dropOn ? "device" : "network") : kind_)
        velX = 0
        velY = 0
        lastMove = Date.now()
        homeX = fromX
        homeY = fromY
        cursorX = x
        cursorY = y
        landSpot = ""
        swapped = ""
        if (kind_ === "screenshot") listWindows()

        // the icon starts on the pill, pill-sized, and springs to the cursor (started by
        // hand: a spring only starts by itself when its target changes)
        ghostX.snap(fromX)
        ghostY.snap(fromY)
        ghostScale.snap(cfg.ghostPickScale)
        phase = "drag"
        ghostX.start()
        ghostY.start()
        ghostScale.start()
    }

    function move(x, y) {
        // the cursor's speed (px per second), smoothed over the last few moves
        const now = Date.now(), dt = Math.max(1, now - lastMove)
        const k = Math.min(1, dt / cfg.flingSmoothing)
        velX += ((x - cursorX) * 1000 / dt - velX) * k
        velY += ((y - cursorY) * 1000 / dt - velY) * k
        lastMove = now
        cursorX = x
        cursorY = y
    }

    // the cursor's speed, and when it last moved
    property real velX: 0
    property real velY: 0
    property real lastMove: 0

    // where the icon lands (a spot or a tile), and where a flung one flies to
    property point landPoint: Qt.point(0, 0)
    property point flingPoint: Qt.point(0, 0)

    function release(x, y) {
        if (phase !== "drag") return
        move(x, y)
        if (kind === "screenshot") {
            const off = offDial

            // a copy: `hotWindow` itself would read empty once reset() ends the drag
            const win = Qt.rect(hotWindow.x, hotWindow.y, hotWindow.width, hotWindow.height)

            // gone at once: the screenshot mustn't catch it
            reset()
            if (off) screenshotDropped(x, y, win)
            return
        }
        // let go mid-flick: it keeps flying that way and does its action. The speed of the
        // release decides it, not how far it went (a slow let-go springs back)
        const still = Date.now() - lastMove > cfg.flingStale
        const speed = still ? 0 : Math.hypot(velX, velY)

        // (checked first: a flick that ends over a tile is still a fling, never a drop
        // there, e.g. flinging a device away must never play through it on Media)
        if (entry && typeof entry.fling === "function" && speed >= cfg.flingSpeed) {
            flingPoint = Qt.point(x + velX * cfg.flingCarry, y + velY * cfg.flingCarry)
            ghostX.velocity = velX
            ghostY.velocity = velY
            entry.fling()
            phase = "fling"
            flight.restart()
            return
        }

        // let go (slowly) over a tile that takes the held device / tile: do its action (or
        // move the tile), flying in
        if ((kind === "device" || kind === "tile") && dropTile >= 0) {
            const tc = dial.tileCenter(dial.tileAt(x - dial.x, y - dial.y))
            landPoint = Qt.point(dial.x + tc.x, dial.y + tc.y)
            if (kind === "device") entry.dropOn[dial.controls[dropTile].key]()
            else dial.moveControl(itemIndex, dropTile)
            phase = "land"
            flight.restart()
            return
        }

        const spot = canLand ? hotSpot : ""
        if (spot === "") {
            phase = "back"
            flight.restart()
            return
        }

        // a tile let go on a free spot: its control moves out to a dial of its own there
        if (kind === "tile") {
            const key = dial.controls[itemIndex].key
            landSpot = spot
            landPoint = spotIconPoint(spot, cfg.spotHotRadius)
            landed = "cc-" + key
            Dials.detach(key, spot)
            phase = "land"
            flight.restart()
            return
        }

        // a control's own dial let go on the control center's spot: it goes back in
        if (goingBack) {
            landSpot = spot
            landPoint = spotIconPoint(spot, cfg.spotHotRadius)
            Dials.attach(dialName)
            phase = "land"
            flight.restart()
            return
        }
        landSpot = spot
        landPoint = spotIconPoint(spot, cfg.spotHotRadius)
        swapped = Dials.swapWith(dialName, spot)

        // a move that takes the control center somewhere waits until the icon has landed
        // (then the control center closes and peeks out of its new spot); any other moves now
        deferred = dialName === "center" || swapped === "center"
        if (!deferred) Dials.moveTo(dialName, spot)
        phase = "land"
        flight.restart()
    }

    // the move is waiting for the landing (it moves the control center)
    property bool deferred: false

    // the dial a tile just became (it peeks out of its spot once the icon has landed)
    property string landed: ""

    // the drag was called off (e.g. the window lost the mouse): fly back
    function cancel() {
        if (phase !== "drag") return
        phase = "back"
        flight.restart()
    }

    function reset() {
        flight.stop()
        phase = ""
        kind = ""
        dialName = ""
        icon = ""
        itemIndex = -1
        entry = null
        if (hintTimer.running && root.hint !== Hints.text("edit")) { hintTimer.stop(); hint = "" }
    }

    // the flight to the spot (or back) is over: the moved dials peek out of their new
    // spots so you see where they went, then it's all put away
    Timer {
        id: flight
        interval: Prefs.defaultSpatial.duration
        onTriggered: {
            if (root.phase === "land" && root.kind === "tile" && root.landed !== "") {
                const c = Dials.dials[root.landed]
                if (c && c.peek) c.peek()
                root.landed = ""
            }
            if (root.phase === "land" && root.kind === "dial") {
                if (root.deferred) {
                    root.dial.snapClose()
                    Dials.moveTo(root.dialName, root.landSpot)
                    root.deferred = false
                }
                const a = Dials.dials[root.dialName]
                if (a && a.peek) a.peek()
                const b = Dials.dials[root.swapped]
                if (b && b.peek) b.peek()
            }
            root.reset()
        }
    }

    // ── the spots ──
    readonly property var spotNames: ({
        topLeft: "Top left", top: "Top", topRight: "Top right", right: "Right",
        bottomRight: "Bottom right", bottom: "Bottom", bottomLeft: "Bottom left", left: "Left"
    })

    function isCorner(s) { return s === "topLeft" || s === "topRight" || s === "bottomLeft" || s === "bottomRight" }

    // a spot's centre: the corner, or the middle of the edge
    function spotPoint(s) {
        const W = width, H = height
        switch (s) {
        case "topLeft": return Qt.point(0, 0)
        case "top": return Qt.point(W / 2, 0)
        case "topRight": return Qt.point(W, 0)
        case "right": return Qt.point(W, H / 2)
        case "bottomRight": return Qt.point(W, H)
        case "bottom": return Qt.point(W / 2, H)
        case "bottomLeft": return Qt.point(0, H)
        default: return Qt.point(0, H / 2)
        }
    }

    // the direction from a spot into the screen, degrees (0° = right, 90° = down)
    readonly property var spotDegs: ({ topLeft: 45, top: 90, topRight: 135, right: 180, bottomRight: 225, bottom: 270, bottomLeft: 315, left: 0 })

    // where a spot's icon sits: the middle of its quarter (or half) disc of radius r
    // (0.6 of the radius out on a quarter disc, 0.42 on a half disc, as in AudioOsd)
    function spotIconPoint(s, r) {
        const p = spotPoint(s)
        const a = spotDegs[s] * Math.PI / 180
        const d = r * (isCorner(s) ? 0.6 : 0.42)
        return Qt.point(p.x + d * Math.cos(a), p.y + d * Math.sin(a))
    }

    // the spot within reach of (x, y), or ""
    function spotNear(x, y) {
        let best = "", bestD = cfg.spotReach
        for (let i = 0; i < Dials.spots.length; i++) {
            const s = Dials.spots[i]
            const p = spotPoint(s)
            const d = Math.hypot(x - p.x, y - p.y)
            if (d < bestD) { best = s; bestD = d }
        }
        return best
    }

    // the spot under the held dial, and whether dropping it there moves it (its own spot
    // changes nothing)
    readonly property string hotSpot: phase === "drag" && (kind === "dial" || kind === "tile" && offDial) ? spotNear(cursorX, cursorY) : ""
    readonly property bool canLand: hotSpot !== "" && (kind === "tile" ? tileCanLeave && Dials.dialAt(hotSpot) === "" : hotSpot !== Dials.spotOf(dialName))

    // the held pill is a control's own dial over the control center's spot: it would go back in
    readonly property bool goingBack: kind === "dial" && dialName.indexOf("cc-") === 0 && hotSpot !== "" && hotSpot === Dials.spotOf("center")

    // the held tile's control can move out to a dial of its own (all but Dials: Edit lives there)
    readonly property bool tileCanLeave: kind === "tile" && itemIndex >= 0 && !!dial.controls[itemIndex] && dial.controls[itemIndex].key !== "dials"

    // the held icon is off the dial (the Screenshot pill drops there)
    readonly property real dialCX: dial.x + dial.pivotX
    readonly property real dialCY: dial.y + dial.pivotY
    readonly property bool offDial: Math.hypot(cursorX - dialCX, cursorY - dialCY) > dial.currentSize

    // ── the windows ── (for the Screenshot pill) the windows showing on this screen
    // (Windows.qml), asked for when the drag starts
    function listWindows() {
        const win = root.QsWindow.window
        Windows.refresh(win && win.screen ? win.screen.name : "")
    }

    // the window under the held Screenshot pill (off the dial), or an empty rect
    readonly property rect hotWindow: {
        Windows.list
        if (kind !== "screenshot" || phase !== "drag" || !offDial) return Qt.rect(0, 0, 0, 0)
        return Windows.rectAt(cursorX, cursorY)
    }
    readonly property bool overWindow: hotWindow.width > 0

    // the outer-ring tile under the held device / tile that takes it (controls index, -1:
    // none): one the device has a dropOn action for, or any other tile while reordering
    readonly property int dropTile: {
        if ((kind !== "device" && kind !== "tile") || phase !== "drag") return -1
        const n = dial.tileAt(cursorX - dial.x, cursorY - dial.y)
        if (n === null) return -1
        const t = ((n % dial.controls.length) + dial.controls.length) % dial.controls.length
        if (kind === "tile") return t === itemIndex ? -1 : t
        const c = dial.controls[t]
        return entry && entry.dropOn && c && typeof entry.dropOn[c.key] === "function" ? t : -1
    }

    // the held pill can be flung off (a device pill) and is off the dial, where letting go
    // mid-flick dismisses it (and while it flies off)
    readonly property bool flingZone: !!entry && typeof entry.fling === "function"
        && (phase === "fling" || phase === "drag" && offDial && dropTile < 0)

    // the held icon is over somewhere it can be dropped
    readonly property bool hot: kind === "dial" ? canLand
        : kind === "screenshot" ? offDial
        : dropTile >= 0 || kind === "tile" && canLand

    Repeater {
        model: Dials.spots

        Item {
            id: spotItem
            required property string modelData
            required property int index
            anchors.fill: parent

            readonly property string spot: modelData
            readonly property point at: root.spotPoint(spot)

            // the dial with a hot corner living here ("" for none), and the OSDs that pop up here
            readonly property string occupant: Dials.dialAt(spot)
            readonly property var osds: Dials.popupsAt(spot)

            // what to show for what lives here: the dial, or else the first OSD
            readonly property string resident: occupant !== "" ? occupant : osds.length > 0 ? osds[0] : ""

            // the held dial would swap with this one if dropped on the spot under it
            // (a control's own dial going back into the control center swaps with nothing)
            readonly property string swapIn: root.canLand && root.kind === "dial" && !root.goingBack ? Dials.swapWith(root.dialName, root.hotSpot) : ""

            // the held dial would land here; the held dial lives here; it's flying in here
            readonly property bool hot: root.hotSpot === spot && root.canLand
            readonly property bool home: root.kind === "dial" && Dials.spotOf(root.dialName) === spot && root.phase === "drag"
            readonly property bool landing: root.phase === "land" && root.landSpot === spot

            // the icon shown here: the held one while it's over (or landing in) this spot; on
            // its old spot, the dial it would swap with (a preview) or its own icon, faint
            readonly property string shownIcon: hot || landing ? root.icon
                : home ? (swapIn !== "" ? root.info[swapIn].icon : root.icon)
                : resident !== "" && root.info[resident] ? root.info[resident].icon : ""
            readonly property real iconOpacity: hot || landing ? 1 : home ? (swapIn !== "" ? 0.75 : 0.35) : 1

            // the OSDs that also pop up here, small under the main icon (not the held one)
            readonly property var extras: osds.filter(n => n !== resident && n !== root.dialName && !!root.info[n])

            // shown while a dial is held (or landing), or a tile that can move out is off the
            // dial, popping in one after another, clockwise
            readonly property bool wanted: (root.kind === "dial" || root.kind === "tile" && root.tileCanLeave && (root.offDial || root.phase === "land")) && root.phase !== "back"
            property bool shown: false
            onWantedChanged: {
                if (wanted) appear.restart()
                else { appear.stop(); shown = false }
            }
            Timer {
                id: appear
                interval: spotItem.index * root.cfg.spotStagger
                onTriggered: spotItem.shown = spotItem.wanted
            }

            // its radius: springs out from nothing, and grows while the held icon is over it
            SpringValue {
                id: spotGrow
                to: spotItem.shown ? (spotItem.hot || spotItem.landing ? root.cfg.spotHotRadius : root.cfg.spotRadius) : 0
                stiffness: Vars.springs.expressive.fast.spatial.stiffness
                dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
                epsilon: 0.2
            }
            readonly property real r: Math.max(0, spotGrow.value)
            visible: r > 0.5

            // the disc (the screen's edges cut it to a quarter or a half)
            Rectangle {
                x: spotItem.at.x - spotItem.r
                y: spotItem.at.y - spotItem.r
                width: spotItem.r * 2
                height: width
                radius: width / 2
                antialiasing: true

                // M3E: primary-container where it will land, a surface step up where a dial
                // lives, the plain surface for an empty spot
                color: spotItem.hot || spotItem.landing ? Roles.primary_container
                    : spotItem.resident !== "" || spotItem.home ? Roles.surface_container_high
                    : Roles.surface_container
                Behavior on color { ColorAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
            }

            // the outline: dashed round an empty spot, solid primary where it will land
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    readonly property bool solid: spotItem.hot || spotItem.landing
                    strokeColor: solid ? Roles.primary
                        : spotItem.resident === "" && !spotItem.home ? Roles.outline
                        : "transparent"
                    strokeWidth: root.cfg.spotOutline
                    strokeStyle: solid ? ShapePath.SolidLine : ShapePath.DashLine
                    dashPattern: [root.cfg.spotDash, root.cfg.spotDashGap]
                    fillColor: "transparent"
                    PathAngleArc {
                        centerX: spotItem.at.x; centerY: spotItem.at.y
                        radiusX: Math.max(0, spotItem.r - root.cfg.spotOutline / 2)
                        radiusY: radiusX
                        startAngle: 0
                        sweepAngle: 360
                    }
                }
            }

            // the icon and, while you're over it, the spot's name and a swap mark
            Column {
                readonly property point c: root.spotIconPoint(spotItem.spot, spotItem.r)
                x: c.x - width / 2
                y: c.y - (spotItem.hot || spotItem.extras.length > 0 ? height / 2 : root.cfg.spotIconSize / 2)
                spacing: 2
                visible: spotItem.shownIcon !== ""
                opacity: spotItem.iconOpacity
                Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

                SymbolIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: spotItem.shownIcon
                    size: root.cfg.spotIconSize
                    filled: spotItem.hot || spotItem.landing
                    color: spotItem.hot || spotItem.landing ? Roles.on_primary_container : Roles.on_surface_variant
                }

                // the OSDs that also pop up here, small
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !spotItem.hot && !spotItem.landing && spotItem.extras.length > 0
                    spacing: 2
                    Repeater {
                        model: spotItem.extras
                        SymbolIcon {
                            required property string modelData
                            text: root.info[modelData].icon
                            size: root.cfg.spotIconSize * 0.6
                            color: Roles.on_surface_variant
                        }
                    }
                }

                // "Top left" (with ⇄ when the dial living here swaps places)
                SmoothText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: spotItem.hot
                    text: root.spotNames[spotItem.spot] + (spotItem.swapIn !== "" ? "  ⇄" : "")
                    font.pixelSize: root.cfg.spotLabelSize
                    font.weight: 600
                    color: Roles.on_primary_container
                }
            }
        }
    }

    // ── the screenshot preview ── a dashed rectangle the size a new screenshot starts
    // at, round the held Screenshot pill once it's off the dial
    Shape {
        id: preview

        // where it wants to be: on the window under the pill, or the size a new screenshot
        // starts at, round the cursor
        readonly property real dw: Math.min(root.shot.startWidth, root.width)
        readonly property real dh: Math.min(root.shot.startHeight, root.height)
        readonly property real wantW: root.overWindow ? root.hotWindow.width : dw
        readonly property real wantH: root.overWindow ? root.hotWindow.height : dh
        readonly property real wantX: root.overWindow ? root.hotWindow.x : Math.max(0, Math.min(root.width - dw, root.cursorX - dw / 2))
        readonly property real wantY: root.overWindow ? root.hotWindow.y : Math.max(0, Math.min(root.height - dh, root.cursorY - dh / 2))

        // it springs there, so it slides from window to window; it jumps while hidden
        readonly property bool snapping: opacity === 0
        SpringValue { id: pvX; to: preview.wantX; stiffness: Vars.springs.expressive.fast.spatial.stiffness; dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio; epsilon: 0.2 }
        SpringValue { id: pvY; to: preview.wantY; stiffness: Vars.springs.expressive.fast.spatial.stiffness; dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio; epsilon: 0.2 }
        SpringValue { id: pvW; to: preview.wantW; stiffness: Vars.springs.expressive.fast.spatial.stiffness; dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio; epsilon: 0.2 }
        SpringValue { id: pvH; to: preview.wantH; stiffness: Vars.springs.expressive.fast.spatial.stiffness; dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio; epsilon: 0.2 }
        onSnappingChanged: if (snapping) { pvX.snap(wantX); pvY.snap(wantY); pvW.snap(wantW); pvH.snap(wantH) }
        readonly property real px: snapping ? wantX : pvX.value
        readonly property real py: snapping ? wantY : pvY.value
        readonly property real w: snapping ? wantW : Math.max(0, pvW.value)
        readonly property real h: snapping ? wantH : Math.max(0, pvH.value)
        anchors.fill: parent

        // gone at once on the drop (not faded), so the frozen screen doesn't catch it
        visible: root.kind === "screenshot" && opacity > 0
        opacity: root.kind === "screenshot" && root.phase === "drag" && root.offDial ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            // dashed while it's only a size, solid (and a stronger state layer) on a window
            strokeColor: Roles.primary
            strokeWidth: root.overWindow ? root.cfg.previewOutline * 2 : root.cfg.previewOutline
            strokeStyle: root.overWindow ? ShapePath.SolidLine : ShapePath.DashLine
            dashPattern: [4, 3]
            fillColor: Qt.rgba(Roles.primary.r, Roles.primary.g, Roles.primary.b, root.overWindow ? 0.16 : 0.08)   // M3 hover / drag state layer
            PathRectangle {
                x: preview.px; y: preview.py
                width: preview.w; height: preview.h
                radius: root.cfg.previewRadius
            }
        }
    }

    // ── the hint ── off the dial's edge on its middle line, in a pill, fading in and out
    Rectangle {
        id: hintPill
        readonly property real d: dial.currentSize + cfg.hintGap
        readonly property real px: dial.x + dial.pivotX + d * Math.cos(dial.midRad)
        readonly property real py: dial.y + dial.pivotY + d * Math.sin(dial.midRad)

        // kept on the screen
        x: Math.max(cfg.hintMargin, Math.min(root.width - width - cfg.hintMargin, px - width / 2))
        y: Math.max(cfg.hintMargin, Math.min(root.height - height - cfg.hintMargin, py - height / 2))
        width: hintText.implicitWidth + cfg.hintPadding * 2
        height: hintText.implicitHeight + cfg.hintPadding
        radius: height / 2
        antialiasing: true
        z: 2

        // M3E: an inverse surface, as a tooltip / snackbar
        color: Roles.inverse_surface
        opacity: root.hint !== "" ? 1 : 0
        visible: opacity > 0
        scale: 0.9 + 0.1 * opacity
        Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

        // keeps the last words while fading out
        property string shownText: ""
        Connections {
            target: root
            function onHintChanged() { if (root.hint !== "") hintPill.shownText = root.hint }
        }

        SmoothText {
            id: hintText
            anchors.centerIn: parent
            text: hintPill.shownText
            font.pixelSize: cfg.hintFontSize
            font.weight: 600
            color: Roles.inverse_on_surface
        }
    }

    // ── the held icon ── springs after the cursor, leans into the way it moves, morphs
    // to a cookie (and grows a little) over somewhere it can be dropped, and to
    // ghostFlingShape off the dial when it can be flung away
    SpringValue {
        id: ghostX
        to: root.phase === "land" ? root.landPoint.x
            : root.phase === "fling" ? root.flingPoint.x
            : root.phase === "back" ? root.homeX : root.cursorX
        stiffness: Vars.springs.standard.fast.spatial.stiffness
        dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
        epsilon: 0.1
    }
    SpringValue {
        id: ghostY
        to: root.phase === "land" ? root.landPoint.y
            : root.phase === "fling" ? root.flingPoint.y
            : root.phase === "back" ? root.homeY : root.cursorY
        stiffness: Vars.springs.standard.fast.spatial.stiffness
        dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
        epsilon: 0.1
    }
    SpringValue {
        id: ghostScale
        to: root.phase === "land" ? 0
            : root.phase === "fling" ? root.cfg.flingEndScale
            : root.phase === "back" ? root.cfg.ghostPickScale
            : root.hot ? root.cfg.ghostHotScale : 1
        stiffness: Vars.springs.expressive.fast.spatial.stiffness
        dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
        epsilon: 0.005
    }

    Item {
        id: ghost
        width: root.cfg.ghostSize
        height: width
        x: ghostX.value - width / 2
        y: ghostY.value - height / 2
        visible: root.active
        scale: Math.max(0, ghostScale.value)
        rotation: Math.max(-root.cfg.ghostTiltMax, Math.min(root.cfg.ghostTiltMax, ghostX.velocity / 1000 * root.cfg.ghostTilt))
        opacity: root.phase === "back" || root.phase === "fling" ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Vars.expressiveDefaultEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveDefaultEffects.bezier } }

        // a soft shadow under it, so it reads as lifted off the dial
        ShapeMorph {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: -4
            shape: root.hot ? root.cfg.ghostHotShape : root.flingZone ? root.cfg.ghostFlingShape : root.cfg.ghostShape
            color: Qt.rgba(Roles.shadow.r, Roles.shadow.g, Roles.shadow.b, 0.28)
        }

        ShapeMorph {
            anchors.fill: parent
            shape: root.hot ? root.cfg.ghostHotShape : root.flingZone ? root.cfg.ghostFlingShape : root.cfg.ghostShape
            color: Roles.primary
        }

        SymbolIcon {
            anchors.centerIn: parent
            text: root.icon
            size: root.cfg.ghostIconSize
            filled: true
            color: Roles.on_primary
        }
    }
}

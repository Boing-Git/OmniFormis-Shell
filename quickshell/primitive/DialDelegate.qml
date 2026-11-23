import QtQuick
import "../variables.js" as Vars

// ╭───────────────────────────────────────────────────────────────╮
// │ DialDelegate - the base for every corner dial.                 │
// │                                                               │
// │ Gives you: a hot corner that springs open into a quarter      │
// │ circle (or a half circle on the middle of an edge), the        │
// │ background, hover/click/wheel handling, and the geometry       │
// │ (centre + visible angles) for whatever you put in it.          │
// │                                                               │
// │   DialDelegate {                                              │
// │       corner: "topLeft"                                       │
// │       onScrolled: dir => ...                                  │
// │       onActivated: ...            // clicked while open        │
// │       Item { ... }                // your content              │
// │   }                                                           │
// ╰───────────────────────────────────────────────────────────────╯
// Children are placed in an `expandedSize` square pinned to the corner (twice as long
// along the edge for an edge dial), so they don't move while the dial opens; use
// centerX / centerY / startDeg / sweepDeg to lay them out.
Item {
    id: root

    // where the dial lives:
    //   "topLeft" | "topRight" | "bottomLeft" | "bottomRight"  a quarter circle in that corner
    //   "top" | "bottom" | "left" | "right"                    a half circle on the middle of that edge
    property string corner: "bottomRight"

    property real collapsedSize: 20
    property real expandedSize: 400
    property bool open: false

    // close after a click picks something (activated). Off for dials you keep using
    // after a click (the control center, the OSDs, the wallpaper dial)
    property bool autoClose: true

    // close when the mouse leaves
    property bool closeOnExit: true

    // close after Enter / Space picks something
    property bool closeOnEnter: true

    // close on Esc (escaped() is sent either way, e.g. to leave a mode first)
    property bool closeOnEscape: true

    // background
    // required: you must pass both colours, there are no defaults
    required property var color
    required property var borderColor
    Component.onCompleted: {
        if (color === undefined) console.error("DialDelegate: no color was passed; there is no default, set it")
        if (borderColor === undefined) console.error("DialDelegate: no borderColor was passed; there is no default, set it")

        // starting open (open: true set from outside): skip the animations
        if (open) { expanded = true; growSpring.snap(expandedSize); contentArea.opacity = 1 }
    }
    property real borderWidth: 3

    // which glass it is when the shell is translucent: "dial" (a dial with a corner) or
    // "popup" (a pop-up dial). Prefs.glass, the Look settings
    property string glassKind: "dial"

    // ── liquid glass ── (Settings → Liquid glass) the pictures the dial's glass sees,
    // shared with the glass on it (DialBand, SearchBar find it here); loaded only while
    // liquid glass is on
    readonly property LiquidBackdrop liquidBackdrop: liquidPictures
    LiquidBackdrop {
        id: liquidPictures

        // Sees: Live streams only while this dial is out, and only the windows under its box
        // (screen px: the corner's square, or twice as long along an edge)
        awake: root.currentSize > root.collapsedSize + 0.5
        area: Qt.rect(root.alongX ? Backdrop.screenSize.width / 2 - root.expandedSize : root.isRight ? Backdrop.screenSize.width - root.expandedSize : 0,
                      root.alongY ? Backdrop.screenSize.height / 2 - root.expandedSize : root.isBottom ? Backdrop.screenSize.height - root.expandedSize : 0,
                      root.alongX ? 2 * root.expandedSize : root.expandedSize,
                      root.alongY ? 2 * root.expandedSize : root.expandedSize)
    }

    // the background is liquid glass right now (on, and its picture is loaded)
    readonly property bool liquid: discGlass.active

    // show the background only while hovered
    property bool backgroundOnHover: true

    // ── open / close ──
    // `open` is what you ask for; `expanded` is what the size follows. They differ
    // only while closing: the content fades out first, THEN the dial shrinks.
    property bool expanded: false

    // true while snapOpen / snapClose run: sizes jump instead of animating
    property bool snapping: false

    // open at full size right away, content showing, no animation
    // (e.g. so a morph can photograph the finished dial)
    function snapOpen() {
        snapping = true
        closeAnim.stop()
        open = true
        forceActiveFocus()       // take the keys, like a normal open
        expanded = true
        growSpring.snap(expandedSize)
        contentFade.stop()
        contentArea.opacity = 1
        snapping = false
    }

    // opens carrying on from a dial that was just put away on this spot (a hand-over,
    // see Dials.popUpAt): the background starts at `size` instead of at the hot corner
    // and springs on to this dial's own size, and the content fades in over it
    function openFrom(size) {
        if (open) return
        closeAnim.stop()
        peeking = false
        growSpring.snap(Math.max(collapsedSize, size))
        crossfading = true
        open = true
    }

    // true while a hand-over's content fades in (openFrom); off once it's shown
    property bool crossfading: false

    // the same hand-over for a dial that is opening already (its hot corner was clicked
    // while another dial was out on the spot): it goes on growing from `size`
    function carryOn(size) {
        if (!open || currentSize >= size) return
        growSpring.snap(Math.max(collapsedSize, Math.min(size, expandedSize)))
        growSpring.start()
        if (currentSize >= expandedSize * contentAt - 0.5) showContent()
    }

    // closed right away, no fade and no shrink
    function snapClose() {
        snapping = true
        closeAnim.stop()
        open = false
        contentFade.stop()
        contentArea.opacity = 0
        expanded = false
        peeking = false
        growSpring.snap(collapsedSize)
        snapping = false
    }

    onOpenChanged: {
        if (!open) stranded = false

        // a grace left over from the last opening must not close this one
        leaveGrace.stop()

        // the mouse owns this opening only if it's on the dial now (it clicked the corner)
        pointerOwned = open && mouse.containsMouse
        if (snapping) return
        if (open) {
            closeAnim.stop()
            forceActiveFocus()       // take the keys (see "keyboard" below)
            expanded = true          // grow now...

            // reopened before it shrank: already big enough, so bring the content back now
            if (currentSize >= expandedSize * contentAt - 0.5) showContent()
        } else {
            contentFade.stop()
            closeAnim.restart()      // fade the content out; it shrinks the dial when done
        }
    }

    // Opening is closing backwards: the dial grows first, and the content fades in over
    // the last of the growing, once the dial has reached `contentAt` of its size. (Waiting
    // for the full size cost a moment on every open, more so on a spring with no bounce,
    // which only creeps up to its full size.)
    property real contentAt: 0.9
    onCurrentSizeChanged: {
        if (!open || !expanded) return
        if (currentSize >= expandedSize * contentAt - 0.5) showContent()
        if (currentSize >= expandedSize - 0.5) {
            atSize = true

            // fully open, but the mouse that opened it isn't on it (it slipped off while it
            // grew): give it a moment to come back before closing
            if (closeOnExit && pointerOwned && !mouse.containsMouse && !leaveGrace.running) {
                leaveGrace.interval = leaveGraceTime
                leaveGrace.restart()
            }
        }
    }

    // fades the content in (from wherever a fade-out left it)
    function showContent() {
        if (contentArea.opacity >= 1 || contentFade.running) return
        closeAnim.stop()
        contentFade.restart()
    }
    NumberAnimation {
        id: contentFade
        target: contentArea; property: "opacity"; to: 1
        duration: Vars.expressiveFastEffects.duration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Vars.expressiveFastEffects.bezier
        onRunningChanged: if (!running) root.crossfading = false
    }

    // ── the mouse leaving ──
    // True once the mouse has been on this opening of the dial. Only then does the mouse
    // being off it close it: a dial opened from a keybind (the mouse somewhere else) stays
    // until you pick something, press Esc, or bring the mouse onto it and away again.
    property bool pointerOwned: false

    // ms the mouse has to come back onto a dial that opened while it was off it
    property int leaveGraceTime: 700

    // ms the mouse has to come back after it slips off an open dial (0: closes at once)
    property int slipGraceTime: Prefs.slipGrace

    // ms it has to come back after a ring was turned from off the dial (reach is
    // precision) and let go out there: long enough to bring the hand back in
    property int reachGraceTime: 1500

    // the mouse left the open dial: it closes once slipGraceTime passes without it back
    function slipped() {
        if (!open) return
        if (slipGraceTime <= 0) { open = false; return }
        leaveGrace.interval = slipGraceTime
        leaveGrace.restart()
    }
    Timer {
        id: leaveGrace
        interval: root.leaveGraceTime
        onTriggered: {
            if (!root.open || !root.closeOnExit || mouse.containsMouse || mouse.claimed || root.stranded) return
            if (mouse.dragging && mouse.pressed) return

            // still growing (or resizing for another control): look again once it has
            if (root.currentSize < root.expandedSize - 0.5) { restart(); return }
            root.open = false
        }
    }

    // ── stranded ── true when the dial shrank out from under a mouse that didn't move
    // (e.g. a control asking for a smaller dial): it stays open instead of closing. The
    // window can't see the mouse there any more, so it should take the whole screen while
    // this is true and pass each move to strandedMoved(), which closes the dial once the
    // mouse really goes somewhere else. Moving back onto the dial clears it.
    property bool stranded: false

    // while stranded: how far from the dial's centre the mouse can go and still count as
    // on the dial (the size it had while the mouse was last on it), px
    property real strandReach: 0

    // the dial's centre in the parent's px (it doesn't move while the dial resizes)
    readonly property real centerInParentX: x + pivotX
    readonly property real centerInParentY: y + pivotY

    // the mouse moved to (x, y) (this item's parent's px) while stranded: it closes only
    // once the mouse goes past where the bigger dial reached
    function strandedMoved(x, y) {
        if (!stranded) return
        if (Math.hypot(x - centerInParentX, y - centerInParentY) <= strandReach) return
        stranded = false
        if (closeOnExit) open = false
    }

    // true once the dial has finished growing: from then on its size follows
    // expandedSize directly, so a dial that animates its own size (e.g. per control)
    // isn't animated twice (its own animation plus the spring chasing it)
    property bool atSize: false
    onExpandedChanged: atSize = expanded && Math.abs(currentSize - expandedSize) < 0.5
    onExpandedSizeChanged: if (atSize && expanded) growSpring.snap(expandedSize)

    SequentialAnimation {
        id: closeAnim
        NumberAnimation {
            target: contentArea; property: "opacity"; to: 0
            duration: Vars.expressiveFastEffects.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Vars.expressiveFastEffects.bezier
        }
        ScriptAction { script: root.expanded = false }   // content gone: now shrink
    }

    // ── peek ── while closed: grows the hot corner to peekSize for a moment and
    // back, so you can see where the dial lives (e.g. right after it was moved)
    property real peekSize: 56
    property bool peeking: false
    function peek(ms) {
        if (open) return
        peeking = true
        peekTimer.interval = ms > 0 ? ms : 900
        peekTimer.restart()
    }
    Timer {
        id: peekTimer
        onTriggered: root.peeking = false
    }

    // your content goes here
    default property alias content: contentArea.data
    readonly property alias contentItem: contentArea

    // ── where it sits ──
    // the screen edges it touches; an edge dial touches one, a corner dial two
    readonly property bool isLeft: corner === "topLeft" || corner === "bottomLeft" || corner === "left"
    readonly property bool isRight: corner === "topRight" || corner === "bottomRight" || corner === "right"
    readonly property bool isTop: corner === "topLeft" || corner === "topRight" || corner === "top"
    readonly property bool isBottom: corner === "bottomLeft" || corner === "bottomRight" || corner === "bottom"

    // on the middle of an edge: a half circle, twice as long along the edge as it is deep
    readonly property bool isEdge: corner === "top" || corner === "bottom" || corner === "left" || corner === "right"

    // the edge runs across (top / bottom) or down (left / right)
    readonly property bool alongX: corner === "top" || corner === "bottom"
    readonly property bool alongY: corner === "left" || corner === "right"

    // ── geometry, in contentItem coordinates ──
    // the point the dial grows out of (the circles' centre)
    readonly property real centerX: alongX || isRight ? expandedSize : 0
    readonly property real centerY: alongY || isBottom ? expandedSize : 0

    // the visible part runs from startDeg to startDeg + sweepDeg (0° = right, 90° = down):
    // a quarter (90°) in a corner, a half (180°) on an edge
    readonly property real startDeg: corner === "top" ? 0
        : corner === "right" ? 90
        : corner === "bottom" ? 180
        : corner === "left" ? -90
        : isBottom ? (isRight ? 180 : 270) : (isRight ? 90 : 0)
    readonly property real sweepDeg: isEdge ? 180 : 90

    // the middle of the visible part: where a ring's selected item sits
    readonly property real midDeg: startDeg + sweepDeg / 2

    // the same centre, in this item's own coordinates (moves while the dial grows)
    readonly property real pivotX: alongX ? width / 2 : isRight ? width : 0
    readonly property real pivotY: alongY ? height / 2 : isBottom ? height : 0

    readonly property bool hovered: mouse.containsMouse

    // where the mouse is on the dial (px), for hit-testing things drawn on it
    readonly property real hoverX: mouse.mouseX
    readonly property real hoverY: mouse.mouseY

    // true while the mouse button is held down on the dial
    readonly property bool pressed: mouse.pressed

    // true while a ring is being turned by a drag (not a pill pulled off: see claimDrag).
    // hoverRadius keeps following the hand, also past the dial's edge
    readonly property bool turning: mouse.dragging && mouse.pressed && !mouse.claimed

    // how far the mouse is from the dial's centre (the circles' centre), in px.
    // Compare it with a ring's radius to tell which ring the mouse is over; it
    // keeps the last position while the mouse is outside the dial
    readonly property real hoverRadius: Math.hypot(mouse.mouseX - pivotX, mouse.mouseY - pivotY)

    signal activated()          // clicked while open
    signal scrolled(int dir)    // one wheel notch: -1 or +1
    signal typed(string text)   // a letter/number/symbol was typed while open (e.g. to start a search)
    signal secondaryActivated() // right-clicked or Delete pressed while open (e.g. forget a device)
    signal escaped()            // Esc was pressed while open
    signal dragged(real deg)    // held and dragged round the corner by this many degrees
    signal flung(real speed)    // let go of a drag, turning this many degrees per second

    // ── taking over a drag ── e.g. to pull something off the dial instead of turning it.
    // Set claimDrag to a function(pressX, pressY, x, y) → bool; it's asked once, when a
    // drag starts (this item's px). Return true and the drag is yours: you get
    // claimedMoved / claimedReleased (or claimCanceled) instead of dragged / flung, and
    // the dial doesn't close when the mouse leaves it meanwhile.
    property var claimDrag: null
    readonly property bool dragClaimed: mouse.claimed
    signal claimedMoved(real x, real y)
    signal claimedReleased(real x, real y)
    signal claimCanceled()

    // ── keyboard ── while open (and the window has the keyboard, see
    // README): arrows / Tab spin, Enter or Space picks (like a click),
    // Esc closes, anything printable goes to typed().
    Keys.onPressed: event => {
        if (!root.open) return
        switch (event.key) {
        case Qt.Key_Up: case Qt.Key_Left: case Qt.Key_Backtab:
            root.scrolled(-1); break
        case Qt.Key_Down: case Qt.Key_Right: case Qt.Key_Tab:
            root.scrolled(1); break
        case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space:
            root.activated(); if (root.closeOnEnter) root.open = false; break
        case Qt.Key_Escape: {
            // decided before escaped() runs, so a handler that leaves a mode doesn't also close
            const close = root.closeOnEscape
            root.escaped()
            if (close) root.open = false
            break
        }
        case Qt.Key_Delete: case Qt.Key_Backspace:
            root.secondaryActivated(); break
        default:

            // printable, and not a Ctrl/Alt/Super shortcut
            if (event.text.length === 1 && event.text >= " "
                && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                root.typed(event.text); break
            }
            return                       // not ours: let it through
        }
        event.accepted = true
    }

    // the dial's radius right now: grows from collapsedSize to expandedSize as it opens
    property real currentSize: useSpring ? Math.max(0, growSpring.value) : (expanded ? expandedSize : peeking ? peekSize : collapsedSize)

    // a quarter circle is as wide as it is deep; a half circle twice as long along its edge
    width: currentSize * (alongX ? 2 : 1)
    height: currentSize * (alongY ? 2 : 1)
    clip: true

    // pinned to its corner, or centred on its edge
    x: parent ? (isLeft ? 0 : isRight ? parent.width - width : (parent.width - width) / 2) : 0
    y: parent ? (isTop ? 0 : isBottom ? parent.height - height : (parent.height - height) / 2) : 0

    // ── grow / shrink motion ── a spring (Prefs.openSpring: the Bounce and Speed settings)
    // or a curve (Prefs.defaultSpatial)
    property bool useSpring: Vars.useSprings
    property var spring: Prefs.openSpring
    SpringValue {
        id: growSpring
        to: root.expanded ? root.expandedSize : root.peeking ? root.peekSize : root.collapsedSize
        stiffness: root.spring.stiffness
        dampingRatio: root.spring.dampingRatio
        epsilon: 0.2
        Component.onCompleted: snap(to)          // start at the right size, no motion
    }

    // M3E expressive default spatial curve (variables.js), when not using the spring
    Behavior on currentSize {
        enabled: !root.useSpring && !root.snapping && !root.atSize
        NumberAnimation {
            duration: Prefs.defaultSpatial.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Prefs.defaultSpatial.bezier
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        property bool wasOpen: false

        // where the mouse last was, in the parent's px (stays put while the dial resizes)
        property real lastX: 0
        property real lastY: 0

        // the dial's size when the mouse was last on it
        property real lastSize: 0
        onContainsMouseChanged: if (containsMouse) { root.stranded = false; root.pointerOwned = true; leaveGrace.stop() }

        // ── drag / flick ── the angle round the corner while the left button is held
        property bool dragging: false

        // true while claimDrag took this drag over
        property bool claimed: false
        property real pressX: 0
        property real pressY: 0
        property real lastDeg: 0
        property real lastTime: 0
        property real speed: 0
        function angleAt(x, y) { return Math.atan2(y - root.pivotY, x - root.pivotX) * 180 / Math.PI }

        onPressed: mouse => {
            // open only once the content shows: a click while it's still growing is not a
            // click on the content (it would activate it and close the dial)
            wasOpen = root.open && contentArea.opacity > 0
            dragging = false
            claimed = false
            pressX = mouse.x
            pressY = mouse.y
            lastDeg = angleAt(mouse.x, mouse.y)
            lastTime = Date.now()
            speed = 0
        }
        onPositionChanged: mouse => {
            if (root.parent) {
                const p = mapToItem(root.parent, mouse.x, mouse.y)
                lastX = p.x
                lastY = p.y
                lastSize = root.currentSize
            }
            if (!pressed || !wasOpen || !(mouse.buttons & Qt.LeftButton)) return
            if (!dragging) {
                if (Math.hypot(mouse.x - pressX, mouse.y - pressY) < Qt.styleHints.startDragDistance) return
                dragging = true

                // someone else may want this drag (claimDrag above)
                claimed = typeof root.claimDrag === "function" && root.claimDrag(pressX, pressY, mouse.x, mouse.y) === true
            }
            if (claimed) { root.claimedMoved(mouse.x, mouse.y); return }
            const deg = angleAt(mouse.x, mouse.y)
            const d = ((deg - lastDeg + 540) % 360) - 180
            const now = Date.now()

            // smoothed, so one uneven mouse event doesn't decide the throw
            speed = Vars.flickSmoothing * d / (Math.max(8, now - lastTime) / 1000) + (1 - Vars.flickSmoothing) * speed
            lastDeg = deg
            lastTime = now
            root.dragged(d)
        }

        // held still before letting go: no throw
        onReleased: mouse => {
            if (claimed) {
                claimed = false
                root.claimedReleased(mouse.x, mouse.y)

                // what was pulled off was let go off the dial: the mouse is off it now
                if (!containsMouse && root.closeOnExit) root.slipped()
                return
            }
            if (dragging) root.flung(Date.now() - lastTime > Vars.flickHoldMs ? 0 : speed * Prefs.throwStrength)

            // the drag ended off the dial (it was kept open for the drag): the hand gets
            // time to come back before it counts as having left
            if (dragging && !containsMouse && root.closeOnExit && root.open) {
                leaveGrace.interval = Math.max(root.slipGraceTime, root.reachGraceTime)
                leaveGrace.restart()
            }
        }

        // the press was taken away (e.g. the window lost the mouse): a claimed drag is called off
        onCanceled: if (claimed) { claimed = false; dragging = false; root.claimCanceled() }

        onClicked: mouse => {
            if (dragging) return     // a drag isn't a click
            if (mouse.button === Qt.RightButton) { if (wasOpen) root.secondaryActivated(); return }
            if (!wasOpen) { root.open = true; return }   // corner click (or one while it grows): only open, never activate
            root.activated()
            if (root.autoClose) root.open = false
        }

        // while it's still growing the mouse can easily slip off the small dial: don't
        // close then; once it's fully open, `leaveGrace` decides
        onExited: {
            if (!root.closeOnExit || claimed) return

            // a ring being turned keeps its dial while the hand is off it (reach is
            // precision: the further out you pull, the finer it turns); onReleased decides
            if (dragging && pressed) return
            if (root.open && root.currentSize < root.expandedSize - 0.5) return

            // the mouse's last spot is off the dial now: the dial shrank away, the mouse didn't leave
            const r = Qt.styleHints.startDragDistance
            if (root.open && !(lastX >= root.x - r && lastX < root.x + root.width + r
                               && lastY >= root.y - r && lastY < root.y + root.height + r)) {
                // (the mouse could also have been in the square's corner, past the circle)
                root.strandReach = Math.max(lastSize, Math.hypot(lastX - root.centerInParentX, lastY - root.centerInParentY)) + r
                root.stranded = true
                return
            }
            root.slipped()
        }
        onWheel: event => root.scrolled(event.angleDelta.y > 0 ? -1 : 1)
    }

    // a circle centred on the corner (or the edge's middle), so only a quarter (or half) shows
    Rectangle {
        width: root.currentSize * 2
        height: width
        radius: width / 2
        antialiasing: true

        // glass when the shell is translucent (Prefs.glass, as its glassKind); the rim
        // stays solid, so the dial keeps a crisp edge over any wallpaper. Liquid glass
        // draws both itself (below)
        color: root.liquid ? "transparent" : Prefs.glass(root.color, root.glassKind)
        border.width: root.liquid ? 0 : root.borderWidth
        border.color: root.borderColor
        x: root.pivotX - width / 2
        y: root.pivotY - height / 2

        // visible while hovered, and also for as long as the dial is bigger than its
        // collapsed size, so the shrink can be seen before the background fades away
        opacity: !root.backgroundOnHover || mouse.containsMouse || root.currentSize > root.collapsedSize + 0.5 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

        // liquid glass in the background's place (Settings → Liquid glass): the dial's
        // colour fills its body, its rim bends the wallpaper behind
        LiquidGlass {
            id: discGlass
            anchors.fill: parent
            anchors.margins: -shadowReach
            radius: parent.width / 2
            tint: Prefs.liquidBody(root.color, root.glassKind)
            hovered: root.hovered
            pressed: root.pressed

            // the dial clips to its own box (root's), here in the glass's px
            clipRect: Qt.rect(-(parent.x + x), -(parent.y + y), root.width, root.height)
        }
    }

    Item {
        id: contentArea
        width: root.expandedSize * (root.alongX ? 2 : 1)
        height: root.expandedSize * (root.alongY ? 2 : 1)

        // its centre (centerX / centerY) stays on the dial's centre while the dial grows
        x: root.pivotX - root.centerX
        y: root.pivotY - root.centerY
        opacity: 0      // faded in by contentFade as the dial opens, out by closeAnim
    }
}

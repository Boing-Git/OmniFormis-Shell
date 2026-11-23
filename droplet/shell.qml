import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// The circle shell: everything is a circle, and you get things done by dragging one onto
// the next.
//
// At rest there is nothing on screen, and nothing happens when the mouse only passes
// over the edge. Press on the right edge and pull: a drop is drawn out of the edge, still
// joined to it by a neck of liquid. Pull far enough and it comes free: that is the seed,
// and the first circles bud out round where it came free (Control center, Apps, Media,
// Windows, Workspaces, Tools, Power). The drop is still in your hand: drag it onto one of
// them and the two join, the drop swings back to its place, and now you hold that circle,
// with the circles inside it budding out in turn. Go on, each circle onto the next, until
// you drag one onto a task (the tinted ones): the chain lights up from the seed to the
// task, and it is done, e.g.
//
//     edge → seed → Control center → Wi-Fi → Home → Connect
//
// Nothing connects by clicking: a circle only joins when the one before it is dragged
// onto it. You don't have to hold the button the whole way: let go and the circle you
// held swings back to its place; pick it up again to go on. Picking up an earlier circle
// of the chain goes back to it, and so does dragging a circle back onto the one before
// it. Some tasks stay out after they ran (next track, a volume level): drag onto them as
// often as you like. Where a circle can be searched (Apps, a Wi-Fi password) just type;
// Enter takes the first circle. A click on the empty screen (or Backspace) goes back one;
// Esc, a click on the seed, or pushing the seed back into the edge lets it all run back in.
//
// Everything moves like liquid: circles are drops (Bubble.qml) joined by necks and threads
// of the same stuff (Goo.qml). What the circles are and do is in Tree.qml.
//
//   qs -p <this folder>                              run it
//   qs -p <this folder> ipc call circles toggle      open / close from a keybind
//   CIRCLES_DEMO=1 qs -p <this folder>               try it: tasks only say what they'd do
Scope {
    PanelWindow {
        id: win
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "droplet"
        WlrLayershell.layer: WlrLayer.Overlay

        // the keys only while it's open (Esc, Backspace, Enter, and typing to search)
        WlrLayershell.keyboardFocus: web.phase === "open" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // at rest only a strip along the right edge takes the mouse (not the corners: other
        // shells live there); while a drop is out, the whole screen does
        mask: Region {
            x: web.phase === "rest" ? win.width - win.strip : 0
            y: web.phase === "rest" ? win.cornerClear : 0
            width: web.phase === "rest" ? win.strip : win.width
            height: web.phase === "rest" ? win.height - win.cornerClear * 2 : win.height
        }

        // ── settings ── sizes are px
        // a circle's radius, the seed's, and how much bigger a `big` circle is
        readonly property real bubbleR: 34
        readonly property real seedR: 24
        readonly property real bigger: 1.2

        // the strip along the right edge that can be pulled, and how much of the edge is left
        // alone at its top and bottom
        readonly property real strip: 10
        readonly property real cornerClear: 110

        // how far the drop must be pulled to come free (it pinches off right there), and the size
        // of the body of liquid behind the edge it is drawn from (it stays that size: pulling
        // never swells the edge)
        readonly property real pullOut: 80
        readonly property real edgeR: 58

        // how far the next circles come out from the one they belong to, the room each needs
        // along their arc (two radii plus this gap), and the widest that arc may fan (degrees)
        readonly property real step: 170
        readonly property real gap: 52
        readonly property real fanMax: 230

        // the fan would rather go further out than open wider than this (degrees): a fan
        // that wraps round the circle it came from is hard to read and to drag through
        readonly property real fanEasy: 130

        // circles never come closer than this to the screen's edges
        readonly property real edge: 70

        // the cursor counts as on a circle this far past its rim, and a press that moves less
        // than `clickSlop` before it is let go is a click, not a drag
        readonly property real reach: 10
        readonly property real clickSlop: 8

        // the seed let go this near the edge it came out of goes back in
        readonly property real pushIn: 46

        // at most this many circles come out of one (the rest are left out)
        readonly property int most: 12

        // how many circles' room a slider takes on the fan (Slider.qml)
        readonly property int sliderSlots: 4

        // ms between one circle budding out and the next, between one circle of a finished
        // chain lighting up and the next, and between one running back in and the next
        readonly property int budStagger: 38
        readonly property int doneStagger: 90
        readonly property int closeStagger: 70

        // how dark the screen behind gets while it's open (0..1), and ms a finished chain
        // stays lit before it is let go
        readonly property real dim: 0.42
        readonly property int doneHold: 1000

        // ms the words at the top say what a task that stays out just did, and ms between
        // looks at whether what's on offer has changed (a network found, the track changed)
        readonly property int saidHold: 1400
        readonly property int lookEvery: 1500

        // Quickshell 0.3.2 on Qt 6.12 crashes while showing its own "reloaded" popup, so don't
        // show it (reloads still happen; the log still says so)
        Connections {
            target: Quickshell
            function onReloadCompleted() { Quickshell.inhibitReloadPopup() }
            function onReloadFailed(error) { Quickshell.inhibitReloadPopup() }
        }

        IpcHandler {
            target: "circles"
            function toggle(): void { if (web.phase === "open") web.collapse(); else if (web.phase === "rest") web.popOut() }
            function open(): void { if (web.phase === "rest") web.popOut() }
            function close(): void { web.collapse() }
        }

        Item {
            id: web
            anchors.fill: parent
            focus: true

            // "rest"     nothing out: the edge waits
            // "pull"     a drop is being pulled out of the edge (the button is held)
            // "open"     the drop came free: it is the seed, and circles can be connected
            // "closing"  the chain is running back in
            property string phase: "rest"

            // ── the chain ── the circles connected so far (the seed first) and the circles the
            // last one can be connected to next. Each circle draws the liquid to the one it
            // came out of itself (Bubble.qml), so the chain's threads are part of its circles
            property var chain: [seed]
            property var cands: []
            readonly property var head: chain[chain.length - 1]

            // the curved slider on offer with the circles (a node with `slider`), or null
            property var slider: null

            // a chain that reached its task: it stays lit for a moment, then it's let go
            property bool finished: false

            // the circle in the hand (the last of the chain, while the button is held on it), or null
            property var grabbed: null
            property real cursorX: 0
            property real cursorY: 0

            // where the button went down, and whether it has moved off that spot since
            property point pressAt: Qt.point(0, 0)
            property bool moved: false

            // true after a task that stays out ran, until the hand has left the circles on
            // offer: holding still on it doesn't do it over and over
            property bool spent: false

            // what was typed, for a circle that can be searched (cleared on every other circle)
            property string query: ""

            // what a task that stays out just did, for a moment
            property string said: ""
            Timer {
                id: hush
                interval: win.saidHold
                onTriggered: web.said = ""
            }
            function say(text) {
                said = text
                hush.restart()
            }

            // where the seed came free (its place while the shell is open), and the height
            // it went back into the edge at (it waits there until the edge is touched)
            property point anchor: Qt.point(0, 0)
            property real restY: 0

            // ── holding a circle ── it follows the hand until it is let go, then swings back
            // to its place. (The seed's own bindings do this for it: see below)
            function grab(b) {
                if (grabbed === b) return
                drop()
                grabbed = b
                if (b && b !== seed) b.grabbed = true
                follow()
            }
            function drop() {
                const b = grabbed
                grabbed = null
                if (!b || b === seed || b.role === "gone") return
                b.grabbed = false
                b.toX = b.homeX
                b.toY = b.homeY
            }
            function follow() {
                const b = grabbed
                if (!b || b === seed) return
                b.toX = cursorX
                b.toY = cursorY
            }

            // ── where the next circles go ── fanned out from the last circle's place, away
            // from the one before it; the nearer the screen's edge, the more the fan turns
            // back in towards the middle of the screen
            function fan(n, widestR) {
                const h = head, prev = chain.length > 1 ? chain[chain.length - 2] : null
                const hx = h.homeX, hy = h.homeY
                let ox = width / 2 - hx, oy = height / 2 - hy
                const od = Math.hypot(ox, oy) || 1
                ox /= od
                oy /= od
                let bx = ox, by = oy
                if (prev) {
                    const dx = hx - prev.homeX, dy = hy - prev.homeY, d = Math.hypot(dx, dy) || 1
                    const pull = Math.pow(Math.min(1, od / (0.42 * Math.min(width, height))), 2)
                    bx = dx / d * (1 - pull) + ox * pull
                    by = dy / d * (1 - pull) + oy * pull
                }
                const base = Math.atan2(by, bx)

                // each needs `need` px along the arc. Find the stretch of the arc round the last
                // circle that is on the screen (nearest the way we're heading), and if the
                // circles don't fit on it, go further out, where the arc is longer
                const need = (widestR || win.bubbleR) * 2 + win.gap, widest = win.fanMax * Math.PI / 180, easy = win.fanEasy * Math.PI / 180
                const ok = (a, d) => {
                    const x = hx + d * Math.cos(a), y = hy + d * Math.sin(a)
                    return x >= win.edge && x <= width - win.edge && y >= win.edge + 40 && y <= height - win.edge - 56
                }
                const one = Math.PI / 90
                let dist = win.step, from = base, to = base, spacing = need / dist
                for (; dist <= win.step * 4; dist += 30) {
                    // the nearest angle to `base` that is on the screen, then as far each way as it stays on
                    let mid = NaN
                    for (let k = 0; k <= 90 && isNaN(mid); k++) {
                        if (ok(base + k * one, dist)) mid = base + k * one
                        else if (ok(base - k * one, dist)) mid = base - k * one
                    }
                    if (isNaN(mid)) continue
                    from = mid
                    to = mid
                    while (to - mid < Math.PI && ok(to + one, dist)) to += one
                    while (mid - from < Math.PI && ok(from - one, dist)) from -= one
                    spacing = need / dist
                    if (spacing * (n - 1) <= Math.min(easy, to - from)) break
                }
                const room = Math.min(widest, to - from)
                if (n > 1 && spacing * (n - 1) > room) spacing = room / (n - 1)

                // centred on the way we're heading, slid along to stay on the on-screen stretch
                const span = spacing * (n - 1)
                const start = Math.max(from, Math.min(to - span, base - span / 2))
                const out = []
                for (let i = 0; i < n; i++) {
                    const a = start + i * spacing
                    out.push(Qt.point(hx + dist * Math.cos(a), hy + dist * Math.sin(a)))
                }

                // the first circle where you'd start reading: the top of a fan that runs up and
                // down, the left of one that runs across
                if (n > 1) {
                    const dx = out[n - 1].x - out[0].x, dy = out[n - 1].y - out[0].y
                    if (Math.abs(dy) > Math.abs(dx) ? dy < 0 : dx < 0) out.reverse()
                }
                return out
            }

            // what the last circle offers right now: its own circles, or (once something is
            // typed) what it finds for that
            function kids() {
                const n = head.node
                return (n.search && query !== "" ? n.search(query) : n.children()).slice(0, win.most)
            }

            // the last circle's own circles bud out of it, one after another (it shivers as
            // they leave it). A slider among them takes the end of the fan: a band along it
            function bloom() {
                clearCands()
                const all = kids(), sl = all.find(k => k.slider) || null, list = all.filter(k => !k.slider)
                const at = fan(list.length + (sl ? win.sliderSlots : 0), win.bubbleR * (list.some(k => k.big) ? win.bigger : 1))
                head.jiggle(0.16)
                cands = list.map((k, i) => bubbleC.createObject(bubbles, {
                    node: k, from: head, r: win.bubbleR * (k.big ? win.bigger : 1),
                    toX: at[i].x, toY: at[i].y, homeX: at[i].x, homeY: at[i].y, delay: i * win.budStagger
                }))
                if (sl) {
                    const a = at[list.length], b = at[at.length - 1], hx = head.homeX, hy = head.homeY
                    const a0 = Math.atan2(a.y - hy, a.x - hx)
                    let sweep = Math.atan2(b.y - hy, b.x - hx) - a0
                    while (sweep > Math.PI) sweep -= 2 * Math.PI
                    while (sweep <= -Math.PI) sweep += 2 * Math.PI
                    slider = sliderC.createObject(bubbles, {
                        node: sl, cx: hx, cy: hy, radius: Math.hypot(a.x - hx, a.y - hy), a0: a0, sweep: sweep,
                        thick: win.bubbleR * 1.1, reach: win.reach
                    })
                }
            }

            // what's on offer may have changed (a task switched something, a network was
            // found, a letter was typed). As many circles as before: each just takes its new
            // face where it is. A different number: they bud out afresh, if that's allowed
            // right now (see calm())
            function look(afresh) {
                if (phase !== "open" || finished) return
                // the chain's own circles that can say how they are now (what's playing) do
                for (const b of chain) if (b.node.live) b.node = b.node.live()
                const all = kids(), sl = all.find(k => k.slider) || null, list = all.filter(k => !k.slider)
                if (list.length !== cands.length || !sl !== !slider) { if (afresh) bloom(); return }
                for (let i = 0; i < list.length; i++) cands[i].node = list[i]
                if (slider) { slider.node = sl; if (!slider.hot) slider.value = sl.value }
            }
            Timer {
                interval: win.lookEvery
                repeat: true
                running: web.phase === "open" && !web.finished
                onTriggered: web.look(web.calm())
            }
            Timer {
                id: lookSoon
                interval: 260
                onTriggered: web.look(web.calm())
            }

            // true when the circles on offer can be swapped for others: the button is up, or
            // the hand is not on its way to one of them (none is near it)
            function calm() {
                return !area.pressed || !cands.some(c => Math.hypot(c.homeX - cursorX, c.homeY - cursorY) < win.step * 0.6)
            }

            // the circles on offer are drawn back into the one they came out of
            function clearCands() {
                for (const c of cands) c.leaveInto(head.cx, head.cy)
                cands = []
                if (slider) slider.leave()
                slider = null
            }

            // the drop came free of the edge at (x, y): it is the seed now, and it opens
            function openAt(x, y) {
                anchor = Qt.point(Math.max(win.edge, Math.min(width - win.edge, x)), Math.max(win.edge, Math.min(height - win.edge, y)))
                finished = false
                spent = false
                query = ""
                said = ""
                phase = "open"
                Tree.open = true
                forceActiveFocus()
                seed.pulse()
                seed.jiggle(0.26)
                bloom()
            }

            // opened from a keybind: the seed comes out of the middle of the edge by itself
            function popOut() {
                cursorY = height / 2
                openAt(width - win.pullOut - 40, height / 2)
            }

            // the circle in the hand was dragged onto `b`, one of the circles on offer.
            // A task that stays out: it runs, lights up, and everything stays as it is.
            // Anything else joins the chain: the one that was held swings back to its place,
            // and `b` is the one in the hand now (its own circles bud out); a task ends it
            function connect(b) {
                if (b.node.leaf && b.node.stay) {
                    b.node.run()
                    b.flash()
                    b.hot = false
                    say(Tree.last)
                    spent = true
                    lookSoon.restart()
                    return
                }
                const held = grabbed !== null
                drop()
                cands = cands.filter(c => c !== b)
                clearCands()
                b.role = "chain"
                b.hot = false
                b.pulse()
                chain = chain.concat([b])
                query = ""
                if (b.node.leaf) { finish(); return }
                bloom()
                if (held) grab(b)
            }

            // back to the circle at `i` of the chain: everything after it runs back into it
            function backTo(i) {
                if (i >= chain.length - 1) return
                drop()
                clearCands()
                for (let k = chain.length - 1; k > i; k--) chain[k].leaveInto(chain[i].cx, chain[i].cy)
                chain = chain.slice(0, i + 1)
                query = ""
                bloom()
            }

            // back one, or (from the seed) all the way in
            function backOne() {
                if (chain.length > 1) backTo(chain.length - 2)
                else collapse()
            }

            // everything runs back: the chain into the seed, one circle after another from its
            // far end, then the seed into the edge
            function collapse() {
                if (phase !== "open") return
                closer.stop()
                lighter.stop()
                drop()
                clearCands()
                phase = "closing"
                Tree.open = false
                retract.restart()
            }
            Timer {
                id: retract
                interval: win.closeStagger
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    if (web.chain.length > 1) {
                        const b = web.chain[web.chain.length - 1], into = web.chain[web.chain.length - 2]
                        b.leaveInto(into.cx, into.cy)
                        into.jiggle(0.14)
                        web.chain = web.chain.slice(0, -1)
                        return
                    }
                    stop()
                    web.finished = false
                    web.query = ""
                    web.said = ""
                    web.restY = web.anchor.y
                    web.phase = "rest"
                }
            }

            // the chain ends on a task: it runs, and the chain lights up from the seed to the
            // task, one circle after another; then it is let go
            function finish() {
                if (finished || chain.length < 2 || !head.node.leaf) return
                finished = true
                head.node.run()
                lighter.next = 1
                lighter.restart()
            }
            Timer {
                id: lighter
                property int next: 1
                interval: win.doneStagger
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    if (next < web.chain.length) {
                        web.chain[next].role = "done"
                        web.chain[next].pulse()
                        next++
                        return
                    }
                    stop()
                    closer.restart()
                }
            }
            Timer {
                id: closer
                interval: win.doneHold
                onTriggered: web.collapse()
            }

            // the circle of `list` under (x, y), or null
            function under(list, x, y) {
                for (const b of list) if (Math.hypot(x - b.cx, y - b.cy) <= b.r + win.reach) return b
                return null
            }

            // (only circles that have reached their place: one still on its way out past the
            // hand is not one you dragged onto)
            function candidateAt(x, y) { return under(cands.filter(c => c.arrived), x, y) }

            // true when (x, y) is on the place of the circle before the last one: the one in
            // the hand was dragged back onto it. (Its place, not where it is: just after a
            // join it is still under the hand, on its way back there)
            function onPrevious(x, y) {
                if (chain.length < 2) return false
                const p = chain[chain.length - 2]
                return Math.hypot(x - p.homeX, y - p.homeY) <= p.r + win.reach
            }

            // ── the keys ── Esc lets it all go (or first clears what was typed); Backspace
            // rubs out a letter, or goes back one; Enter takes the first circle on offer;
            // anything else is typed into a circle that can be searched
            Keys.onPressed: event => {
                if (phase !== "open" || finished) return
                event.accepted = true
                if (event.key === Qt.Key_Escape) {
                    if (query !== "") { query = ""; look(true) }
                    else collapse()
                } else if (event.key === Qt.Key_Backspace) {
                    if (query !== "") { query = query.slice(0, -1); look(true) }
                    else backOne()
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (cands.length > 0 && cands[0].started) connect(cands[0])
                } else if (head.node.search && event.text.length === 1 && event.text >= " " && event.text !== "\x7f") {
                    query += event.text
                    look(true)
                } else {
                    event.accepted = false
                }
            }

            // the screen behind dims while it's open, so the circles stand out (it starts to
            // as the drop is pulled out)
            Rectangle {
                anchors.fill: parent
                color: Colors.scrim
                opacity: web.phase === "open" ? win.dim : web.phase === "pull" ? win.dim * Math.min(1, seed.out / win.pullOut) * 0.6 : 0
                Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            }

            // ── the liquid ── under the circles
            // the seed's neck to the edge: it stretches as the drop is pulled out, and pinches
            // off about where the drop comes free. The body of liquid it is drawn from sits
            // behind the edge, level with the drop, and stays there whatever the pull (it is
            // filled too, so the neck runs into the edge with no gap)
            Goo {
                anchors.fill: parent
                visible: seed.out > 1
                ax: win.width + win.edgeR
                ay: seed.cy
                ar: win.edgeR
                bodyA: true
                bx: seed.cx
                by: seed.cy
                br: seed.r * seed.size
                color: seed.fill
                spread: 0.7
                // the neck lets go as the drop comes free, not after
                snapAt: (win.pullOut + win.edgeR + 4) / (win.edgeR + win.seedR)
            }

            // ── the circles ──
            Item { id: bubbles; anchors.fill: parent }
            Component { id: bubbleC; Bubble {} }
            Component { id: sliderC; Slider {} }

            // the seed: the drop pulled out of the edge, and the first circle of every chain.
            // At rest it waits behind the edge, out of sight; pulled, it follows the hand; free,
            // its place is where it came free, and it follows the hand again while it is held
            Bubble {
                id: seed
                node: ({ label: "", icon: "hub", leaf: false, children: () => Tree.roots() })
                r: win.seedR
                fixedSize: true
                role: web.phase === "open" || web.phase === "closing" ? "chain" : "seed"
                grabbed: web.phase === "pull" || web.grabbed === seed

                // how far out of the edge its middle is
                readonly property real out: win.width + r - cx
                homeX: web.anchor.x
                homeY: web.anchor.y
                toX: web.phase === "pull" ? Math.min(win.width, web.cursorX)
                    : web.phase === "rest" ? win.width + r + 6
                    : web.grabbed === seed ? web.cursorX
                    : web.anchor.x
                toY: web.phase === "pull" || web.grabbed === seed ? web.cursorY
                    : web.phase === "rest" ? web.restY
                    : web.anchor.y
            }

            // where you are, in words: the chain so far, what is being typed, what a task
            // just did. It drops in from the top
            Rectangle {
                readonly property bool shown: web.phase === "open"
                readonly property bool telling: web.finished || web.said !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                y: shown ? 36 : 8
                width: path.implicitWidth + 32
                height: path.implicitHeight + 16
                radius: height / 2
                color: telling ? Colors.tertiary_container : Colors.surface_container_high
                opacity: shown ? 1 : 0
                visible: opacity > 0
                Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                Behavior on opacity { NumberAnimation { duration: 160 } }
                Behavior on color { ColorAnimation { duration: 180 } }
                Text {
                    id: path
                    anchors.centerIn: parent
                    text: {
                        if (web.finished) return Tree.last
                        if (web.said !== "") return web.said
                        if (web.chain.length < 2) return "Drag the drop onto a circle"
                        const n = web.head.node
                        let t = web.chain.slice(1).map(b => b.node.label).join("   →   ")
                        if (n.search) t += "   ·   " + (web.query === "" ? (n.ask || "type to search")
                            : n.secret ? "•".repeat(web.query.length) : web.query)
                        return t
                    }
                    font.pixelSize: 14
                    font.weight: 600
                    color: parent.telling ? Colors.on_tertiary_container : Colors.on_surface
                }
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onPressed: mouse => {
                    web.cursorX = mouse.x
                    web.cursorY = mouse.y
                    web.pressAt = Qt.point(mouse.x, mouse.y)
                    web.moved = false
                    if (web.finished || web.phase === "closing") return

                    // at rest only the edge can be pressed (the mask): a drop starts to come out,
                    // from behind the edge at the height of the press
                    if (web.phase === "rest") {
                        if (mouse.button !== Qt.LeftButton) return
                        web.restY = mouse.y
                        seed.jumpTo(win.width + seed.r + 6, mouse.y)
                        web.phase = "pull"
                        return
                    }

                    // the right button: back one
                    if (mouse.button === Qt.RightButton) { web.backOne(); return }

                    // on a circle of the chain: it is picked up. An earlier one than the last
                    // goes back to it first
                    const b = web.under(web.chain.slice().reverse(), mouse.x, mouse.y)
                    if (b) {
                        web.backTo(web.chain.indexOf(b))
                        web.grab(b)
                        return
                    }

                    // on a circle on offer: nothing joins by a click. The one to drag shows itself
                    if (web.under(web.cands, mouse.x, mouse.y) || (web.slider && !isNaN(web.slider.valueAt(mouse.x, mouse.y)))) {
                        web.head.pulse()
                        web.head.jiggle(0.28)
                        web.say(web.chain.length > 1 ? "Drag " + web.head.node.label + " onto it" : "Drag the drop onto it")
                    }
                }

                onPositionChanged: mouse => {
                    web.cursorX = mouse.x
                    web.cursorY = mouse.y
                    if (pressed && Math.hypot(mouse.x - web.pressAt.x, mouse.y - web.pressAt.y) > win.clickSlop) web.moved = true

                    // pulled far enough: the drop comes free, still in the hand
                    if (web.phase === "pull") {
                        if (pressed && win.width - mouse.x >= win.pullOut) {
                            web.openAt(mouse.x, mouse.y)
                            web.grab(seed)
                        }
                        return
                    }
                    if (web.phase !== "open" || web.finished) return
                    web.follow()

                    // the held circle on the slider's band: where it sits is the level
                    const s = web.slider
                    const v = s && web.grabbed ? s.valueAt(mouse.x, mouse.y) : NaN
                    if (s) s.hot = !isNaN(v)
                    if (!isNaN(v)) { s.slide(v); for (const k of web.cands) k.hot = false; return }

                    const c = web.candidateAt(mouse.x, mouse.y)
                    for (const k of web.cands) k.hot = k === c
                    if (!c) web.spent = false
                    if (!web.grabbed) return

                    // the held circle was dragged onto one on offer: joined; back onto the
                    // place of the one before it: undone, and that one is in the hand again
                    if (c) { if (!web.spent) web.connect(c); return }
                    if (web.onPrevious(mouse.x, mouse.y)) {
                        const i = web.chain.length - 2
                        web.backTo(i)
                        web.grab(web.chain[i])
                    }
                }

                onReleased: mouse => {
                    // let go before it came free: it runs back into the edge
                    if (web.phase === "pull") { web.restY = web.cursorY; web.phase = "rest"; return }
                    if (web.phase !== "open" || web.finished || mouse.button !== Qt.LeftButton) return
                    const b = web.grabbed

                    // let go on the slider: the level stays where it was put
                    if (b && web.slider && web.slider.hot) { web.slider.commit(); web.say(Tree.last) }
                    web.drop()

                    // the seed, clicked or pushed back into the edge: it all runs back in
                    if (b === seed && (!web.moved || win.width - mouse.x <= win.pushIn)) { web.collapse(); return }

                    // a click on the empty screen: back one
                    if (!b && !web.moved && !web.under(web.cands, mouse.x, mouse.y)) web.backOne()
                }
            }
        }
    }

    // the lock screen (hypridle, the Lock circle): Droplet's own
    Lock {}

    // the AI, pulled down out of the top edge (Settings: Ask the AI)
    LazyLoader {
        active: Settings.assistant
        Assistant {}
    }
}

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Droplet's way to ask the local AI. Pull a drop of liquid down out of the middle of the top
// edge (or press Super + A): it stretches, pinches off and spreads into the bar you type in.
// Your words go to ../scripts/assistant/assistant.py (Ollama, with the desktop's commands as
// its tools); what it does drips out of the bar as a second drop that opens into the answer
// card. Esc, a click outside or pushing the bar back up sends it all back into the edge.
// The Settings circle's "Ask the AI" switches it off (shell.qml doesn't load it then).
//
//   qs -p <this folder> ipc call assistant toggle         open / close (Super + A)
//   qs -p <this folder> ipc call assistant ask "<text>"   ask without typing
Scope {
    id: root

    // ── settings ── sizes are px, times ms
    // the strip at the top edge that can be pulled, and the drop that comes out of it
    readonly property real stripWidth: 360
    readonly property real stripHeight: 10
    readonly property real dropR: 22

    // the body of liquid behind the edge (it never swells), and how far down the drop must
    // be pulled to come free (the neck lets go right there), as at Droplet's right edge
    readonly property real edgeR: 60
    readonly property real pullOut: 80

    // the bar it becomes: width (at most this share of the screen), height, and where it rests
    readonly property real barWidth: 620
    readonly property real barShare: 0.6
    readonly property real barHeight: 60
    readonly property real barY: 110

    // the answer card under it: the gap, and the drop it drips out as
    readonly property real cardGap: 18
    readonly property real cardDropR: 14

    readonly property string assistant: Quickshell.shellDir + "/../scripts/assistant/assistant.py"

    // ── state ── "rest" (in the edge), "pull" (held), "open" (the bar), "closing"
    property string phase: "rest"
    property bool busy: false
    property var steps: []           // what it did: [{ icon, text, ok }]
    property string answer: ""
    property bool answerOk: true     // the answer is an answer (false: an error)
    property var confirmStep: null   // { name, args, question }: waiting for a yes
    readonly property bool hasCard: busy || steps.length > 0 || answer !== "" || confirmStep !== null

    // out of the edge (the shortcut's way: the drop comes down by itself)
    function open() {
        if (phase === "open") return
        phase = "open"
    }

    // back into the edge; stops a request still running
    function close() {
        if (phase === "rest" || phase === "closing") return
        if (asker.running) asker.running = false
        busy = false
        phase = "closing"
    }

    // the shortcut
    function toggle() { phase === "open" ? close() : open() }

    // sends the words to assistant.py; its events fill the card as they come
    function ask(text) {
        const t = text.trim()
        if (t === "" || busy) return
        steps = []
        answer = ""
        confirmStep = null
        busy = true
        asker.command = ["python3", assistant, t]
        asker.running = true
    }

    // the answer to a step that asked first: yes runs it (assistant.py --yes), no drops it
    function confirm(yes) {
        const c = confirmStep
        confirmStep = null
        if (!yes || !c) { answer = "Okay, I didn't."; return }
        busy = true
        asker.command = ["python3", assistant, "--yes", c.name, JSON.stringify(c.args)]
        asker.running = true
    }

    // one JSON line per event (assistant.py's docstring)
    function event(e) {
        if (e.type === "tool")
            steps = steps.concat([{ icon: e.ok ? "check" : "error", ok: e.ok,
                                    text: pretty(e.name) + (e.ok ? "" : ": " + e.result) }])
        else if (e.type === "answer") { answerOk = true; answer = e.text }
        else if (e.type === "error") { answerOk = false; answer = e.text }
        else if (e.type === "confirm") confirmStep = e
    }

    // settings_search -> "Settings search"
    function pretty(name) { return name.replace(/_/g, " ").replace(/^./, c => c.toUpperCase()) }

    Process {
        id: asker
        stdout: SplitParser {
            onRead: line => { try { root.event(JSON.parse(line)) } catch (err) {} }
        }
        onExited: root.busy = false
    }

    function begin(text) { open(); input.text = text; input.cursorPosition = text.length }
    // Tree's "Make one" (Automations)
    Connections {
        target: Tree
        function onStartAsk(text) { root.begin(text) }
    }

    IpcHandler {
        target: "assistant"
        function toggle(): void { root.toggle() }
        function open(): void { root.open() }
        function close(): void { root.close() }
        function ask(text: string): void { root.open(); input.text = text; root.ask(text) }
        // opens with the question begun, for you to finish
        function start(text: string): void { root.begin(text) }
    }

    PanelWindow {
        id: win
        screen: Quickshell.screens[0]
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "droplet-assistant"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.phase === "open" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // at rest only the strip in the middle of the top edge takes the mouse
        mask: Region {
            x: root.phase === "rest" ? (win.width - root.stripWidth) / 2 : 0
            width: root.phase === "rest" ? root.stripWidth : win.width
            height: root.phase === "rest" ? root.stripHeight : win.height
        }

        readonly property real cx: width / 2
        readonly property real wideW: Math.min(root.barWidth, width * root.barShare)

        // where the hand is while pulling
        property real handX: cx
        property real handY: 0

        // ── the drop / the bar ── its middle, and its size: a circle until it is free,
        // then it spreads into the bar (and back into a circle before it goes home)
        SpringValue {
            id: dx
            to: root.phase === "pull" ? win.cx + (win.handX - win.cx) * 0.12 : win.cx
            stiffness: 500; dampingRatio: 0.75; epsilon: 0.1
        }
        SpringValue {
            id: dy
            to: root.phase === "pull" ? Math.max(-root.dropR, win.handY - root.dropR)
                : root.phase === "open" ? root.barY + root.barHeight / 2
                : root.phase === "closing" && spread.value > 0.08 ? root.barY + root.barHeight / 2
                : -root.dropR * 1.6
            stiffness: root.phase === "open" ? 260 : 420
            dampingRatio: root.phase === "open" ? 0.62 : 0.8
            epsilon: 0.1
            onValueChanged: if (root.phase === "closing" && value <= -root.dropR * 1.5) root.phase = "rest"
        }
        // 0: a drop, 1: the bar (the expressive spring: it spreads with a little overshoot)
        SpringValue {
            id: spread
            // closing is opening backwards: the bar stays wide until the card is back in it
            to: (root.phase === "open" && dy.value > root.barY - 8) || (root.phase === "closing" && card.t > 0.04) ? 1 : 0
            stiffness: 420; dampingRatio: 0.55; epsilon: 0.002
        }

        readonly property real barW: 2 * root.dropR + (wideW - 2 * root.dropR) * spread.value
        readonly property real barH: 2 * root.dropR + (root.barHeight - 2 * root.dropR) * Math.min(1.1, spread.value)

        // ── the liquid ── the neck from the edge to the drop: it stretches as the drop is
        // pulled and pinches off about where it comes free (and joins again on the way home)
        Goo {
            anchors.fill: parent
            visible: dy.value > -root.dropR && spread.value < 0.3
            ax: dx.value
            ay: -root.edgeR
            ar: root.edgeR
            bodyA: true
            bx: dx.value
            by: dy.value
            br: root.dropR
            color: bar.color
            spread: 0.7
            snapAt: (root.pullOut - root.dropR + root.edgeR + 4) / (root.edgeR + root.dropR)
        }

        // the drop out of the bar's underside into the answer card, the same way
        Goo {
            anchors.fill: parent
            visible: card.t > 0.02 && card.t < 0.75
            ax: dx.value
            ay: bar.y + bar.height - root.cardDropR
            ar: root.cardDropR
            bodyA: true
            bx: dx.value
            by: card.y + Math.min(card.height / 2, root.cardDropR)
            br: root.cardDropR
            color: card.color
            spread: 0.7
            snapAt: 2.2
        }

        Rectangle {
            id: bar
            x: dx.value - width / 2
            y: dy.value - height / 2
            width: win.barW
            height: win.barH
            radius: height / 2
            color: Colors.surface_container_high
            visible: dy.value > -root.dropR * 1.5
            clip: true
            border.width: root.busy || root.waking ? 2 : 1
            antialiasing: true

            // while it thinks, its rim runs through the theme's accents
            property int hue: 0
            border.color: root.busy || root.waking ? [Colors.primary, Colors.tertiary, Colors.secondary][hue] : Colors.outline_variant
            Behavior on border.color { ColorAnimation { duration: 700 } }
            Timer { running: root.busy || root.waking; repeat: true; interval: 700; onTriggered: bar.hue = (bar.hue + 1) % 3 }

            // Droplet itself (the AI is Droplet): it watches the letters, looks up and bobs while it
            // thinks, is glad at an answer and sad at an error. Mascot off: a spinning spark
            Item {
                id: spark
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter
                x: spread.value > 0.5 ? 14 : (parent.width - width) / 2
                Text {
                    anchors.centerIn: parent
                    visible: !Settings.mascot
                    text: "auto_awesome"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 24
                    color: Colors.primary
                    RotationAnimation on rotation { running: root.busy && !Settings.mascot; from: 0; to: 360; duration: 1400; loops: Animation.Infinite }
                }
                Mascot {
                    id: buddy
                    anchors.fill: parent
                    visible: Settings.mascot
                    kind: "droplet"
                    happyColor: Colors.tertiary_container
                    sadColor: Colors.secondary_container
                    angryColor: Colors.error_container
                    body: Colors.primary_container
                    ink: Colors.on_primary_container
                    eyeWhite: Colors.primary_fixed
                    pupil: Colors.on_primary_fixed
                    accent: Colors.primary
                    run: root.busy || root.waking ? 0.7 : 0
                    look: root.busy || root.waking ? Qt.point(0.2, -1)
                        : input.text !== "" ? Qt.point(Math.min(1, input.cursorRectangle.x / Math.max(1, input.width) * 1.6 + 0.2), 0.1)
                        : Qt.point(0, -0.35)
                    Connections {
                        target: input
                        function onTextChanged() { if (root.phase === "open") buddy.react("type") }
                    }
                    Connections {
                        target: root
                        function onAnswerChanged() { if (root.answer !== "") buddy.react(root.answerOk ? "right" : "wrong") }
                    }
                }
            }

            TextInput {
                id: input
                anchors { left: spark.right; leftMargin: 14; right: parent.right; rightMargin: 24; verticalCenter: parent.verticalCenter }
                opacity: root.phase === "open" && spread.value > 0.85 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 140 } }
                enabled: root.phase === "open"
                font.pixelSize: 18
                color: Colors.on_surface
                selectionColor: Colors.primary
                selectedTextColor: Colors.on_primary
                clip: true
                Keys.onReturnPressed: root.ask(text)
                Keys.onEnterPressed: root.ask(text)
                Keys.onEscapePressed: root.close()

                Text {
                    visible: input.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.busy ? "Droplet is on it…" : root.waking ? "Droplet is waking up…" : "Ask Droplet: \"bigger gaps\", \"open Downloads\", \"dark mode\""
                    font: input.font
                    color: Colors.on_surface_variant
                }
            }
        }

        // ── the answer card ── what it did, then what it says (or a question to say yes to)
        Rectangle {
            id: card
            readonly property bool wanted: root.phase === "open" && root.hasCard && spread.value > 0.9
            SpringValue { id: cardT; to: card.wanted ? 1 : 0; stiffness: 380; dampingRatio: 0.62; epsilon: 0.002 }
            readonly property real t: Math.max(0, cardT.value)
            readonly property real fullH: content.implicitHeight + 36

            width: 2 * root.cardDropR + (bar.width - 2 * root.cardDropR) * Math.min(1, t)
            height: 2 * root.cardDropR + (fullH - 2 * root.cardDropR) * Math.min(1, t)
            radius: Math.min(28, height / 2)
            x: dx.value - width / 2
            y: bar.y + bar.height - root.cardDropR * 2 + (root.cardGap + root.cardDropR * 2) * Math.min(1.15, t)
            visible: t > 0.02
            color: Colors.surface_container
            antialiasing: true
            clip: true

            // a click on the card stays on the card (not "outside", which closes)
            MouseArea { anchors.fill: parent }

            Column {
                id: content
                x: 22; y: 18
                width: card.width - 44
                spacing: 10
                opacity: card.wanted && card.t > 0.85 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 90 } }

                Repeater {
                    model: root.steps
                    Row {
                        required property var modelData
                        spacing: 8
                        Text { text: modelData.icon; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: modelData.ok ? Colors.primary : Colors.error }
                        Text { text: modelData.text; font.pixelSize: 14; color: Colors.on_surface_variant; width: content.width - 30; elide: Text.ElideRight }
                    }
                }

                Text {
                    visible: root.busy && root.answer === ""
                    text: root.steps.length ? "…" : "Thinking…"
                    font.pixelSize: 16
                    color: Colors.on_surface_variant
                }

                Text {
                    visible: root.answer !== ""
                    width: content.width
                    text: root.answer
                    wrapMode: Text.Wrap
                    font.pixelSize: 17
                    color: Colors.on_surface
                }

                // a step that asks first (log out, restart, shut down)
                Column {
                    visible: root.confirmStep !== null
                    spacing: 12
                    Text { text: root.confirmStep ? root.confirmStep.question : ""; font.pixelSize: 17; font.weight: 600; color: Colors.on_surface }
                    Row {
                        spacing: 10
                        Repeater {
                            model: [{ label: "Yes", yes: true }, { label: "No", yes: false }]
                            Rectangle {
                                required property var modelData
                                width: label.implicitWidth + 36
                                height: 40
                                radius: 20
                                color: modelData.yes ? (yesMouse.containsMouse ? Colors.error : Colors.error_container)
                                                     : (yesMouse.containsMouse ? Colors.secondary : Colors.secondary_container)
                                Text {
                                    id: label
                                    anchors.centerIn: parent
                                    text: parent.modelData.label
                                    font.pixelSize: 15; font.weight: 600
                                    color: parent.modelData.yes ? (yesMouse.containsMouse ? Colors.on_error : Colors.on_error_container)
                                                                : (yesMouse.containsMouse ? Colors.on_secondary : Colors.on_secondary_container)
                                }
                                MouseArea { id: yesMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.confirm(parent.modelData.yes) }
                            }
                        }
                    }
                }
            }
        }

        // ── the hand ── press the strip and pull down; let go far enough and it comes free.
        // Open: a click outside the bar and card closes, as does pushing the bar back up
        MouseArea {
            anchors.fill: parent
            z: -1
            onPressed: mouse => {
                win.handX = mouse.x
                win.handY = mouse.y
                if (root.phase === "rest") root.phase = "pull"
                else if (root.phase === "open") root.close()
            }
            onPositionChanged: mouse => { win.handX = mouse.x; win.handY = mouse.y }
            onReleased: {
                if (root.phase !== "pull") return
                if (win.handY >= root.pullOut) root.open()
                else root.phase = "closing"
            }
        }

        // the bar can be pushed back up into the edge
        MouseArea {
            x: bar.x; y: bar.y; width: bar.width; height: bar.height
            enabled: root.phase === "open"
            property real fromY: 0
            onPressed: mouse => { fromY = mouse.y; input.forceActiveFocus() }
            onPositionChanged: mouse => { if (mouse.y - fromY < -40) root.close() }
            propagateComposedEvents: true
            onClicked: mouse => { mouse.accepted = false; input.forceActiveFocus() }
        }
    }

    // a new bar is an empty one, with the keys; opening it wakes the model
    onPhaseChanged: {
        if (phase === "open") { input.text = ""; steps = []; answer = ""; confirmStep = null; input.forceActiveFocus(); wake() }
    }

    // ── waking the AI ── assistant.py --warm loads the model into the graphics card as the
    // bar opens (its rim runs through the accents meanwhile, as while it thinks); again only
    // once the last wake is older than Ollama keeps it (15 min)
    property bool waking: false
    property real wokeAt: 0
    function wake() {
        if (waking || Date.now() - wokeAt < 10 * 60 * 1000) return
        waking = true
        waker.running = true
    }
    Process {
        id: waker
        command: ["python3", root.assistant, "--warm"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const e = JSON.parse(line)
                    if (e.type === "ready") root.wokeAt = Date.now()
                    else if (e.type === "error") root.answer = e.text
                } catch (err) {}
            }
        }
        onExited: root.waking = false
    }
}

import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../primitive"
import "../variables.js" as Vars

// The Ask control of the control center: the local AI, on the dial's own parts. With Ask at
// the mark, just type: the words go on the curved bar between the rings (the one Settings
// types values on), Enter asks. ../scripts/assistant/assistant.py does it with the desktop's
// own commands; the card in the middle says what it did, step by step, then its answer.
// The inner ring has a pill per question asked before (ask it again) and a few to try; a
// step that asks first (log out, restart, shut down) puts Yes and No there instead.
// Settings → Extras → Ask the AI hides it. ControlCenter.qml uses `control`.
Item {
    id: ask

    required property var dial
    required property var bar

    // ★ the card's and the dial's sizes while this is selected: controlcenter/ReaderSettings.qml ★
    readonly property var cfg: ReaderSettings { liveSize: ask.dial.expandedSize; sweepDeg: ask.dial.sweepDeg }

    readonly property bool active: dial.open && !!dial.currentControl && dial.currentControl.key === "ask"

    // ── what happened ── the question, the steps done ("Settings search"), the answer, and a
    // step waiting for a yes
    property string question: ""
    property var steps: []
    property string answer: ""
    property var confirmStep: null
    property bool busy: false
    property var history: []

    readonly property string script: Quickshell.shellDir + "/../scripts/assistant/assistant.py"

    function run(args) {
        busy = true
        _asker.command = ["python3", script].concat(args)
        _asker.running = true
    }
    function askNow(text) {
        const t = text.trim()
        if (t === "" || busy) return
        question = t
        steps = []
        answer = ""
        confirmStep = null
        history = [t].concat(history.filter(h => h !== t)).slice(0, 8)
        run([t])
    }
    function confirm(yes) {
        const c = confirmStep
        confirmStep = null
        if (!yes || !c) { answer = "Okay, I didn't."; return }
        run(["--yes", c.name, JSON.stringify(c.args)])
    }

    // one JSON line per event (assistant.py's docstring)
    function event(e) {
        if (e.type === "tool")
            steps = steps.concat([(e.ok ? "✓ " : "✗ ") + e.name.replace(/_/g, " ").replace(/^./, c => c.toUpperCase())])
        else if (e.type === "answer" || e.type === "error") answer = e.text
        else if (e.type === "confirm") confirmStep = e
    }
    property Process _asker: Process {
        stdout: SplitParser { onRead: line => { try { ask.event(JSON.parse(line)) } catch (err) {} } }
        onExited: ask.busy = false
    }

    // ── typing ── on the shared curved bar (ControlCenter.qml routes it here while Ask is at
    // the mark)
    property bool typing: false
    function startTyping(first) {
        if (busy) return
        typing = true
        bar.clear()
        if (first !== undefined) bar.insert(first)
        bar.focusInput()
    }
    function typed(keep) {
        const t = bar.text
        typing = false
        bar.clear()
        if (keep) askNow(t)
        if (dial.open) dial.forceActiveFocus()
    }
    onActiveChanged: if (!active && typing) typed(false)

    // from Super + A (scripts/shell ipc call assistant toggle): the control center opens on Ask,
    // ready to type
    function summon() {
        if (active) { dial.open = false; return }
        dial.showControl("ask")
        startTyping()
    }

    // ── the card in the middle ──
    property Component corner: Component {
        ReaderCard {
            dial: ask.dial
            cfg: ask.cfg
            shape: ask.busy ? "SoftBurst" : ask.confirmStep ? "Arch" : "Circle"
            fill: ask.confirmStep ? Roles.error_container : ask.answer !== "" ? Roles.secondary_container : Roles.surface_container_high
            ink: ask.confirmStep ? Roles.on_error_container : ask.answer !== "" ? Roles.on_secondary_container : Roles.on_surface_variant
            symbol: ask.busy ? "hourglass_top" : ask.confirmStep ? "help" : "auto_awesome"
            note: ask.busy ? "Thinking…" : ask.question
            // the title is one line: the answer goes in the body, which wraps along the card
            title: ask.confirmStep ? ask.confirmStep.question
                : ask.answer !== "" ? (ask.steps.length === 0 ? "Answer" : ask.steps.length + (ask.steps.length === 1 ? " step" : " steps"))
                : ask.busy ? "" : "Ask the local AI"
            body: ask.answer !== "" ? ask.answer + (ask.steps.length > 0 ? "\n" + ask.steps.join("   ") : "")
                : ask.steps.length > 0 ? ask.steps.join("\n")
                : ask.busy ? "" : "Type, then Enter: \"bigger gaps\", \"open Downloads\", \"dark mode\", \"what's playing\"."
        }
    }

    readonly property var suggestions: ["Bigger gaps", "Dark mode", "What's playing?", "Screen time today", "Open Downloads"]

    readonly property var control: ({
        key: "ask",
        label: "Ask",
        icon: "auto_awesome",
        shape: "Sunny",
        shapeSelected: "SoftBurst",
        on: ask.busy,
        toggle: () => ask.startTyping(),
        size: ask.cfg.dialSize,
        dateIcon: false,
        corner: ask.corner,
        settings: ask.cfg.controlCenter,

        // Yes / No while a step waits; else the questions asked before, and ones to try
        devices: () => {
            if (ask.confirmStep) return [
                { label: "Yes", icon: "check", shape: "Circle", on: false, status: "none", activate: () => ask.confirm(true) },
                { label: "No", icon: "close", shape: "Circle", on: false, status: "none", activate: () => ask.confirm(false) }
            ]
            const asked = ask.history.map(h => ({ label: h.slice(0, 40), icon: "history", shape: "Circle", on: false, status: "none", activate: () => ask.askNow(h) }))
            const tries = ask.suggestions.filter(s => ask.history.indexOf(s) < 0)
                .map(s => ({ label: s, icon: "lightbulb", shape: "Circle", on: false, status: "none", activate: () => ask.askNow(s) }))
            return asked.concat(tries)
        }
    })
}

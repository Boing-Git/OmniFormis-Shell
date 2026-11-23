import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../primitive"
import "../variables.js" as Vars

// The Automations control of the control center: runs of steps kept as JSON files in
// ~/.config/automations (../scripts/automate/automate.py, which works in any shell or none).
// The inner ring has a pill per automation (a click runs it; it spins while it runs); the card
// in the middle says the one at the mark: its steps, or how far a run has got. The tile reads
// the files again. The last pill, Make one, opens Ask with "make an automation that " begun;
// or put a file in the folder.
// Settings → Extras → Automations hides it. ControlCenter.qml uses `control`.
Item {
    id: auto

    required property var dial

    // ★ the card's and the dial's sizes while this is selected: controlcenter/ReaderSettings.qml ★
    readonly property var cfg: ReaderSettings { liveSize: auto.dial.expandedSize; sweepDeg: auto.dial.sweepDeg }

    readonly property bool active: dial.open && !!dial.currentControl && dial.currentControl.key === "automations"
    onActiveChanged: if (active) _lister.running = true

    readonly property string script: Quickshell.shellDir + "/../scripts/automate/automate.py"

    // [{ id, name, icon, steps, ok, says: [what each step does] }]
    property var list: []
    property Process _lister: Process {
        command: ["python3", auto.script, "list", "--json"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { auto.list = JSON.parse(text) } catch (e) {} } }
    }

    // ── a run ── one at a time: which, the step it's on (of how many) and what it does, and
    // how it ended ("" while running or before)
    property string runningId: ""
    property int step: 0
    property int of: 0
    property string doing: ""
    property string ended: ""
    property string endedId: ""
    function start(id) {
        if (runningId !== "") return
        runningId = id
        endedId = ""
        ended = ""
        step = 0
        doing = "Starting"
        // in a session of its own: a run outlives this shell restarting (it carries on unheard)
        _runner.command = ["setsid", "-w", "python3", script, "run", id]
        _runner.running = true
    }
    property Process _runner: Process {
        stdout: SplitParser {
            onRead: line => {
                try {
                    const e = JSON.parse(line)
                    if (e.doing !== undefined) { auto.step = e.step; auto.of = e.of; auto.doing = e.doing }
                    else if (e.done !== undefined) auto.ended = e.done ? "Done" : (e.error || "It stopped")
                } catch (err) {}
            }
        }
        onExited: {
            auto.endedId = auto.runningId
            if (auto.ended === "") auto.ended = "It stopped"
            auto.runningId = ""
        }
    }

    // "Make one" (the last pill): ControlCenter.qml opens Ask with the question begun
    signal makeOne()

    readonly property var atMark: active ? (list[dial.innerIndex] || null) : null
    readonly property bool atMakeOne: active && Prefs.assistant && dial.innerIndex === list.length

    property Component corner: Component {
        ReaderCard {
            dial: auto.dial
            cfg: auto.cfg
            readonly property var a: auto.atMark
            readonly property bool running: !!a && auto.runningId === a.id
            readonly property bool finished: !!a && auto.endedId === a.id
            shape: running ? "SoftBurst" : a ? "Sunny" : "Circle"
            fill: finished && auto.ended !== "Done" ? Roles.error_container : a ? Roles.tertiary_container : Roles.surface_container_high
            ink: finished && auto.ended !== "Done" ? Roles.on_error_container : a ? Roles.on_tertiary_container : Roles.on_surface_variant
            symbol: running ? "hourglass_top" : a ? (a.icon || "bolt") : auto.atMakeOne ? "auto_awesome" : "bolt"
            note: running ? "Step " + auto.step + " of " + auto.of : finished ? auto.ended : a ? a.steps + (a.steps === 1 ? " step" : " steps") : ""
            title: a ? a.name : auto.atMakeOne ? "Make one" : "Automations"
            body: running ? auto.doing
                : a ? (a.ok ? a.says.join("\n") : "Something in its file is wrong: automate.py check " + a.id)
                : auto.atMakeOne ? "Click, then tell the AI what it should do: \"make an automation that opens Spotify and plays\". It shows up here."
                : auto.list.length === 0 ? "None yet. Ask the AI: \"make an automation that opens Spotify and plays\", or put one in ~/.config/automations."
                : "Turn to one; a click runs it."
        }
    }

    readonly property var control: ({
        key: "automations",
        label: "Automations",
        icon: "bolt",
        shape: "Gem",
        shapeSelected: "SoftBurst",

        // on while one runs; the tile reads the files again
        on: auto.runningId !== "",
        toggle: () => { auto._lister.running = true },
        size: auto.cfg.dialSize,
        dateIcon: false,
        corner: auto.corner,
        settings: auto.cfg.controlCenter,

        // a pill per automation: a click runs it
        devices: () => auto.list.map(a => ({
            label: a.name,
            icon: a.icon || "bolt",
            shape: "Circle",
            on: auto.endedId === a.id && auto.ended === "Done",
            status: auto.runningId === a.id ? "loading" : "none",
            activate: () => auto.start(a.id)
        })).concat(Prefs.assistant ? [{
            label: "Make one",
            icon: "auto_awesome",
            shape: "Circle",
            on: false,
            status: "none",
            activate: () => auto.makeOne()
        }] : [])
    })
}

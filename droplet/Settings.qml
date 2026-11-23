pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Droplet's settings: an on / off per feature, kept in ~/.local/state/droplet/settings.json
// (Tree.qml shows them as the Settings circle, each a task that flips it). Screen time is the
// one switch every shell shares (scripts/screentime.py on | off), so it is read from there.
Singleton {
    id: root

    property bool assistant: true   // the AI: pull a drop down out of the top edge (Super + A)
    property bool mascot: true      // Droplet's mascot, hiding in plain sight
    property bool screenTime: true  // the Screen time circle, and the tracking itself

    // what the Settings circle lists
    readonly property var all: [
        { key: "assistant", label: "Ask the AI", icon: "auto_awesome" },
        { key: "mascot", label: "Mascot", icon: "water_drop" },
        { key: "screenTime", label: "Screen time", icon: "hourglass_top" }
    ]

    function toggle(key) {
        root[key] = !root[key]
        if (key === "screenTime") Quickshell.execDetached([screenTimeScript, root.screenTime ? "on" : "off"])
        else _write()
    }

    readonly property string screenTimeScript: Quickshell.shellDir + "/../scripts/screentime.py"
    readonly property string path: Quickshell.env("HOME") + "/.local/state/droplet/settings.json"

    FileView {
        path: root.path
        printErrors: false
        blockLoading: true
        onLoaded: {
            try {
                const o = JSON.parse(text())
                if (typeof o.assistant === "boolean") root.assistant = o.assistant
                if (typeof o.mascot === "boolean") root.mascot = o.mascot
            } catch (e) { /* none yet, or broken: the defaults */ }
        }
    }
    Process {
        running: true
        command: [root.screenTimeScript, "status"]
        stdout: StdioCollector { onStreamFinished: root.screenTime = text.trim() !== "off" }
    }

    // to a temp file first, then renamed over the real one
    Process { id: writer }
    function _write() {
        writer.exec(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s\\n" "$2" > "$1.tmp" && mv "$1.tmp" "$1"',
                     "sh", root.path, JSON.stringify({ assistant: root.assistant, mascot: root.mascot }, null, 2)])
    }
}

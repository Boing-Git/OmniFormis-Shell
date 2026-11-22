pragma Singleton
import QtQuick
import Quickshell.Io
import "primitive"
import "variables.js" as Vars

// The shell's first-contact hints: which ones have been shown how often (remembered in
// Vars.hintsPath), and their words. A hint is shown Prefs.hintTimes times, so the drags
// get taught without the shell nagging; after that it comes back once whenever its
// gesture went unused for Prefs.hintRemindDays days, so a rare gesture isn't forgotten by
// the time it's needed.
//
//   if (Hints.wants("edit")) { show(Hints.text("edit")); Hints.shown("edit") }
//   Hints.used("device")          // the gesture was done: no reminder needed for a while
QtObject {
    id: root

    // hint key → the line shown. Keep each one short: it's read mid-gesture
    readonly property var texts: ({
        edit: "Drag a pill onto a corner or edge to move that dial there  ·  Drag a tile along the ring to reorder  ·  Done when you're finished",
        dial: "Drop it on a lit spot  ·  Dropping on another dial swaps the two",
        tile: "Drop it on another tile to move it there",
        screenshot: "Drop it on a window to capture just that window  ·  Anywhere else gives you a box to adjust",
        device: "Drop it on Media to play through it  ·  Flick it away to dismiss it",
        network: "Flick it away to disconnect",
        knob: "Pull past the end for a nudge  ·  Let go past 0% to mute",
        app: "Drop it on a workspace to open it there  ·  On another app to move it",
        notify: "Flick it away to dismiss it",
        notifyCenter: "Scroll the tick ring for an app's other messages  ·  Flick its pill away to clear them",
        reach: "Pull further out while you turn: the further, the finer",
        settings: "Scroll the tick ring to change it  ·  Click to switch or type  ·  Right-click puts it back",
        shortcut: "Click, then press the new keys  ·  Esc cancels  ·  Backspace turns it off",
        tour: "(the first-run tour: Onboarding.qml)"
    })

    function text(key) { return texts[key] || "" }

    // key → how many times it has been shown
    property var seen: ({})

    function wants(key) {
        if (!texts[key]) return false
        if (Prefs.hintTimes > 0 && (seen[key] || 0) < Prefs.hintTimes) return true
        return due(key)
    }

    // key → when its gesture was last done, or its hint last shown (ms since 1970). Kept
    // in the same file under "@touched"
    property var touched: ({})

    // true when the gesture went unused (and its hint unshown) for hintRemindDays days.
    // A gesture met for the first time starts counting from now
    function due(key) {
        if (Prefs.hintRemindDays <= 0 || key === "tour") return false
        const t = touched[key]
        if (t === undefined) { touch(key, Date.now()); return false }
        return Date.now() - t > Prefs.hintRemindDays * 86400000
    }

    function touch(key, when) {
        const next = Object.assign({}, touched)
        next[key] = when
        touched = next
        save()
    }

    function shown(key) {
        const next = Object.assign({}, seen)
        next[key] = (next[key] || 0) + 1
        seen = next
        touch(key, Date.now())
    }

    // the gesture `key` teaches was just done: its reminder starts counting again (written
    // at most once an hour, so a knob pulled ten times isn't ten file writes)
    function used(key) {
        if (!texts[key]) return
        if (Date.now() - (touched[key] || 0) > 3600000) touch(key, Date.now())
    }

    // every gesture's hint is due once more (the Help pill: "teach me again")
    function revive() {
        const next = {}
        for (const k in texts) if (k !== "tour") next[k] = 0
        touched = next
        save()
    }

    // every hint shows again
    function reset() {
        seen = {}
        touched = {}
        save()
    }

    property FileView _file: FileView {
        path: Vars.hintsPath
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const o = JSON.parse(text())
                if (o && typeof o === "object") {
                    const t = o["@touched"]
                    root.touched = t && typeof t === "object" ? t : {}
                    delete o["@touched"]
                    root.seen = o
                }
            } catch (e) { /* empty or broken: every hint is new */ }
        }
    }

    property Process _writer: Process {}
    function save() {
        _writer.exec(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s\\n" "$2" > "$1"',
                      "sh", Vars.hintsPath, JSON.stringify(Object.assign({}, seen, { "@touched": touched }))])
    }

    // qs -p <this folder> ipc call hints reset
    property IpcHandler _ipc: IpcHandler {
        target: "hints"
        function reset(): void { root.reset() }

        // replays the first-run tour (Onboarding.qml)
        function tour(): void { if (Dials.onboarding) Dials.onboarding.begin() }

        // jumps the tour to step n (1-based), e.g. to look at one card; ends it
        function tourStep(n: int): void { if (Dials.onboarding) { if (!Dials.onboarding.shown) Dials.onboarding.begin(); Dials.onboarding.step = Math.max(0, n - 1) } }
        function tourEnd(): void { if (Dials.onboarding) Dials.onboarding.finish() }
    }
}

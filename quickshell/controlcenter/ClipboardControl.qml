import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../primitive"
import "../variables.js" as Vars

// The Clipboard control of the control center: what you copied (cliphist, fed by
// hypr/modules/autostart.lua through scripts/clip-store.sh), newest first, with the ones you
// pinned before them. The tile pauses and resumes keeping copies; the inner ring has a pill
// per copy, a text or a picture; the middle of the dial shows the one at the mark, whole.
// Copies a password manager marks sensitive are never kept (cliphist skips them).
// ControlCenter.qml uses `control`.
//
//   copy pill    click / Enter: back on the clipboard (Ctrl + V pastes it)
//                right-click / Delete: pin it (kept, first, until unpinned), or unpin
//                pull it off the ring and flick it away: forget it
//   Clear all    forgets every copy that isn't pinned
Item {
    id: board

    required property var dial

    // ★ the card's and the dial's sizes while this is selected: controlcenter/ReaderSettings.qml ★
    readonly property var cfg: ReaderSettings { liveSize: board.dial.expandedSize; sweepDeg: board.dial.sweepDeg }

    readonly property bool active: dial.open && !!dial.currentControl && dial.currentControl.key === "clipboard"
    onActiveChanged: if (active) refresh()

    // ── the copies ── [{ id, text, image, size }] newest first, as cliphist lists them (its
    // preview: the first line, up to 100 letters; a picture as "[[ binary data … ]]")
    property var copies: []
    function refresh() { _lister.running = true }
    property Process _lister: Process {
        command: ["sh", "-c", "cliphist list | head -n " + Vars.clipboard.shown]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t")
                    if (tab < 1) continue
                    const id = line.slice(0, tab), preview = line.slice(tab + 1)
                    const pic = /^\[\[ binary data (.+?) (png|jpeg|jpg|webp|gif|bmp) (\d+x\d+) \]\]$/.exec(preview)
                    out.push(pic ? { id: id, text: "", image: pic[2], size: pic[3] + " · " + pic[1] } : { id: id, text: preview, image: "", size: "" })
                }
                board.copies = out
            }
        }
    }

    // ── the pinned ones ── kept by the shell (cliphist forgets the oldest past its limit):
    // [{ text }] or [{ image: a file in Vars.clipboard.pinsDir }], in the order pinned
    property var pins: []
    property FileView _pinsFile: FileView {
        path: Vars.clipboard.pinsDir + "/pins.json"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { const o = JSON.parse(text()); if (Array.isArray(o)) board.pins = o } catch (e) {} }
    }
    function _savePins(list) {
        pins = list
        _run.exec(["sh", "-c", 'mkdir -p "$1" && printf "%s\\n" "$2" > "$1/pins.json.tmp" && mv "$1/pins.json.tmp" "$1/pins.json"',
                   "sh", Vars.clipboard.pinsDir, JSON.stringify(list, null, 2)])
    }

    // everything on the ring: the pins first, then the copies not pinned already
    readonly property var entries: pins.map((p, i) => ({ pin: i, id: "", text: p.text || "", image: p.image ? "png" : "", file: p.image || "", size: p.size || "" }))
        .concat(copies.filter(c => !pins.some(p => (p.text && p.text === c.text) || (p.source && p.source === c.id))).map(c => Object.assign({ pin: -1, file: "" }, c)))
    readonly property var entry: active ? (entries[dial.innerIndex] || null) : null

    // ── the one at the mark, whole ── its full text, or its picture as a file (cached by id)
    property string fullText: ""
    property string pictureFile: ""
    readonly property string entryKey: entry ? (entry.pin >= 0 ? "pin" + entry.pin : entry.id) : ""
    onEntryKeyChanged: _show()
    function _show() {
        fullText = entry && entry.pin >= 0 ? entry.text : ""
        pictureFile = entry && entry.file !== "" ? entry.file : ""
        if (!entry || entry.pin >= 0) return
        if (entry.image !== "") {
            const f = Vars.clipboard.cacheDir + "/" + entry.id + "." + entry.image
            _decoder.target = f
            _decoder.exec(["sh", "-c", 'mkdir -p "$(dirname "$2")" && { test -s "$2" || cliphist decode "$1" > "$2"; }', "sh", entry.id, f])
        } else {
            _texter.exec(["cliphist", "decode", entry.id])
        }
    }
    property Process _decoder: Process {
        property string target: ""
        onExited: code => { if (code === 0) board.pictureFile = target }
    }
    property Process _texter: Process {
        stdout: StdioCollector { onStreamFinished: board.fullText = text }
    }

    // ── doing things ──
    property Process _run: Process { onExited: board.refresh() }

    // back on the clipboard; the card says so for a moment
    function copy(e) {
        if (!e) return
        if (e.pin >= 0) _run.exec(e.file !== "" ? ["sh", "-c", 'wl-copy < "$1"', "sh", e.file] : ["wl-copy", "--", e.text])
        else _run.exec(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", e.id])
        copied.restart()
    }
    Timer { id: copied; interval: 1400 }

    function forget(e) {
        if (!e) return
        if (e.pin >= 0) { _savePins(pins.filter((p, i) => i !== e.pin)); return }
        _run.exec(["sh", "-c", "cliphist list | awk -F '\\t' -v id=\"$1\" '$1 == id' | cliphist delete", "sh", e.id])
    }

    // a pin keeps the text itself, or a copy of the picture (cliphist may forget its own)
    function togglePin(e) {
        if (!e) return
        if (e.pin >= 0) { _savePins(pins.filter((p, i) => i !== e.pin)); return }
        if (e.image === "") { _savePins(pins.concat([{ text: board.fullText || e.text, source: e.id }])); return }
        const f = Vars.clipboard.pinsDir + "/" + Date.now() + "." + e.image
        _savePins(pins.concat([{ image: f, size: e.size, source: e.id }]))
        _run.exec(["sh", "-c", 'mkdir -p "$(dirname "$2")" && cliphist decode "$1" > "$2"', "sh", e.id, f])
    }

    // ── keeping copies at all ── (the flag scripts/clip-store.sh checks)
    readonly property string pauseFlag: Quickshell.env("XDG_STATE_HOME") ? Quickshell.env("XDG_STATE_HOME") + "/clipboard-paused"
        : Quickshell.env("HOME") + "/.local/state/clipboard-paused"
    property bool paused: false
    property Process _pauseCheck: Process {
        running: true
        command: ["test", "-e", board.pauseFlag]
        onExited: code => board.paused = code === 0
    }
    function togglePause() {
        paused = !paused
        _run.exec(paused ? ["sh", "-c", 'mkdir -p "$(dirname "$1")" && touch "$1"', "sh", pauseFlag] : ["rm", "-f", pauseFlag])
    }

    // ── the card in the middle ──
    property Component corner: Component {
        ReaderCard {
            dial: board.dial
            cfg: board.cfg
            readonly property var e: board.entry
            shape: !e ? "Circle" : e.pin >= 0 ? "Arch" : e.image !== "" ? "Square" : "Circle"
            fill: !e ? Roles.surface_container_high : e.pin >= 0 ? Roles.tertiary_container : Roles.secondary_container
            ink: !e ? Roles.on_surface_variant : e.pin >= 0 ? Roles.on_tertiary_container : Roles.on_secondary_container
            image: board.pictureFile !== "" ? "file://" + board.pictureFile : ""
            symbol: !e ? (board.paused ? "content_paste_off" : "content_paste") : e.pin >= 0 ? "push_pin" : e.image !== "" ? "image" : "content_paste"
            note: copied.running ? "Copied: Ctrl + V pastes it" : !e ? "" : (e.pin >= 0 ? "Pinned" : e.image !== "" ? "Picture" : "Text")
                + (e && e.size !== "" ? "  ·  " + e.size : "")
            title: !e ? (board.paused ? "Not keeping copies" : "Nothing copied yet")
                : e.image !== "" ? "Picture" : (board.fullText || e.text).split("\n")[0]
            body: !e ? (board.paused ? "The tile turns it back on." : "Copy something and it shows up here.")
                : e.image !== "" ? "" : (board.fullText || e.text).split("\n").slice(1).join("\n")
        }
    }

    readonly property var control: ({
        key: "clipboard",
        label: "Clipboard",
        icon: board.paused ? "content_paste_off" : "content_paste",
        shape: "Square",
        shapeSelected: "SoftBurst",

        // on = copies are kept; the tile pauses keeping them
        on: !board.paused,
        toggle: () => board.togglePause(),
        size: board.cfg.dialSize,
        dateIcon: false,
        // nothing kept: no card (the inner ring says so)
        corner: board.entries.length > 0 ? board.corner : null,
        settings: board.cfg.controlCenter,

        // a pill per copy, pinned first, then Clear all
        devices: () => {
            // nothing kept: one pill that says so (paused: a click keeps copies again)
            if (board.entries.length === 0) return [board.paused
                ? { label: "Paused", icon: "content_paste_off", shape: "Circle", on: false, status: "none", activate: () => board.togglePause() }
                : { label: "No copies", icon: "content_paste", shape: "Circle", on: false, status: "none", activate: () => {} }]
            const pills = board.entries.map(e => ({
                label: e.image !== "" ? "Picture" : e.text.slice(0, 40),
                icon: e.pin >= 0 ? "push_pin" : e.image !== "" ? "image" : "notes",
                shape: "Circle",
                on: false,
                status: "none",
                activate: () => board.copy(e),
                secondary: () => board.togglePin(e),
                drag: "device",
                fling: () => board.forget(e)
            }))
            if (board.copies.length === 0) return pills
            return pills.concat([{
                label: "Clear all", icon: "clear_all", shape: "Circle", on: false, status: "none", badgeIcon: "delete_sweep",
                activate: () => board._run.exec(["cliphist", "wipe"])
            }])
        }
    })
}

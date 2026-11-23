pragma Singleton
import QtQuick
import Quickshell.Io
import "../variables.js" as Vars

// Settings → Advanced: every plain setting of the settings files, live (the media player, the
// control center's parts, the screenshot tool, the lock screen).
//
// What a setting is comes from its file, so nothing is listed twice: a plain
// `property real|int|bool|string` is one (a `readonly property` is worked out from them and
// follows by itself), the comment right above it is its help, and a `// ── section ──` line
// starts its group. A change goes to every instance of that file at once (the media's copy of
// the control center's settings too), is saved in Vars.advancedPath and is put back on each
// instance as it starts: each settings file calls adopt(this, "<its type>").
//
//   qs ipc call advanced set ControlCenterSettings knobGemSize 48     (get, reset, resetAll)
QtObject {
    id: root

    // the files, in the order the Settings control shows them
    readonly property var files: [
        { type: "ControlCenterSettings", label: "Control center", path: "controlcenter/ControlCenterSettings.qml", icon: "radio_button_checked" },
        { type: "MediaSettings", label: "Media", path: "controlcenter/MediaSettings.qml", icon: "music_note" },
        { type: "ArrangeSettings", label: "Arrange", path: "controlcenter/ArrangeSettings.qml", icon: "open_with" },
        { type: "ReaderSettings", label: "Reader card", path: "controlcenter/ReaderSettings.qml", icon: "article" },
        { type: "ScreenshotSettings", label: "Screenshot", path: "screenshot/ScreenshotSettings.qml", icon: "screenshot" },
        { type: "LockSettings", label: "Lock screen", path: "lock/LockSettings.qml", icon: "lock" }
    ]

    // type → [{ key, kind: "number" | "bool" | "text", int, section, help }], from the files
    property var schema: ({})

    // goes up on every change (bindings that read through valueOf follow it)
    property int revision: 0

    // the changes: { type: { key: value } }
    property var _stored: ({})

    // type → [{ obj, defaults }]: every live instance, with its own values from before any change
    property var _live: ({})

    function adopt(obj, type) {
        const defaults = {}
        for (const k of Object.keys(obj)) {
            const v = obj[k]
            if (typeof v === "number" || typeof v === "boolean" || typeof v === "string") defaults[k] = v
        }
        if (!_live[type]) _live[type] = []
        _live[type].push({ obj: obj, defaults: defaults })
        const s = _stored[type] || {}
        for (const k in s) _put(obj, k, s[k])
    }
    function release(obj, type) {
        if (_live[type]) _live[type] = _live[type].filter(l => l.obj !== obj)
    }
    function _put(obj, key, value) {
        try { obj[key] = value } catch (e) { console.warn("Advanced:", key, e) }
    }

    function entry(type, key) { return (schema[type] || []).find(e => e.key === key) || null }
    function valueOf(type, key) {
        revision
        const l = (_live[type] || [])[0]
        return l ? l.obj[key] : undefined
    }
    function defaultOf(type, key) {
        const l = (_live[type] || [])[0]
        return l ? l.defaults[key] : undefined
    }
    function isChanged(type, key) { revision; return !!_stored[type] && key in _stored[type] }

    // a number's range and step, from its own value: ms and px in whole steps, shares in
    // hundredths. shortcut: guessed from the value, not declared; declare ranges in the files if one is wrong
    function rangeOf(type, key) {
        const e = entry(type, key), d = Number(defaultOf(type, key)) || 0, m = Math.abs(d)
        const step = e && e.int ? (m >= 100 ? 10 : 1) : m >= 10 ? 1 : m >= 1 ? 0.1 : 0.01
        return [d < 0 ? d * 3 : 0, Math.max(d < 0 ? 0 : d * 3, e && e.int ? 10 : 1), step]
    }

    // "" when it worked, or why not
    function set(type, key, given) {
        const e = entry(type, key)
        if (!e) return "unknown setting '" + type + "." + key + "'"
        let v = given
        if (e.kind === "number") {
            v = Number(String(given).trim())
            if (String(given).trim() === "" || !isFinite(v)) return "'" + key + "' is a number"
            if (e.int) v = Math.round(v)
        } else if (e.kind === "bool") {
            const t = String(given).trim().toLowerCase()
            v = typeof given === "boolean" ? given : ["true", "1", "on", "yes"].indexOf(t) >= 0
        } else {
            v = String(given).trim()
            if (["undefined", "null", "NaN", ""].indexOf(v) >= 0 || /[\n\r"\\]/.test(v)) return "'" + key + "' can't be '" + v + "'"
        }
        if (!_stored[type]) _stored[type] = {}
        _stored[type][key] = v
        for (const l of _live[type] || []) _put(l.obj, key, v)
        revision++
        _save()
        return ""
    }

    // back to the file's value. shortcut: a value that was bound to something comes back as the value it had at start; the binding returns with the next reload
    function reset(type, key) {
        if (!_stored[type] || !(key in _stored[type])) return ""
        delete _stored[type][key]
        for (const l of _live[type] || []) if (key in l.defaults) _put(l.obj, key, l.defaults[key])
        revision++
        _save()
        return ""
    }
    function resetAll(type) { for (const k of Object.keys(_stored[type] || {})) reset(type, k) }

    // ── reading the files ──
    property Process _reader: Process {
        running: true
        command: ["sh", "-c", 'cd "$1" && shift && for f; do echo "@@FILE $f"; cat "$f"; done', "sh",
                  Qt.resolvedUrl("..").toString().replace(/^file:\/\//, "")].concat(root.files.map(f => f.path))
        stdout: StdioCollector { onStreamFinished: root.schema = root._parse(text) }
    }
    function _parse(text) {
        const out = {}
        let type = null, section = "", comment = []
        for (const line of text.split("\n")) {
            const f = /^@@FILE (.+)$/.exec(line)
            if (f) {
                const file = files.find(x => x.path === f[1])
                type = file ? file.type : null
                if (type) out[type] = []
                section = ""
                comment = []
                continue
            }
            if (!type) continue

            // "// ── the outer ring (the control tiles) ── ..." → "Outer ring"
            const sec = /^\s*\/\/\s*──\s*(.+?)\s*(──|$)/.exec(line)
            if (sec) {
                const s = sec[1].replace(/\(.*$/, "").replace(/^the /, "").trim()
                section = s.charAt(0).toUpperCase() + s.slice(1)
                comment = []
                continue
            }
            const c = /^\s*\/\/\s?(.*)$/.exec(line)
            if (c) { comment.push(c[1]); continue }
            const p = /^\s*property\s+(real|int|bool|string)\s+(\w+)\s*:/.exec(line)
            if (p && section.toLowerCase() !== "worked out")
                out[type].push({ key: p[2], kind: p[1] === "bool" ? "bool" : p[1] === "string" ? "text" : "number",
                                 int: p[1] === "int", section: section || "General", help: comment.join(" ").trim() })

            // a comment explains only the line right under it
            comment = []
        }
        return out
    }

    // ── remembering ── (written to a temp file and renamed, as Prefs does)
    property FileView _file: FileView {
        path: Vars.advancedPath
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const o = JSON.parse(text())
                if (!o || typeof o !== "object") return
                root._stored = o
                for (const type in o) for (const l of root._live[type] || []) for (const k in o[type]) root._put(l.obj, k, o[type][k])
                root.revision++
            } catch (e) { /* empty or broken: keep what we have */ }
        }
    }
    property Timer _saveTimer: Timer { interval: 250; onTriggered: root._write() }
    function _save() { _saveTimer.restart() }
    property Process _writer: Process {}
    function _write() {
        _writer.exec(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s\\n" "$2" > "$1.tmp" && mv "$1.tmp" "$1"',
                      "sh", Vars.advancedPath, JSON.stringify(_stored, null, 2)])
    }

    property IpcHandler _ipc: IpcHandler {
        target: "advanced"
        function list(): string {
            const out = []
            for (const f of root.files) for (const e of root.schema[f.type] || [])
                out.push(f.type + " " + e.key + " = " + root.valueOf(f.type, e.key) + (root.isChanged(f.type, e.key) ? "  (changed)" : ""))
            return out.join("\n")
        }
        function get(type: string, key: string): string { return String(root.valueOf(type, key)) }
        function set(type: string, key: string, value: string): string { const r = root.set(type, key, value); return r === "" ? "ok" : "Error: " + r }
        function reset(type: string, key: string): string { return root.reset(type, key) || "ok" }
        function resetAll(type: string): void { root.resetAll(type) }
    }
}

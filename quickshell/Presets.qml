pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "primitive"
import "variables.js" as Vars

// Presets: everything you set, kept under a name, and put back in one go. A preset holds the
// full value of every setting at the time it was saved (Settings, Advanced, where the dials
// live, the wallpaper with its scheme and source, Hyprland's variables), so applying it
// restores exactly that; a setting newer than the preset goes back to its default. One JSON
// file per preset in Vars.presetsPath, so they can be copied, shared or kept in git
// (import / export is copying the file in or out of that folder). Applying first saves the
// way things were as "Before last apply": applying that is the undo.
//
//   qs ipc call preset list | save <name> | apply <name> | undo | remove <name>
//   qs ipc call preset rename <from> <to> | duplicate <from> <to> | folder
Singleton {
    id: root

    readonly property string undoName: "Before last apply"

    // [{ id, name, description, created, modified, settings }], by name
    property var list: []

    // the last one applied ("" before any)
    property string current: ""

    function idOf(name) { return String(name).trim().toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "preset" }
    function find(name) { return list.find(p => p.name === name || p.id === idOf(name)) || null }

    // ── what a preset holds ── every value as it is now; Hyprland's through omniformis
    // (asked for once per save, then the preset is written)
    function _capture(hypr) {
        const prefs = {}
        for (const e of Prefs.schema) if (!e.preset) prefs[e.key] = Prefs.valueOf(e.key)
        const advanced = {}
        for (const f of Advanced.files) {
            advanced[f.type] = {}
            for (const e of Advanced.schema[f.type] || []) advanced[f.type][e.key] = Advanced.valueOf(f.type, e.key)
        }
        return { prefs: prefs, advanced: advanced, positions: Object.assign({}, Dials.moved),
                 wallpaper: Backdrop.wallpaper, hyprland: hypr }
    }

    // "" when it worked, or why not (the file is written a moment later)
    function save(name, description) {
        const n = String(name || "").trim()
        if (n === "" || /[\n\r"\\\/]/.test(n)) return "a preset needs a name (no quotes, slashes or new lines)"
        _pendingSave = { name: n, description: description || "" }
        _hyprReader.running = true
        return ""
    }
    property var _pendingSave: null
    property Process _hyprReader: Process {
        command: ["omniformis", "hypr", "list", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                const hypr = {}
                try { for (const v of JSON.parse(text)) hypr[v.key] = v.value } catch (e) { /* no omniformis: the preset holds no Hyprland values */ }
                const p = root._pendingSave
                root._pendingSave = null
                if (p) root._write(p.name, p.description, root._capture(hypr))
            }
        }
    }

    function _write(name, description, settings) {
        const old = find(name), now = new Date().toISOString()
        const p = { schema_version: 1, id: idOf(name), name: name, description: description || (old ? old.description : ""),
                    created: old ? old.created : now, modified: now, settings: settings }
        _files.exec(["sh", "-c", 'mkdir -p "$1" && printf "%s\\n" "$3" > "$1/$2.json.tmp" && mv "$1/$2.json.tmp" "$1/$2.json"',
                     "sh", Vars.presetsPath, p.id, JSON.stringify(p, null, 2)])
    }

    // ── applying ── each part through its own checks (Prefs.set, Advanced.set): a value a
    // setting no longer takes is skipped, not forced
    function apply(name) {
        const p = find(name)
        if (!p) return "no preset called '" + name + "'"
        if (p.name !== undoName) _write(undoName, "The way things were before the last preset was applied.", _capture(_hyprNow))
        const s = p.settings || {}
        for (const e of Prefs.schema) {
            if (e.preset) continue
            if (s.prefs && e.key in s.prefs) Prefs.set(e.key, s.prefs[e.key])
            else Prefs.reset(e.key)
        }
        for (const f of Advanced.files) for (const e of Advanced.schema[f.type] || []) {
            const v = s.advanced && s.advanced[f.type] ? s.advanced[f.type][e.key] : undefined
            if (v !== undefined && v !== Advanced.defaultOf(f.type, e.key)) Advanced.set(f.type, e.key, v)
            else Advanced.reset(f.type, e.key)
        }
        if (s.positions) { Dials.moved = s.positions; Dials.save() }
        if (s.wallpaper && s.wallpaper !== Backdrop.wallpaper) {
            Quickshell.execDetached(["awww", "img", s.wallpaper, "--transition-type", "grow"])
            if (Dials.dials.wallpaper) Dials.dials.wallpaper.currentPath = s.wallpaper
            Prefs.applyTheme(s.wallpaper)
        }
        if (s.hyprland) {
            // only what differs: each change reloads Hyprland once
            const args = []
            for (const k in s.hyprland) if (k in _hyprNow && String(_hyprNow[k]) !== String(s.hyprland[k])) args.push(k, String(s.hyprland[k]))
            if (args.length > 0) _hyprWriter.exec(["sh", "-c", 'while [ $# -gt 1 ]; do OMNIFORMIS_NO_SIDE_EFFECTS=1 omniformis hypr set "$1" "$2"; shift 2; done', "sh"].concat(args))
        }
        current = p.name
        return ""
    }
    function undo() { return apply(undoName) }
    property Process _hyprWriter: Process {}

    // Hyprland's values right now, kept fresh for apply's comparison and its undo point
    property var _hyprNow: ({})
    property Process _hyprNowReader: Process {
        command: ["omniformis", "hypr", "list", "--json"]
        stdout: StdioCollector {
            onStreamFinished: { try { const h = {}; for (const v of JSON.parse(text)) h[v.key] = v.value; root._hyprNow = h } catch (e) {} }
        }
    }

    function remove(name) {
        const p = find(name)
        if (!p) return "no preset called '" + name + "'"
        _files.exec(["rm", "-f", Vars.presetsPath + "/" + p.id + ".json"])
        return ""
    }
    function rename(from, to) {
        const p = find(from)
        if (!p) return "no preset called '" + from + "'"
        if (find(to)) return "there is already a preset called '" + to + "'"
        _write(to, p.description, p.settings)
        _files.exec(["rm", "-f", Vars.presetsPath + "/" + p.id + ".json"])
        return ""
    }
    function duplicate(from, to) {
        const p = find(from)
        if (!p) return "no preset called '" + from + "'"
        if (find(to)) return "there is already a preset called '" + to + "'"
        _write(to, p.description, p.settings)
        return ""
    }

    // ── the folder ── read again whenever a preset is written or removed (here, or by
    // copying a file in)
    property Process _files: Process { onExited: root._reader.running = true }
    property Process _reader: Process {
        command: ["sh", "-c", 'mkdir -p "$1"; for f in "$1"/*.json; do [ -f "$f" ] && { cat "$f"; echo; echo "@@END"; }; done', "sh", Vars.presetsPath]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const chunk of text.split("@@END")) {
                    try { const p = JSON.parse(chunk); if (p && p.name && p.settings) out.push(p) } catch (e) { /* not a preset */ }
                }
                out.sort((a, b) => a.name === root.undoName ? 1 : b.name === root.undoName ? -1 : a.name.localeCompare(b.name))
                root.list = out
            }
        }
    }
    property Timer _poll: Timer {
        // a file copied in by hand shows up within a few seconds
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: { root._reader.running = true; root._hyprNowReader.running = true }
    }

    property IpcHandler _ipc: IpcHandler {
        target: "preset"
        function list(): string { return root.list.map(p => p.name + (p.name === root.current ? "  (applied)" : "") + "  · " + p.modified).join("\n") }
        function save(name: string): string { return root.save(name) || "saved '" + name + "'" }
        function apply(name: string): string { return root.apply(name) || "applied '" + name + "'" }
        function undo(): string { return root.undo() || "back to before the last apply" }
        function remove(name: string): string { return root.remove(name) || "removed '" + name + "'" }
        function rename(from: string, to: string): string { return root.rename(from, to) || "renamed" }
        function duplicate(from: string, to: string): string { return root.duplicate(from, to) || "duplicated" }
        function folder(): string { return Vars.presetsPath }
    }
}

import QtQuick
import Quickshell
import Quickshell.Io
import "../variables.js" as Vars

// Hyprland's settings and the theme, for the control center's Settings control. Both are
// read and written through the omniformis CLI (scripts/omniformis in the dotfiles), which
// already knows how: it reads every variable out of hypr/modules/variables.lua together
// with its type, its group and its help line (the comments above it), checks a new value
// against the type, and writes the file safely. So nothing about Hyprland is listed here:
// add a variable to variables.lua with a comment and it shows up in the dial.
//
//   vars      [{ key, type: "bool" | "number" | "string", value, enums, category, help }]
//   set(key, value)        writes one (a moment after the last change, then reloads Hyprland)
//   schemes / scheme / mode / setTheme(scheme, mode) / themed()   (the theme: see below)
//   palettes  { scheme: { dark | light: { primary, on_primary, secondary, tertiary, surface } } }
//   binds     every shortcut (`omniformis hypr binds --json`), plus the modifier and
//             navigation keys they are built from:
//             [{ key, kind: "bind" | "modifier" | "key", category, description, combo,
//                resolved, conflicts, active, error }]
//   setBind(key, combo)    writes one ("" turns it off)
//   error     what omniformis answered when the last change failed ("" when it worked)
Item {
    id: root

    property var vars: []
    property bool loaded: false
    property string error: ""

    // the groups, in the order they're shown (ones not listed here come after, by name)
    readonly property var categoryOrder: ["General", "Input", "Gestures", "Modifiers", "Navigation Keys", "Decoration",
                                          "Shadows", "Blur", "Liquid Glass", "Groupbar", "Animation Style", "Misc",
                                          "Environment Variables"]
    readonly property var categories: {
        const seen = []
        for (const v of vars) if (seen.indexOf(v.category) < 0) seen.push(v.category)
        const rank = c => { const i = categoryOrder.indexOf(c); return i < 0 ? 1000 : i }
        return seen.sort((a, b) => (rank(a) - rank(b)) || a.localeCompare(b))
    }

    // ── a number's range ── omniformis knows a variable is a number but not how far it
    // goes: [min, max, step] for the ones that have a sensible range. Any other number
    // gets one worked out from its value (rangeOf)
    readonly property var ranges: ({
        gaps_in: [0, 40, 1], gaps_out: [0, 80, 1], border_size: [0, 10, 1], rounding: [0, 40, 1],
        rounding_power: [1, 10, 0.5], active_opacity: [0.1, 1, 0.05], inactive_opacity: [0.1, 1, 0.05],
        singleWindowGapsOut: [0, 120, 2], shadow_range: [0, 100, 2], shadow_render_power: [1, 4, 1],
        blur_size: [1, 20, 1], blur_passes: [1, 8, 1], blur_vibrancy: [0, 1, 0.02],
        sensitivity: [-1, 1, 0.05], follow_mouse: [0, 3, 1], gesture_fingers: [3, 5, 1],
        force_default_wallpaper: [-1, 2, 1], vrr: [0, 2, 1],
        env_xcursor_size: [16, 64, 2], env_hyprcursor_size: [16, 64, 2], env_qt_scale_factor: [0.5, 3, 0.25]
    })
    function rangeOf(key, value) {
        if (ranges[key]) return ranges[key]
        const whole = Math.round(value) === value
        return [Math.min(0, value), Math.max(whole ? 10 : 1, value * 2), whole ? 1 : 0.05]
    }

    // ── reading ──
    function refresh() {
        lister.running = false
        lister.running = true
        themes.running = false
        themes.running = true
        current.running = false
        current.running = true
        colours.running = false
        colours.running = true
        refreshBinds()
    }
    Process {
        id: lister
        command: ["omniformis", "hypr", "list", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = JSON.parse(text)
                    if (Array.isArray(list)) {
                        // a change still waiting to be written wins over what the file says
                        root.vars = list.map(v => v.key in root._pending ? Object.assign({}, v, { value: root._pending[v.key] }) : v)
                        root.loaded = true
                    }
                } catch (e) { /* omniformis isn't there, or said something else: keep what we have */ }
            }
        }
    }

    // ── the shortcuts ──
    property var binds: []
    property bool bindsLoaded: false

    // name → value of every variable a combination can use ($MM → SUPER ...)
    property var bindVariables: ({})
    function refreshBinds() {
        bindLister.running = false
        bindLister.running = true
    }
    Process {
        id: bindLister
        command: ["omniformis", "hypr", "binds", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    const list = (data.settings || []).map(s => ({
                        key: s.key, kind: s.kind, category: s.category, description: s.description, combo: s.value,
                        resolved: [], conflicts: [], active: true, error: null
                    })).concat((data.binds || []).map(b => Object.assign({ kind: "bind" }, b)))
                    root.binds = list.map(b => b.key in root._pending ? Object.assign({}, b, { combo: root._pending[b.key] }) : b)
                    root.bindVariables = data.variables || {}
                    root.bindsLoaded = true
                } catch (e) { /* omniformis isn't there, or said something else: keep what we have */ }
            }
        }
    }

    // the dial shows the new combination at once; what it clashes with comes back with the
    // next read, once the file is written
    function setBind(key, combo) {
        binds = binds.map(b => b.key === key ? Object.assign({}, b, { combo: combo, resolved: [], conflicts: [], error: null }) : b)
        const p = Object.assign({}, _pending)
        p[key] = combo
        _pending = p
        error = ""
        flush.restart()
    }

    // ── writing ── the dial changes at once; the file is written a moment after the last
    // change (a knob being turned is many changes), one variable at a time, and Hyprland
    // is asked to read it again once they're all in
    property var _pending: ({})
    function set(key, value) {
        vars = vars.map(v => v.key === key ? Object.assign({}, v, { value: value }) : v)
        const p = Object.assign({}, _pending)
        p[key] = value
        _pending = p
        error = ""
        flush.restart()
    }
    Timer {
        id: flush
        interval: 300
        onTriggered: root._next()
    }
    function _next() {
        if (writer.running) return
        const keys = Object.keys(_pending)
        if (keys.length === 0) { apply.restart(); return }
        const key = keys[0]
        const value = _pending[key]
        const p = Object.assign({}, _pending)
        delete p[key]
        _pending = p
        writer.key = key

        // no side effects: omniformis would kill and relaunch the shell for GameMode. The
        // value is written, and Hyprland reads it again below
        writer.command = ["env", "OMNIFORMIS_NO_SIDE_EFFECTS=1", "omniformis", "hypr", "set", key, String(value)]
        writer.running = true
    }
    Process {
        id: writer
        property string key: ""
        stderr: StdioCollector { id: writerErr }
        onExited: code => {
            if (code !== 0) {
                // it didn't take: say so on the card, and show what the file really has
                root.error = writerErr.text.trim().replace(/^Error:\s*/, "") || ("could not set " + writer.key)
                root.refresh()
            }
            root._next()
        }
    }

    // Hyprland reads its config again (it doesn't watch the Lua modules by itself), and the
    // shortcuts are read again: a change can make or clear a clash
    Timer {
        id: apply
        interval: 150
        onTriggered: {
            Quickshell.execDetached(["hyprctl", "reload"])
            root.refreshBinds()
        }
    }

    // ── the theme ── the colour schemes omniformis knows, and the one in use: the
    // shell's colours are a link to .../<scheme>/<dark | light>/quickTheme.qml
    property var schemes: []
    property string scheme: ""
    property string mode: ""
    Process {
        id: themes
        command: ["omniformis", "theme", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.schemes = text.split("\n").map(l => l.replace(/^\s*-\s*/, "").trim())
                .filter(l => l !== "" && l.indexOf("Available") !== 0 && l.indexOf("No themes") !== 0)
        }
    }
    Process {
        id: current
        command: ["sh", "-c", 'readlink -f "$HOME/.config/color-schemes/current/quickTheme.qml"']
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("/")
                if (parts.length >= 3) {
                    root.mode = parts[parts.length - 2]
                    root.scheme = parts[parts.length - 3]
                }
            }
        }
    }

    // each scheme's own colours, in both modes, read from its quickTheme.qml (so a scheme
    // can be shown in its colours before it's picked)
    property var palettes: ({})
    Process {
        id: colours
        command: ["sh", "-c", 'for f in "$HOME"/.config/color-schemes/*/*/quickTheme.qml; do echo "FILE $f"; '
                            + 'grep -E "property color (primary|on_primary|secondary|tertiary|surface):" "$f"; done']
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {}
                let scheme = "", mode = ""
                for (const line of text.split("\n")) {
                    if (line.indexOf("FILE ") === 0) {
                        const parts = line.split("/")
                        mode = parts[parts.length - 2]
                        scheme = parts[parts.length - 3]
                        continue
                    }
                    const m = line.match(/property color (\w+):\s*["']([^"']+)["']/)
                    if (!m || scheme === "" || scheme === "current") continue
                    if (!out[scheme]) out[scheme] = {}
                    if (!out[scheme][mode]) out[scheme][mode] = {}
                    out[scheme][mode][m[1]] = m[2]
                }
                root.palettes = out
            }
        }
    }

    // the colour dots for a scheme in a mode: [primary, secondary, tertiary]; and for a
    // mode of a scheme: its surface first, so light and dark read apart at a glance
    function schemeDots(scheme_, mode_) {
        const p = (palettes[scheme_] || {})[mode_]
        return p ? [p.surface, p.primary, p.secondary, p.tertiary].filter(c => !!c) : []
    }

    // one colour of a scheme in a mode ("" when it isn't known)
    function colourOf(scheme_, mode_, role) {
        const p = (palettes[scheme_] || {})[mode_]
        return p && p[role] ? p[role] : ""
    }
    function modeDots(scheme_, mode_) {
        const p = (palettes[scheme_] || {})[mode_]
        return p ? [p.surface, p.primary, p.tertiary].filter(c => !!c) : []
    }

    // ── switching the theme ── a moment after the last pick (turning the ring passes
    // several), the scheme's files are linked in by Vars.themeScript. It is told not to
    // kill and relaunch the shell; `themed` says when it's done, and the Settings control
    // reloads the shell and comes back to where you were
    signal themed()
    property string _scheme: ""
    property string _mode: ""
    function setTheme(scheme_, mode_) {
        if (!scheme_ || !mode_) return
        scheme = scheme_
        mode = mode_
        _scheme = scheme_
        _mode = mode_
        themeLater.restart()
    }
    Timer {
        id: themeLater
        interval: 600
        onTriggered: {
            if (themer.running) { restart(); return }
            themer.command = ["env", "DIAL_SHELL_RELOADS=1", Vars.themeScript, root._scheme, root._mode]
            themer.running = true
        }
    }
    Process {
        id: themer
        onExited: root.themed()
    }
}

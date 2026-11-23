import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../primitive"
import "../keycapture.js" as KeyCapture
import "../variables.js" as Vars

// The Settings control of the control center: the shell's own settings (Prefs: feel,
// sound, hints, corners, notifications, dials, wallpapers), the theme, and Hyprland's
// variables, all changed from the dial. ControlCenter.qml uses `control`.
//
// It is a menu made of the dial's own parts: the inner ring's pills are the groups; a
// click on one goes into it and its settings take the ring, with a Back pill first (a
// group can hold groups: Hyprland → Decoration → Rounding). For the setting at the mark,
// the middle of the dial shows its value, its name and what it does, and:
//
//   a switch      click flips it (its pill lights up while it's on); Off / On sit in the gap
//   a number      scroll or drag the tick ring in the gap to turn it; click to type it
//   a choice      its choices are chips in the gap: scroll them, or click for the next one
//                 (a colour scheme's chip shows that scheme's colours)
//   a text        its value is written in the gap: click (or just type) to type it there;
//                 Enter keeps it, Esc doesn't
//   a shortcut    its keys are chips in the gap: click, then press the new combination and
//                 it is mapped (Esc cancels, Backspace turns the shortcut off). A modifier
//                 or a navigation key is recorded the same way, with one key
//   right-click   puts a setting back (to variables.js; Hyprland's: to what it was when
//                 the dial opened)
//
// The Hyprland and theme side is read and written by the omniformis CLI (HyprSettings.qml).
Item {
    id: settings

    required property var dial

    // the curved bar values are typed on (the control center's, in the gap between the rings)
    required property var bar

    // ★ the card's and the dial's sizes while this is selected: controlcenter/ReaderSettings.qml ★
    readonly property var cfg: ReaderSettings { liveSize: settings.dial.expandedSize; sweepDeg: settings.dial.sweepDeg }

    readonly property bool active: dial.open && dial.inSettings

    // Hyprland and the theme are read when the control is first opened, and again each
    // time (they can have been changed in the file meanwhile)
    HyprSettings { id: hypr }
    onActiveChanged: {
        if (active) { hypr.refresh(); if (!originals.taken) originals.take() }
        else { typing = false; stopCapture(); originals.taken = false }
    }

    // ── where you are in the menu ── the groups gone into (their names), and for each the
    // pill it was opened from, to come back to
    property var path: []
    property var trail: []

    // ── the menu ── groups of settings, a group may hold groups instead:
    //   { label, icon, items: [setting, ...] }  or  { label, icon, children: [group, ...] }
    // A setting, wherever it comes from:
    //   { source: "prefs" | "theme" | "hypr", key, label, title, icon, help, type: "bool" |
    //     "number" | "choice" | "text", value, shown, changed, min, max, step, options }
    readonly property var groupNames: ({
        Feel: "Feel", Sound: "Sound", Hints: "Hints", Corners: "Corners", Notify: "Notifications",
        Dials: "Dials", Liquid: "Liquid glass", Wallpaper: "Wallpaper"
    })
    readonly property var hyprIcons: ({
        "General": "tune", "Input": "keyboard", "Gestures": "swipe", "Modifiers": "keyboard_command_key",
        "Navigation Keys": "keyboard_tab", "Decoration": "border_style", "Shadows": "ev_shadow", "Blur": "blur_on",
        "Liquid Glass": "water_drop", "Groupbar": "tab_group", "Animation Style": "animation", "Misc": "more_horiz",
        "Environment Variables": "terminal"
    })

    function prefSetting(e) {
        return {
            source: "prefs", key: e.key, label: e.label, title: e.label, icon: e.icon, help: e.help, type: e.type,
            value: Prefs.valueOf(e.key), shown: Prefs.shown(e.key), changed: !Prefs.isDefault(e.key),
            min: e.min, max: e.max, step: e.step, options: e.options
        }
    }

    // "gaps_in" / "enableSingleWindowGaps" → "Gaps in" / "Enable single window gaps"
    function pretty(key) {
        const s = String(key).replace(/_/g, " ").replace(/([a-z0-9])([A-Z])/g, "$1 $2").toLowerCase().trim()
        return s.charAt(0).toUpperCase() + s.slice(1)
    }

    function hyprSetting(v) {
        const choice = v.type === "string" && v.enums && v.enums.length > 0
        const type = v.type === "bool" ? "bool" : v.type === "number" ? "number" : choice ? "choice" : "text"
        const r = type === "number" ? hypr.rangeOf(v.key, Number(v.value)) : [0, 0, 1]
        return {
            source: "hypr", key: v.key, label: pretty(v.key), title: pretty(v.key), help: v.help, type: type,
            icon: type === "bool" ? "toggle_on" : type === "number" ? "tune" : type === "choice" ? "list" : "edit",
            value: v.value,
            shown: type === "bool" ? (v.value ? "On" : "Off") : String(type === "number" ? Math.round(v.value * 1000) / 1000 : v.value),
            changed: originals.taken && originals.values[v.key] !== undefined && originals.values[v.key] !== v.value,
            min: r[0], max: r[1], step: r[2],
            options: choice ? v.enums.map(e => ({ value: e, label: e })) : []
        }
    }

    // ── the shell ── which of the dotfiles' shells runs (scripts/shell): picking another starts
    // it, and this one goes once the new one answers
    property string shellNow: "dial-e"
    Process {
        running: true
        command: [Vars.shellSwitcher, "current"]
        stdout: StdioCollector { onStreamFinished: if (text.trim() !== "") settings.shellNow = text.trim() }
    }
    readonly property var shellSettings: [
        { source: "shell", key: "shell", label: "Shell", title: "Which shell", icon: "swap_horiz", type: "choice",
          help: "Dial-E: these dials. Puffy: the panels and bar it grew from. Droplet: circles you drag onto circles. The new one starts before this one goes.",
          value: shellNow, shown: ({ "dial-e": "Dial-E", puffy: "Puffy", droplet: "Droplet" })[shellNow] || shellNow, changed: false,
          options: [{ value: "dial-e", label: "Dial-E" }, { value: "puffy", label: "Puffy" }, { value: "droplet", label: "Droplet" }] }
    ]

    // ── Presets ── (Presets.qml) apply one (Before last apply is the undo), or save what you
    // have now under a name you type
    readonly property var presetSettings: [
        { source: "preset", key: "apply", label: "Apply", title: "Apply a preset", icon: "bookmark", type: "choice",
          help: "Puts back everything a preset holds: settings, Advanced, the dials' spots, the wallpaper and its colours, Hyprland's variables. " + Presets.undoName + " undoes the last one.",
          value: Presets.current, shown: Presets.current || "none", changed: false,
          options: Presets.list.map(p => ({ value: p.name, label: p.name })) },
        { source: "preset", key: "save", label: "Save as", title: "Save a preset", icon: "bookmark_add", type: "text",
          help: "Type a name: everything as it is now becomes a preset (the same name replaces it). They are files in " + Vars.presetsPath + ".",
          value: "", shown: "", changed: false }
    ]

    // ── Advanced ── every plain setting of the settings files (Advanced.qml), by file and by
    // each file's own sections; the comment above it in the file is its help
    function advancedSetting(type, e) {
        const v = Advanced.valueOf(type, e.key)
        const r = e.kind === "number" ? Advanced.rangeOf(type, e.key) : [0, 0, 1]
        return {
            source: "advanced", object: type, key: e.key, label: pretty(e.key), title: pretty(e.key), help: e.help, type: e.kind,
            icon: e.kind === "bool" ? "toggle_on" : e.kind === "number" ? "tune" : "edit",
            value: v, shown: e.kind === "bool" ? (v ? "On" : "Off") : String(e.kind === "number" ? Math.round(v * 1000) / 1000 : v),
            changed: Advanced.isChanged(type, e.key), min: r[0], max: r[1], step: r[2], options: []
        }
    }
    function advancedGroups() {
        return Advanced.files.filter(f => (Advanced.schema[f.type] || []).length > 0).map(f => {
            const list = Advanced.schema[f.type], sections = []
            for (const e of list) if (sections.indexOf(e.section) < 0) sections.push(e.section)
            return { label: f.label, icon: f.icon, children: sections.map(sec => ({
                label: sec, icon: "tune", items: list.filter(e => e.section === sec).map(e => advancedSetting(f.type, e)) })) }
        })
    }

    // ── the shortcuts ── (hypr.binds) grouped as omniformis groups them
    readonly property var bindCategories: {
        const out = []
        for (const b of hypr.binds) if (out.indexOf(b.category) < 0) out.push(b.category)
        return out
    }

    // a group's icon, by the first word of its name
    readonly property var bindIcons: ({
        Modifiers: "keyboard_command_key", Navigation: "keyboard_tab", Applications: "apps", Window: "web_asset",
        Groups: "tab_group", Special: "star", "Dial-Quickshell": "radio_button_checked", Media: "music_note",
        Volume: "volume_up", Utilities: "build", Layout: "view_column"
    })

    // what a shortcut's key (e.g. "WindowPinBind") is called
    function bindName(key) {
        const b = hypr.binds.find(b => b.key === key)
        return b && b.description ? b.description : key
    }

    function bindSetting(b) {
        const isBind = b.kind === "bind"
        return {
            source: "bind", key: b.key, kind: b.kind, type: "shortcut", icon: "keyboard",
            label: b.description || b.key, title: b.description || b.key,
            value: b.combo, shown: b.combo === "" ? "off" : b.combo,
            changed: originals.taken && originals.binds[b.key] !== undefined && originals.binds[b.key] !== b.combo,
            off: isBind && b.combo === "",
            clash: isBind && !!b.conflicts && b.conflicts.length > 0,

            // what the card says about it: what's wrong first, else the keys it comes down to
            help: b.error ? String(b.error)
                : isBind && b.active === false ? "Not used by the current layout."
                : isBind && b.conflicts && b.conflicts.length > 0 ? "Also used by: " + b.conflicts.map(bindName).join(", ") + "."
                : isBind && b.combo === "" ? "Turned off. Click, then press keys to give it a shortcut."
                : isBind && b.resolved && b.resolved.length > 0
                    ? (b.resolved.length > 1 ? b.resolved[0] + " to " + b.resolved[b.resolved.length - 1] : b.resolved[0]) + ". Click, then press the new keys."
                : b.kind === "modifier" ? "Click, then press the modifier key you want."
                : "Click, then press the key you want."
        }
    }

    readonly property var themeSettings: [
        {
            source: "theme", key: "mode", label: "Mode", title: "Light or dark", icon: "dark_mode", type: "choice",
            help: "The whole desktop's colours, light or dark. The shell reloads with them.",
            value: hypr.mode, shown: hypr.mode === "light" ? "Light" : "Dark", changed: false,
            options: [{ value: "dark", label: "Dark", colors: hypr.modeDots(hypr.scheme, "dark") },
                      { value: "light", label: "Light", colors: hypr.modeDots(hypr.scheme, "light") }]
        },
        {
            source: "theme", key: "scheme", label: "Scheme", title: "Colour scheme", icon: "palette", type: "choice",
            help: "material-you follows the wallpaper; the others are fixed palettes. Each one shows its own colours.",
            value: hypr.scheme, shown: hypr.scheme, changed: false,
            options: hypr.schemes.map(s => ({ value: s, label: s, colors: hypr.schemeDots(s, hypr.mode) }))
        }
    ]

    readonly property var tree: {
        Prefs.revision
        Advanced.revision
        const top = Prefs.groups.map(g => ({
            label: groupNames[g] || g, icon: Prefs.groupIcons[g] || "settings",
            items: Prefs.inGroup(g).map(prefSetting)
        }))
        top.push({ label: "Theme", icon: "palette", items: themeSettings })
        if (hypr.bindsLoaded) top.push({
            label: "Shortcuts", icon: "keyboard",
            children: bindCategories.map(c => ({
                // "Dial-Quickshell (empty = disabled until you pick a key)" → "Dial-Quickshell"
                label: c.replace(/\s*\(.*\)\s*$/, ""), icon: bindIcons[c.split(" ")[0]] || "keyboard",
                items: hypr.binds.filter(b => b.category === c).map(bindSetting)
            }))
        })
        if (hypr.loaded) top.push({
            label: "Hyprland", icon: "desktop_windows",
            children: hypr.categories.map(c => ({
                label: c, icon: hyprIcons[c] || "settings",
                items: hypr.vars.filter(v => v.category === c).map(hyprSetting)
            }))
        })
        top.push({ label: "Shell", icon: "swap_horiz", items: shellSettings })
        top.push({ label: "Presets", icon: "bookmarks", items: presetSettings })
        top.push({ label: "Advanced", icon: "tune", children: advancedGroups() })
        return top
    }

    // the group you're in (null at the top)
    readonly property var node: {
        let list = tree, n = null
        for (const name of path) {
            n = list.find(g => g.label === name) || null
            if (!n) return null
            list = n.children || []
        }
        return n
    }

    // ── the pills of where you are ── Back first (once inside), then its groups or settings
    //   { kind: "back" | "group" | "setting", label, icon, on, group / setting }
    readonly property var pills: {
        const out = []
        if (path.length > 0) out.push({ kind: "back", label: "Back", icon: "arrow_back", on: false })
        const groups = path.length === 0 ? tree : (node && node.children) || []
        for (const g of groups) out.push({ kind: "group", label: g.label, icon: g.icon, on: false, group: g })
        for (const s of (node && node.items) || [])
            out.push({ kind: "setting", label: s.label, icon: s.icon, on: s.type === "bool" && !!s.value, setting: s })
        return out
    }

    // the pill at the mark, and its setting if it is one
    readonly property var pill: dial.inSettings ? (pills[dial.innerIndex] || null) : null
    readonly property var setting: pill && pill.kind === "setting" ? pill.setting : null

    // ── moving through the menu ── the ring turns one pill as it changes hands, forwards
    // going in and backwards coming out, so you can see which way you went
    function enter(group) {
        trail = trail.concat([dial.innerIndex])
        path = path.concat([group.label])
        Qt.callLater(() => dial.turnInner(0, 1))
    }
    function back() {
        if (path.length === 0) return
        const from = trail.length > 0 ? trail[trail.length - 1] : 0
        trail = trail.slice(0, -1)
        path = path.slice(0, -1)
        Qt.callLater(() => dial.turnInner(from + 1, from))
    }

    // ── changing a setting ── "" when it worked, or why not
    function put(s, value) {
        if (!s) return "nothing selected"
        if (s.source === "prefs") return Prefs.set(s.key, value)
        if (s.source === "advanced") return Advanced.set(s.object, s.key, value)
        if (s.source === "preset") return s.key === "apply" ? Presets.apply(String(value)) : Presets.save(String(value))
        if (s.source === "shell") {
            if (value !== shellNow) Quickshell.execDetached([Vars.shellSwitcher, "switch", String(value)])
            return ""
        }
        if (s.source === "theme") {
            if (s.key === "mode") hypr.setTheme(hypr.scheme, String(value))
            else hypr.setTheme(String(value), hypr.mode)
            return ""
        }
        if (s.source === "bind") {
            hypr.setBind(s.key, String(value))
            return ""
        }

        // Hyprland: checked here the way omniformis will check it, so a wrong value is
        // caught while you can still see what you typed
        if (s.type === "number") {
            const n = Number(String(value).trim())
            if (String(value).trim() === "" || !isFinite(n)) return "'" + s.key + "' is a number"
            hypr.set(s.key, Math.round(n * 1e6) / 1e6)
        } else if (s.type === "bool") {
            hypr.set(s.key, !!value)
        } else {
            const t = String(value).trim()
            if (["undefined", "null", "NaN", ""].indexOf(t) >= 0 || /[\n\r"\\]/.test(t)) return "'" + s.key + "' can't be '" + t + "'"
            hypr.set(s.key, t)
        }
        return ""
    }

    // the next value: a switch flipped, a choice's next option (round and round)
    function advance(s) {
        if (s.type === "bool") return put(s, !s.value)
        if (s.type === "choice" && s.options.length > 0) {
            const i = s.options.findIndex(o => o.value === s.value)
            return put(s, s.options[(i + 1) % s.options.length].value)
        }
        return ""
    }

    // back to what it was: variables.js for the shell's own, the value it had when the
    // dial opened for Hyprland's
    function restore(s) {
        if (s.source === "prefs") Prefs.reset(s.key)
        else if (s.source === "advanced") Advanced.reset(s.object, s.key)
        else if (s.source === "hypr" && originals.values[s.key] !== undefined) hypr.set(s.key, originals.values[s.key])
        else if (s.source === "bind" && originals.binds[s.key] !== undefined) hypr.setBind(s.key, originals.binds[s.key])
    }

    // Hyprland's values as they were when the control was opened (for restore, and to mark
    // what you changed since)
    QtObject {
        id: originals
        property bool taken: false
        property var values: ({})
        property var binds: ({})
        function take() {
            if (!hypr.loaded || !hypr.bindsLoaded) return
            const o = {}
            for (const v of hypr.vars) o[v.key] = v.value
            values = o
            const b = {}
            for (const s of hypr.binds) b[s.key] = s.combo
            binds = b
            taken = true
        }
    }
    Connections {
        target: hypr
        function onLoadedChanged() { if (settings.active && !originals.taken) originals.take() }
        function onBindsLoadedChanged() { if (settings.active && !originals.taken) originals.take() }
    }

    // a click on the pill at the mark
    function activate() {
        const p = pill
        if (!p) return
        if (p.kind === "back") back()
        else if (p.kind === "group") enter(p.group)
        else if (p.setting.type === "shortcut") { if (capturing) stopCapture(); else startCapture() }
        else if (p.setting.type === "bool" || p.setting.type === "choice") advance(p.setting)
        else startTyping()
    }

    // ── recording a shortcut ── click it, press the keys, and that's its combination now.
    // Modifiers held build up in the gap; the first real key completes it. While it
    // records, Hyprland is switched to an empty submap so it passes every key through
    // instead of running the shortcut being pressed; it is always switched back, and a
    // timer in the shell command does it too should the shell die meanwhile.
    property bool capturing: false
    property var heldMods: []
    function startCapture() {
        const s = setting
        if (!s || s.type !== "shortcut") return
        typing = false
        heldMods = []
        capturing = true
        Quickshell.execDetached({ command: ["bash", "-c",
            "hyprctl dispatch 'hl.dsp.submap(\"omniformis_capture\")' >/dev/null 2>&1; " +
            "( sleep 90; [ \"$(hyprctl submap 2>/dev/null)\" = omniformis_capture ] && hyprctl dispatch 'hl.dsp.submap(\"reset\")' >/dev/null 2>&1 ) >/dev/null 2>&1 &"] })
        catcher.forceActiveFocus()
    }
    function leaveCaptureSubmap() {
        Quickshell.execDetached({ command: ["bash", "-c",
            "[ \"$(hyprctl submap 2>/dev/null)\" = omniformis_capture ] && hyprctl dispatch 'hl.dsp.submap(\"reset\")' >/dev/null 2>&1; true"] })
    }
    function stopCapture() {
        if (!capturing) return
        capturing = false
        heldMods = []
        leaveCaptureSubmap()
        if (dial.open) dial.forceActiveFocus()
    }
    Component.onDestruction: if (capturing) leaveCaptureSubmap()

    // the keys while recording (they never reach the dial: Esc must not close it)
    Item {
        id: catcher
        Keys.onPressed: event => {
            if (!settings.capturing) return
            event.accepted = true
            const s = settings.setting
            if (!s) { settings.stopCapture(); return }
            const mod = KeyCapture.modifierOfKey(event.key)
            if (mod !== "") {
                // a modifier setting takes the modifier itself; a shortcut waits for a key
                if (s.kind === "modifier") { settings.stopCapture(); settings.put(s, mod); return }
                settings.heldMods = KeyCapture.modifiersFrom(event.modifiers)
                return
            }
            if (event.modifiers === Qt.NoModifier) {
                if (event.key === Qt.Key_Escape) { settings.stopCapture(); return }

                // Backspace / Delete by themselves: the shortcut is turned off
                if ((event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) && s.kind === "bind") {
                    settings.stopCapture()
                    settings.put(s, "")
                    return
                }
            }
            const name = KeyCapture.keyName(event)
            if (name === "" || s.kind === "modifier") return
            const mods = KeyCapture.modifiersFrom(event.modifiers)
            settings.stopCapture()
            Hints.used("shortcut")
            if (s.kind === "key") settings.put(s, name.length === 1 ? name.toLowerCase() : name)
            else settings.put(s, KeyCapture.buildCombo(mods, name, true, hypr.bindVariables))
        }
        Keys.onReleased: event => {
            if (!settings.capturing) return
            event.accepted = true
            settings.heldMods = KeyCapture.modifiersFrom(event.modifiers)
        }
    }

    // ── typing a value ── on the control center's curved bar: a number or a text
    property bool typing: false
    property bool typedOk: true
    function startTyping(first) {
        const s = setting
        if (!s || (s.type !== "number" && s.type !== "text")) return
        typedOk = true
        typing = true
        bar.clear()

        // typed straight away: that letter starts the new value; clicked: the old one to edit
        bar.insert(first !== undefined ? first : String(s.value))
        bar.focusInput()
    }

    // Enter (keep) or Esc (don't) on the bar
    function typed(keep) {
        if (keep) {
            const why = put(setting, bar.text)
            if (why !== "") { typedOk = true; typedOk = false; return }     // it shakes, and stays for another go
        }
        typing = false
        typedOk = true
        bar.clear()
        if (dial.open) dial.forceActiveFocus()
    }

    // another pill came to the mark while typing or recording: that is dropped
    onPillChanged: {
        if (typing) typed(false)
        if (capturing) stopCapture()
    }

    // ── what sits in the gap between the rings for the setting at the mark ──
    // a number: the tick ring (KnobRing: a tick per step). A choice or a switch: its
    // choices as chips to turn through (OptionRing: `options`, `index`, `setIndex`); a
    // switch is the two choices Off and On. A text: its value, written large (below)
    QtObject {
        id: level
        readonly property var s: settings.setting
        readonly property var options: !s ? null
            : s.type === "choice" && s.options.length > 1 ? s.options.map(o => ({ label: o.label, colors: o.colors }))
            : s.type === "bool" ? [{ label: "Off" }, { label: "On" }]
            : null
        readonly property bool available: !!s && (s.type === "number" || !!options)
        function setIndex(i) {
            if (!s || !options) return
            if (s.type === "bool") settings.put(s, i === 1)
            else settings.put(s, s.options[Math.max(0, Math.min(s.options.length - 1, i))].value)
        }
        readonly property int steps: !s || !available ? 1
            : options ? options.length - 1
            : Math.max(1, Math.round((s.max - s.min) / s.step))
        readonly property int index: !s || !available ? 0
            : s.type === "bool" ? (s.value ? 1 : 0)
            : s.type === "choice" ? Math.max(0, s.options.findIndex(o => o.value === s.value))
            : Math.max(0, Math.min(steps, Math.round((Number(s.value) - s.min) / s.step)))
        readonly property real value: index / steps
        readonly property bool muted: false
        readonly property bool locked: false
        readonly property string icon: s ? s.icon : "tune"

        // on the gem: the number, short; for a choice, which one it is
        readonly property string text: !s || !available || options ? "" : String(Math.round(Number(s.value) * 100) / 100)
        readonly property string subject: s ? s.source + ":" + s.key : ""

        // a few steps spread wide, many packed closer; long ticks so the ring reads at a glance
        readonly property real tickDeg: Math.max(2.5, Math.min(9, 48 / steps))
        readonly property int major: steps > 24 ? 10 : steps > 8 ? 5 : 1
        function set(v) {
            if (!s || !available || options) return
            const i = Math.round(v * steps)
            settings.put(s, Math.round((s.min + i * s.step) * 1e6) / 1e6)
        }

        // a click on the ring does what a click on the pill does
        function activate() { settings.activate() }
    }

    // ── the gap between the rings, for what has no ring to turn ── a text setting's
    // value written large (click, or just type, to change it there), and for a group the
    // names of what's inside it
    readonly property real gapRadius: cfg.controlCenter.knobsMid
    Item {
        z: 1
        opacity: settings.dial.inSettings && !settings.typing ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

        CurvedText {
            cx: settings.dial.centerX
            cy: settings.dial.centerY
            visible: !!settings.setting && settings.setting.type === "text"
            text: settings.setting ? settings.setting.shown : ""
            radius: settings.gapRadius
            centerDeg: settings.dial.midDeg
            maxDeg: settings.cfg.maxDeg
            font.pixelSize: 22                  // M3 titleLarge
            font.weight: 800
            color: Roles.on_surface
        }
        // a shortcut: its combination, one chip per key; while it's recorded, the modifiers
        // held so far and a pulsing chip for the key to come
        KeyChips {
            cx: settings.dial.centerX
            cy: settings.dial.centerY
            readonly property var s: settings.setting && settings.setting.type === "shortcut" ? settings.setting : null
            visible: !!s
            recording: settings.capturing
            tokens: !s ? []
                : settings.capturing ? settings.heldMods.concat(["…"])
                : s.value === "" ? ["none"] : KeyCapture.tokens(s.value)
            radius: settings.gapRadius
            centerDeg: settings.dial.midDeg
        }
        CurvedText {
            cx: settings.dial.centerX
            cy: settings.dial.centerY
            readonly property var g: settings.pill && settings.pill.kind === "group" ? settings.pill.group : null
            visible: !!g
            text: g ? (g.children || g.items || []).map(i => i.label).join("   ·   ") : ""
            radius: settings.gapRadius
            centerDeg: settings.dial.midDeg
            maxDeg: Math.min(150, settings.dial.sweepDeg - 16)
            font.pixelSize: 13                  // M3 bodyMedium
            font.weight: 600
            color: Roles.on_surface_variant
        }
    }

    // ── the theme changed ── the shell has to load its colours again. It reloads itself
    // (nothing is killed) and comes straight back to the pill you were on
    // (where it was is written to a small file first: nothing in the shell outlives a reload)
    FileView {
        id: resumeFile
        path: Vars.settingsResumePath
        printErrors: false
        blockLoading: true
        blockWrites: true
    }
    Connections {
        target: hypr
        function onThemed() {
            const open = settings.dial.open && settings.dial.inSettings
            resumeFile.setText(JSON.stringify({ path: settings.path, pill: open ? settings.dial.innerIndex : -1, at: Date.now() }))
            Quickshell.reload(false)
        }
    }

    // after that reload: back into the same group, on the same pill (only for a note left
    // in the last few seconds: an old one is not a reload we asked for)
    property int pendingPill: -1
    Timer {
        interval: 400
        running: true
        onTriggered: {
            let o = null
            try { o = JSON.parse(resumeFile.text()) } catch (e) { return }
            if (!o || !(o.pill >= 0) || Date.now() - o.at > 15000) return
            resumeFile.setText("{}")
            settings.path = Array.isArray(o.path) ? o.path : []
            settings.trail = settings.path.map(() => 0)
            settings.pendingPill = o.pill
            settings.dial.showControl("settings")
        }
    }
    Connections {
        target: settings.dial
        function onInSettingsChanged() {
            if (!settings.dial.inSettings || settings.pendingPill < 0) return
            const i = settings.pendingPill
            settings.pendingPill = -1
            Qt.callLater(() => settings.dial.turnInner(i, i))
        }
    }

    // ── the card in the middle ── the value in a shape that says what kind it is (and
    // morphs when a switch flips), the setting's name, and what it does
    property Component corner: Component {
        ReaderCard {
            dial: settings.dial
            cfg: settings.cfg

            // the pill at the mark, and its setting (worked out from the pill here, so the two
            // can never be out of step for a moment)
            readonly property var p: settings.pill
            readonly property var s: p && p.kind === "setting" ? p.setting : null
            readonly property var g: p && p.kind === "group" ? p.group : null
            readonly property bool isOn: !!s && s.type === "bool" && !!s.value

            // M3E: a switch that's on is primary (a cookie); off, a plain surface circle; a
            // number is secondary-container; a choice tertiary-container; a group or a text
            // a surface step
            readonly property bool isKeys: !!s && s.type === "shortcut"
            shape: !s ? (g ? "4LeafClover" : "Circle")
                : isKeys ? (settings.capturing ? "SoftBurst" : s.off ? "Circle" : "Gem")
                : s.type === "bool" ? (isOn ? "12SidedCookie" : "Circle")
                : s.type === "number" ? "6SidedCookie"
                : s.type === "choice" ? "Clamshell" : "Pill"
            // the theme's two settings wear the picked scheme's own primary
            readonly property string themePrimary: s && s.source === "theme" ? hypr.colourOf(hypr.scheme, hypr.mode, "primary") : ""
            readonly property string themeInk: s && s.source === "theme" ? hypr.colourOf(hypr.scheme, hypr.mode, "on_primary") : ""
            fill: !s ? Roles.surface_container_high
                : themePrimary !== "" ? themePrimary
                : isKeys ? (settings.capturing ? Roles.primary : s.clash ? Roles.tertiary_container : s.off ? Roles.surface_container_highest : Roles.secondary_container)
                : s.type === "bool" ? (isOn ? Roles.primary : Roles.surface_container_highest)
                : s.type === "number" ? Roles.secondary_container
                : s.type === "choice" ? Roles.tertiary_container : Roles.surface_container_high
            ink: !s ? Roles.on_surface_variant
                : themeInk !== "" ? themeInk
                : isKeys ? (settings.capturing ? Roles.on_primary : s.clash ? Roles.on_tertiary_container : s.off ? Roles.on_surface_variant : Roles.on_secondary_container)
                : s.type === "bool" ? (isOn ? Roles.on_primary : Roles.on_surface_variant)
                : s.type === "number" ? Roles.on_secondary_container
                : s.type === "choice" ? Roles.on_tertiary_container : Roles.on_surface
            // a long value is in the gap already: the shape then carries the setting's icon
            value: s && !isKeys && s.shown.length <= 5 ? s.shown : ""
            symbol: !p ? "settings" : isKeys ? (settings.capturing ? "fiber_manual_record" : s.clash ? "warning" : s.off ? "block" : "keyboard") : p.icon

            // where you are, and whether this one was changed
            note: settings.path.concat(s && s.changed ? ["changed"] : []).join("  ·  ")
            title: !p ? "Settings" : s ? s.title : p.kind === "back" ? "Back" : p.label
            body: hypr.error !== "" && s && (s.source === "hypr" || s.source === "bind") ? "Not saved: " + hypr.error
                : isKeys && settings.capturing ? (s.kind === "modifier" ? "Press the modifier key you want. Esc cancels."
                    : s.kind === "key" ? "Press the key you want. Esc cancels."
                    : "Press the new shortcut. Esc cancels, Backspace turns it off.")
                : s ? s.help
                : g ? (g.children ? g.children.length + " groups inside" : g.items.length + (g.items.length === 1 ? " setting inside" : " settings inside"))
                : p && p.kind === "back" ? "Click to go back to " + (settings.path.length > 1 ? settings.path[settings.path.length - 2] : "all settings")
                : ""
        }
    }

    readonly property var control: ({
        key: "settings",
        label: "Settings",
        icon: "settings",
        shape: "7SidedCookie",
        shapeSelected: "9SidedCookie",

        // nothing to switch: the tile takes you back to the top of the menu
        on: false,
        toggle: () => { settings.path = []; settings.trail = []; Qt.callLater(() => settings.dial.turnInner(0, 0)) },
        size: settings.cfg.dialSize,
        dateIcon: false,
        corner: settings.corner,
        value: level,
        hint: "settings",

        // a click in the gap between the rings, on what's written there (a text's value, a
        // shortcut's keys): the same as a click on the pill
        gapClick: () => settings.activate(),

        // its own control center settings while selected (ReaderSettings → controlCenter)
        settings: settings.cfg.controlCenter,

        devices: () => settings.pills.map(p => ({
            label: p.label,
            icon: p.icon,
            shape: "Circle",
            on: p.on,
            status: "none",

            // the badge: a group opens, a setting shows its value (short ones as words)
            badgeIcon: p.kind === "back" ? "undo" : p.kind === "group" ? "chevron_right"
                : p.setting.type === "shortcut" ? (p.setting.clash ? "warning" : p.setting.off ? "block" : "keyboard")
                : p.setting.shown.length > 4 ? (p.setting.type === "text" ? "edit" : "more_horiz") : "",
            badgeText: p.kind === "setting" && p.setting.type !== "shortcut" && p.setting.shown.length <= 4 ? p.setting.shown : undefined,
            activate: () => settings.activate(),
            secondary: () => { if (settings.setting) settings.restore(settings.setting) }
        }))
    })
}

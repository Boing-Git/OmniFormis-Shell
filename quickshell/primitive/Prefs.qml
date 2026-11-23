pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../variables.js" as Vars

// The shell's live settings: the values you change from inside the shell (the control
// center's Settings control, or `qs ipc call prefs set <key> <value>`) and see change at
// once, with no reload.
//
// Each one starts at its value from variables.js. What you change is remembered in
// Vars.settingsPath (only the changed ones) and wins over variables.js from then on;
// `reset` forgets it again.
//
//   momentum: Prefs.scrollMomentum          // read one (bindings follow it)
//   Prefs.set("tickVolume", 0.3)            // change one (checked against its type)
//   Prefs.toggle("dnd")
//
// Borrowed from the omniformis CLI: every setting has a type and is checked before it's
// stored (a number is clamped to its range and snapped to its step, a choice must be one
// of its options, "undefined" / "null" / "NaN" are refused), every setting carries its
// own group and help line (`schema`), and the file is written to a temp file and renamed,
// so a reader never sees half of it.
QtObject {
    id: root

    // ── feel ──
    // how far a ring keeps turning after a scroll, 0 (one item per notch) .. 10
    property int glide: nearestGlide(Vars.scrollMomentum)

    // how hard a flick throws a ring (0: it only settles)
    property real throwStrength: Vars.flickStrength

    // how far a dial overshoots as it opens, 0 (none) .. 10, and how quickly it opens, 1 .. 10
    // ── design ── (Vars.design) the shapes: "expressive" (M3E's cookies, gems, suns…) or
    // "round" (Apple's circles and capsules, app icons rounded squares; M3Shapes.styled);
    // the text font: "system" (the app font) or a font family
    property string shapeStyle: Vars.design.shapes
    property string textFont: Vars.design.font

    // tiles: the colours every part reads through Roles.qml, "tonal" (the theme's M3 roles)
    // or "glass" (Apple's: white glyphs, white washes, picked in white); tracks: "wavy" (M3E's wavy progress) or
    // "straight"
    property string tileStyle: Vars.design.tiles
    property string trackStyle: Vars.design.tracks

    // the control center's outer ring: "three" colours taking turns, or all "primary" /
    // "secondary" / "tertiary"
    property string ringColors: Vars.design.ringColors

    // the items not picked on every ring, as a share of their own size (the picked one keeps
    // its size, so the pick stands out more the smaller the others are)
    property real inactiveScale: Vars.design.inactiveScale
    readonly property string fontFamily: textFont === "system" ? Qt.application.font.family : textFont

    property int openBounce: Vars.openBounce
    property int openSpeed: Vars.openSpeed

    // ms a dial waits for the mouse to come back before it closes
    property int slipGrace: Vars.slipGrace

    // ── sound ──
    // "off", "even" (every tick at tickVolume) or "soft" (quieter in a fast spin and while
    // music plays)
    property string ticks: Vars.ticks
    property real tickVolume: Vars.tickVolume


    // ── hints ──
    // how many times each first-contact hint shows (0: off), and after how many days
    // without using its gesture a hint comes back once (0: never)
    property int hintTimes: Vars.hintTimes
    property int hintRemindDays: Vars.hintRemindDays

    // ── what the closed corners say ──
    // the volume's corner: "off", "level", "music" (only while music plays) or "both"
    property string cornerVolume: Vars.cornerVolume
    property bool cornerUnread: Vars.cornerUnread

    // ── notifications ──
    property bool dnd: false
    property bool assistant: Vars.assistant
    property bool screenTime: Vars.screenTime
    property bool mascots: Vars.mascots
    property bool automations: Vars.automations
    // (screen time's switch is shared with the other shells: the truth is the tracker's own)
    property Process _screenTimeState: Process {
        running: true
        command: [Quickshell.shellDir + "/../scripts/screentime.py", "status"]
        stdout: StdioCollector { onStreamFinished: root.screenTime = text.trim() !== "off" }
    }
    property int notifyHold: Vars.notifyHold

    // ── dials ──
    property bool osdVolume: Vars.osdEnabled.volume
    property bool osdBrightness: Vars.osdEnabled.brightness
    property bool osdWorkspaces: Vars.osdEnabled.workspaces
    property string clockFormat: Vars.clockFormat
    property int workspaceCount: Vars.workspaceOsdCount

    // ── look ──
    // the dials and their rings turn to frosted glass; how solid each kind of glass is;
    // whether Hyprland frosts what's behind the dials / the pop-ups, and over what; how
    // blurred the lock's wallpaper is
    property real glassDials: Vars.glass.dials
    property real glassRings: Vars.glass.rings
    property real glassPopups: Vars.glass.popups
    property real glassLock: Vars.glass.lock
    property bool frostDials: Vars.frostDials
    property bool frostPopups: Vars.frostPopups
    property string frostOver: Vars.frostOver
    property int lockBlur: Vars.lockBlur
    property string lockBackground: Vars.lockBackground
    property string lockFace: Vars.lockFace

    // ── liquid glass ── (LiquidGlass.qml) "off", "on" or "button" (on, and a dial's glass
    // brightens under the mouse and flattens while pressed); the rest are the liquid glass
    // library's own settings (variables.js: liquid)
    property string liquidGlass: Vars.liquid.mode
    property real liquidBlur: Vars.liquid.blurAmount
    property real liquidRefraction: Vars.liquid.refraction
    property real liquidChroma: Vars.liquid.chromAberration
    property real liquidEdge: Vars.liquid.edgeHighlight
    property real liquidSpecular: Vars.liquid.specular
    property real liquidFresnel: Vars.liquid.fresnel
    property real liquidDistortion: Vars.liquid.distortion
    property int liquidDepth: Vars.liquid.zRadius
    property string liquidBevel: Vars.liquid.bevelMode
    property real liquidOpacity: Vars.liquid.opacity
    property real liquidFill: Vars.liquid.bodyFill

    // the rings are liquid glass too; off: a flat wash with hairline edges (Apple never
    // stacks glass on glass)
    property bool liquidRings: Vars.liquid.rings
    property real liquidSaturation: Vars.liquid.saturation
    property real liquidTint: Vars.liquid.tintStrength
    property real liquidBrightness: Vars.liquid.brightness
    property real liquidShadow: Vars.liquid.shadowOpacity
    property int liquidShadowSpread: Vars.liquid.shadowSpread
    property int liquidShadowOffset: Vars.liquid.shadowOffsetY
    readonly property bool liquidOn: liquidGlass !== "off"

    // what the glass bends: "wallpaper", "windows" (a grim snapshot of the screen) or
    // "live" (every window streamed, so video plays through it), see Backdrop.qml
    property string liquidSees: Vars.liquid.sees

    // ── presets ── (Vars.presets) one per group that has any: the preset whose values are
    // all on, "default" when the whole group is as in variables.js, else "custom". Picking
    // one sets its values; Custom brings back the last values that matched no preset
    readonly property string presetDesign: { revision; return _matching("Design") }
    readonly property string presetLiquid: { revision; return _matching("Liquid") }

    // ── wallpapers ──
    property string wallpaperSort: Vars.sortBy
    property bool wallpaperDescending: Vars.sortDescending
    property bool wallpaperShuffle: Vars.shuffle

    // ── the theme ── what a wallpaper's colours become (Vars.themeApplyScript runs matugen):
    // the kind of scheme, and which of the wallpaper's colours it starts from
    property string themeScheme: Vars.themeScheme
    property string themeSource: Vars.themeSource
    readonly property var schemeTypes: ["scheme-tonal-spot", "scheme-content", "scheme-expressive", "scheme-fidelity",
        "scheme-fruit-salad", "scheme-monochrome", "scheme-neutral", "scheme-rainbow", "scheme-vibrant", "scheme-smart"]

    // colours the whole desktop from `image` (the wallpaper dial, and a Scheme or Theme
    // from change, with the wallpaper on screen). Detached: the script queues runs itself
    function applyTheme(image) {
        if (image) Quickshell.execDetached([Vars.themeApplyScript, image, themeScheme, themeSource])
    }

    // for the chips' dots, from the wallpaper on screen: each scheme's primary, secondary
    // and tertiary ({ "scheme-vibrant": [..3] }), and the colour each source picks
    property var schemeDots: ({})
    property var sourceDots: ({})
    property Process _preview: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                const schemes = {}, sources = {}
                for (const line of text.split("\n")) {
                    const p = line.trim().split(" ")
                    if (p[0].startsWith("source:")) sources[p[0].slice(7)] = [p[1]]
                    else if (p.length === 4) schemes[p[0]] = p.slice(1)
                }
                root.schemeDots = schemes
                root.sourceDots = sources
            }
        }
    }
    function _previewTheme() {
        if (Backdrop.wallpaper !== "") _preview.exec([Vars.themeApplyScript, "--preview", Backdrop.wallpaper, themeSource].concat(schemeTypes))
    }
    property Connections _wallpaperWatch: Connections {
        target: Backdrop
        function onWallpaperChanged() { root._previewTheme() }
    }

    // ── worked out from the settings above ──
    // glide level → momentum (DialRotation.momentum); level 8 is the old default, 0.98
    readonly property var glideTable: [0, 0.80, 0.86, 0.90, 0.93, 0.95, 0.965, 0.975, 0.98, 0.987, 0.992]
    function nearestGlide(momentum) {
        let best = 0
        for (let i = 1; i < glideTable.length; i++)
            if (Math.abs(glideTable[i] - momentum) < Math.abs(glideTable[best] - momentum)) best = i
        return best
    }
    readonly property real scrollMomentum: glideTable[Math.max(0, Math.min(glideTable.length - 1, glide))]

    // speed added per notch: must stay above the momentum (1 = one notch ≈ one item)
    readonly property real energy: Math.max(1, scrollMomentum + 0.01)

    // the spring a dial opens and closes on (M3E numbers: Vars.springs). Bounce 2 / speed 6
    // is M3E's standard default spatial spring (0.9 / 700): quick, with almost no overshoot,
    // since opening is the most frequent thing a dial does. Bounce 6 / speed 3 is close to
    // the expressive one (0.7 / 380)
    readonly property var speedTable: [200, 200, 260, 340, 450, 580, 700, 850, 1050, 1300, 1600]
    // Bounce 0: nothing overshoots anywhere, not only the dials opening. Every spring
    // (SpringValue) settles without passing its target, the moves that run on a curve take
    // the calm one, and the flourishes that are overshoot by nature (the wiggle when a ring
    // rests on a tile, the loading indicator's springy morph) go quiet
    readonly property bool calm: openBounce === 0

    // the two spatial moves every Behavior uses (size, position, rotation): M3E's expressive
    // curves, or with Bounce 0 the same moves with no overshoot (variables.js)
    readonly property var fastSpatial: calm ? Vars.calmFastSpatial : Vars.expressiveFastSpatial
    readonly property var defaultSpatial: calm ? Vars.calmDefaultSpatial : Vars.expressiveDefaultSpatial

    readonly property var openSpring: ({
        stiffness: speedTable[Math.max(1, Math.min(10, openSpeed))],
        dampingRatio: 1 - Math.max(0, Math.min(10, openBounce)) * 0.05
    })

    // A container colour as glass: `c` with the opacity of its kind ("dial", "ring",
    // "popup" or "lock"); at 100% it comes back unchanged (solid). Only for containers:
    // what sits on them stays solid. With Hyprland's blur off nothing frosts the dials, so
    // they stay almost solid (0.9 at least) to keep them readable; the lock blurs its own
    // wallpaper, so it doesn't need Hyprland, and liquid glass sees the wallpaper itself
    // (there it's how much of the colour fills the glass's body: LiquidGlass.tint)
    // a container colour as it fills liquid glass (LiquidGlass.tint, and a ring's `under`):
    // glass() times Body fill
    function liquidBody(c, kind) {
        const g = glass(c, kind)
        return Qt.rgba(g.r, g.g, g.b, g.a * liquidFill)
    }

    function glass(c, kind) {
        let a = kind === "ring" ? glassRings : kind === "popup" ? glassPopups : kind === "lock" ? glassLock : glassDials
        if (a >= 1) return c
        if (kind !== "lock" && !blurAvailable && !liquidOn) a = Math.max(a, 0.9)
        const q = typeof c === "string" ? Qt.color(c) : c
        return Qt.rgba(q.r, q.g, q.b, q.a * a)
    }

    // ── frost ── Hyprland's blur behind the shell, as layer rules the shell sets itself (live,
    // through hyprctl eval). The dials' windows are the "quickshell" layer, the pop-ups'
    // "quickshell-popup". Hyprland only blurs where the shell isn't (nearly) see-through,
    // so with Translucent off the blur is there but nothing shows it
    function frostRules() {
        const over = frostOver === "wallpaper" ? "true" : "false"
        const rule = (name, ns, on) => 'hl.layer_rule({ name = "' + name + '", match = { namespace = "^' + ns
            + '$" }, blur = ' + on + ', blur_popups = ' + on
            + ', ignore_alpha = 0.1, xray = ' + over + ' })'

        // "quickshell-blur" is the rule hypr/modules/winrules.lua starts with: this replaces it
        return rule("quickshell-blur", "quickshell", frostDials) + "; " + rule("quickshell-popup-blur", "quickshell-popup", frostPopups)
    }
    property Process _frost: Process {}
    function applyFrost() { _frost.exec(["hyprctl", "eval", frostRules()]) }
    onFrostDialsChanged: applyFrost()
    onFrostPopupsChanged: applyFrost()
    onFrostOverChanged: applyFrost()

    // Hyprland forgets rules set at runtime when its config reloads: set them again
    property Connections _hyprReload: Connections {
        target: Hyprland
        function onRawEvent(event) { if (event.name === "configreloaded") root.applyFrost() }
    }

    // ── facts the shell reports (not settings: never saved) ──
    // Hyprland blurs behind the shell (decoration:blur:enabled; off in game mode and on low
    // spec), asked once at start
    property bool blurAvailable: true
    property Process _blurQuery: Process {
        running: true
        command: ["hyprctl", "getoption", "decoration:blur:enabled", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const o = JSON.parse(text)
                    if (o && "bool" in o) root.blurAvailable = o.bool
                    else if (o && "int" in o) root.blurAvailable = o.int !== 0
                } catch (e) { /* no Hyprland (or an old one): assume it blurs */ }
            }
        }
    }

    // something is playing (set from shell.qml): ticks go quieter, the volume corner waves
    property bool musicPlaying: false

    // how loud a tick should be (0..1), `dt` ms after the one before it: full for single
    // notches, down to 35% in a fast spin, and less than half of that while music plays
    function tickGain(dt) {
        if (ticks === "off" || tickVolume <= 0) return 0
        if (ticks === "even") return tickVolume
        const rate = Math.max(0.35, Math.min(1, dt / 120))
        return tickVolume * rate * (musicPlaying ? 0.4 : 1)
    }

    // ── the schema ── one entry per setting, in the order the Settings control shows them:
    //   key      the property above
    //   group    which pill of the Settings control it sits under
    //   label    its name on the pill (keep it short: a pill fits about 12 letters)
    //   help     one line on what it does (shown in the dial's centre)
    //   type     "bool" | "number" | "choice" | "text"
    //   min / max / step   (number) its range; `unit` is added to the value shown
    //   options  (choice) [{ value, label }]
    //   icon     Material Symbols name
    readonly property var _settings: [
        { key: "shapeStyle", group: "Design", label: "Shapes", icon: "category", type: "choice",
          options: [{ value: "expressive", label: "Expressive" }, { value: "round", label: "Round" }],
          help: "Expressive: M3's cookies, suns and gems, morphing as things are picked. Round: circles and capsules." },
        { key: "tileStyle", group: "Design", label: "Colours", icon: "toggle_on", type: "choice",
          options: [{ value: "tonal", label: "Tonal" }, { value: "glass", label: "Glass" }],
          help: "Tonal: the theme's colours, as M3. Glass: white icons and text on clear glass, the picked thing in white, as Apple." },
        { key: "trackStyle", group: "Design", label: "Tracks", icon: "timeline", type: "choice",
          options: [{ value: "wavy", label: "Wavy" }, { value: "straight", label: "Straight" }],
          help: "The timeline ring while something plays: M3's travelling wave, or a straight line." },
        { key: "ringColors", group: "Design", label: "Ring colours", icon: "palette", type: "choice",
          options: [{ value: "three", label: "Three" }, { value: "primary", label: "Primary" },
                    { value: "secondary", label: "Secondary" }, { value: "tertiary", label: "Tertiary" }],
          help: "The control center's outer ring: its tiles take turns through three colours, or all wear one." },
        { key: "inactiveScale", group: "Design", label: "Unpicked size", icon: "photo_size_select_small", type: "number", min: 0.5, max: 1, step: 0.05, percent: true,
          help: "How big the items you haven't picked are on every ring. The picked one keeps its size. 100%: as they used to be." },
        { key: "textFont", group: "Design", label: "Text font", icon: "match_case", type: "choice",
          options: [{ value: "system", label: "System" }, { value: "Inter", label: "Inter" }],
          help: "The font of the shell's words. Inter: close to Apple's San Francisco." },
        { key: "glide", group: "Feel", label: "Glide", icon: "swipe", type: "number", min: 0, max: 10, step: 1,
          help: "How far a ring keeps turning after a scroll. 0: one item per notch." },
        { key: "throwStrength", group: "Feel", label: "Throw", icon: "sports_baseball", type: "number", min: 0, max: 2, step: 0.1,
          help: "How hard a flick throws a ring. 0: it only settles." },
        { key: "openBounce", group: "Feel", label: "Bounce", icon: "airline_stops", type: "number", min: 0, max: 10, step: 1,
          help: "How far a dial overshoots as it opens. 0: nothing overshoots anywhere (dials, tiles, shapes, shakes). 6: the bouncy feel." },
        { key: "openSpeed", group: "Feel", label: "Speed", icon: "speed", type: "number", min: 1, max: 10, step: 1,
          help: "How quickly a dial opens and closes." },
        { key: "slipGrace", group: "Feel", label: "Slip grace", icon: "pan_tool", type: "number", min: 0, max: 1000, step: 50, unit: " ms",
          help: "How long a dial waits for the mouse to come back before it closes." },
        { key: "ticks", group: "Sound", label: "Ticks", icon: "music_note", type: "choice",
          options: [{ value: "off", label: "Off" }, { value: "even", label: "Even" }, { value: "soft", label: "Soft" }],
          help: "A tick each time a ring passes an item. Soft: quieter in a fast spin and while music plays." },
        { key: "tickVolume", group: "Sound", label: "Tick volume", icon: "volume_up", type: "number", min: 0, max: 1, step: 0.05, percent: true,
          help: "How loud the ticks are." },
        { key: "hintTimes", group: "Hints", label: "First hints", icon: "lightbulb", type: "number", min: 0, max: 5, step: 1, unit: "×",
          help: "How many times each first-contact hint shows. 0: off." },
        { key: "hintRemindDays", group: "Hints", label: "Remind", icon: "event_repeat", type: "number", min: 0, max: 90, step: 5, unit: " d",
          help: "A hint comes back once when its gesture went unused this many days. 0: never." },
        { key: "cornerVolume", group: "Corners", label: "Volume arc", icon: "graphic_eq", type: "choice",
          options: [{ value: "off", label: "Off" }, { value: "level", label: "Level" }, { value: "music", label: "Music" }, { value: "both", label: "Both" }],
          help: "What the volume's closed corner shows: the level, a wave only while music plays, or the level that waves with music." },
        { key: "cornerUnread", group: "Corners", label: "Unread", icon: "mark_chat_unread", type: "bool",
          help: "The control center's closed corner shows a bead per waiting notification." },
        { key: "assistant", group: "Extras", label: "Ask the AI", icon: "auto_awesome", type: "bool",
          help: "The Ask control: type a question or a wish on the dial (\"bigger gaps\", \"open Downloads\"); the local AI does it with the desktop's own commands. Super + A opens it." },
        { key: "screenTime", group: "Extras", label: "Screen time", icon: "hourglass_top", type: "bool",
          help: "Counts how long each app is used, per day, and shows it in the Screen time control. One switch for every shell: off stops the counting too." },
        { key: "mascots", group: "Extras", label: "Mascots", icon: "sentiment_satisfied", type: "bool",
          help: "Dial-E hides in plain sight: in an empty corner of the control center and on the lock screen. Find it." },
        { key: "automations", group: "Extras", label: "Automations", icon: "bolt", type: "bool",
          help: "The Automations control: runs of steps (open Steam and Spotify, play, open a game…) kept in ~/.config/automations. Ask the AI to make one." },
        { key: "dnd", group: "Notify", label: "Do not disturb", icon: "notifications_off", type: "bool",
          help: "Notifications arrive silently: nothing pops out, they wait in the control center." },
        { key: "notifyHold", group: "Notify", label: "Stay", icon: "timer", type: "number", min: 2, max: 20, step: 1, unit: " s",
          help: "How long an arriving notification stays out." },
        { key: "osdVolume", group: "Dials", label: "Volume pop-up", icon: "volume_up", type: "bool",
          help: "A dial pops up when the volume changes." },
        { key: "osdBrightness", group: "Dials", label: "Bright pop-up", icon: "brightness_6", type: "bool",
          help: "A dial pops up when the brightness changes." },
        { key: "osdWorkspaces", group: "Dials", label: "Space pop-up", icon: "space_dashboard", type: "bool",
          help: "A dial pops up while you move between workspaces." },
        { key: "workspaceCount", group: "Dials", label: "Workspaces", icon: "grid_view", type: "number", min: 1, max: 20, step: 1,
          help: "How many workspaces the workspace ring goes up to." },
        { key: "clockFormat", group: "Dials", label: "Clock", icon: "schedule", type: "choice",
          options: [{ value: "24h", label: "24 h" }, { value: "12h", label: "12 h" }, { value: "12hAmPm", label: "12 h AM/PM" }],
          help: "How the control center's clock counts the hours." },
        { key: "glassDials", group: "Look", label: "Dials", icon: "radio_button_partial", type: "number", min: 0.3, max: 1, step: 0.05, percent: true,
          help: "How solid the dials are (control center, apps, wallpaper, power). 100%: solid; lower turns them to frosted glass." },
        { key: "glassRings", group: "Look", label: "Rings", icon: "trip_origin", type: "number", min: 0.3, max: 1, step: 0.05, percent: true,
          help: "How solid the rings and search bars on the dials are, over the dial's own glass." },
        { key: "glassPopups", group: "Look", label: "Pop-ups", icon: "picture_in_picture", type: "number", min: 0.3, max: 1, step: 0.05, percent: true,
          help: "How solid the pop-up dials are: volume, brightness, workspaces, notifications." },
        { key: "glassLock", group: "Look", label: "Lock dial", icon: "lock", type: "number", min: 0.3, max: 1, step: 0.05, percent: true,
          help: "How solid the lock screen's dial is, over the lock's blurred wallpaper." },
        { key: "frostDials", group: "Look", label: "Frost dials", icon: "ac_unit", type: "bool",
          help: "Hyprland blurs what is behind the dials. Off: clear glass, the windows behind stay sharp." },
        { key: "frostPopups", group: "Look", label: "Pop-up frost", icon: "ac_unit", type: "bool",
          help: "Hyprland blurs what is behind the pop-up dials. Off: clear glass." },
        { key: "frostOver", group: "Look", label: "Frost over", icon: "layers", type: "choice",
          options: [{ value: "everything", label: "Everything" }, { value: "wallpaper", label: "Wallpaper" }],
          help: "Everything: the windows behind show through, blurred. Wallpaper: only the wallpaper does, calmer." },
        { key: "lockBlur", group: "Look", label: "Lock blur", icon: "lens_blur", type: "number", min: 0, max: 10, step: 1,
          help: "How blurred the wallpaper behind the lock screen is. 0: sharp." },
        { key: "lockBackground", group: "Look", label: "Lock sheet", icon: "wallpaper", type: "choice",
          options: [{ value: "blur", label: "Blur" }, { value: "glass", label: "Liquid glass" }],
          help: "Blur: the lock covers the desktop with the wallpaper, softened. Liquid glass: a pane of glass sweeps over it, bending it at its rim (Lock blur frosts it)." },
        { key: "lockFace", group: "Look", label: "Lock face", icon: "lock_clock", type: "choice",
          options: [{ value: "dial", label: "Dial" }, { value: "eclipse", label: "Eclipse" }],
          help: "Dial: the clock, and a bead on the ring per letter. Eclipse: the time in beads; each letter pulls one into the ring, so the clock thins as you type. Wrong sends them back, right sends them to your dials." },
        { key: "liquidGlass", group: "Liquid", label: "Liquid glass", icon: "water_drop", type: "choice",
          options: [{ value: "off", label: "Off" }, { value: "on", label: "On" }, { value: "button", label: "Button" }],
          help: "Every dial, ring and pop-up turns to glass that bends the wallpaper. Button: brighter under the mouse, flatter while pressed." },
        { key: "liquidSees", group: "Liquid", label: "Sees", icon: "visibility", type: "choice",
          options: [{ value: "wallpaper", label: "Wallpaper" }, { value: "windows", label: "Snapshot" }, { value: "live", label: "Live" }],
          help: "What the glass bends. Snapshot: a picture of the screen, taken again when the windows change and every few seconds. Live: the windows as they move, video too, while a dial is open (costs the most)." },
        { key: "liquidBlur", group: "Liquid", label: "Blur", icon: "blur_on", type: "number", min: 0, max: 3, step: 0.05,
          help: "How blurred what is seen through the glass is. 0: sharp, 1: the library's strongest, 3: heavy frost." },
        { key: "liquidRings", group: "Liquid", label: "Rings", icon: "trip_origin", type: "bool",
          help: "The rings are liquid glass too. Off: a flat wash with hairline edges, so glass never sits on glass." },
        { key: "liquidFill", group: "Liquid", label: "Body fill", icon: "format_color_fill", type: "number", min: 0, max: 1, step: 0.05, percent: true,
          help: "How much of the dial's own colour fills the glass (times its Look solidity). 0: clear, only what is behind it." },
        { key: "liquidRefraction", group: "Liquid", label: "Refraction", icon: "lens", type: "number", min: 0, max: 2, step: 0.01,
          help: "How much the glass bends the wallpaper behind it." },
        { key: "liquidChroma", group: "Liquid", label: "Aberration", icon: "looks", type: "number", min: 0, max: 0.3, step: 0.005,
          help: "Chromatic aberration: rainbow fringes where the glass bends most, at the rim." },
        { key: "liquidEdge", group: "Liquid", label: "Edge light", icon: "highlight", type: "number", min: 0, max: 1, step: 0.01,
          help: "The glow along the rim and the thin highlight just inside the edge, brighter on top." },
        { key: "liquidSpecular", group: "Liquid", label: "Specular", icon: "flare", type: "number", min: 0, max: 1, step: 0.01,
          help: "Shine from four lights on the curve of the rim." },
        { key: "liquidFresnel", group: "Liquid", label: "Fresnel", icon: "light_mode", type: "number", min: 0, max: 2, step: 0.01,
          help: "The whitening where the glass turns away from you, at the very rim." },
        { key: "liquidDistortion", group: "Liquid", label: "Distortion", icon: "grain", type: "number", min: 0, max: 1, step: 0.01,
          help: "Fine grain in the glass, like hand-made glass. 0: flawless." },
        { key: "liquidDepth", group: "Liquid", label: "Bevel depth", icon: "height", type: "number", min: 1, max: 100, step: 1, unit: " px",
          help: "How far in from the edge the rim curves: a deep bevel bends more of the glass." },
        { key: "liquidBevel", group: "Liquid", label: "Bevel", icon: "rounded_corner", type: "choice",
          options: [{ value: "pill", label: "Pill" }, { value: "dome", label: "Dome" }],
          help: "Pill: curved on both faces, bending most at the rim. Dome: flat underneath, magnifying like a lens." },
        { key: "liquidOpacity", group: "Liquid", label: "Opacity", icon: "opacity", type: "number", min: 0, max: 1, step: 0.01, percent: true,
          help: "How much the liquid glass covers what is really behind it. Below 100% the windows (and Hyprland's frost) show through." },
        { key: "liquidSaturation", group: "Liquid", label: "Saturation", icon: "palette", type: "number", min: -1, max: 1, step: 0.01,
          help: "The colour of what is seen through the glass. -1: grey, 0: as it is, 1: vivid." },
        { key: "liquidTint", group: "Liquid", label: "Cool tint", icon: "ac_unit", type: "number", min: 0, max: 1, step: 0.01,
          help: "A cool blue cast, like thick glass." },
        { key: "liquidBrightness", group: "Liquid", label: "Brightness", icon: "brightness_6", type: "number", min: -0.5, max: 0.5, step: 0.01,
          help: "Darker or lighter, what is seen through the glass. -0.3: dark glass." },
        { key: "liquidShadow", group: "Liquid", label: "Shadow", icon: "ev_shadow", type: "number", min: 0, max: 1, step: 0.01, percent: true,
          help: "How dark the shadow under the glass is. 0: none." },
        { key: "liquidShadowSpread", group: "Liquid", label: "Spread", icon: "blur_circular", type: "number", min: 0, max: 40, step: 1, unit: " px",
          help: "How far the shadow under the glass spreads." },
        { key: "liquidShadowOffset", group: "Liquid", label: "Drop", icon: "vertical_align_bottom", type: "number", min: -20, max: 20, step: 1, unit: " px",
          help: "How far down the shadow falls (below 0: up)." },
        { key: "wallpaperSort", group: "Wallpaper", label: "Sort by", icon: "sort", type: "choice",
          options: [{ value: "name", label: "Name" }, { value: "time", label: "Time" }, { value: "size", label: "Size" },
                    { value: "type", label: "Type" }, { value: "none", label: "None" }],
          help: "What the wallpaper ring is ordered by." },
        { key: "wallpaperDescending", group: "Wallpaper", label: "Reverse", icon: "swap_vert", type: "bool",
          help: "Z to A, newest first, biggest first." },
        { key: "wallpaperShuffle", group: "Wallpaper", label: "Shuffle", icon: "shuffle", type: "bool",
          help: "A fixed scramble on top of the order." },
        { key: "themeScheme", group: "Wallpaper", label: "Scheme", icon: "palette", type: "choice",
          options: schemeTypes.map(t => ({ value: t, label: _schemeLabel(t), colors: schemeDots[t] || [] })),
          help: "How the wallpaper's colour becomes the desktop's colours. Each chip shows its own, from this wallpaper." },
        { key: "themeSource", group: "Wallpaper", label: "Theme from", icon: "colorize", type: "choice",
          options: [{ value: "0", label: "Main colour" }, { value: "1", label: "2nd colour" }, { value: "2", label: "3rd colour" },
                    { value: "3", label: "4th colour" }, { value: "saturation", label: "Most vivid" },
                    { value: "less-saturation", label: "Most muted" }, { value: "lightness", label: "Lightest" },
                    { value: "darkness", label: "Darkest" }].map(o => Object.assign(o, { colors: sourceDots[o.value] || [] })),
          help: "Which of the wallpaper's colours the theme starts from. Each chip shows the colour it picks." }
    ]
    function _schemeLabel(t) {
        const s = t.replace("scheme-", "").replace("-", " ")
        return s.charAt(0).toUpperCase() + s.slice(1)
    }

    // every setting, with a Preset choice first in each group that has presets
    readonly property var schema: {
        const out = []
        for (const e of _settings) {
            const list = Vars.presets[e.group]
            if (list && !out.some(o => o.key === "preset" + e.group))
                out.push({ key: "preset" + e.group, group: e.group, label: "Preset", icon: "auto_awesome", type: "choice", preset: true,
                    options: (list.some(p => p.value === "default") ? [] : [{ value: "default", label: "Default" }])
                        .concat(list.map(p => ({ value: p.value, label: p.label })))
                        .concat([{ value: "custom", label: "Custom" }]),
                    help: "A ready-made look for this group. Custom: your own values from before you picked one." })
            out.push(e)
        }
        return out
    }

    // the group's own settings (not its preset)
    function _groupKeys(group) { return _settings.filter(e => e.group === group).map(e => e.key) }

    // which preset is on (see presetLiquid)
    function _matching(group) {
        if (!_ready) return "default"
        for (const p of Vars.presets[group] || []) {
            const hit = Object.keys(p.values).every(k => { const r = check(k, p.values[k]); return r.ok && root[k] === r.value })
            if (hit) return p.value
        }
        const own = (Vars.presets[group] || []).some(p => p.value === "default")
        return !own && _groupKeys(group).every(k => root[k] === _defaults[k]) ? "default" : "custom"
    }

    // values that match no preset, per group: kept (and saved) for Custom
    property var _custom: ({})
    function _rememberCustom(group) {
        if (!Vars.presets[group] || _matching(group) !== "custom") return
        const v = {}
        for (const k of _groupKeys(group)) v[k] = root[k]
        _custom[group] = v
    }

    // "" when it worked, or the reason it didn't
    function applyPreset(group, name) {
        let values = null
        const own = (Vars.presets[group] || []).find(p => p.value === name)
        if (own) values = own.values
        else if (name === "default") { values = {}; for (const k of _groupKeys(group)) values[k] = _defaults[k] }
        else if (name === "custom") values = _custom[group] || null
        if (!values) return name === "custom" ? "no custom values for " + group + " yet" : "no preset '" + name + "' in " + group
        for (const k in values) {
            const r = check(k, values[k])
            if (r.ok) root[k] = r.value
        }
        revision++
        _save()
        return ""
    }

    // the groups, in the order they first appear, with the icon of their pill
    readonly property var groupIcons: ({
        Design: "style", Feel: "touch_app", Sound: "volume_up", Hints: "lightbulb", Corners: "rounded_corner",
        Notify: "notifications", Dials: "apps", Look: "blur_on", Liquid: "water_drop", Wallpaper: "wallpaper"
    })
    readonly property var groups: {
        const out = []
        for (const e of schema) if (out.indexOf(e.group) < 0) out.push(e.group)
        return out
    }
    function inGroup(group) { return schema.filter(e => e.group === group) }
    function entry(key) { return schema.find(e => e.key === key) || null }

    // goes up by one on every change, so a binding that reads values through valueOf()
    // (which a binding can't follow by itself) can follow this instead
    property int revision: 0

    function valueOf(key) { return root[key] }

    // ── the values from variables.js ── remembered before anything is changed
    property var _defaults: ({})
    Component.onCompleted: {
        const d = {}
        for (const e of schema) d[e.key] = root[e.key]
        _defaults = d
        _ready = true
        revision++
        _apply(_stored)
        applyFrost()
    }
    property bool _ready: false
    function defaultOf(key) { return _defaults[key] }
    function isDefault(key) { return root[key] === _defaults[key] }

    // the value as shown: "On", "40%", "300 ms", a choice's label
    function shown(key) {
        const e = entry(key)
        if (!e) return ""
        const v = root[key]
        if (e.type === "bool") return v ? "On" : "Off"
        if (e.type === "choice") { const o = e.options.find(o => o.value === v); return o ? o.label : String(v) }
        if (e.type === "number") {
            if (e.percent) return Math.round(v * 100) + "%"
            return String(Math.round(v * 1000) / 1000) + (e.unit || "")
        }
        return String(v)
    }

    // ── checking ── turns what was given into a value of the setting's type:
    // { ok: true, value } or { ok: false, error }
    function check(key, given) {
        const e = entry(key)
        if (!e) return { ok: false, error: "unknown setting '" + key + "'" }
        const text = String(given).trim()
        if (e.type === "bool") {
            if (typeof given === "boolean") return { ok: true, value: given }
            const t = text.toLowerCase()
            if (["true", "1", "yes", "y", "on", "t"].indexOf(t) >= 0) return { ok: true, value: true }
            if (["false", "0", "no", "n", "off", "f"].indexOf(t) >= 0) return { ok: true, value: false }
            return { ok: false, error: "'" + key + "' is on / off (got '" + text + "')" }
        }
        if (e.type === "number") {
            const n = typeof given === "number" ? given : Number(text)
            if (text === "" || !isFinite(n)) return { ok: false, error: "'" + key + "' is a number (got '" + text + "')" }

            // into its range, then onto its step (counted from min, and rounded so 0.1
            // steps don't pick up 0.30000000000000004)
            const c = Math.max(e.min, Math.min(e.max, n))
            const s = e.min + Math.round((c - e.min) / e.step) * e.step
            return { ok: true, value: Math.round(s * 1e6) / 1e6 }
        }
        if (e.type === "choice") {
            const o = e.options.find(o => String(o.value) === text || o.label.toLowerCase() === text.toLowerCase())
            if (!o) return { ok: false, error: "'" + key + "' is one of: " + e.options.map(o => o.value).join(", ") + " (got '" + text + "')" }
            return { ok: true, value: o.value }
        }

        // text: never the words a broken caller sends for "nothing", and one line only
        if (["undefined", "null", "NaN", ""].indexOf(text) >= 0 || /[\n\r"\\]/.test(text))
            return { ok: false, error: "refusing to store '" + text + "' in '" + key + "'" }
        return { ok: true, value: text }
    }

    // ── changing ── each returns "" when it worked, or the reason it didn't
    function set(key, given) {
        const r = check(key, given)
        if (!r.ok) return r.error
        const e = entry(key)
        if (e.preset) return r.value === root[key] ? "" : applyPreset(e.group, r.value)
        if (root[key] !== r.value) {
            root[key] = r.value
            revision++
            _rememberCustom(e.group)
            _save()

            // a new scheme or source recolours the desktop now, from the wallpaper on screen
            // (here, not on the property: loading the saved settings must not re-theme)
            if (key === "themeScheme" || key === "themeSource") applyTheme(Backdrop.wallpaper)

            // screen time's switch is the shared one (every shell's): the counting follows it
            if (key === "screenTime") Quickshell.execDetached([Quickshell.shellDir + "/../scripts/screentime.py", r.value ? "on" : "off"])
            if (key === "themeSource") _previewTheme()
        }
        return ""
    }

    // a bool flips; a choice with an "off" (liquidGlass, ticks, cornerVolume) goes off, and
    // back on to what it was before (or its first other option)
    function toggle(key) {
        const e = entry(key)
        if (!e) return "unknown setting '" + key + "'"
        const offable = e.type === "choice" && e.options.some(o => o.value === "off")
        if (e.type !== "bool" && !offable) return "'" + key + "' is not on / off (it is " + shown(key) + ")"
        if (e.type === "bool") return set(key, !root[key])
        if (root[key] !== "off") {
            _wasOn[key] = root[key]
            return set(key, "off")
        }
        const back = _wasOn[key] || (_defaults[key] !== "off" ? _defaults[key] : e.options.find(o => o.value !== "off").value)
        return set(key, back)
    }
    property var _wasOn: ({})

    // the next (dir 1) or previous (dir -1) value: a choice's next option, a number's next
    // step, a bool flipped. `wrap` lets a choice go round from the last to the first
    function step(key, dir, wrap) {
        const e = entry(key)
        if (!e) return "unknown setting '" + key + "'"
        if (e.type === "bool") return set(key, !root[key])
        if (e.type === "number") return set(key, root[key] + dir * e.step)
        if (e.type === "choice") {
            const n = e.options.length
            let i = e.options.findIndex(o => o.value === root[key]) + dir
            i = wrap ? ((i % n) + n) % n : Math.max(0, Math.min(n - 1, i))
            return set(key, e.options[i].value)
        }
        return "'" + key + "' is text: set it"
    }

    // back to the value from variables.js
    function reset(key) {
        if (!entry(key)) return "unknown setting '" + key + "'"
        return set(key, _defaults[key])
    }
    function resetAll() { for (const e of _settings) set(e.key, _defaults[e.key]) }

    // ── remembering ── only what differs from variables.js is stored
    property var _stored: ({})
    function _apply(o) {
        if (!_ready || !o || typeof o !== "object") return
        let changed = false
        for (const e of _settings) {
            const want = e.key in o ? check(e.key, o[e.key]) : { ok: true, value: _defaults[e.key] }
            if (want.ok && root[e.key] !== want.value) { root[e.key] = want.value; changed = true }
        }
        if (changed) revision++
    }

    // Settings that used to take two switches are one now; a file saved before keeps what
    // it meant: Ticks + Soft ticks → ticks, Volume arc + Music wave → cornerVolume, and
    // Translucent + the glass sliders → the glass sliders alone (Translucent on keeps the
    // glass it had; off means solid)
    function _migrate(o) {
        const n = Object.assign({}, o)
        let changed = false
        if ("tickSound" in n || "softTicks" in n) {
            n.ticks = n.tickSound === false ? "off" : n.softTicks === false ? "even" : "soft"
            delete n.tickSound; delete n.softTicks
            changed = true
        }
        if (typeof n.cornerVolume === "boolean" || "cornerMusic" in n) {
            const level = n.cornerVolume !== false, music = n.cornerMusic !== false
            n.cornerVolume = level && music ? "both" : level ? "level" : music ? "music" : "off"
            delete n.cornerMusic
            changed = true
        }
        if ("translucent" in n) {
            const was = { glassDials: 0.72, glassRings: 0.8, glassPopups: 0.62, glassLock: 0.6 }
            for (const k in was)
                if (n.translucent === true && !(k in n)) n[k] = was[k]
                else if (n.translucent !== true) delete n[k]
            delete n.translucent
            changed = true
        }

        // Theme colour (an index, 0..4, where 4 always failed: matugen takes 0..3) → Theme from
        if ("themeColor" in n) {
            n.themeSource = String(Math.max(0, Math.min(3, Math.round(Number(n.themeColor)) || 0)))
            delete n.themeColor
            changed = true
        }
        return { settings: n, changed: changed }
    }

    property FileView _file: FileView {
        path: Vars.settingsPath

        // there's no file until the first change
        printErrors: false

        // read again when it changes: edited by hand, or changed by another running shell
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const o = JSON.parse(text())
                if (o && typeof o === "object") {
                    const m = root._migrate(o)
                    root._stored = m.settings
                    root._apply(m.settings)
                    if (o._custom && typeof o._custom === "object") root._custom = o._custom

                    // written back in the new shape
                    if (m.changed) root._save()
                }
            } catch (e) { /* empty or broken: keep what we have */ }
        }
    }

    // a knob being turned changes a value many times a second: write once it rests
    property Timer _saveTimer: Timer {
        interval: 250
        onTriggered: root._write()
    }
    function _save() { _saveTimer.restart() }

    // to a temp file first, then renamed over the real one (never a half-written file)
    property Process _writer: Process {}
    function _write() {
        const o = {}
        for (const e of _settings) if (root[e.key] !== _defaults[e.key]) o[e.key] = root[e.key]
        _stored = o
        if (Object.keys(_custom).length > 0) o._custom = _custom
        _writer.exec(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s\\n" "$2" > "$1.tmp" && mv "$1.tmp" "$1"',
                      "sh", Vars.settingsPath, JSON.stringify(o, null, 2)])
    }

    // from a keybind or the terminal (the same verbs as `omniformis qs`):
    //   qs ipc call prefs list
    //   qs ipc call prefs get tickVolume
    //   qs ipc call prefs set tickVolume 0.3
    //   qs ipc call prefs toggle dnd
    //   qs ipc call prefs reset tickVolume        (prefs resetAll)
    property IpcHandler _ipc: IpcHandler {
        target: "prefs"
        function list(): string {
            return root.schema.map(e => e.key + ": " + root.shown(e.key)
                + (root.isDefault(e.key) ? "" : "   (variables.js: " + root._defaults[e.key] + ")")
                + "   - " + e.group + " | " + e.help).join("\n")
        }
        function listJson(): string {
            return JSON.stringify(root.schema.map(e => ({
                key: e.key, group: e.group, label: e.label, type: e.type, value: root[e.key],
                "default": root._defaults[e.key], help: e.help,
                options: e.options ? e.options.map(o => o.value) : undefined, min: e.min, max: e.max
            })), null, 2)
        }
        function get(key: string): string { return root.entry(key) ? String(root[key]) : "unknown setting '" + key + "'" }
        function set(key: string, value: string): string { const r = root.set(key, value); return r === "" ? "Set '" + key + "' to " + root.shown(key) : "Error: " + r }
        function toggle(key: string): string { const r = root.toggle(key); return r === "" ? "Set '" + key + "' to " + root.shown(key) : "Error: " + r }
        function reset(key: string): string { const r = root.reset(key); return r === "" ? "Set '" + key + "' to " + root.shown(key) : "Error: " + r }
        function resetAll(): void { root.resetAll() }
    }
}

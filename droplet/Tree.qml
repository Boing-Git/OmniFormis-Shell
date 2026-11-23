pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

// What the circles are: every thing the circle shell can do, as a tree. A circle is either
// a group (dragging onto it brings out the circles inside it) or a task (the end of a
// chain: dragging onto it does it).
//
//   group:  { label, icon, leaf: false, children: () => [circle, ...] }
//   task:   { label, icon, leaf: true, done: "what it says once done", run: () => ... }
//
// What a circle can also have:
//   note    a second, smaller line under its name ("Connected", the artist)
//   on      true: a dot on its rim (it is switched on / connected / playing)
//   image   an icon file shown instead of the symbol (an app)
//   art     a picture that fills the whole circle (the cover of what's playing)
//   big     true: a bigger circle
//   live    a function → this circle as it is now: once it is in the chain, it keeps up
//           (the cover and title of what's playing)
//   stay    (task) true: the chain stays out after it ran, to do it again or do another
//           (next track, a volume level); without it the chain lights up and is let go
//   search  (group) a function(text) → [circle, ...]: while this group is the last of the
//           chain, typing narrows what it offers (apps by name), or is handed to its
//           tasks (a Wi-Fi password); `ask` is the hint shown for it;
//           `secret` shows what is typed as dots
//
// Add a circle by adding it to roots() or to a group's list: nothing else needs to change.
Singleton {
    id: root

    // CIRCLES_DEMO=1: tasks don't really run (they only say what they would do), and
    // Wi-Fi shows made-up networks when it finds none. For trying the shell out safely
    readonly property bool demo: Quickshell.env("CIRCLES_DEMO") === "1"

    // what the last task did, e.g. "Connecting to Home"
    property string last: ""

    // true while the shell is open: Wi-Fi only lists what's around while it scans
    property bool open: false

    function task(label, icon, done, fn, more) {
        return Object.assign({ label: label, icon: icon, leaf: true, done: done, run: () => {
            root.last = done
            if (root.demo) console.log("circle shell (demo): " + done)
            else fn()
        } }, more || {})
    }
    function group(label, icon, children, more) {
        return Object.assign({ label: label, icon: icon, leaf: false, children: children }, more || {})
    }

    // the dotfiles' shared scripts (Droplet is a shell of its own: it never calls another shell)
    function script(name) { return Quickshell.shellDir + "/../scripts/" + name }

    // the first circles: what the seed opens into
    function roots() {
        return [
            group("Control center", "tune", control),
            group("Apps", "apps", () => appsFor(""), { search: appsFor, ask: "type to find an app" }),
            mediaCircle(),
            group("Windows", "select_window", windows),
            group("Workspaces", "space_dashboard", workspaces),
            group("Tools", "construction", tools),
            Settings.screenTime ? group("Screen time", "hourglass_top", screenTime, { note: pretty(total(0)) + " today" }) : null,
            Settings.automations ? group("Automations", "bolt", automations, { note: automationList.length + (automationList.length === 1 ? " automation" : " automations") }) : null,
            group("Settings", "settings", settings),
            group("Shells", "swap_horiz", shells),
            group("Power", "power_settings_new", power)
        ].filter(c => c)
    }

    // ── settings ── Droplet's own (Settings.qml): each one flips as you drop onto it
    function settings() {
        return Settings.all.map(s => task(s.label, s.icon, s.label + (Settings[s.key] ? " off" : " on"),
            () => Settings.toggle(s.key), { on: Settings[s.key], note: Settings[s.key] ? "On" : "Off", stay: true }))
    }

    // ══════════════════════════════ screen time ═══════════════════════════════
    // How long each app had you, from the tracker every shell shares (scripts/screentime.py):
    // today's apps, longest first (dropping onto one opens it), and the last seven days
    property var usage: ({ on: true, days: [] })
    Process {
        id: usageReader
        command: [root.script("screentime.py"), "json", "7"]
        stdout: StdioCollector { onStreamFinished: { try { root.usage = JSON.parse(text) } catch (e) {} } }
    }
    // ══════════════════════════════ automations ═══════════════════════════════
    // Runs of steps kept in ~/.config/automations (scripts/automate/automate.py, a tool of its
    // own that works in any shell): dropping onto one runs it, on its own (it outlives Droplet)
    property var automationList: []
    // opens the AI with a question begun (Assistant.qml listens)
    signal startAsk(string text)
    Process {
        id: automationLister
        command: ["python3", root.script("automate/automate.py"), "list", "--json"]
        stdout: StdioCollector { onStreamFinished: { try { root.automationList = JSON.parse(text) } catch (e) {} } }
    }
    function automations() {
        const runs = automationList.map(a => task(a.name, a.icon || "bolt", "Running " + a.name,
            () => Quickshell.execDetached(["python3", root.script("automate/automate.py"), "run", a.id]), { note: a.steps + " steps" }))
        // always last: how to make one (the AI opens with the question begun)
        const none = runs.length ? "" : "None yet. "
        return runs.concat(Settings.assistant
            ? [task(none + "Make one: tell the AI", "auto_awesome", "Finish the sentence for the AI",
                    () => root.startAsk("make an automation that "))]
            : [task(none + "Make one: a file in ~/.config/automations", "bolt", "Nothing to run", () => {}, { stay: true })])
    }

    // opening the shell reads what can change meanwhile: today's screen time, the automations,
    // and the wallpapers the first time
    onOpenChanged: {
        if (!open) return
        if (Settings.automations) automationLister.running = true
        if (Settings.screenTime) usageReader.running = true
        if (wallpaperFiles.length === 0) wallLister.running = true
    }
    function total(i) {
        const d = usage.days[i]
        return d ? Object.values(d.apps).reduce((a, b) => a + b, 0) : 0
    }
    function pretty(s) {
        const m = Math.floor(s / 60)
        return m >= 60 ? Math.floor(m / 60) + " h " + (m % 60) + " min" : m >= 1 ? m + " min" : "< 1 min"
    }
    // a window class ("firefox", "org.wezfurlong.wezterm") as the app it belongs to
    function entryOf(cls) { return DesktopEntries.heuristicLookup(cls) }
    function usageCircle(cls, seconds) {
        const e = entryOf(cls)
        return task(e ? e.name : cls, "apps", "Opening " + (e ? e.name : cls), () => { if (e) e.execute() },
            { image: e ? Quickshell.iconPath(e.icon, true) : "", note: pretty(seconds) })
    }
    function screenTime() {
        const today = usage.days[0] ? usage.days[0].apps : {}
        const apps = Object.keys(today).sort((a, b) => today[b] - today[a]).slice(0, 9).map(c => usageCircle(c, today[c]))
        if (apps.length === 0) apps.push(task("Nothing yet today", "hourglass_empty", "Nothing to open", () => {}, { stay: true }))
        return apps.concat([group("Last 7 days", "date_range", week, { note: pretty([0, 1, 2, 3, 4, 5, 6].reduce((a, i) => a + total(i), 0)) })])
    }
    function week() {
        return usage.days.map((d, i) => group(i === 0 ? "Today" : i === 1 ? "Yesterday" : Qt.formatDate(new Date(d.date + "T12:00"), "dddd"),
            "calendar_today", () => {
                const apps = Object.keys(d.apps).sort((a, b) => d.apps[b] - d.apps[a]).slice(0, 9)
                return apps.length ? apps.map(c => usageCircle(c, d.apps[c])) : [task("Nothing that day", "hourglass_empty", "Nothing to open", () => {}, { stay: true })]
            }, { note: pretty(total(i)) }))
    }

    // ── shells ── the dotfiles' other shells (scripts/shell): the new one starts before this goes
    function shells() {
        return [["Dial-E", "dial-e", "donut_large"], ["Puffy", "puffy", "bubble_chart"]].map(s =>
            task(s[0], s[2], "Switching to " + s[0], () => Quickshell.execDetached([Quickshell.shellDir + "/../scripts/shell", "switch", s[1]])))
    }

    // ═════════════════════════════ control center ═════════════════════════════
    function control() {
        const a = Bluetooth.defaultAdapter
        return [
            group("Wi-Fi", Networking.wifiEnabled ? "wifi" : "wifi_off", wifi, { on: Networking.wifiEnabled, note: wifiNote() }),
            group("Bluetooth", a && a.enabled ? "bluetooth" : "bluetooth_disabled", bluetooth, { on: !!a && a.enabled, note: btNote() }),
            group("Volume", muted ? "volume_off" : "volume_up", volume, { note: muted ? "Muted" : Math.round(level * 100) + "%" }),
            group("Sound out", "speaker", outputs, { note: sink ? nameOf(sink) : "" }),
            group("Microphone", micMuted ? "mic_off" : "mic", microphones, { note: source ? nameOf(source) : "" }),
            group("Brightness", "brightness_6", brightness)
        ]
    }

    // ── Wi-Fi ── on / off, then the networks around: connected first, then the strongest.
    // A network: connect or disconnect, and forget it if it's a saved one. A secured one
    // that isn't saved asks for its password: type it while its circle is the last one
    Instantiator {
        model: Networking.devices
        delegate: QtObject {
            required property var modelData
            readonly property Binding scan: Binding {
                target: modelData
                property: "scannerEnabled"
                value: root.open
                when: !!modelData && modelData.type === DeviceType.Wifi
            }
        }
    }
    function networks() {
        const nets = []
        for (const d of Networking.devices.values) {
            if (d.type !== DeviceType.Wifi) continue
            for (const n of d.networks.values) if (n.name !== "") nets.push(n)
        }
        return nets.sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
    }
    function wifiNote() {
        if (!Networking.wifiEnabled) return "Off"
        const n = networks().find(n => n.connected)
        return n ? n.name : "Not connected"
    }
    function bars(strength) { return strength > 0.66 ? "wifi" : strength > 0.33 ? "wifi_2_bar" : "wifi_1_bar" }

    // the kinds of network that want a password typed (a company's sign-in kinds don't:
    // those need settings a circle can't ask for, so they are only tried as they are)
    function secured(n) {
        return [WifiSecurityType.Sae, WifiSecurityType.Wpa2Psk, WifiSecurityType.WpaPsk, WifiSecurityType.StaticWep].indexOf(n.security) >= 0
    }
    function wifi() {
        const on = Networking.wifiEnabled
        const out = [task(on ? "Turn off" : "Turn on", on ? "wifi_off" : "wifi", on ? "Wi-Fi is off" : "Wi-Fi is on",
            () => { Networking.wifiEnabled = !on })]
        if (!on && !root.demo) return out
        const nets = networks()
        for (const n of nets.slice(0, 9)) out.push(networkCircle(n))
        if (root.demo && nets.length === 0) {
            out.push(group("Home", "wifi", () => [
                task("Disconnect", "link_off", "Disconnected from Home", () => {}),
                task("Forget", "delete", "Forgot Home", () => {})
            ], { on: true, note: "Connected" }))
            for (const name of ["Cafe upstairs", "Phone"]) out.push(group(name, "wifi_2_bar", () => passwordTasks(name, null, ""),
                { search: text => passwordTasks(name, null, text), ask: "type its password", secret: true, note: "Secured" }))
        }
        return out
    }
    function networkCircle(n) {
        const needsPassword = !n.known && !n.connected && secured(n)
        const kids = text => {
            if (needsPassword) return passwordTasks(n.name, n, text)
            const list = [n.connected
                ? task("Disconnect", "link_off", "Disconnected from " + n.name, () => n.disconnect())
                : task("Connect", "link", "Connecting to " + n.name, () => n.connect())]
            if (n.known) list.push(task("Forget", "delete", "Forgot " + n.name, () => n.forget()))
            return list
        }
        return group(n.name, n.connected ? "wifi_tethering" : bars(n.signalStrength), () => kids(""), {
            on: n.connected,
            note: n.connected ? "Connected" : n.known ? "Saved" : secured(n) ? "Secured" : "Open",
            search: needsPassword ? kids : undefined, ask: needsPassword ? "type its password" : undefined, secret: needsPassword
        })
    }

    // the one task of a network that wants a password: it carries what was typed so far
    function passwordTasks(name, n, text) {
        const ready = text.length >= 8
        return [task(ready ? "Connect" : "Password…", ready ? "key" : "password",
            ready ? "Connecting to " + name : "Type the password first (8 or more)",
            () => { if (ready && n) n.connectWithPsk(text) }, { stay: !ready, note: "•".repeat(Math.min(text.length, 16)) })]
    }

    // ── Bluetooth ── on / off and scan, then the devices: a known one connects,
    // disconnects or is unpaired; one found by the scan is paired
    function btNote() {
        const a = Bluetooth.defaultAdapter
        if (!a || !a.enabled) return "Off"
        const d = Bluetooth.devices.values.find(d => d.connected)
        return d ? (d.name || d.deviceName) : "On"
    }
    function bluetooth() {
        const a = Bluetooth.defaultAdapter
        if (!a) return [task("No adapter", "bluetooth_disabled", "Nothing to do", () => {})]
        const out = [task(a.enabled ? "Turn off" : "Turn on", a.enabled ? "bluetooth_disabled" : "bluetooth",
            a.enabled ? "Bluetooth is off" : "Bluetooth is on", () => { a.enabled = !a.enabled })]
        if (!a.enabled) return out
        out.push(task(a.discovering ? "Stop scan" : "Scan", a.discovering ? "bluetooth_searching" : "search",
            a.discovering ? "Stopped scanning" : "Scanning for devices", () => { a.discovering = !a.discovering },
            { stay: true, on: a.discovering }))
        const devs = Bluetooth.devices.values
            .filter(d => d.paired || d.connected || a.discovering)
            .sort((x, y) => (y.connected - x.connected) || (y.paired - x.paired))
        for (const d of devs.slice(0, 8)) {
            const name = d.name !== "" ? d.name : d.deviceName
            out.push(group(name, d.connected ? "bluetooth_connected" : d.paired ? "bluetooth" : "add_link", () => {
                if (!d.paired) return [task("Pair", "add_link", "Pairing " + name, () => {
                    if (!a.pairable) a.pairable = true
                    d.trusted = true
                    d.pair()
                })]
                return [
                    d.connected
                        ? task("Disconnect", "link_off", "Disconnected " + name, () => d.disconnect())
                        : task("Connect", "link", "Connecting " + name, () => d.connect()),
                    task("Unpair", "delete", "Unpaired " + name, () => d.forget())
                ]
            }, { on: d.connected, note: d.connected ? "Connected" : d.paired ? "Paired" : "New" }))
        }
        return out
    }

    // ── sound ── the volume (mute, or straight to a level), where it plays, and the microphone
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var nodes: Pipewire.nodes.values
    PwObjectTracker { objects: root.nodes }
    readonly property bool muted: !!(sink && sink.audio && sink.audio.muted)
    readonly property real level: sink && sink.audio ? Math.min(1, sink.audio.volume) : 0
    readonly property bool micMuted: !!(source && source.audio && source.audio.muted)
    function nameOf(n) { return n ? (n.nickname || n.description || n.name) : "" }
    function volume() {
        const out = [task(muted ? "Unmute" : "Mute", muted ? "volume_up" : "volume_off", muted ? "Sound is on" : "Muted",
            () => { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted }, { stay: true })]
        for (const p of [0, 25, 50, 75, 100]) out.push(task(p + "%", p === 0 ? "volume_mute" : p <= 50 ? "volume_down" : "volume_up",
            "Volume at " + p + "%", () => { if (sink && sink.audio) { sink.audio.muted = false; sink.audio.volume = p / 100 } },
            { stay: true, on: Math.abs(level * 100 - p) < 6 && !muted }))
        return out
    }
    function outputs() {
        const list = nodes.filter(n => n.audio && n.isSink && !n.isStream)
        if (list.length === 0) return [task("No outputs", "volume_off", "Nothing to do", () => {})]
        return list.slice(0, 10).map(n => task(nameOf(n), n.name.indexOf("bluez") === 0 ? "headphones" : n.name.indexOf("hdmi") >= 0 ? "tv" : "speaker",
            "Sound plays on " + nameOf(n), () => { Pipewire.preferredDefaultAudioSink = n }, { on: n === sink, stay: true }))
    }
    function microphones() {
        const out = [task(micMuted ? "Unmute" : "Mute", micMuted ? "mic" : "mic_off", micMuted ? "Microphone is on" : "Microphone muted",
            () => { if (source && source.audio) source.audio.muted = !source.audio.muted }, { stay: true })]
        for (const n of nodes.filter(n => n.audio && !n.isSink && !n.isStream).slice(0, 8))
            out.push(task(nameOf(n), "mic", "Listening on " + nameOf(n), () => { Pipewire.preferredDefaultAudioSource = n }, { on: n === source, stay: true }))
        return out
    }

    // ── brightness ── straight to a level: a laptop's backlight, else the monitor over DDC
    Process { id: brightProc }
    function brightness() {
        return [10, 25, 50, 75, 100].map(p => task(p + "%", p <= 25 ? "brightness_low" : p <= 50 ? "brightness_medium" : "brightness_high",
            "Brightness at " + p + "%", () => brightProc.exec(["sh", "-c",
                "brightnessctl -q -c backlight set " + p + "% 2>/dev/null || ddcutil --noverify setvcp 10 " + p]), { stay: true }))
    }

    // ══════════════════════════════════ apps ══════════════════════════════════
    // With nothing typed: the first nine of your own order (the dial shell's launcher
    // keeps it; the alphabet otherwise), then All apps, the alphabet in groups. Typing
    // narrows it to the names that start with what you typed, then the ones that contain it
    // the apps you use most this week first (screen time), then by name
    function allApps() {
        const used = {}
        for (const d of usage.days) for (const c in d.apps) {
            const e = entryOf(c)
            if (e) used[e.id] = (used[e.id] || 0) + d.apps[c]
        }
        return DesktopEntries.applications.values.filter(e => !e.noDisplay)
            .sort((a, b) => ((used[b.id] || 0) - (used[a.id] || 0)) || a.name.localeCompare(b.name))
    }
    function appCircle(e) {
        return task(e.name, "apps", "Opening " + e.name, () => e.execute(), { image: Quickshell.iconPath(e.icon, true) })
    }
    function appsFor(text) {
        const q = text.trim().toLowerCase()
        const all = allApps()
        if (q === "") return all.slice(0, 9).map(appCircle).concat([group("All apps", "grid_view", alphabet)])
        const starts = all.filter(e => e.name.toLowerCase().startsWith(q))
        const has = all.filter(e => !e.name.toLowerCase().startsWith(q)
            && (e.name + " " + (e.genericName || "") + " " + (e.keywords || []).join(" ")).toLowerCase().includes(q))
        const found = starts.concat(has).slice(0, 10).map(appCircle)
        return found.length > 0 ? found : [task("Nothing called that", "search_off", "Nothing to open", () => {}, { stay: true })]
    }
    // (the app list is read in the background the first time it is asked for: ask at
    // once, so it is there when Apps is first opened)
    readonly property int appCount: DesktopEntries.applications.values.length
    Component.onCompleted: void appCount

    readonly property int perGroup: 12
    function alphabet() {
        const all = DesktopEntries.applications.values.filter(e => !e.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
        const out = []
        for (let i = 0; i < all.length; i += perGroup) {
            const part = all.slice(i, i + perGroup)
            const first = part[0].name.charAt(0).toUpperCase(), last = part[part.length - 1].name.charAt(0).toUpperCase()
            out.push(group(first === last ? first : first + " – " + last, "apps", () => part.map(appCircle)))
        }
        return out
    }

    // ═════════════════════════════════ media ══════════════════════════════════
    // The circle itself wears the cover and says what's playing. Inside: the transport
    // (these stay, to press again), ten seconds back and on, shuffle and repeat where the
    // player has them, bringing the player to the front, and the other players
    readonly property var player: {
        const ps = Mpris.players.values
        return ps.find(x => x.isPlaying) || ps[0] || null
    }
    function mediaCircle() {
        const p = player
        return group(p && p.trackTitle ? p.trackTitle : "Media", "music_note", () => media(p), {
            art: p && p.trackArtUrl ? p.trackArtUrl : "", big: true, on: !!p && p.isPlaying, live: mediaCircle,
            note: p ? (p.trackArtist || p.identity || "") : "Nothing playing"
        })
    }
    function media(p) {
        if (!p) return [task("Nothing playing", "music_off", "Nothing to do", () => {}, { stay: true })]
        const out = [
            task("Previous", "skip_previous", "Previous track", () => { if (p.canGoPrevious) p.previous() }, { stay: true }),
            task(p.isPlaying ? "Pause" : "Play", p.isPlaying ? "pause" : "play_arrow", p.isPlaying ? "Paused" : "Playing",
                () => { if (p.canTogglePlaying) p.togglePlaying() }, { stay: true, big: true }),
            task("Next", "skip_next", "Next track", () => { if (p.canGoNext) p.next() }, { stay: true })
        ]
        if (p.canSeek && p.positionSupported) {
            out.unshift(task("Back 10 s", "replay_10", "Back ten seconds", () => p.seek(-10), { stay: true }))
            out.push(task("On 10 s", "forward_10", "On ten seconds", () => p.seek(10), { stay: true }))
        }
        if (p.shuffleSupported) out.push(task("Shuffle", "shuffle", p.shuffle ? "Shuffle is off" : "Shuffle is on",
            () => { p.shuffle = !p.shuffle }, { stay: true, on: p.shuffle }))
        if (p.loopSupported) out.push(task("Repeat", p.loopState === MprisLoopState.Track ? "repeat_one" : "repeat", "Repeat changed", () => {
            p.loopState = p.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                : p.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
        }, { stay: true, on: p.loopState !== MprisLoopState.None }))
        if (p.canRaise) out.push(task("Show player", "open_in_new", "Showing " + (p.identity || "the player"), () => p.raise()))
        return out
    }

    // ════════════════════════════════ windows ═════════════════════════════════
    // every open window: bring it to the front, make it fill the screen, or close it
    function windows() {
        const list = ToplevelManager.toplevels.values
        if (list.length === 0) return [task("No windows", "web_asset_off", "Nothing to do", () => {})]
        return list.slice(0, 12).map(w => {
            const e = DesktopEntries.heuristicLookup(w.appId)
            return group(w.title || w.appId, "web_asset", () => [
                task("Go to", "open_in_new", "Went to " + (w.title || w.appId), () => w.activate()),
                task(w.fullscreen ? "Leave full screen" : "Full screen", w.fullscreen ? "fullscreen_exit" : "fullscreen",
                    "Full screen changed", () => { w.fullscreen = !w.fullscreen }),
                task("Close", "close", "Closed " + (w.title || w.appId), () => w.close())
            ], { image: e ? Quickshell.iconPath(e.icon, true) : "", on: w.activated, note: e ? e.name : w.appId })
        })
    }

    // ── workspaces ── each one is a task: go there
    function workspaces() {
        const out = []
        const here = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0
        for (let i = 1; i <= 8; i++) out.push(task(String(i), "counter_" + i, "On workspace " + i,
            () => Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ workspace = ${i} })` : `workspace ${i}`), { on: i === here }))
        return out
    }

    // ── tools ── Droplet's own: a screenshot (once the circles have run back in, so they
    // aren't in it), and the wallpapers (the colours follow, through theme-apply.sh)
    readonly property string shotDir: Quickshell.env("HOME") + "/Pictures/Screenshots"
    function tools() {
        return [
            task("Screenshot", "screenshot_monitor", "Screenshot copied and saved", () => Quickshell.execDetached(["sh", "-c",
                'sleep 0.9; mkdir -p "$1"; f="$1/$(date +%Y-%m-%d_%H-%M-%S).png"; grim "$f" && wl-copy < "$f"', "sh", shotDir])),
            task("Screenshot to edit", "draw", "Opening it in Satty", () => Quickshell.execDetached(["sh", "-c",
                'sleep 0.9; grim - | satty --filename - --output-filename "$1/$(date +%Y-%m-%d_%H-%M-%S).png"', "sh", shotDir])),
            group("Wallpapers", "wallpaper", () => wallpapersFor(""), { search: wallpapersFor, ask: "type part of its name" })
        ]
    }

    // the pictures in ~/Pictures/Wallpapers (and the folders in it), read when the shell opens
    property var wallpaperFiles: []
    Process {
        id: wallLister
        command: ["sh", "-c", 'find -L "$HOME/Pictures/Wallpapers" -maxdepth 3 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \\) 2>/dev/null | sort | head -n 500']
        stdout: StdioCollector { onStreamFinished: root.wallpaperFiles = text.split("\n").filter(l => l !== "") }
    }
    function wallpapersFor(text) {
        const q = text.trim().toLowerCase()
        const hits = wallpaperFiles.filter(f => f.split("/").pop().toLowerCase().includes(q)).slice(0, 9)
        if (hits.length === 0) return [task("No wallpaper called that", "search_off", "Nothing to set", () => {}, { stay: true })]
        return hits.map(f => {
            const name = f.split("/").pop().replace(/\.[^.]+$/, "").replace(/[-_]+/g, " ")
            return task(name, "wallpaper", "Wallpaper set: " + name, () => Quickshell.execDetached([root.script("theme-apply.sh"), f]),
                { art: "file://" + f.split("/").map(encodeURIComponent).join("/") })
        })
    }

    // ── power ── each one asks once more, so a slip of the hand can't shut the machine down
    Process { id: runner }
    function power() {
        const items = [
            ["Lock", "lock", "Locked", ["loginctl", "lock-session"]],
            ["Suspend", "bedtime", "Suspending", ["systemctl", "suspend"]],
            ["Log out", "logout", "Logging out", ["hyprctl", "dispatch", "exit"]],
            ["Restart", "restart_alt", "Restarting", ["systemctl", "reboot"]],
            ["Shut down", "power_settings_new", "Shutting down", ["systemctl", "poweroff"]]
        ]
        return items.map(i => group(i[0], i[1], () => [task("Yes, " + i[0].toLowerCase(), "check", i[2], () => runner.exec(i[3]))]))
    }
}

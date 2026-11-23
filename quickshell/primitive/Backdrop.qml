pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import "../variables.js" as Vars

// What liquid glass (LiquidGlass.qml) sees through itself: the wallpaper on screen. A
// layer-shell window can't see the windows under it, so the glass bends the wallpaper, the
// way Frost over: Wallpaper frosts only the wallpaper. shell.qml tells it which wallpaper is
// on screen (the wallpaper dial knows) and the screen's size.
//
// The picture covers the screen as awww shows it (scaled to fill, centred, the rest cropped).
// The Blur setting is a blurred copy made ahead of time with ImageMagick (one small file per
// wallpaper and level in Vars.liquidCachePath), as the lock does: no live blur (Qt 6.12's
// effects crash, see WallpaperRing.qml), and blurred glass costs nothing more to draw.
QtObject {
    id: root

    // ── told by shell.qml ──
    // the wallpaper on screen ("" while not known), the screen's size (logical px) and its
    // device pixel ratio
    property string wallpaper: ""
    property size screenSize: Qt.size(0, 0)
    property real dpr: 1

    // the output grim snaps for Sees: Windows ("" for all of them), and whether a dial is
    // open (or opening, or closing): no snapshot then, or the dial would be in it
    property string output: ""
    property bool dialOpen: false

    // a path as a url (each part escaped, so names with spaces or # load)
    function fileUrl(path) { return "file://" + path.split("/").map(encodeURIComponent).join("/") }

    // ── the sharp picture ── the wallpaper itself, decoded at the screen's size: an Image
    // with this sourceSize and Image.PreserveAspectCrop keeps its shape and covers the
    // screen (LiquidGlass crops it the way awww does). "" until the size is known, so a big
    // wallpaper is never decoded at full size
    readonly property size sharpSize: Qt.size(Math.round(screenSize.width * dpr), Math.round(screenSize.height * dpr))
    readonly property string sharpUrl: windows && _snapUrl !== "" ? _snapUrl : wallpaper === "" || sharpSize.width < 1 || sharpSize.height < 1 ? "" : fileUrl(wallpaper)

    // ── the blurred picture ── at half the screen's size (it's blurred: the eye can't tell),
    // cropped to the screen's shape. The library blurs with 6 passes of a 9-tap Gaussian,
    // spread 2.5 px apart at full Blur, on the screen's own px: about one Gaussian of
    // 10.35 px × Blur. Half the size, half the px
    readonly property size blurSize: Qt.size(Math.round(sharpSize.width / 2), Math.round(sharpSize.height / 2))
    readonly property real blurSigma: Prefs.liquidBlur * 10.35 * dpr / 2

    // one file per wallpaper (and size) and Blur level, made once and kept
    readonly property string blurKey: wallpaper === "" || blurSize.width < 1 ? ""
        : Qt.md5(wallpaper) + "-" + blurSize.width + "x" + blurSize.height
    readonly property string blurTarget: windows || !Prefs.liquidOn || Prefs.liquidBlur <= 0 || blurKey === "" ? ""
        : Vars.liquidCachePath + "/" + blurKey + "-" + Math.round(Prefs.liquidBlur * 100) + ".jpg"

    // the last file made. While the next level is being made the last one stands in (turning
    // the Blur knob never flickers back to sharp); a file of another wallpaper doesn't
    property string blurMade: ""
    readonly property string blurUrl: windows && _snapUrl !== "" ? (Prefs.liquidBlur > 0 ? _snapBlurUrl : "") : blurTarget !== "" && blurMade.indexOf("/" + blurKey + "-") >= 0 ? fileUrl(blurMade) : ""

    onBlurTargetChanged: _makeBlur()
    function _makeBlur() {
        if (blurTarget === "" || _blurrer.running) return
        _blurrer.target = blurTarget
        _blurrer.exec(["sh", "-c",
            'test -s "$2" || { mkdir -p "$(dirname "$2")" && magick "$1[0]" -resize "$3^" -gravity center -extent "$3" -blur "0x$4" -quality 92 "$2.part.jpg" && mv "$2.part.jpg" "$2"; }',
            "sh", wallpaper, blurTarget, blurSize.width + "x" + blurSize.height, blurSigma.toFixed(2)])
    }
    property Process _blurrer: Process {
        property string target: ""
        onExited: code => {
            if (code === 0) root.blurMade = target

            // the wallpaper or the level changed again while this one was being made
            if (target !== root.blurTarget) root._makeBlur()
        }
    }

    // ── Sees: Windows ── a layer window can't see the windows under it, so grim snaps the
    // screen and the glass bends that. Snapped into two slots in turn (one may still be
    // loading while the other is written), the blurred copy made from the same snap
    readonly property bool windows: Prefs.liquidOn && Prefs.liquidSees === "windows"
    property string _snapUrl: ""
    property string _snapBlurUrl: ""
    property int _slot: 0
    property bool _snapPending: false

    function snap() {
        if (!windows || sharpSize.width < 1) return
        if (dialOpen || _snapper.running) { _snapPending = true; return }
        _snapPending = false
        _slot = 1 - _slot
        const base = Vars.liquidCachePath + "/windows-" + _slot
        _snapper.base = base
        _snapper.exec(["sh", "-c",
            'mkdir -p "$(dirname "$1")" && grim ${4:+-o "$4"} -t ppm - | magick ppm:- -quality 90 -write "$1.jpg" -resize "$2!" -blur "0x$3" "$1-blur.jpg"',
            "sh", base, blurSize.width + "x" + blurSize.height, Math.max(blurSigma, 0.01).toFixed(2), output])
    }
    property Process _snapper: Process {
        property string base: ""
        onExited: code => {
            if (code === 0) {
                // a new query each time, so the Image never shows its cached old snap
                const t = "?" + Date.now()
                root._snapUrl = root.fileUrl(base + ".jpg") + t
                root._snapBlurUrl = root.fileUrl(base + "-blur.jpg") + t
            }
            if (root._snapPending) root.snap()
        }
    }

    // a moment after the windows change (they finish moving and drawing first)
    property Timer _settle: Timer {
        interval: Vars.liquid.windowsSettle
        onTriggered: root.snap()
    }
    // (the window events: _hypr, below)

    // and every few seconds, for what changes inside the windows (a page scrolled, a video)
    property Timer _refresh: Timer {
        interval: Math.max(1000, Vars.liquid.windowsRefresh)
        running: root.windows && Vars.liquid.windowsRefresh > 0 && !root.dialOpen
        repeat: true
        onTriggered: root.snap()
    }

    onWindowsChanged: if (windows) snap()
    onDialOpenChanged: {
        if (!dialOpen && _snapPending) _settle.restart()
        if (dialOpen && live) _relist()
    }

    // ── Sees: Live ── each window on the screen streamed on its own (ScreencopyView in
    // LiquidBackdrop, over the wallpaper), so video plays through the glass. A whole-screen
    // stream would have the glass in it, seeing itself; Hyprland's no_screen_share paints a
    // layer black instead of leaving it out. Only a dial that is out streams, and only the
    // windows that reach under it (LiquidBackdrop.awake / area)
    readonly property bool live: Prefs.liquidOn && Prefs.liquidSees === "live"

    // the windows to stream, bottom first: { handle (a Toplevel), key, ws, x, y, w, h, z,
    // entering, leaving } in the screen's logical px. While a workspace changes, the ones
    // going (`leaving`, kept as last seen) and the ones coming (`entering`) move as
    // Hyprland moves them (inDX, outOpacity, ...)
    property var liveWindows: []

    // Hyprland's window list is asked for again, then read a moment later (it answers
    // asynchronously)
    function _relist() {
        if (!live) return
        Hyprland.refreshToplevels()
        Hyprland.refreshMonitors()
        _relistTimer.restart()
    }
    property Timer _relistTimer: Timer {
        interval: 80
        onTriggered: root._rebuildLive()
    }
    onLiveChanged: live ? _relist() : (liveWindows = [])
    onOutputChanged: _relist()

    // the windows on the screen right now (not the leaving ones)
    property var _current: []

    function _rebuildLive() {
        const m = Hyprland.monitors.values.find(m => m.name === output) || Hyprland.focusedMonitor
        if (!live || !m) return
        const mo = m.lastIpcObject || {}
        const ws = [mo.activeWorkspace ? mo.activeWorkspace.id : (m.activeWorkspace ? m.activeWorkspace.id : -1),
                    mo.specialWorkspace && mo.specialWorkspace.id ? mo.specialWorkspace.id : null]
        _lastWs = ws[0]
        const list = []
        for (const t of Hyprland.toplevels.values) {
            const o = t.lastIpcObject
            // (nothing to stream from a window with no size: Steam opens such transient ones)
            if (!t.wayland || !o || !o.at || !o.size || o.size[0] <= 0 || o.size[1] <= 0 || o.hidden || o.mapped === false || !o.workspace) continue
            if (ws.indexOf(o.workspace.id) < 0) continue

            // the stacking: fullscreen over floating over tiled, the most recently focused on top
            // shortcut: Hyprland's IPC has no real z-order, so overlapping floats can come out in the wrong order
            const z = (o.fullscreen ? 2e6 : 0) + (o.floating ? 1e6 : 0) + (o.workspace.id < 0 ? 4e6 : 0) - (o.focusHistoryID ?? 0)
            list.push({ handle: t.wayland, key: t.address, ws: o.workspace.id, x: o.at[0] - (mo.x ?? m.x), y: o.at[1] - (mo.y ?? m.y),
                        w: o.size[0], h: o.size[1], z: z, entering: false, leaving: false })
        }

        // a change underway: what wasn't there before comes in; what's still here stays
        if (_switch) {
            for (const w of list) w.entering = !_switch.before[w.key] && _switch.side(w)
            _leaving = _leaving.filter(l => !list.some(w => w.key === l.key))
        }
        list.sort((a, b) => a.z - b.z)
        _current = list
        _publish()
    }

    // the leaving windows go under the others (and away when their animation ends)
    property var _leaving: []
    function _publish() {
        const all = _leaving.concat(_current)
        const sig = l => l.map(w => [w.key, w.x, w.y, w.w, w.h, w.entering, w.leaving].join(",")).join(";")
        if (sig(all) !== sig(liveWindows)) liveWindows = all
    }

    // ── workspace changes, as Hyprland animates them ── its own style, time and curve
    // (hyprctl animations), the incoming and the outgoing each their own. A workspace slides
    // (or fades) the windows of the screen's regular workspace; a special workspace the
    // windows over it
    property var _switch: null      // { before: { key: true }, side(w) }
    property int _lastWs: -1        // the screen's regular workspace, as last listed
    property real inT: 1            // 0 → 1 as the new windows come in
    property real outT: 1           // 0 → 1 as the old ones go
    property int _dir: 1            // 1: the new one comes from the right (or from below)
    property var _inStyle: _parseStyle("")
    property var _outStyle: _parseStyle("")

    // "slide", "slidevert", "fade", "slidefade 20%", "slidefadevert 20%" → how far it moves
    // (share of the screen) and whether it fades
    function _parseStyle(style) {
        const s = String(style || "slide")
        const pct = /(\d+)%/.exec(s)
        const share = s.startsWith("slidefade") ? (pct ? Number(pct[1]) / 100 : 0.2) : s.startsWith("slide") ? 1 : 0
        return { share: share, vertical: s.indexOf("vert") >= 0, fade: s.startsWith("fade") || s.startsWith("slidefade") }
    }
    readonly property real inDX: _inStyle.vertical ? 0 : _dir * _inStyle.share * screenSize.width * (1 - inT)
    readonly property real inDY: _inStyle.vertical ? _dir * _inStyle.share * screenSize.height * (1 - inT) : 0
    readonly property real inOpacity: _inStyle.fade ? inT : 1
    readonly property real outDX: _outStyle.vertical ? 0 : -_dir * _outStyle.share * screenSize.width * outT
    readonly property real outDY: _outStyle.vertical ? -_dir * _outStyle.share * screenSize.height * outT : 0
    readonly property real outOpacity: _outStyle.fade ? 1 - outT : 1

    property NumberAnimation _inAnim: NumberAnimation { target: root; property: "inT"; from: 0; to: 1; easing.type: Easing.BezierSpline }
    property NumberAnimation _outAnim: NumberAnimation { target: root; property: "outT"; from: 0; to: 1; easing.type: Easing.BezierSpline }
    property Timer _switchEnd: Timer {
        onTriggered: {
            root._switch = null
            root._leaving = []
            for (const w of root._current) w.entering = false
            root._publish()
        }
    }

    // `kind`: "workspaces" or "specialWorkspace"; `side(w)`: the windows it moves
    function _beginSwitch(kind, dir, side) {
        const a = anim(kind + "In"), b = anim(kind + "Out")
        const before = {}
        for (const w of _current) before[w.key] = true
        _switch = { before: before, side: side }
        _dir = dir
        _inStyle = _parseStyle(a.style)
        _outStyle = _parseStyle(b.style)

        // the going ones stay as last seen (LiquidBackdrop stops streaming them) and move out
        _leaving = _current.filter(side).map(w => Object.assign({}, w, { leaving: true, entering: false }))
        _current = _current.filter(w => !side(w))
        _inAnim.stop(); _outAnim.stop()
        _inAnim.duration = a.ms; _inAnim.easing.bezierCurve = a.bezier.concat([1, 1])
        _outAnim.duration = b.ms; _outAnim.easing.bezierCurve = b.bezier.concat([1, 1])
        inT = 0; outT = 0
        _inAnim.start(); _outAnim.start()
        _switchEnd.interval = Math.max(a.ms, b.ms) + 20
        _switchEnd.restart()
        _publish()
    }

    // ── Hyprland's animation settings ── (hyprctl animations -j), read at start and after a
    // config reload. A node that isn't overridden takes its parent's
    property var _anims: ({})
    property var _beziers: ({})
    readonly property var _animParent: ({ workspacesIn: "workspaces", workspacesOut: "workspaces",
        specialWorkspaceIn: "specialWorkspace", specialWorkspaceOut: "specialWorkspace",
        specialWorkspace: "workspaces", workspaces: "global" })
    function anim(name) {
        let n = name
        while (_animParent[n] && !(_anims[n] && _anims[n].overridden)) n = _animParent[n]
        let s = n
        while (_animParent[s] && !(_anims[s] && _anims[s].overridden && _anims[s].style)) s = _animParent[s]
        const a = _anims[n] || { enabled: true, speed: 4, bezier: "default" }
        return { ms: a.enabled ? Math.round(a.speed * 100) : 0, bezier: _beziers[a.bezier] || [0, 0.75, 0.15, 1],
                 style: (_anims[s] && _anims[s].style) || "slide" }
    }

    // ── Hyprland's window decorations ── how it rounds and edges the windows, so the glass
    // sees them as they're drawn: { rounding, border (px), active, active2, inactive }
    property var deco: ({ rounding: 0, border: 0, active: "transparent", active2: "transparent", inactive: "transparent" })

    // "ffbec2ff ffe7b9d5 45deg" → its colours as "#aarrggbb"
    function _colours(g) { return String(g || "").split(" ").filter(c => /^[0-9a-f]{8}$/i.test(c)).map(c => "#" + c) }
    property Process _hyprLook: Process {
        command: ["sh", "-c", "hyprctl animations -j; echo; for o in decoration:rounding general:border_size general:col.active_border general:col.inactive_border; do hyprctl getoption $o -j | tr -d '\\n'; echo; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const lines = text.trim().split("\n")
                    const opts = lines.slice(-4).map(l => JSON.parse(l))
                    const animList = JSON.parse(lines.slice(0, -4).join("\n"))
                    const anims = {}, beziers = {}
                    for (const a of animList[0]) anims[a.name] = a
                    for (const b of animList[1]) beziers[b.name] = [b.X0, b.Y0, b.X1, b.Y1]
                    root._anims = anims
                    root._beziers = beziers
                    const act = root._colours(opts[2].gradient || opts[2].custom), inact = root._colours(opts[3].gradient || opts[3].custom)
                    root.deco = { rounding: opts[0].int || 0, border: opts[1].int || 0,
                                  active: act[0] || "transparent", active2: act[1] || act[0] || "transparent", inactive: inact[0] || "transparent" }
                } catch (e) { /* no Hyprland, or another output: windows stay square and slides use the defaults */ }
            }
        }
    }
    Component.onCompleted: _hyprLook.running = true

    // ── what Hyprland says ──
    readonly property var _windowEvents: ["openwindow", "closewindow", "movewindow", "movewindowv2", "workspace", "workspacev2",
        "changefloatingmode", "fullscreen", "activewindow", "activewindowv2", "focusedmon", "activespecial", "activespecialv2"]
    property Connections _hypr: Connections {
        target: Hyprland
        enabled: root.windows || root.live
        function onRawEvent(event) {
            if (event.name === "configreloaded") { root._hyprLook.running = true; return }
            if (root._windowEvents.indexOf(event.name) < 0) return
            if (root.windows) { root._settle.restart(); return }
            if (!root.dialOpen) { root._relist(); return }

            // a dial is out: a change of workspace on this screen moves the windows under it as
            // Hyprland does (to a higher number: in from the right)
            if (event.name === "workspacev2" && Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === root.output) {
                const to = Number(event.parse(2)[0])
                if (to !== root._lastWs) root._beginSwitch("workspaces", to < root._lastWs ? -1 : 1, w => w.ws >= 0)
            } else if (event.name === "activespecialv2" && event.parse(3)[2] === root.output) {
                root._beginSwitch("specialWorkspace", 1, w => w.ws < 0)
            }
            root._relist()
        }
    }
    onBlurSigmaChanged: if (windows) _settle.restart()
}

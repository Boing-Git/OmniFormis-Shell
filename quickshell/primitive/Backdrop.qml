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
    readonly property var _windowEvents: ["openwindow", "closewindow", "movewindow", "movewindowv2", "workspace", "workspacev2",
        "changefloatingmode", "fullscreen", "activewindow", "activewindowv2", "focusedmon"]
    property Connections _hypr: Connections {
        target: Hyprland
        enabled: root.windows || root.live
        function onRawEvent(event) {
            if (root._windowEvents.indexOf(event.name) < 0) return
            if (root.windows) root._settle.restart()
            else root._relist()
        }
    }

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
    // layer black instead of leaving it out. Streams only while a dial is open; otherwise
    // each window keeps its last frame
    readonly property bool live: Prefs.liquidOn && Prefs.liquidSees === "live"

    // the windows to stream, bottom first: { handle (a Toplevel), key, x, y, w, h } in the
    // screen's logical px
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

    function _rebuildLive() {
        const m = Hyprland.monitors.values.find(m => m.name === output) || Hyprland.focusedMonitor
        if (!live || !m) return
        const mo = m.lastIpcObject || {}
        const ws = [mo.activeWorkspace ? mo.activeWorkspace.id : (m.activeWorkspace ? m.activeWorkspace.id : -1),
                    mo.specialWorkspace && mo.specialWorkspace.id ? mo.specialWorkspace.id : null]
        const list = []
        for (const t of Hyprland.toplevels.values) {
            const o = t.lastIpcObject
            if (!t.wayland || !o || !o.at || !o.size || o.hidden || o.mapped === false) continue
            if (ws.indexOf(o.workspace ? o.workspace.id : null) < 0) continue

            // the stacking: fullscreen over floating over tiled, the most recently focused on top
            // shortcut: Hyprland's IPC has no real z-order, so overlapping floats can come out in the wrong order
            const z = (o.fullscreen ? 2e6 : 0) + (o.floating ? 1e6 : 0) + (o.workspace.id < 0 ? 4e6 : 0) - (o.focusHistoryID ?? 0)
            list.push({ handle: t.wayland, key: t.address, x: o.at[0] - (mo.x ?? m.x), y: o.at[1] - (mo.y ?? m.y), w: o.size[0], h: o.size[1], z: z })
        }
        list.sort((a, b) => a.z - b.z)

        // the same windows in the same places: keep the list, so no stream starts over
        const sig = l => l.map(w => [w.key, w.x, w.y, w.w, w.h].join(",")).join(";")
        if (sig(list) !== sig(liveWindows)) liveWindows = list
    }
    onBlurSigmaChanged: if (windows) _settle.restart()
}

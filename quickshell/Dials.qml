pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "primitive"
import "variables.js" as Vars

// Where the dials find each other, and where each one lives on the screen. Each dial
// registers itself by name:
//
//   Dials.register("apps", dial)          // in each dial's file
//   corner: Dials.spotOf("apps")          // where it lives (moved with Edit in the control center)
QtObject {
    id: root

    // name → the dial (a DialDelegate)
    property var dials: ({})

    // the screenshot tool (screenshot/ScreenshotTool.qml), once it exists: start(x, y)
    property var screenshot: null

    // the lock screen (lock/LockScreen.qml), once it exists: lock(fromSize), locked
    property var lock: null

    // The screen every dial's window is on: the first real monitor (a HEADLESS-n output is a
    // virtual one, e.g. for streaming), or whatever there is. A binding, so when the monitor
    // disconnects (a DisplayPort monitor does as it sleeps) and comes back, every window
    // moves back onto it instead of staying on the placeholder Qt made meanwhile
    readonly property var screen: {
        const all = Quickshell.screens
        return all.find(s => !s.name.startsWith("HEADLESS")) ?? all[0] ?? null
    }

    // the first-run tour (Onboarding.qml), once it exists: begin()
    property var onboarding: null

    // the About card (About.qml), once it exists: open()
    property var about: null

    function register(name, dial) {
        dials[name] = dial
        revision++
        dial.openChanged.connect(() => { if (dial.open && root.dials[name] === dial) root.opened(name) })
    }

    // A dial with a hot corner just opened: an OSD that is out on its spot is put away,
    // and the dial carries on from the OSD's size instead of growing through it (the
    // other way round, an OSD asking to pop up over an open dial, is popUpAt)
    function opened(name) {
        if (homes.indexOf(name) < 0) return
        const spot = spotOf(name)
        let size = 0
        for (const p of popups) {
            const o = dials[p]
            if (!o || spotOf(p) !== spot) continue
            if (o.open || o.currentSize > o.collapsedSize + 0.5) {
                size = Math.max(size, o.currentSize)
                o.snapClose()
            }
        }
        if (size > 0) dials[name].carryOn(size)
    }

    // a dial that goes away (an OSD switched off in the settings) takes its name with it
    function unregister(name, dial) { if (dials[name] === dial) { delete dials[name]; revision++ } }

    // goes up by one whenever a dial registers or goes away: `dials` is a plain object a
    // binding can't follow, so a binding that looks dials up reads this too
    property int revision: 0

    // true while a dial is open (or peeking, or still shrinking) on `spot`
    function busyAt(spot) {
        revision
        for (const name in dials) {
            const d = dials[name]
            if (d && spotOf(name) === spot && d.currentSize > d.collapsedSize + 0.5) return true
        }
        return false
    }

    // ── where the dials live ──
    // the 8 spots: the 4 corners (quarter circles) and the middle of each edge (half
    // circles), clockwise from the top-left
    readonly property var spots: ["topLeft", "top", "topRight", "right", "bottomRight", "bottom", "bottomLeft", "left"]

    // where each dial lives until it's moved (variables.js)
    readonly property var defaults: ({
        center: Vars.controlCenterPosition,
        wallpaper: Vars.wallpaperDialPosition,
        apps: Vars.appLauncherPosition,
        power: Vars.powerMenuPosition,
        volume: Vars.audioOsdPosition,
        brightness: Vars.brightnessOsdPosition,
        workspaces: Vars.workspaceOsdPosition
    })

    // the dials with a hot corner: one per spot, so moving one onto another swaps them
    readonly property var homes: ["center", "wallpaper", "apps", "power"]

    // the OSDs: they only pop up for a moment, so they share a spot with anything. Only
    // the ones the shell loads (osdEnabled in variables.js, or the pop-up settings)
    readonly property var popups: {
        const on = { volume: Prefs.osdVolume, brightness: Prefs.osdBrightness, workspaces: Prefs.osdWorkspaces }
        return ["volume", "brightness", "workspaces"].filter(n => on[n]).concat(["notify"])
    }

    // every dial Edit can move (in the control center's Dials control)
    readonly property var movable: homes.concat(popups)

    // name → spot, for the dials that were moved; remembered in Vars.dialPositionsPath
    property var moved: ({})

    // ── a spot's geometry ── (the same numbers DialDelegate works out for a dial there)
    function isCorner(spot) { return spot === "topLeft" || spot === "topRight" || spot === "bottomLeft" || spot === "bottomRight" }

    // the point a dial on `spot` grows out of, on a screen w × h
    function spotPoint(spot, w, h) {
        switch (spot) {
        case "topLeft": return Qt.point(0, 0)
        case "top": return Qt.point(w / 2, 0)
        case "topRight": return Qt.point(w, 0)
        case "right": return Qt.point(w, h / 2)
        case "bottomRight": return Qt.point(w, h)
        case "bottom": return Qt.point(w / 2, h)
        case "bottomLeft": return Qt.point(0, h)
        default: return Qt.point(0, h / 2)
        }
    }

    // the visible part of a dial there runs from startDeg over sweepDeg (0° = right, 90° = down)
    readonly property var spotStartDegs: ({ topLeft: 0, top: 0, topRight: 90, right: 90, bottomRight: 180, bottom: 180, bottomLeft: 270, left: -90 })
    function spotStartDeg(spot) { return spotStartDegs[spot] ?? 0 }
    function spotSweepDeg(spot) { return isCorner(spot) ? 90 : 180 }

    // where the dial called `name` lives now
    function spotOf(name) {
        const s = moved[name]
        if (spots.indexOf(s) >= 0) return s

        // notifications come out of the control center's spot until they're given their own
        if (name === "notify") return spotOf("center")
        return defaults[name] || "bottomRight"
    }

    // the dial with a hot corner living at `spot`, or ""
    function dialAt(spot) {
        for (let i = 0; i < homes.length; i++)
            if (spotOf(homes[i]) === spot) return homes[i]
        return ""
    }

    // the OSDs that pop up at `spot`
    function popupsAt(spot) {
        return popups.filter(name => spotOf(name) === spot)
    }

    // An OSD (`name`) wants to pop up. -1: it can't, a dial with a hot corner is open on
    // its spot (that dial holds the spot). Otherwise any other OSD showing on the spot
    // is put away at once and its size comes back, so the new one carries on from it
    // (DialDelegate.openFrom); 0 when there was nothing to carry on from
    function popUpAt(name) {
        const d = dials[name]
        if (!d) return -1
        const spot = spotOf(name)
        for (let i = 0; i < homes.length; i++) {
            const o = dials[homes[i]]
            if (o && o !== d && o.open && spotOf(homes[i]) === spot) return -1
        }
        let size = 0
        for (let i = 0; i < popups.length; i++) {
            const o = dials[popups[i]]
            if (!o || o === d || spotOf(popups[i]) !== spot) continue
            if (o.open || o.currentSize > o.collapsedSize + 0.5) {
                size = Math.max(size, o.currentSize)
                o.snapClose()
            }
        }
        return size
    }

    // the dial `name` would swap with if it moved to `spot` ("" for none)
    function swapWith(name, spot) {
        if (popups.indexOf(name) >= 0) return ""
        const other = dialAt(spot)
        return other === name ? "" : other
    }

    // Moves the dial `name` to `spot`. A dial with a hot corner already living there takes
    // `name`'s old spot (they swap); an OSD just goes there.
    function moveTo(name, spot) {
        if (movable.indexOf(name) < 0 || spots.indexOf(spot) < 0) return false
        const from = spotOf(name)
        if (from === spot) return true
        const other = swapWith(name, spot)
        const next = Object.assign({}, moved)
        next[name] = spot
        if (other !== "") next[other] = from
        moved = next
        save()
        return true
    }

    // every dial back to its spot from variables.js
    function resetSpots() {
        moved = {}
        save()
    }

    // ── remembering the spots ──
    property FileView _file: FileView {
        path: Vars.dialPositionsPath

        // there's no file until the first move
        printErrors: false

        // read again when it changes: edited by hand, or moved by another running shell
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const o = JSON.parse(text())
                if (o && typeof o === "object") root.moved = o
            } catch (e) { /* empty or broken: keep the defaults */ }
        }
    }

    // writes through the shell, so the folder is made the first time
    property Process _writer: Process {}
    function save() {
        _writer.exec(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s\\n" "$2" > "$1"',
                      "sh", Vars.dialPositionsPath, JSON.stringify(moved, null, 2)])
    }

    // from a keybind or the terminal:
    //   qs -p <this folder> ipc call dials move apps top
    //   qs -p <this folder> ipc call dials reset
    property IpcHandler _ipc: IpcHandler {
        target: "dials"
        function move(name: string, spot: string): void { root.moveTo(name, spot) }
        function reset(): void { root.resetSpots() }
    }
}

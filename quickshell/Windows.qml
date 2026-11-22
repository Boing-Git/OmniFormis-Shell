pragma Singleton
import QtQuick
import Quickshell.Io

// The windows Hyprland shows on a screen, for things that drop onto or shoot a window
// (the Screenshot pill, `screenshot window`). Asked for with refresh(); `list` then
// holds the visible windows on that screen in this shell's px, frontmost first.
//
//   Windows.refresh(screenName, () => { const r = Windows.rectAt(x, y) })
QtObject {
    id: root

    // {x, y, width, height, address, title, cls, focused} per window, frontmost first
    property var list: []

    // the screen the list is for ("" while nothing was asked yet)
    property string screenName: ""

    property var _done: null
    function refresh(name, done) {
        screenName = name || ""
        _done = done || null
        _lister.running = false
        _lister.running = true
    }

    property Process _lister: Process {
        command: ["sh", "-c", 'printf \'{"m":%s,"c":%s}\' "$(hyprctl -j monitors)" "$(hyprctl -j clients)"']
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.list = root.fromJson(JSON.parse(text)) }
                catch (e) { root.list = [] }
                const d = root._done
                root._done = null
                if (d) d()
            }
        }
    }

    // Hyprland's monitors and clients → this screen's visible windows, frontmost first:
    // the focused one, then floating over tiled, then by how recently each was focused.
    // Workspaces are told apart by name (a special workspace has no id)
    function fromJson(j) {
        const mon = j.m.find(m => m.name === root.screenName) || j.m.find(m => m.focused) || j.m[0]
        if (!mon) return []
        const names = [mon.activeWorkspace ? mon.activeWorkspace.name : ""]
        if (mon.specialWorkspace && mon.specialWorkspace.name) names.push(mon.specialWorkspace.name)
        return j.c
            .filter(c => c.mapped && !c.hidden && c.visible !== false && c.monitor === mon.id
                && c.workspace && names.indexOf(c.workspace.name) >= 0)
            .sort((a, b) => (a.focusHistoryID === 0 ? -1 : b.focusHistoryID === 0 ? 1 : 0)
                || (b.workspace.type === "special") - (a.workspace.type === "special")
                || (b.fullscreen > 0) - (a.fullscreen > 0)
                || b.floating - a.floating
                || a.focusHistoryID - b.focusHistoryID)
            .map(c => ({
                x: c.at[0] - mon.x, y: c.at[1] - mon.y, width: c.size[0], height: c.size[1],
                address: c.address, title: c.title, cls: c["class"], focused: c.focusHistoryID === 0
            }))
    }

    // the frontmost window under (x, y), or null
    function at(x, y) {
        for (let i = 0; i < list.length; i++) {
            const r = list[i]
            if (x >= r.x && x < r.x + r.width && y >= r.y && y < r.y + r.height) return r
        }
        return null
    }

    // its rect, or an empty one
    function rectAt(x, y) {
        const r = at(x, y)
        return r ? Qt.rect(r.x, r.y, r.width, r.height) : Qt.rect(0, 0, 0, 0)
    }

    // the focused window's rect, or an empty one
    function focusedRect() {
        const r = list.find(w => w.focused) || null
        return r ? Qt.rect(r.x, r.y, r.width, r.height) : Qt.rect(0, 0, 0, 0)
    }
}

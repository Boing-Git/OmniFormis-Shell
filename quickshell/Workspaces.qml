pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "primitive"
import "variables.js" as Vars

// Hyprland's workspaces, one copy for the whole shell: the workspace OSD's ring and the
// launcher's drop spots (pull an app onto a workspace) read the same list, wear the same
// shapes and go through the same dispatches.
//
//   Workspaces.focusedId        the workspace you're on (1 and up; special ones don't count)
//   Workspaces.lastId           the last workspace a ring should show
//   Workspaces.shapeOf(id)      the M3 shape that workspace wears
//   Workspaces.windowCount(id)  how many windows it has
//   Workspaces.go(id)           go there
//   Workspaces.launchOn(id, entry)   open an app (a DesktopEntry) there, staying where you are
QtObject {
    id: root

    // the workspace you're on. Special workspaces (music, scratchboard ...) have negative
    // ids and aren't on the rings, so opening one doesn't count as moving
    property int focusedId: 1
    property Binding _focused: Binding {
        target: root
        property: "focusedId"
        when: (Hyprland.focusedWorkspace?.id ?? 0) > 0
        value: Hyprland.focusedWorkspace?.id ?? 1
        restoreMode: Binding.RestoreNone
    }

    // the M3 shape a workspace wears (Vars.workspaceShapes); ids below 1 (a ring's spare
    // slots before workspace 1) wrap round too, so they always get one
    function shapeOf(id) {
        const n = Vars.workspaceShapes.length
        return Vars.workspaceShapes[((id - 1) % n + n) % n]
    }

    // Hyprland's workspace with this id, or null: it only keeps the ones that have
    // windows or are open, so most ids have none
    function workspace(id) {
        return Hyprland.workspaces.values.find(w => w.id === id) ?? null
    }

    // how many windows a workspace has
    function windowCount(id) {
        return workspace(id)?.toplevels.values.length ?? 0
    }

    // the last workspace on a ring: the Workspaces setting, or further if one past it is open
    readonly property int lastId: Math.max(Prefs.workspaceCount,
        ...Hyprland.workspaces.values.map(w => w.id))

    // go to a workspace by its id. A Hyprland configured in Lua only takes Lua dispatches
    function go(id) {
        if (id < 1 || id === focusedId) return
        Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ workspace = ${id} })` : `workspace ${id}`)
    }

    // one argument, quoted for the shell Hyprland runs the command in
    function shellQuote(arg) { return "'" + String(arg).replace(/'/g, "'\\''") + "'" }

    // Opens an app on workspace `id` without leaving the one you're on (Hyprland's exec
    // with a "workspace <id> silent" rule). An app that runs in a terminal can't take the
    // rule (the terminal is what opens), so that one goes there first and opens as usual.
    // Returns false when there was nothing to run
    function launchOn(id, entry) {
        if (!entry || id < 1) return false
        const argv = entry.command || []
        if (argv.length === 0 || entry.runInTerminal) {
            go(id)
            entry.execute()
            return true
        }
        const cmd = argv.map(shellQuote).join(" ")
        const what = Hyprland.usingLua
            ? "hl.dsp.exec_cmd(" + JSON.stringify(cmd) + ", { workspace = \"" + id + " silent\" })"
            : "exec [workspace " + id + " silent] " + cmd

        // through hyprctl: the same call a keybind would make
        Quickshell.execDetached(["hyprctl", "dispatch", what])
        return true
    }
}

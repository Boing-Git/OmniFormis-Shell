import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "primitive"
import "screenshot"
import "lock"
import "variables.js" as Vars

PanelWindow{
    id: root
    // the screen the shell lives on (Dials.screen): when the monitor goes away and comes
    // back (a DisplayPort monitor does as it sleeps) the window follows it back
    screen: Dials.screen

    anchors {
        right: true
        bottom: true
        top: true
        left: true
    }
    color: "transparent"

    // take the keyboard only while the wallpaper search is being typed in
    // (OnDemand focus flickers on Hyprland, so typing never arrived)
    // take the keyboard while the dial is open, so it can be used with keys
    WlrLayershell.keyboardFocus: wallpaperDial.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region {
        Region { item: wallpaperDial }
    }

    WallpaperDial {
        id: wallpaperDial

        // M3E roles: surface container dial, outline-variant edge,
        // a surface step up for the film strip, primary for the loading indicator
        color: Roles.surface_container
        borderColor: Roles.outline_variant
        reelColor: Roles.surface_container_high
        holeColor: Roles.outline_variant
        loadingColor: Roles.primary
        selectedColor: Roles.primary
    }

    AppLauncher {}

    ControlCenter {}

    // the control center's controls moved out to dials of their own (Edit in its Dials
    // control: drag a tile off the dial onto a free spot), one each
    Variants {
        model: Dials.detached.map(n => n.substring(3))
        ControlCenter {
            required property var modelData
            only: modelData
        }
    }

    // the OSDs, each only if it's switched on (osdEnabled in variables.js, or the pop-up
    // settings in the control center's Settings control): off means no window at all, not
    // a hidden one
    // pops up on volume changes
    Loader { active: Prefs.osdVolume; sourceComponent: AudioOsd {} }

    // pops up on brightness changes
    Loader { active: Prefs.osdBrightness; sourceComponent: BrightnessOsd {} }

    // pops up in a corner while you move between workspaces
    Loader { active: Prefs.osdWorkspaces; sourceComponent: WorkspaceOsd {} }

    // a notification arriving: comes out of the control center's spot as a pill (the
    // shell is the notification server: Notifs.qml)
    NotifyOsd {}

    // the screenshot tool (screenshot/): from the control center's Dials control, or
    // qs -p <this folder> ipc call screenshot open
    ScreenshotTool {}

    // open / close from a keybind:  qs -p <this folder> ipc call wallpaper toggle
    IpcHandler {
        target: "wallpaper"
        function toggle(): void { wallpaperDial.open = !wallpaperDial.open }
        function open(): void { wallpaperDial.open = true }
        function close(): void { wallpaperDial.open = false }
    }

    PowerMenu{
        id:topLeft
    }

    // the lock screen (lock/): Super + L, the power dial's Lock, hypridle, or
    // qs ipc call lock lock
    LockScreen {}

    // the first-run tour (replay: the Help pill in the control center's Dials control, or
    // qs ipc call hints tour)
    Onboarding {}

    // the shells' mascots, and switching between them (the About pill, qs ipc call about open)
    About {}

    // what the closed corners say (the volume as an arc, a bead per new notification): one
    // tiny window per spot, only where there's something to say
    Variants {
        model: Dials.spots
        CornerWhisper {
            required property string modelData
            spot: modelData
        }
    }

    // something is playing: ticks go quieter and the volume corner waves (Prefs.musicPlaying)
    Binding {
        target: Prefs
        property: "musicPlaying"
        value: Mpris.players.values.some(p => p.isPlaying)
    }

    // what liquid glass sees through itself (Backdrop): the wallpaper on screen, at the
    // screen's size (this window covers it)
    Binding { target: Backdrop; property: "wallpaper"; value: wallpaperDial.currentPath }
    Binding { target: Backdrop; property: "screenSize"; value: Qt.size(root.width, root.height) }
    Binding { target: Backdrop; property: "dpr"; value: Dials.screen ? Dials.screen.devicePixelRatio : 1 }
    Binding { target: Backdrop; property: "output"; value: Dials.screen ? Dials.screen.name : "" }
    Binding { target: Backdrop; property: "dialOpen"; value: { Dials.revision; return Dials.spots.some(s => Dials.busyAt(s)) } }

    Component.onCompleted: Dials.register("wallpaper", wallpaperDial)

    // Quickshell 0.3.2 on Qt 6.12 crashes while showing its own "reloaded"
    // popup, so don't show it (reloads still happen; the log still says so)
    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup() }
        function onReloadFailed(error) { Quickshell.inhibitReloadPopup() }
    }

    // A monitor that goes away and comes back (a DisplayPort monitor does as it sleeps)
    // takes every dial's window with it: the compositor closes them, and a closed layer
    // window doesn't come back by itself. So once the screens have settled after a change,
    // the shell rebuilds itself. While the session is locked it waits for the unlock (the
    // lock makes its own surface for each screen that comes back)
    property bool screensMoved: false
    Connections {
        target: Quickshell
        function onScreensChanged() { root.screensMoved = true; screensSettle.restart() }
    }
    Timer {
        id: screensSettle
        interval: 1000
        onTriggered: root.rebuildForScreens()
    }
    function rebuildForScreens() {
        if (!screensMoved || Quickshell.screens.length === 0) return
        if (Dials.lock && Dials.lock.locked) return
        screensMoved = false
        Quickshell.reload(false)
    }
    Connections {
        target: Dials.lock
        function onLockedChanged() { if (!Dials.lock.locked) root.rebuildForScreens() }
    }

    // Quickshell only watches .qml files, so saving variables.js wouldn't
    // reload anything. Watch it ourselves and reload when it changes (not while the
    // session is locked: the lock holds on through a reload, but nothing should
    // rebuild the shell under it; save again once unlocked)
    FileView {
        path: Qt.resolvedUrl("variables.js").toString().replace(/^file:\/\//, "")
        watchChanges: true
        onFileChanged: if (!Dials.lock || !Dials.lock.locked) Quickshell.reload(false)
    }
}

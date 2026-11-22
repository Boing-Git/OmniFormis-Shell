import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "primitive"

// The workspace OSD: a corner dial that springs open whenever you move to another
// workspace, turns its ring of workspaces until the one you're on sits at the middle
// mark, and closes itself again a moment later.
//
// While it's open you can scroll on it to step through your workspaces one by one, drag
// the ring round and let go on one, or click a workspace to go there.
//
// open it from a keybind:  qs -p <this folder> ipc call workspaces open
//
// It only exists on screen while it's open (the window hides when it's collapsed),
// so it never adds a hot corner on top of the dial that already lives in that corner.
//
// settings: workspaceOsdPosition / Size / HoldTime / Count in variables.js (its spot can
// also be moved with Edit in the control center's Dials control)
PanelWindow {
    id: win
    // the screen the shell lives on (Dials.screen): when the monitor goes away and comes
    // back (a DisplayPort monitor does as it sleeps) the window follows it back
    screen: Dials.screen

    // its own layer name, so its frost is its own (Prefs: Pop-up frost, Look settings)
    WlrLayershell.namespace: "quickshell-popup"

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: dial }

    // shown only while the dial is open or still shrinking
    visible: dial.open || dial.currentSize > dial.collapsedSize + 0.5

    // ── workspaces ── the shell's one copy of them (Workspaces.qml): the workspace you're
    // on, the shape each one wears, how many windows it has, and going to one
    readonly property int focusedId: Workspaces.focusedId
    function shapeOf(id) { return Workspaces.shapeOf(id) }
    function workspace(id) { return Workspaces.workspace(id) }
    function windowCount(id) { return Workspaces.windowCount(id) }
    readonly property int lastId: Workspaces.lastId
    function go(id) { Workspaces.go(id) }

    // ── scrolling ── one notch is one workspace, every workspace on the ring (empty ones
    // too, as the ring shows them), so each notch moves the ring exactly one tile. The ring
    // turns at once; Hyprland follows. Notches in a quick run add up from where the ring is
    // heading, not from where Hyprland has got to yet
    property int heading: 1
    function step(dir) {
        const from = stepping.running ? heading : focusedId
        heading = Math.max(1, Math.min(lastId, from + dir))
        stepping.restart()
        spin.snapTo(heading - 1)
        go(heading)
        show()
    }

    // while it runs the ring belongs to the scrolling (Hyprland's answers on the way don't
    // pull it back); then it settles on wherever Hyprland ended up
    Timer {
        id: stepping
        interval: 600
        onTriggered: spin.snapTo(win.focusedId - 1)
    }

    // the workspace under a point on the dial (in the dial's px), or 0 if it's off the ring
    function idAt(x, y) {
        const dx = x - dial.pivotX
        const dy = y - dial.pivotY
        if (Math.abs(Math.hypot(dx, dy) - ring.radius) > ring.itemHeight / 2) return 0

        // its angle from the middle mark, -180 .. 180
        const deg = ((Math.atan2(dy, dx) * 180 / Math.PI - ring.anchorDeg) % 360 + 540) % 360 - 180
        return Math.round((deg - spin.scroll) / spin.stepDeg) + 1
    }

    // ── showing and hiding ──
    // the workspace Hyprland reports at startup isn't you moving: ignore changes until
    // it has settled
    property bool armed: false
    Timer { interval: 1000; running: true; onTriggered: win.armed = true }

    function show() {
        if (!armed) return

        // not over a dial that's open on this spot (e.g. the control center); another OSD
        // there hands over to this one (it's put away, and this one carries on from its size)
        const from = Dials.popUpAt("workspaces")
        if (from < 0) return
        if (!dial.open) { if (from > 0) dial.openFrom(from); else dial.open = true }
        hideTimer.interval = Vars.workspaceOsdHoldTime
        hideTimer.restart()
    }

    // opened on purpose (the Dials control, a keybind): stays a while longer
    function popUp() {
        armed = true
        show()
        hideTimer.interval = Vars.workspaceOsdHoldTime * 3
        hideTimer.restart()
    }

    IpcHandler {
        target: "workspaces"
        function open(): void { win.popUp() }
        function close(): void { dial.open = false }
    }

    // closes the OSD once the hold time passes, unless the mouse is on it
    Timer {
        id: hideTimer
        interval: Vars.workspaceOsdHoldTime
        onTriggered: if (dial.hovered || dial.pressed) restart(); else dial.open = false
    }

    // the ring position (in DialRotation's scroll) that puts a workspace at the middle mark
    function scrollFor(id) { return -(id - 1) * spin.stepDeg }

    // moved: turn the ring to the new workspace and pop up. Before it's armed, jump
    // straight there with no turning; while you scroll it, the scrolling turns it
    onFocusedIdChanged: {
        if (!armed) { spin.scroll = scrollFor(focusedId); return }
        if (!stepping.running) spin.snapTo(focusedId - 1)
        show()
    }
    Component.onCompleted: {
        spin.scroll = scrollFor(focusedId)
        Dials.register("workspaces", dial)
    }
    Component.onDestruction: Dials.unregister("workspaces", dial)

    DialDelegate {
        id: dial

        // glass as a pop-up (Prefs: Pop-ups, Look settings)
        glassKind: "popup"
        corner: Dials.spotOf("workspaces")

        // opened from the Dials control (the control center calls it)
        function popUp() { win.popUp() }
        expandedSize: Vars.workspaceOsdSize

        // an OSD shouldn't close the moment the mouse passes over it: the hold
        // timer closes it instead
        closeOnExit: false
        autoClose: false

        // M3E roles: the dial is a surface container, edged with outline-variant
        color: Roles.surface_container
        borderColor: Roles.outline_variant

        // scroll down: the next workspace, up: the one before
        onScrolled: dir => win.step(dir)

        // drag the ring round, let go, and it goes to the workspace at the middle mark
        onDragged: deg => { spin.dragBy(deg); win.show() }
        onFlung: {
            const id = Math.max(1, Math.min(win.lastId, spin.pos + 1))
            spin.snapTo(id - 1)
            win.go(id)
        }

        // a click goes to the workspace under the mouse
        onActivated: win.go(win.idAt(dial.hoverX, dial.hoverY))

        // ── sizes ── all from the dial's size, so Vars.workspaceOsdSize scales everything
        readonly property real ringRadius: expandedSize * 0.78
        readonly property real tileSize: expandedSize * 0.16

        // a wide gap, so only a few workspaces show at once and the ring stays calm
        readonly property real tileGap: tileSize * 0.45

        DialRotation {
            id: spin

            // spacing from the tile size, so tiles never touch at any dial size:
            // (tile + gap) / (inner edge of the ring) → degrees
            stepDeg: (dial.tileSize + dial.tileGap) / (dial.ringRadius - dial.tileSize / 2) * 180 / Math.PI

            // never glides: it follows Hyprland, and a drag settles where you let go
            momentum: 0
        }

        // ── the ring of workspaces ── listIndex 0 is workspace 1, and it never loops
        DialRing {
            id: ring
            anchors.fill: parent
            cx: dial.centerX
            cy: dial.centerY
            startDeg: dial.startDeg
            sweepDeg: dial.sweepDeg
            radius: dial.ringRadius
            stepDeg: spin.stepDeg
            scroll: spin.scroll
            preload: 1
            itemWidth: dial.tileSize
            itemHeight: dial.tileSize

            delegate: Item {
                id: tile

                // filled in by DialRing: the raw slot number (doesn't wrap), whether it's
                // the one at the middle mark, and its angle on the ring
                property int listIndex
                property bool selected
                property real ringDeg

                readonly property int wsId: listIndex + 1
                readonly property bool occupied: win.windowCount(wsId) > 0
                readonly property bool urgent: win.workspace(wsId)?.urgent ?? false

                // there's no workspace 0 or below
                visible: wsId >= 1 && wsId <= win.lastId

                // cancel the ring's tilt: the tile stays upright
                rotation: -(ringDeg + 90)

                // empty workspaces are just small dots: only the ones with windows (and the
                // one you're on) get a shape and a number
                readonly property bool quiet: !tile.occupied && !tile.selected && !tile.urgent

                ShapeMorph {
                    anchors.fill: parent

                    // empty workspaces are plain circles; the rest (and the one at the
                    // mark) wear their own shape, morphing into it as they arrive
                    shape: tile.occupied || tile.selected ? win.shapeOf(tile.wsId) : "Circle"

                    // M3E roles: primary marks where you are, secondary-container for
                    // workspaces with windows, a surface step up for empty ones, error
                    // for one asking for attention
                    color: tile.selected ? Roles.primary
                         : tile.urgent ? Roles.error
                         : tile.occupied ? Roles.secondary_container
                         : Roles.outline_variant
                    scale: tile.selected ? 1 : tile.occupied || tile.urgent ? 0.8 : 0.22

                    Behavior on scale {
                        NumberAnimation {
                            duration: Prefs.fastSpatial.duration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Prefs.fastSpatial.bezier
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: Vars.expressiveFastEffects.duration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Vars.expressiveFastEffects.bezier
                        }
                    }
                }

                SmoothText {
                    anchors.centerIn: parent
                    visible: !tile.quiet
                    text: tile.wsId
                    color: tile.selected ? Roles.on_primary
                         : tile.urgent ? Roles.on_error
                         : tile.occupied ? Roles.on_secondary_container
                         : Roles.on_surface_variant
                    font.pixelSize: tile.selected ? 16 : 12
                    font.weight: 700
                }
            }
        }

        // ── the workspace at the mark, big, with a dot per window, in the empty space ──
        // The tiles' inner edge is a quarter disc (a half disc on an edge) of this radius.
        // The group sits on the middle line, as far from the screen's edges as from the
        // ring, with `groupMargin` kept clear of both
        readonly property real emptyRadius: ringRadius - tileSize / 2
        readonly property real groupMargin: expandedSize * 0.05
        readonly property real groupHalf: Math.max(group.width, group.height) / 2

        // nearest: clear of the screen's edges (on a corner the box's corner points at them,
        // so it needs √2 more); farthest: its far corner clear of the ring
        readonly property real groupNear: (groupHalf + groupMargin) * (isEdge ? 1 : Math.SQRT2)
        readonly property real groupFar: emptyRadius - groupMargin - groupHalf * Math.SQRT2
        readonly property real groupRadius: Math.max(groupNear, (groupNear + groupFar) / 2)
        readonly property real midRad: midDeg * Math.PI / 180

        // the workspace you're on; while you drag the ring, the one you'd land on
        readonly property int shownId: pressed ? Math.max(1, spin.pos + 1) : win.focusedId
        readonly property int shownWindows: win.windowCount(shownId)

        Column {
            id: group
            spacing: 6
            width: dial.expandedSize * 0.26
            x: dial.centerX + dial.groupRadius * Math.cos(dial.midRad) - width / 2
            y: dial.centerY + dial.groupRadius * Math.sin(dial.midRad) - height / 2

            Item {
                width: parent.width
                height: width

                ShapeMorph {
                    anchors.fill: parent
                    shape: win.shapeOf(dial.shownId)

                    // M3E roles: primary-container, one step quieter than the tile at the mark
                    color: Roles.primary_container
                }

                SmoothText {
                    anchors.centerIn: parent
                    text: dial.shownId
                    color: Roles.on_primary_container
                    font.pixelSize: 28                 // M3 headlineMedium
                    font.weight: 800
                }
            }

            // a dot per window (up to 6), or one hollow dot for an empty workspace
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                Repeater {
                    model: Math.max(1, Math.min(6, dial.shownWindows))
                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        antialiasing: true
                        color: dial.shownWindows > 0 ? Roles.on_surface_variant : "transparent"
                        border.width: dial.shownWindows > 0 ? 0 : 1.5
                        border.color: Roles.outline
                    }
                }
            }
        }
    }
}

import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Wayland
import QtQuick.Shapes
import "primitive"

// The app launcher: a corner dial with every app on a ring. Type to search, Enter (or a
// click) launches the one at the mark; pull a tile off the ring and drop it on a workspace
// to open it there, or on another tile to move it (your own order, see `apps`).
PanelWindow {
    id: launcher
    // the screen the shell lives on (Dials.screen): when the monitor goes away and comes
    // back (a DisplayPort monitor does as it sleeps) the window follows it back
    screen: Dials.screen


    // the dial, under a name AppDragLayer can be given (inside it `dial: dial` would point
    // at its own `dial` property)
    readonly property var dialItem: dial

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: dial }

    // take the keyboard only while the search bar is being typed in
    // take the keyboard while the dial is open, so it can be used with keys
    WlrLayershell.keyboardFocus: dial.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // open / close from a keybind:  qs -p <this folder> ipc call apps toggle
    IpcHandler {
        target: "apps"
        function toggle(): void { dial.open = !dial.open }
        function open(): void { dial.open = true }
        function close(): void { dial.open = false }
    }

    // so other dials can find it (Dials.qml)
    Component.onCompleted: Dials.register("apps", dial)

    DialDelegate {
        id: dial
        corner: Dials.spotOf("apps")
        expandedSize: 280

        // M3E roles: the dial is a surface container, edged with outline-variant
        color: Roles.surface_container
        borderColor: Roles.outline_variant

        onScrolled: dir => spin.scrollBy(dir)
        onDragged: deg => spin.dragBy(deg)
        onFlung: speed => spin.fling(speed)

        // launch the app at the 45° mark
        onActivated: applySelected()
        function applySelected() {
            // the app the ring is turning to, not the one passing the mark mid-spin (a search
            // spins to its match, and Enter often comes before the ring gets there)
            if (apps.length > 0) apps[ring.wrap(spin.heading)].entry.execute()
            open = false             // close the dial (content fades out, then it shrinks)
        }

        // ── search ── type part of an app's name and the dial spins to it
        // true while typing in the search bar (click it to start; Esc, Enter or
        // closing the dial stops)
        property bool searching: false

        // searching: keys go to the search bar; done: back to the dial (arrows, Enter...)
        onSearchingChanged: if (searching) searchBar.focusInput(); else if (open) forceActiveFocus()

        // typing while the dial is open starts a search with that letter
        onTyped: text => { searching = true; searchBar.insert(text) }

        // Backspace / Delete reaching the dial (the field lost the focus somehow): still
        // delete a letter, and give the field the keys back
        onSecondaryActivated: if (searchText !== "") { searching = true; searchBar.backspace(); searchBar.focusInput() }

        // closed: the search is over, and the next open starts clean
        onOpenChanged: if (!open) { searching = false; searchBar.clear() }
        property string searchText: ""

        // matching positions in `apps`, best first: names starting with the
        // text, then names / generic names (e.g. "Web Browser") / keywords containing it
        readonly property var searchMatches: {
            const q = searchText.trim().toLowerCase()
            if (q === "") return []
            const starts = [], rest = []
            for (let i = 0; i < apps.length; i++) {
                const e = apps[i].entry
                const name = e.name.toLowerCase()
                if (name.startsWith(q)) { starts.push(i); continue }
                const extra = [e.genericName, e.comment].concat(e.keywords || []).join(" ").toLowerCase()
                if (name.includes(q) || extra.includes(q)) rest.push(i)
            }
            return starts.concat(rest)
        }
        property int searchMatchIndex: -1

        // false while searchText is not empty and nothing matches it
        readonly property bool searchMatched: searchText.trim() === "" || searchMatches.length > 0
        onSearchMatchesChanged: {
            const m = searchMatches
            searchMatchIndex = m.length > 0 ? 0 : -1
            if (m.length > 0) goTo(m[0])
        }

        // next / previous match (wraps around)
        function nextMatch(dir) {
            const m = searchMatches
            if (m.length === 0) return
            searchMatchIndex = ((searchMatchIndex + dir) % m.length + m.length) % m.length
            goTo(m[searchMatchIndex])
        }

        // spin to app `index` the short way round
        function goTo(index) {
            const n = apps.length
            if (n === 0 || index < 0) return
            let d = (((index - spin.pos) % n) + n) % n
            if (d > n / 2) d -= n
            spin.snapTo(spin.pos + d)
        }

        // one shared shape library for every tile
        M3Shapes { id: shapes }

        // ── the apps ── every installed app with a .desktop file (the same list app
        // menus show), hidden ones left out, in YOUR order: the one they were first seen
        // in (the alphabet, the first time), apps installed since at the end. So
        // installing or removing an app never moves the others, and the hand can learn
        // where things are. Pull a tile off the ring onto another to move it.
        // Each entry:
        //   label - the app's name
        //   icon  - a file path/URL to the app's icon from your icon theme (use it as
        //           an Image source; "" if the app has none)
        //   shape - the M3 shape it wears (from its id, the same one everywhere: Apps.qml)
        //   entry - the DesktopEntry itself (entry.execute() launches it)
        readonly property var apps: {
            const all = DesktopEntries.applications.values.filter(e => !e.noDisplay)
            const rank = {}
            appOrder.forEach((id, i) => { rank[id] = i })
            const known = all.filter(e => e.id in rank).sort((a, b) => rank[a.id] - rank[b.id])
            const fresh = all.filter(e => !(e.id in rank)).sort((a, b) => a.name.localeCompare(b.name))
            return known.concat(fresh).map(e => ({
                label: e.name,
                icon: Quickshell.iconPath(e.icon, true),
                shape: Apps.shapeFor(e.id),
                entry: e
            }))
        }

        // ── your order ── app ids in the order you keep them (Vars.appOrderPath). Apps
        // not in it yet come after it by name, and are added to its end once the list of
        // apps has settled, which fixes their place from then on
        property var appOrder: []
        property bool orderLoaded: false
        FileView {
            path: Vars.appOrderPath
            printErrors: false
            watchChanges: true
            onFileChanged: reload()
            onLoaded: {
                try {
                    const o = JSON.parse(text())
                    if (Array.isArray(o)) dial.appOrder = o
                } catch (e) { /* empty or broken: the alphabet */ }
                dial.orderLoaded = true
            }

            // no file yet: the first run
            onLoadFailed: dial.orderLoaded = true
        }
        Process { id: orderWriter }
        function saveOrder(ids) {
            appOrder = ids
            orderWriter.exec(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s\\n" "$2" > "$1.tmp" && mv "$1.tmp" "$1"',
                              "sh", Vars.appOrderPath, JSON.stringify(ids)])
        }

        // apps seen for the first time go to the end of the order (waits for the list to
        // stop changing: at startup the apps arrive in a few batches)
        onAppsChanged: newApps.restart()
        onOrderLoadedChanged: newApps.restart()
        Timer {
            id: newApps
            interval: 1500
            onTriggered: {
                if (!dial.orderLoaded || dial.apps.length === 0) return
                const known = {}
                dial.appOrder.forEach(id => { known[id] = true })
                const fresh = dial.apps.map(a => a.entry.id).filter(id => !known[id])
                if (fresh.length > 0) dial.saveOrder(dial.appOrder.concat(fresh))
            }
        }

        // moves the app at `from` to `to` (places in `apps`). The ring doesn't turn: the
        // app is simply where you dropped it now
        function moveApp(from, to) {
            if (from === to || from < 0 || to < 0 || from >= apps.length || to >= apps.length) return
            const ids = apps.map(a => a.entry.id)
            const id = ids.splice(from, 1)[0]
            ids.splice(to, 0, id)

            // apps that aren't installed right now keep their place in the file, after these
            const shown = {}
            ids.forEach(i => { shown[i] = true })
            saveOrder(ids.concat(appOrder.filter(i => !shown[i])))
        }

        // ── pulling an app off the ring ── DialDelegate asks when a drag starts. A drag
        // that starts on a tile and goes out from the ring (away from or towards the
        // centre) lifts that app (AppDragLayer); along the ring it turns the ring as usual
        readonly property real ringRadius: expandedSize * 0.62
        readonly property real tileSize: 70

        // 1 = anything steeper than 45°; 2 = it must be much straighter out
        readonly property real pullStraightness: 1
        claimDrag: (px, py, x, y) => {
            if (drag.active) return false
            const n = tileAt(px, py)
            if (n === null) return false
            const a = Math.atan2(py - pivotY, px - pivotX)
            const mx = x - px, my = y - py
            const out = Math.abs(mx * Math.cos(a) + my * Math.sin(a))
            const along = Math.abs(my * Math.cos(a) - mx * Math.sin(a))
            if (out < along * pullStraightness) return false
            const i = wrapApp(n)
            const c = tileCenter(n)
            drag.begin(apps[i], i, dial.x + x, dial.y + y, dial.x + c.x, dial.y + c.y)
            return true
        }
        onClaimedMoved: (x, y) => drag.move(dial.x + x, dial.y + y)
        onClaimedReleased: (x, y) => drag.release(dial.x + x, dial.y + y)
        onClaimCanceled: drag.cancel()

        // a ring position (any whole number) as a place in `apps`
        function wrapApp(n) { return ring.wrap(n) }

        // the tile under (x, y) (the dial's px) as the ring's raw position (wrapApp turns
        // it into a place in `apps`), or null when there's no tile there
        function tileAt(x, y) {
            if (apps.length === 0) return null
            const dx = x - pivotX, dy = y - pivotY
            if (Math.abs(Math.hypot(dx, dy) - ringRadius) > tileSize / 2 + 4) return null
            const deg = ((Math.atan2(dy, dx) * 180 / Math.PI - midDeg) % 360 + 540) % 360 - 180
            const n = Math.round((deg - spin.scroll) / spin.stepDeg)
            const off = (deg - spin.scroll - n * spin.stepDeg) * Math.PI / 180 * ringRadius
            return Math.abs(off) <= tileSize / 2 + 4 ? n : null
        }

        // the middle of the tile at the ring's raw position n (the dial's px)
        function tileCenter(n) {
            const a = (midDeg + n * spin.stepDeg + spin.scroll) * Math.PI / 180
            return Qt.point(pivotX + ringRadius * Math.cos(a), pivotY + ringRadius * Math.sin(a))
        }

        DialRotation {
            id: spin

            // spacing from the tile size, so tiles never touch at any dial size:
            // (tile 70 + gap 16) / (inner edge of the ring) → degrees
            stepDeg: (70 + 16) / (dial.expandedSize * 0.8 - 35) * 180 / Math.PI

            // scrolling feel is shared by every dial (variables.js)
            momentum: Prefs.scrollMomentum
            energy: Prefs.energy
            snapThreshold: 0.5      // this dial only: snaps sooner
            snapDuration: 300       // this dial only: quicker settle
        }

        DialBand {
            anchors.fill: parent
            cx: dial.centerX; cy: dial.centerY
            radius: dial.expandedSize * 0.62  // same as the ring; follows the dial size
            frameHeight: 80                 // same as the ring's itemHeight
            startDeg: dial.startDeg - 15    // a bit wider than the visible part
            sweepDeg: dial.sweepDeg + 30

            // the track: one surface step above the dial
            bandColor: Roles.surface_container_high
            holeColor: Roles.outline_variant
            DialRing {
                id: ring
                count: dial.apps.length                // every app, looping
                pressed: dial.pressed                  // lets the selected tile know it's being clicked
                anchors.fill: parent
                cx: dial.centerX
                cy: dial.centerY
                startDeg: dial.startDeg
                sweepDeg: dial.sweepDeg
                radius: parent.radius  // 80% of the dial: always fits inside
                stepDeg: spin.stepDeg
                scroll: spin.scroll
                itemWidth: 70
                itemHeight: 70

                delegate: Item {
                    // which entry this tile shows, 0..4, filled in by DialRing (from `count`)
                    property int itemIndex
                    readonly property var entry: dial.apps[itemIndex] ?? ({ label: "", icon: "", shape: "Circle" })

                    // this tile's angle on the ring, filled in by DialRing every frame
                    property real ringDeg

                    // true while this tile is closest to the 45° mark, filled in by DialRing
                    property bool selected

                    // true while this tile is selected and the mouse button is held, filled in by DialRing
                    property bool clicked
                    rotation: -(ringDeg + 90)      // cancel the ring's tilt: the whole tile stays upright

                    // pulled off the ring (AppDragLayer): only a faint copy stays behind
                    opacity: drag.active && drag.appIndex === itemIndex ? 0.3 : 1
                    Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

                    Image {
                        id: icon
                        anchors.centerIn: parent
                        width: iconSize.value                          // follows the spring
                        height: width
                        source: entry.icon
                        sourceSize: Qt.size(60 * 2, 60 * 2)            // see note below
                        smooth: true

                        // shown at about a third of its pixels: mipmaps keep the edges smooth
                        // (plain smoothing alone leaves them jagged, and shimmering as it grows)
                        mipmap: true
                        z: 1

                        SpringValue {
                            id: iconSize
                            to: selected ? 60 : 35                     // where it's heading
                            stiffness: Vars.springs.expressive.fast.spatial.stiffness
                            dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
                            epsilon: 0.2                               // pixels: stop when this close
                            Component.onCompleted: snap(to)            // start at the right size, no motion
                        }
                    }

                    Shape {
                        id: selectedM3Shape
                        anchors.centerIn: icon              // same centre as the icon (was: anchors.fill: parent)
                        width: icon.width + 60              // the gem's room around the icon: try 10–30
                        height: width
                        preferredRendererType: Shape.CurveRenderer
                        visible: selected

                        ShapePath {
                            fillColor: Roles.primary
                            strokeColor: "transparent"
                            scale: ring.fitShape(selectedM3Shape)     // fit the drawing to THIS box (no + 10)
                            PathSvg { path: shapes.getPath(Vars.selectedAppShape) }
                        }
                    }
                }
            }
        }

        // ── curved search bar ──
        SearchBar {
            id: searchBar
            anchors.fill: parent
            cx: dial.centerX; cy: dial.centerY
            radius: dial.expandedSize * 0.9
            fromDeg: dial.startDeg + 5

            // edge to edge: 81° on a corner dial, 90° more on an edge dial
            sweep: 81 + dial.sweepDeg - 90
            barColor: Roles.surface_container_high
            borderColor: Roles.primary
            letterColor: Roles.on_surface
            errorColor: Roles.error
            blobColor: Roles.primary
            blobLetterColor: Roles.on_primary
            counterColor: Roles.on_surface_variant
            searching: dial.searching
            matched: dial.searchMatched
            matchCount: dial.searchMatches.length
            matchIndex: dial.searchMatchIndex
            onTextChanged: dial.searchText = text
            onClicked: dial.searching = true
            onAccepted: { dial.applySelected(); clear(); dial.searching = false }
            onCancelled: dial.searching = false
            onStep: dir => dial.nextMatch(dir)
        }
    }

    // the app pulled off the ring and the workspaces it can be dropped on, over the whole
    // screen above the dial
    AppDragLayer {
        id: drag
        anchors.fill: parent
        dial: launcher.dialItem

        // dropped on a workspace: it opens there, and the launcher is done
        onLaunchOn: (workspace, app) => {
            Workspaces.launchOn(workspace, app.entry)
            dial.open = false
        }
        onReorder: (from, to) => dial.moveApp(from, to)
    }
}

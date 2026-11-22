import QtQuick
import QtQuick.Shapes
import Quickshell.Io
import "primitive"
import "variables.js" as Vars

// The wallpaper dial: hover the corner, click to open, scroll to spin, click
// again to apply. Defaults come from variables.js / Colors; override any of them.
DialDelegate {
    id: dial

    corner: Dials.spotOf("wallpaper")
    expandedSize: 450
    autoClose: false
    borderWidth: Vars.dialBorderWidth

    // ── wallpapers ──
    property string wallpapersPath: Vars.wallpapersPath
    property bool showHidden: Vars.showHidden
    property string sortBy: Prefs.wallpaperSort
    property bool sortDescending: Prefs.wallpaperDescending
    property bool sortCaseSensitive: Vars.sortCaseSensitive
    property bool shuffle: Prefs.wallpaperShuffle
    property int shuffleSeed: Vars.shuffleSeed

    // ── behaviour ──
    property real scrollMomentum: Prefs.scrollMomentum
    property real scrollEnergy: Prefs.energy
    property int preload: 5
    property bool useAwww: true
    property real transitionDuration: 1.2
    property bool useMatugen: true
    required property var reelColor

    // the holes along the film strip, and the loading spinner
    required property var holeColor
    required property var loadingColor

    // marks the selected wallpaper
    required property var selectedColor
    Component.onCompleted: {
        if (reelColor === undefined) console.error("WallpaperDial: no reelColor was passed; there is no default, set it")
        if (holeColor === undefined) console.error("WallpaperDial: no holeColor was passed; there is no default, set it")
        if (loadingColor === undefined) console.error("WallpaperDial: no loadingColor was passed; there is no default, set it")
        if (selectedColor === undefined) console.error("WallpaperDial: no selectedColor was passed; there is no default, set it")
        if (useAwww) awwwQuery.running = true      // find out which wallpaper is on screen now
    }

    // the wallpaper on screen right now (a plain file path); "" until known
    property string currentPath: ""

    // At startup, stand on the current wallpaper. Both the wallpaper list and
    // currentPath load in the background, so try whenever either arrives, once.
    property bool _startedOnCurrent: false
    function standOnCurrent() {
        if (_startedOnCurrent) return
        const i = library.indexOfPath(currentPath)
        if (i < 0) return
        wallpapers.jumpTo(i)
        _startedOnCurrent = true
    }
    onCurrentPathChanged: standOnCurrent()
    onWallpaperCountChanged: standOnCurrent()

    readonly property string selectedPath: wallpapers.selectedPath
    readonly property int wallpaperCount: library.count
    signal wallpaperSelected(string path)

    function scrollBy(dir) { wallpapers.scrollBy(dir) }

    // ── search ── set searchText (e.g. from a TextInput's text) and the dial
    // spins to the match: a number ("12") or part of a file name ("forest").
    property string searchText: ""

    // every match for searchText, best first (dial positions); see WallpaperLibrary.search
    readonly property var searchMatches: library.search(searchText)

    // which match the dial is on, 0-based (-1 when none)
    property int searchMatchIndex: -1
    readonly property int searchMatchCount: searchMatches.length

    // false while searchText is not empty and nothing matches it
    readonly property bool searchMatched: searchText.trim() === "" || searchMatchCount > 0

    // While there are matches, the dial shows ONLY them (best first). With no
    // search, or nothing matching, it shows every wallpaper again, standing on
    // the one you had selected.
    //
    // The swap waits a moment so it can be animated: `resultsChanging` turns true
    // right away (fade the rings out on it), the wallpapers are swapped once
    // `resultsSwapDelay` ms have passed, then it turns false (fade back in).
    // Typing fast keeps restarting the wait, so the rings only swap once you pause.
    property int resultsSwapDelay: Vars.expressiveFastEffects.duration
    readonly property bool resultsChanging: swapTimer.running
    property var _pendingMatches: null

    // a number ("12") isn't a filter: the dial spins through all wallpapers to it
    readonly property bool _numberSearch: /^\s*[0-9]+\s*$/.test(searchText)
    property int _spinTo: -1
    onSearchMatchesChanged: {
        const m = searchMatches
        if (/^\s*[0-9]+\s*$/.test(searchText)) {    // (checked here: _numberSearch may lag)
            searchMatchIndex = m.length > 0 ? 0 : -1
            _spinTo = m.length > 0 ? m[0] : -1
            if (library.filtered) {                    // showing results: go back to all first
                _pendingMatches = []
                swapTimer.restart()                    // ...the spin happens after the swap
            } else if (_spinTo >= 0) {
                swapTimer.stop()
                wallpapers.goTo(_spinTo)
            }
            return
        }
        _spinTo = -1

        // nothing to swap: no search before, and none now
        if (m.length === 0 && !library.filtered) { searchMatchIndex = -1; return }
        _pendingMatches = m
        swapTimer.restart()
    }
    Timer {
        id: swapTimer
        interval: dial.resultsSwapDelay
        onTriggered: {
            const m = dial._pendingMatches
            const was = library.toAll(wallpapers.pos)  // full-list position we're on
            if (m.length > 0) {
                library.filter = m
                dial.searchMatchIndex = 0
                wallpapers.jumpTo(0)                   // the best match
            } else {
                dial.searchMatchIndex = -1
                library.filter = null
                wallpapers.jumpTo(was)                 // back where you were
                if (dial._spinTo >= 0) wallpapers.goTo(dial._spinTo)   // typed a number
            }
        }
    }

    // go to the next / previous match (wraps around)
    function nextMatch(dir) {
        if (searchMatchCount === 0) return

        // While filtered, the matches are side by side on the ring, so the next
        // match is just one step: use the normal scroll (same glide and snap as
        // the wheel and the arrow keys without a search).
        if (library.filtered) { wallpapers.scrollBy(dir); return }
        searchMatchIndex = ((searchMatchIndex + dir) % searchMatchCount + searchMatchCount) % searchMatchCount
        wallpapers.goTo(searchMatches[searchMatchIndex])
    }

    // while filtered, the match you're on is wherever the ring has scrolled to
    Connections {
        target: wallpapers
        function onPosChanged() {
            if (library.filtered && dial.searchMatchCount > 0)
                dial.searchMatchIndex = ((wallpapers.pos % dial.searchMatchCount) + dial.searchMatchCount) % dial.searchMatchCount
        }
    }

    // the categories of the wallpaper at the 45° mark, e.g. ["city", "blue", "dark"]
    readonly property var selectedCategories: { library.colors; return library.categoriesAt(wallpapers.pos) }

    // every category name you can type: Vars.categoryKeywords plus the colours
    readonly property var categoryNames: library.categoryNames

    // true while you're typing in the search bar: the window then takes the
    // keyboard (see shell.qml). Set by clicking the bar; cleared by Esc, Enter,
    // or the dial closing.
    property bool searching: false

    // searching: keys go to the search bar; done: back to the dial (arrows, Enter...)
    onSearchingChanged: if (searching) searchBar.focusInput(); else if (open) forceActiveFocus()

    // typing while the dial is open starts a search with that letter
    onTyped: text => { searching = true; searchBar.insert(text) }

    // Backspace / Delete reaching the dial (the field lost the focus somehow): still
    // delete a letter, and give the field the keys back
    onSecondaryActivated: if (searchText !== "") { searching = true; searchBar.backspace(); searchBar.focusInput() }
    onOpenChanged: if (!open) searching = false
    function applySelected() {
        const path = wallpapers.selectedPath
        if (path === "") return
        if (useAwww) {
            // grow out of the dial: "top-left", ... on a corner, "top", ... on an edge
            const pos = isEdge ? corner : (isBottom ? "bottom" : "top") + "-" + (isRight ? "right" : "left")
            awwwProc.exec(["awww", "img", path,
                           "--transition-type", "grow",
                           "--transition-pos", pos,
                           "--transition-duration", String(transitionDuration)])
        }

        // the desktop's colours from it (scripts/theme-apply.sh: matugen, never prompting)
        if (useMatugen) Prefs.applyTheme(path)
        currentPath = path       // the one we just applied is now the current one
        wallpaperSelected(path)
    }

    onActivated: applySelected()
    onScrolled: dir => wallpapers.scrollBy(dir)
    onDragged: deg => wallpapers.dragBy(deg)
    onFlung: speed => wallpapers.fling(speed)

    Process { id: awwwProc }

    // `awww query` prints e.g. "DP-1: 1920x1080, ..., currently displaying: image: /path/to/file.png"
    // (one line per monitor; the first one wins)
    Process {
        id: awwwQuery
        command: ["awww", "query"]
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/image: (.+)$/)
                if (m && dial.currentPath === "") dial.currentPath = m[1].trim()
            }
        }
    }

    WallpaperLibrary {
        id: library
        folder: dial.wallpapersPath
        showHidden: dial.showHidden
        sortBy: dial.sortBy
        sortDescending: dial.sortDescending
        sortCaseSensitive: dial.sortCaseSensitive
        shuffle: dial.shuffle
        shuffleSeed: dial.shuffleSeed
    }

    WallpaperRing {
        id: wallpapers
        anchors.fill: parent
        library: library
        cx: dial.centerX
        cy: dial.centerY
        startDeg: dial.startDeg
        sweepDeg: dial.sweepDeg
        radius: dial.expandedSize * 0.80
        previewDist: dial.expandedSize * 0.430
        preload: dial.preload
        momentum: dial.scrollMomentum
        energy: dial.scrollEnergy
        bandColor: dial.reelColor
        checkBackroundColor: Roles.primary
        checkIconColor: Roles.on_primary         // M3E: content on a primary fill
        cornerRadius: Vars.wallpaperRadius
        holeColor: dial.holeColor
        loadingBorderColor: dial.loadingColor
        selectedBorderColor: dial.selectedColor
        currentPath: dial.currentPath
    }

    // ── curved search bar ──
    SearchBar {
        id: searchBar
        anchors.fill: parent
        cx: dial.centerX; cy: dial.centerY
        radius: dial.expandedSize * 0.94
        fromDeg: dial.startDeg + 3

        // edge to edge: 84° on a corner dial, 90° more on an edge dial
        sweep: 84 + dial.sweepDeg - 90
        barColor: Roles.surface_container_high
        borderColor: Roles.primary
        letterColor: Roles.on_surface
        errorColor: Roles.error
        blobColor: Roles.primary
        blobLetterColor: Roles.on_primary
        counterColor: Roles.on_surface_variant
        searching: dial.searching
        matched: dial.searchMatched
        matchCount: dial.searchMatchCount
        matchIndex: dial.searchMatchIndex
        onTextChanged: dial.searchText = text
        onClicked: dial.searching = true
        onAccepted: { dial.applySelected(); clear(); dial.searching = false }
        onCancelled: dial.searching = false
        onStep: dir => dial.nextMatch(dir)
    }
}

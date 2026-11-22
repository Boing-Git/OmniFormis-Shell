import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import QtQuick.Shapes
import "primitive"

// The wallpaper rings that go inside a DialDelegate:
//   - an outer ring of small frames
//   - an inner ring of big previews, geared to turn faster, so the selected
//     preview is carried away and the next one carried in from the other side
// Each ring sits on a DialBand (film strip).
Item {
    id: ring

    // where the dial is: pass the DialDelegate's geometry
    property real cx: width
    property real cy: height
    property real startDeg: 180

    // how many degrees of the dial show: 90 on a corner, 180 on an edge
    property real sweepDeg: 90
    readonly property real selectedDeg: startDeg + sweepDeg / 2

    // the list of wallpapers (a WallpaperLibrary)
    property var library
    readonly property int count: library ? library.count : 0

    property int preload: 5
    property int snapDuration: Vars.snapDuration
    property alias momentum: rotation.momentum
    property alias energy: rotation.energy
    required property var bandColor
    required property var holeColor
    required property var checkBackroundColor
    required property var checkIconColor

    // border drawn around a wallpaper's area while it loads
    property real loadingBorderWidth: 1
    required property var loadingBorderColor

    // colour for marking the selected wallpaper (use it in WallpaperImage)
    required property var selectedBorderColor

    // the wallpaper on screen right now (a plain file path), set by WallpaperDial
    property string currentPath: ""

    // corner roundness of every wallpaper, px
    property real cornerRadius: 0

    // On the top spots (top-left, top, top-right) the ring's slots hang downwards, so
    // the pictures in them would be upside down: turn each picture half a turn in its
    // slot, so it stands upright. The slots' own angles aren't touched
    readonly property bool upsideDown: Math.sin(selectedDeg * Math.PI / 180) > 0.01
    Component.onCompleted: {
        if (bandColor === undefined) console.error("WallpaperRing: no bandColor was passed; there is no default, set it")
        if (holeColor === undefined) console.error("WallpaperRing: no holeColor was passed; there is no default, set it")
        if (loadingBorderColor === undefined) console.error("WallpaperRing: no loadingBorderColor was passed; there is no default, set it")
        if (selectedBorderColor === undefined) console.error("WallpaperRing: no selectedBorderColor was passed; there is no default, set it")
    }

    // ── outer ring: frames ──
    property real radius: 350
    property real itemWidth: 96
    property real aspect: 16 / 9
    readonly property real itemHeight: itemWidth / aspect

    // minimum gap between neighbours, on the INNER edge (where tilted frames get closest)
    property real gap: 24
    readonly property real stepDeg: (itemWidth + gap) / (radius - itemHeight / 2) * 180 / Math.PI

    // ── inner ring: previews ──
    property real previewDist: 120
    property real previewWidth: 200
    readonly property real previewHeight: previewWidth / aspect
    property real previewGap: 40
    readonly property real previewStepDeg: (previewWidth + previewGap) / (previewDist - previewHeight / 2) * 180 / Math.PI
    readonly property real previewGear: previewStepDeg / stepDeg

    // ── state ──
    readonly property real scroll: rotation.scroll
    readonly property int pos: rotation.pos       // wallpaper under the 45° mark
    readonly property url selectedUrl: library ? library.urlAt(pos) : ""

    // plain filesystem path, for command-line tools
    readonly property string selectedPath: decodeURIComponent(selectedUrl.toString().replace(/^file:\/\//, ""))

    // the wallpaper the ring is turning to (a search spins to its match): what Enter applies,
    // even mid-spin
    readonly property string targetPath: library ? decodeURIComponent(String(library.urlAt(rotation.heading)).replace(/^file:\/\//, "")) : ""

    function scrollBy(dir) { rotation.scrollBy(dir) }    // -1 / +1
    function dragBy(deg) { rotation.dragBy(deg) }
    function fling(speed) { rotation.fling(speed) }

    // Jump straight to list position `index` with no spin (used at startup).
    function jumpTo(index) {
        if (count <= 0 || index < 0) return
        rotation.scroll = -index * stepDeg
    }

    // Spin so the wallpaper at list position `index` (0..count-1) is selected,
    // going whichever way round is shorter.
    function goTo(index) {
        if (count <= 0 || index < 0) return
        let d = (((index - pos) % count) + count) % count
        if (d > count / 2) d -= count
        rotation.snapTo(pos + d)
    }

    DialRotation {
        id: rotation
        stepDeg: ring.stepDeg
        snapDuration: ring.snapDuration
        snapThreshold: 0.3      // this dial only: snaps sooner
    }

    // one shared shape library for every tile
    M3Shapes { id: shapes }

    // One wallpaper. While its picture is still loading, the space it will take
    // is outlined with a border and a loading indicator spins in the middle.
    component WallpaperImage: Item {
        id: frame
        property int listIndex

        // true while this wallpaper is the one at the 45° mark, filled in by DialRing
        property bool selected

        // true when this tile shows the wallpaper that's on screen right now
        readonly property bool current: ring.currentPath !== ""
            && decodeURIComponent(img.source.toString().replace(/^file:\/\//, "")) === ring.currentPath

        // this tile's place in the list, 1..count (listIndex keeps counting past
        // the ends as the ring spins, so wrap it); 0 while the list is empty
        readonly property int number: ring.count > 0
            ? ((listIndex % ring.count) + ring.count) % ring.count + 1
            : 0

        scale: selected ? 1.2 : 1
        Behavior on scale { NumberAnimation { duration: Prefs.fastSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier } }

        // upright on the top spots (see upsideDown)
        rotation: ring.upsideDown ? 180 : 0

        readonly property bool loading: img.status !== Image.Ready && img.source != ""

        // a corner can't be rounder than half the shorter side
        readonly property real radius: Math.min(ring.cornerRadius, Math.min(width, height) / 2)

        // Antialiasing for the tilted frame: draw it into its own texture with
        // 8× multisampling, so the rotated edges and rounded corners are smooth.
        layer.enabled: true
        layer.samples: 8
        layer.smooth: true

        // Render the off-screen copy at 2x, so rotating it and growing it (selected
        // scale) shrink a sharp copy instead of stretching a soft one.
        layer.textureSize: Qt.size(width * 2, height * 2)
        layer.mipmap: true

        // the picture, cut to rounded corners (Quickshell's ClippingRectangle;
        // MultiEffect masks crash on Qt 6.12)
        ClippingRectangle {
            anchors.fill: parent
            radius: frame.radius
            color: "transparent"
            antialiasing: true

            Image {
                id: img
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true    // decode off the UI thread
                mipmap: true          // smooth downscaling
                sourceSize: Qt.size(width * 2, height * 2)
                source: ring.library ? ring.library.urlAt(frame.listIndex) : ""
            }
        }

        // outline of the wallpaper's area
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            antialiasing: true
            radius: frame.radius
            border.width: ring.loadingBorderWidth
            border.color: ring.loadingBorderColor
            opacity: frame.loading ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
        }

        LoadingIndicator {
            indicatorColor: ring.loadingBorderColor
            backgroundColor: ring.bandColor
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) * 0.6
            height: width

            // `visible` is false while the slot is hidden off-screen, so
            // preloading slots don't animate for nobody
            running: frame.loading && frame.visible
        }
        Rectangle {
            anchors.fill: parent
            color: "transparent"                    // only the edge, not a fill
            radius: frame.radius                    // match the rounded corners
            antialiasing: true
            border.width: 2
            border.color: ring.selectedBorderColor  // your Roles.primary
            opacity: selected ? 1 : 0               // only on the selected one
            Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
        } 
        Rectangle {
            id: badge
            visible: current
            width: 22 
            height: width

            // the picture's top-right corner: the other corner once the frame is turned round
            anchors.top: ring.upsideDown ? undefined : parent.top
            anchors.bottom: ring.upsideDown ? parent.bottom : undefined
            anchors.right: ring.upsideDown ? undefined : parent.right
            anchors.left: ring.upsideDown ? parent.left : undefined
            anchors.margins: 10
            rotation: ring.upsideDown ? 180 : 0
            color: "transparent"
            Shape{
                anchors.centerIn: parent
                ShapePath{
                    // M3E FAB menu: items are primary-container, the selected one primary
                    fillColor: ring.checkBackroundColor
                    strokeColor: "transparent"
                    scale: Qt.size( badge.width / 80, badge.height / 80)
                    PathSvg {
                        path: shapes.getPath("12SidedCookie")
                    } 
                }     
                SymbolIcon {
                    anchors.centerIn: parent
                    text: "check"                              // Material Symbols icon name
                    size: badge.width
                    color: ring.checkIconColor
                }
            }
        }
    }

    // ── drawing, back to front ──
    DialBand {
        anchors.fill: parent
        cx: ring.cx; cy: ring.cy
        radius: ring.radius
        frameHeight: ring.itemHeight
        stepDeg: ring.stepDeg
        scroll: ring.scroll
        startDeg: ring.startDeg - 15; sweepDeg: ring.sweepDeg + 30
        bandColor: ring.bandColor
        holeColor: ring.holeColor
    }

    DialBand {
        anchors.fill: parent
        cx: ring.cx; cy: ring.cy
        radius: ring.previewDist
        frameHeight: ring.previewHeight + 50
        stepDeg: ring.previewStepDeg
        scroll: ring.scroll * ring.previewGear
        startDeg: ring.startDeg - 15; sweepDeg: ring.sweepDeg + 30
        bandColor: ring.bandColor
        holeColor: ring.holeColor
    }

    DialRing {
        anchors.fill: parent
        active: ring.count > 0
        cx: ring.cx; cy: ring.cy
        radius: ring.previewDist
        startDeg: ring.startDeg
        sweepDeg: ring.sweepDeg
        stepDeg: ring.previewStepDeg
        scroll: ring.scroll * ring.previewGear
        itemWidth: ring.previewWidth
        itemHeight: ring.previewHeight
        preload: ring.preload
        delegate: WallpaperImage {}
    }

    DialRing {
        anchors.fill: parent
        active: ring.count > 0
        cx: ring.cx; cy: ring.cy
        radius: ring.radius
        startDeg: ring.startDeg
        sweepDeg: ring.sweepDeg
        stepDeg: ring.stepDeg
        scroll: ring.scroll
        itemWidth: ring.itemWidth
        itemHeight: ring.itemHeight
        preload: ring.preload
        delegate: WallpaperImage {}
    }

    // ── numbers under the outer wallpapers ──
    DialRing {
        anchors.fill: parent
        active: ring.count > 0
        cx: ring.cx; cy: ring.cy

        // the same angle and turn as the outer ring, so each number lines up with its wallpaper
        startDeg: ring.startDeg
        sweepDeg: ring.sweepDeg
        stepDeg: ring.stepDeg
        scroll: ring.scroll
        preload: ring.preload
        count: ring.count              // makes itemIndex loop 0..count-1 for you

        // closer to the middle than the wallpapers: try 20, 30, 40
        radius: ring.radius - ring.itemHeight / 2 - 26
        itemWidth: 30
        itemHeight: 30

        delegate: Item {
            id: num
            property int itemIndex     // filled in by DialRing: 0, 1, 2...
            property real ringDeg      // filled in by DialRing: this item's angle
            property bool selected     // filled in by DialRing
            rotation: -(ringDeg + 90)  // stay upright, like the power menu icons

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: ring.checkBackroundColor
                    strokeColor: "transparent"
                    scale: Qt.size(num.width / 100, num.height / 100)
                    PathSvg { path: shapes.getPath("12SidedCookie") }
                }
            }
            SmoothText {
                anchors.centerIn: parent
                text: num.itemIndex + 1        // +1 so the list starts at 1, not 0
                font.pixelSize: num.width * 0.45
                font.bold: true
                color: ring.checkIconColor
            }
        }
    }
}

import QtQuick
import "../variables.js" as Vars

// Items laid out along a circle that turns with `scroll`, recycled so the list can
// be endless (or huge) while only a few delegates exist.
//
// The ring keeps `preload` extra delegates off-screen on each side, so they are
// ready (images loaded) before they turn into view; those stay hidden until needed.
// When a delegate leaves one end it wraps to the other and gets a new index, so
// only ONE delegate changes per step.
//
//   DialRing {
//       cx: dial.centerX; cy: dial.centerY; radius: 300
//       startDeg: dial.startDeg; stepDeg: 20; scroll: rotation.scroll
//       delegate: Image {
//           property int listIndex          // set by the ring
//           source: myList.urlAt(listIndex)
//       }
//   }
//
// The delegate is sized to itemWidth x itemHeight and turned so its width runs
// along the ring. It may declare `listIndex` (int, any integer, wraps around your
// list however you like), `itemIndex` (int, listIndex wrapped into 0..count-1),
// `ringDeg` (real, its current angle), `selected` (bool, true while it is the
// item closest to the mark at anchorDeg) and `clicked` (bool, true while it is
// selected and the dial is pressed; set the ring's `pressed`).
Item {
    id: ring

    // ring centre and radius, in this item's coordinates
    property real cx: width
    property real cy: height
    property real radius: 300

    // visible arc: startDeg .. startDeg + sweepDeg (0° = right, 90° = down)
    property real startDeg: 180
    property real sweepDeg: 90

    // where listIndex 0 sits when scroll is 0 (the "selected" mark)
    property real anchorDeg: startDeg + sweepDeg / 2

    property real stepDeg: 10
    property real scroll: 0

    property real itemWidth: 96
    property real itemHeight: 54

    // off-screen delegates kept ready on each side
    property int preload: 5

    // set false to create no delegates (e.g. while the list is empty)
    property bool active: true

    // How many items your list has. Set it and each delegate's `itemIndex` is
    // wrapped into 0..count-1, so the list loops with no maths in the delegate.
    // 0 (the default) means "no fixed length": itemIndex is then the raw listIndex.
    property int count: 0

    // Whether the dial is being pressed right now; bind it to your DialDelegate:
    //   pressed: dial.pressed
    // The selected item then gets `clicked` = true while the button is held.
    property bool pressed: false

    // wrap any integer into 0..count-1 (negatives too); the raw value when count is 0
    function wrap(n) { return count > 0 ? ((n % count) + count) % count : n }

    // the item at the mark right now (needs a scroll that snaps to steps, as DialRotation's does)
    readonly property int selectedIndex: wrap(Math.round(-scroll / stepDeg))

    // The scale that fits an M3 shape (M3Shapes paths are drawn in a square box, Vars.m3ShapeBox)
    // to one item. Use it on a ShapePath inside a delegate whose Shape fills the
    // item:  scale: ring.shapeScale
    // `shapeBox` is the box the path is drawn in; it's M3Shapes' own by default,
    // so set it only for a path from somewhere else.
    property real shapeBox: Vars.m3ShapeBox
    readonly property size shapeScale: Qt.size(itemWidth / shapeBox, itemHeight / shapeBox)

    // the same for a Shape that isn't the full item size: ring.fitShape(myShape)
    function fitShape(item) { return fit(item, shapeBox) }

    // Not just for shapes: the scale that makes anything drawn in a square design
    // box of `box` units (a path, an SVG, a 24px icon...) fill `item`.
    //   scale: ring.fit(myItem, 24)
    function fit(item, box) { return Qt.size(item.width / box, item.height / box) }

    property Component delegate

    readonly property int slots: active && stepDeg > 0 ? Math.ceil(sweepDeg / stepDeg) + 2 * preload : 0
    readonly property real span: slots * stepDeg

    // off-screen angle where delegates wrap
    readonly property real wrapStart: startDeg - preload * stepDeg

    Repeater {
        model: ring.slots

        Item {
            id: slot
            required property int index

            readonly property real rawDeg: index * ring.stepDeg + ring.anchorDeg + ring.scroll

            // relative to the start of the wrap window
            readonly property int laps: Math.floor((rawDeg - ring.wrapStart) / ring.span)
            readonly property real deg: rawDeg - laps * ring.span
            readonly property int listIndex: index - laps * ring.slots

            // true while this slot is the one closest to the mark (anchorDeg);
            // within half a step of it, so only one slot is selected at a time
            readonly property bool selected: Math.abs(deg - ring.anchorDeg) < ring.stepDeg / 2

            // listIndex wrapped into 0..count-1 (see `count`)
            readonly property int itemIndex: ring.wrap(listIndex)

            // true while this is the selected item AND the dial is being pressed
            readonly property bool clicked: ring.pressed && selected

            width: ring.itemWidth
            height: ring.itemHeight

            // lay the item along the curve: width runs along the tangent
            rotation: deg + 90
            x: ring.cx + ring.radius * Math.cos(deg * Math.PI / 180) - width / 2
            y: ring.cy + ring.radius * Math.sin(deg * Math.PI / 180) - height / 2

            // waiting off-screen: loaded but hidden (also stops them wrapping into view)
            visible: deg > ring.startDeg - ring.stepDeg && deg < ring.startDeg + ring.sweepDeg + ring.stepDeg

            Loader {
                id: loader
                anchors.fill: parent
                sourceComponent: ring.delegate
            }
            Binding {
                when: !!loader.item && ("listIndex" in loader.item)
                target: loader.item; property: "listIndex"; value: slot.listIndex
            }
            Binding {
                when: !!loader.item && ("ringDeg" in loader.item)
                target: loader.item; property: "ringDeg"; value: slot.deg
            }
            Binding {
                when: !!loader.item && ("selected" in loader.item)
                target: loader.item; property: "selected"; value: slot.selected
            }
            Binding {
                when: !!loader.item && ("itemIndex" in loader.item)
                target: loader.item; property: "itemIndex"; value: slot.itemIndex
            }
            Binding {
                when: !!loader.item && ("clicked" in loader.item)
                target: loader.item; property: "clicked"; value: slot.clicked
            }
        }
    }
}

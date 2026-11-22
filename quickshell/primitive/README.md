# Dial primitives: developer guide

The building blocks for corner dials in Quickshell. The wallpaper switcher is built from them, and you can build any other dial the same way: app launchers, workspaces, media controls, and so on.

None of these files use singletons or global config. Everything is set through properties, so the folder works in any config.

> For the maths behind the ring, recycling, gearing and momentum, see **[HOW-IT-WORKS.md](HOW-IT-WORKS.md)**. This file covers how to use the parts. That one explains why they work.

---

## Contents

1. [Requirements](#requirements)
2. [Installing](#installing)
3. [The 30-second version](#the-30-second-version)
4. [How the pieces fit together](#how-the-pieces-fit-together)
5. [Angles and coordinates (read this once)](#angles-and-coordinates-read-this-once)
6. [DialDelegate](#dialdelegate)
7. [DialRotation](#dialrotation)
8. [DialRing](#dialring)
9. [DialBand](#dialband)
10. [CrossfadeImage](#crossfadeimage)
11. [SpringValue](#springvalue)
12. [SearchBar](#searchbar)
13. [Recipes](#recipes)
14. [Putting dials in a window](#putting-dials-in-a-window)
15. [Keyboard](#keyboard)
16. [Troubleshooting](#troubleshooting)

---

## Requirements

- **Quickshell** on **Qt 6.6 or newer**.
- **`variables.js`** in the folder above `primitive/`: the primitives read their M3E motion (curves, springs, `useSprings`), snap and sound settings from it (`import "../variables.js" as Vars`). `DialBand` uses `Shape.CurveRenderer`; `DialRotation` and `SpringValue` use `FrameAnimation`.
- **Tick sound (optional):** `DialRotation` plays `sounds/tick.mp3` (in the folder above `primitive/`) with `pw-play` (PipeWire) each time the dial passes an item. Turn it off with `tickSoundEnabled = false` in `variables.js`. This is the only external program the primitives run.

## Installing

Copy the `primitive/` folder into your Quickshell config, next to your `shell.qml`:

```
~/.config/quickshell/
├── shell.qml
├── primitive/          ← this folder
│   ├── qmldir
│   ├── DialDelegate.qml
│   └── ...
└── MyDial.qml
```

Then import it by folder path in any file that uses it:

```qml
import "primitive"
```

The path is relative to the importing file. A file in a sub-folder would use `import "../primitive"`. Quickshell won't import from outside the config root, so the folder has to live inside your config.

---

## The 30-second version

A dial in the top-left corner that spins through 50 coloured tiles and logs the one you click. It must sit inside a `PanelWindow`, or nothing is shown:

```qml
import Quickshell
import QtQuick
import "primitive"

PanelWindow {                       // the window the dial lives in
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: dial }     // only the dial takes clicks

    DialDelegate {
    id: dial
    corner: "topLeft"
    color: "#ffb4a2"           // required: no default colours
    borderColor: "#561f11"     // required

    onScrolled: dir => spin.scrollBy(dir)
    onActivated: console.log("picked tile", spin.pos)

    DialRotation {
        id: spin
        stepDeg: 18
    }

    DialRing {
        anchors.fill: parent
        cx: dial.centerX
        cy: dial.centerY
        startDeg: dial.startDeg
        radius: 320
        stepDeg: spin.stepDeg
        scroll: spin.scroll
        itemWidth: 70
        itemHeight: 70

        delegate: Rectangle {
            property int listIndex                         // filled in by DialRing
            readonly property int i: ((listIndex % 50) + 50) % 50
            radius: 10
            color: Qt.hsla(i / 50, 0.6, 0.6, 1)
            Text { anchors.centerIn: parent; text: parent.i }
        }
    }
    }
}
```

A ready copy is in `Test.qml` at the project root. Run it with `qs -p Test.qml`.

That's the whole pattern: **DialDelegate** is the dial, **DialRotation** is how far it has turned, and **DialRing** draws items around the corner at that rotation.

---

## How the pieces fit together

```
DialDelegate  ── the corner itself: hot corner, opening, background, input
 │   emits scrolled(dir) ───────────────┐
 │   emits activated()                  │
 │   gives centerX, centerY, startDeg ──┼──────────────┐
 │                                      ▼              │
 ├── DialRotation  ── turns wheel notches into a smooth `scroll` angle
 │                   and a whole-number `pos`
 │                                      │ scroll       │ geometry
 │                                      ▼              ▼
 ├── DialBand      ── decorative strip under a ring (optional)
 ├── DialRing      ── places delegates around the circle at `scroll`
 └── (anything else you want: text, images, CrossfadeImage...)
```

| Primitive | Kind | Visual? | Job |
|---|---|---|---|
| `DialDelegate` | `Item` | yes | The dial container, corner anchoring, open/close, input |
| `DialRotation` | `QtObject` | no | Rotation state: momentum, snapping, selected index |
| `DialRing` | `Item` | yes | Recycled items on a circle, with preloading |
| `DialBand` | `Item` | yes | A thick arc (film strip) behind a ring |
| `CrossfadeImage` | `Item` | yes | Image that fades between sources |
| `SpringValue` | `QtObject` | no | A number that moves like an M3E spring (used by `DialDelegate` and `DialRotation`) |
| `SearchBar` | `Item` | yes | A curved search bar on a dial's rim, with typed letters laid along it (they flip to read upright on a dial along the top) |
| `IconButton` | `Item` | yes | An M3 Expressive icon button: round, squaring up while pressed, with the M3 state layer |

---

## Angles and coordinates (read this once)

All the primitives share one convention, the standard Qt/screen one:

- **0°** points **right**, **90°** points **down**, **180°** left, **270°** up.
- Angles grow **clockwise** on screen, because the y axis points down.
- The **centre** of every circle is the corner (or the middle of the edge) the dial grows out of.

Each corner shows a different quarter of the circle, and each edge middle a half:

| `corner` | Visible part (`startDeg` … `startDeg + sweepDeg`) | `midDeg` |
|---|---|---|
| `"topLeft"` | 0° … 90° (right → down) | 45° |
| `"topRight"` | 90° … 180° (down → left) | 135° |
| `"bottomLeft"` | 270° … 360° (up → right) | 315° |
| `"bottomRight"` | 180° … 270° (left → up) | 225° |
| `"top"` | 0° … 180° (right → down → left) | 90° |
| `"right"` | 90° … 270° (down → left → up) | 180° |
| `"bottom"` | 180° … 360° (left → up → right) | 270° |
| `"left"` | -90° … 90° (up → right → down) | 0° |

`DialDelegate` works these out for you (`startDeg`, `sweepDeg`, `midDeg`, `centerX`, `centerY`). **Always pass them on instead of hard-coding numbers**, including `sweepDeg` to every `DialRing` (`sweepDeg: dial.sweepDeg`) and a band a little wider than it (`sweepDeg: dial.sweepDeg + 30`). Then the same dial works in any of the 8 spots just by changing `corner`.

`centerX` / `centerY` are in **`contentItem` coordinates**. The content area is a fixed `expandedSize` square pinned to the corner (twice as long along the edge for an edge dial), so children declared inside a `DialDelegate` can use them directly, along with `anchors.fill: parent`.

To place something by angle and distance from the centre yourself:

```qml
x: dial.centerX + r * Math.cos(deg * Math.PI / 180) - width / 2
y: dial.centerY + r * Math.sin(deg * Math.PI / 180) - height / 2
rotation: deg + 90        // optional: top edge faces away from the centre
```

---

## DialDelegate

> **Colours are never defaulted.** `color`, `borderColor` and every other colour in the primitives must be passed. If one is missing, the component logs `ERROR ... no <name> was passed; there is no default, set it`, and nothing is drawn in that colour.

The corner dial itself. Until it's opened it is a small invisible hot corner. Hovering it fades in the background. Clicking springs it open into a quarter circle (a half circle on the middle of an edge). When the mouse leaves, it closes. While open it also works from the keyboard (see [Keyboard](#keyboard)).

```qml
DialDelegate {
    id: dial
    corner: "bottomLeft"
    expandedSize: 360
    color: "#222"
    borderColor: "#888"

    onScrolled: dir => ...
    onActivated: ...

    // children go here
}
```

### Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `corner` | string | `"bottomRight"` | A corner (`"topLeft"`, `"topRight"`, `"bottomLeft"`, `"bottomRight"`: a quarter circle) or the middle of an edge (`"top"`, `"bottom"`, `"left"`, `"right"`: a half circle). The dial places itself there in its parent; it can change at any time. |
| `collapsedSize` | real | `20` | Radius of the hot corner while closed, in px. |
| `expandedSize` | real | `400` | Radius when open. Also the size of `contentItem` (twice as long along the edge for an edge dial). |
| `open` | bool | `false` | Open state. Toggled by clicks; you can also set it yourself. |
| `closeOnExit` | bool | `true` | Close when the mouse leaves the dial (not while a claimed drag is held). |
| `closeOnEscape` | bool | `true` | Close on Esc. `escaped()` fires either way, e.g. to leave a mode first. |
| `peekSize` | real | `56` | How big the hot corner grows during `peek()`. |
| `claimDrag` | function | `null` | `(pressX, pressY, x, y) => bool`, asked once when a drag starts (this item's px). Return `true` to take the drag over: you then get `claimedMoved` / `claimedReleased` / `claimCanceled` instead of `dragged` / `flung`. E.g. to pull an item off the dial. |
| `color` | color | **required** | Background fill. No default: leaving it out logs an ERROR. |
| `borderColor` | color | **required** | Background border colour. No default: leaving it out logs an ERROR. |
| `borderWidth` | real | `3` | Background border width, px. `0` for none. |
| `backgroundOnHover` | bool | `true` | `true`: the background only shows while hovered. `false`: always visible. |
| `useSpring` | bool | `Vars.useSprings` | `true`: the dial grows and shrinks with a spring (`spring` below). `false`: with M3E's expressive default spatial curve (`Vars.expressiveDefaultSpatial`). Fades always use the expressive fast effects curve. |
| `spring` | object | `Vars.springs.expressive.default.spatial` | `{ dampingRatio, stiffness }` for the grow/shrink spring. Any entry of `Vars.springs` works, e.g. `Vars.springs.expressive.slow.spatial`. |

### Read-only

| Property | Type | Description |
|---|---|---|
| `contentItem` | Item | The `expandedSize` square (rectangle, on an edge) your children live in. |
| `centerX`, `centerY` | real | The corner point (circle centre) in `contentItem` coordinates. |
| `pivotX`, `pivotY` | real | The same centre in the dial's own coordinates (moves while it grows); use it with `hoverX` / `hoverY`. |
| `startDeg` | real | Start of the visible part (see the table above). |
| `sweepDeg` | real | How much shows: `90` in a corner, `180` on an edge. Pass it to your rings. |
| `midDeg` | real | `startDeg + sweepDeg / 2`, the natural "selected" mark. |
| `currentSize` | real | The radius right now, from `collapsedSize` to `expandedSize` (use it, not `width`, which is twice as big on a top / bottom edge). |
| `isLeft`, `isRight`, `isTop`, `isBottom` | bool | Which screen edges it touches. Handy for building strings such as `"bottom-right"`. |
| `isEdge`, `alongX`, `alongY` | bool | It's on the middle of an edge; that edge runs across (top / bottom) or down (left / right). |
| `dragClaimed` | bool | A drag is held that `claimDrag` took over. |
| `hovered` | bool | Mouse is over the dial. |
| `pressed` | bool | The mouse button is held down on the dial. |
| `hoverRadius` | real | How far the mouse is from the corner (the circles' centre), in px. Compare it with a ring's radius to tell which of two rings the mouse is over, e.g. to scroll only that ring. |
| `expanded` | bool | What the size follows. Same as `open`, except while closing: `open` turns `false` at once, `expanded` only once the content has faded out. Writable, but leave it to the dial. |

### Signals

| Signal | When |
|---|---|
| `scrolled(int dir)` | One mouse-wheel notch. `dir` is `-1` for wheel up and `+1` for wheel down. Fires whether open or closed. |
| `activated()` | A left click **while open**, or Enter / Space while open. After the signal, the dial closes. |
| `typed(string text)` | A printable key (letter, number, symbol, no Ctrl/Alt/Super) was pressed while open. Use it to start a search. |
| `escaped()` | Esc was pressed while open (it closes too, unless `closeOnEscape` is `false`). |
| `claimedMoved(real x, real y)` / `claimedReleased(real x, real y)` / `claimCanceled()` | A drag `claimDrag` took over moved / was let go / was called off (this item's px). |

`peek(ms)` (a function): while closed, grows the hot corner to `peekSize` for a moment (900 ms by default) and back, so you can see where the dial lives, e.g. right after it was moved.

Click behaviour, step by step:

1. Closed + click → opens. No `activated`.
2. Open + click → `activated()` fires, then the dial closes.

If you want a click that keeps the dial open, set `open = true` in your `onActivated` handler.

Open and close, step by step:

1. **Opening:** the dial grows; the content stays hidden and appears all at once the moment the dial reaches `expandedSize`. Reopening before it has shrunk shows the content straight away.
2. **Closing:** the content fades out first; only then (`expanded` turns `false`) does the dial shrink.

### Default property

Children go into `contentItem`, not the delegate itself. The delegate's size animates while `contentItem` stays a fixed `expandedSize` square pinned to the corner, so your content doesn't move or resize while the dial opens. The delegate clips it, and the opening animation works like a growing window.

### Anchoring

`DialDelegate` sets its own `x` / `y` from `corner` (pinned to the corner, or centred on the edge). Don't anchor or move it yourself, or you'll fight it. Its parent should be the full-screen surface the dial sits in.

---

## DialRotation

The dial's rotation, with no visuals. It turns wheel notches into a smoothly gliding angle that settles on whole steps.

```qml
DialRotation {
    id: spin
    stepDeg: 20
    momentum: 0.95
}
// elsewhere:
onScrolled: dir => spin.scrollBy(dir)
```

It is a `QtObject`, not an `Item`, so it has no position or size and you can declare it anywhere.

### Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `stepDeg` | real | `10` | Degrees between two items. **Must match** the `stepDeg` of the `DialRing` you drive. |
| `snapDuration` | int | `Vars.snapDuration` (350) | ms for the settle onto the nearest step. Only used when `useSpring` is `false`. |
| `snapThreshold` | real | `Vars.snapThreshold` (0.1) | When the glide hands over to the snap: once the speed drops below this share of one notch's speed. Higher = snaps sooner (e.g. `0.3`). |
| `useSpring` | bool | `Vars.useSprings` | `true`: the snap is a spring (`spring` below) that starts with the glide's speed, so there's no "catch" at the handover. `false`: a `snapDuration` ms curve (`Vars.expressiveFastSpatial`). |
| `spring` | object | `Vars.springs.expressive.fast.spatial` | `{ dampingRatio, stiffness }` for the snap spring. |
| `momentum` | real | `0.98` | Glide, from `0` to `0.995`. `0` = exactly one step per notch, no glide. `0.9` = short. `0.95` = medium. `0.98` = long, heavy disc. Values are clamped. |
| `energy` | real | `1` | Speed added per notch. At `1`, a single notch glides about one step. Keep it **above** `momentum` (see Troubleshooting). |
| `scroll` | real | `0` | Current angle in degrees, unbounded. Writable, but prefer `snapTo`. |

### Read-only

| Property | Type | Description |
|---|---|---|
| `pos` | int | The step currently at the mark: `round(-scroll / stepDeg)`. Unbounded, may be negative. This is your "selected index". |
| `velocity` | real | Current speed, °/s. |
| `friction` | real | `momentum` after clamping. |
| `kick` | real | Velocity added per notch. |

### Functions

| Function | Description |
|---|---|
| `scrollBy(dir)` | One notch: `-1` or `+1`. Adds speed (or, with `momentum: 0`, snaps exactly one step). Notches add up, so spinning fast builds speed, capped at ~40 steps/s. |
| `snapTo(p)` | Animate to step `p` (any integer). Cancels the glide in progress. |

### Tick sound

Each time `pos` changes, a short tick plays (at most ~40 a second, overlapping), so a fast spin rattles. Settings live in `variables.js`: `tickSoundEnabled`, `tickVolume`. Needs `pw-play`.

### Direction

`scrollBy(+1)` (wheel down) increases `scroll`, which turns items clockwise and **decreases** `pos`. If you want wheel-down to move to the next item, call `spin.scrollBy(-dir)`.

### pos is unbounded

`pos` keeps counting forever: spin back far enough and it reaches `-37`. Map it onto your list yourself:

```qml
readonly property int selected: ((spin.pos % count) + count) % count   // loops
// or
readonly property int selected: Math.max(0, Math.min(count - 1, spin.pos)) // clamps
```

The `((i % n) + n) % n` form is needed because `%` in JavaScript keeps the sign (`-1 % 5 === -1`).

---

## DialRing

Places items around the circle and turns them with `scroll`. Only a handful of delegates ever exist. They're **recycled**: one that leaves one end of the visible arc wraps round to the other end and takes a new `listIndex`. Your list can be endless while the item count stays small.

`DialRing` also keeps `preload` extra delegates **off-screen on each side**, already created and loaded but hidden. When they turn into view they're ready, with no pop-in.

```qml
DialRing {
    anchors.fill: parent
    cx: dial.centerX; cy: dial.centerY
    startDeg: dial.startDeg
    radius: 300
    stepDeg: spin.stepDeg
    scroll: spin.scroll
    itemWidth: 96; itemHeight: 54
    preload: 5
    delegate: Image {
        property int listIndex
        source: myModel.urlAt(listIndex)
        asynchronous: true
    }
}
```

### Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `cx`, `cy` | real | `width`, `height` | Circle centre, in the ring's coordinates. Pass `dial.centerX/Y` and use `anchors.fill: parent`. |
| `radius` | real | `300` | Distance from the centre to the **middle** of each item. |
| `startDeg` | real | `180` | Start of the visible arc. Pass `dial.startDeg`. |
| `sweepDeg` | real | `90` | Length of the visible arc. 90 for a corner dial. |
| `anchorDeg` | real | `startDeg + sweepDeg/2` | Where `listIndex` 0 sits when `scroll` is 0, i.e. the "selected" mark. |
| `stepDeg` | real | `10` | Degrees between neighbours. Same value as your `DialRotation`. |
| `scroll` | real | `0` | Rotation in degrees. Bind to `DialRotation.scroll`. |
| `itemWidth`, `itemHeight` | real | `96`, `54` | Delegate size. Width runs **along** the ring, height **across** it. |
| `preload` | int | `5` | Hidden, ready delegates on **each** side. Minimum 1 (see HOW-IT-WORKS). |
| `active` | bool | `true` | `false` creates no delegates. Use it while your list is empty. |
| `count` | int | `0` | How many items your list has. When set, each delegate's `itemIndex` is wrapped into `0 … count-1`, so the list loops. `0` = no fixed length. |
| `pressed` | bool | `false` | Bind to `dial.pressed`. Gives the selected delegate `clicked = true` while the mouse button is held. |
| `delegate` | Component | — | What to draw per item. |

### Read-only

| Property | Description |
|---|---|
| `slots` | Number of delegates created: `ceil(sweepDeg / stepDeg) + 2 × preload`. |
| `span` | `slots × stepDeg`, the arc the slots cover before wrapping. |
| `wrapStart` | The off-screen angle where slots wrap. |
| `selectedIndex` | The item at the mark right now, wrapped by `count`. Use it in `onActivated`. |
| `shapeBox` | `Vars.m3ShapeBox` | The square box the path is drawn in. Set it only for a path that doesn't come from `M3Shapes`. |
| `shapeScale` | read-only | `Qt.size(itemWidth / shapeBox, itemHeight / shapeBox)`: the `scale` that fits a path to one item. Use it as `scale: ring.shapeScale` on a `ShapePath` whose `Shape` fills the delegate. |

### Functions

| Function | Description |
|---|---|
| `wrap(n)` | Wraps any integer into `0 … count-1` (negatives too). Returns `n` unchanged when `count` is `0`. |
| `fitShape(item)` | Like `shapeScale`, but for a `Shape` that isn't the full item size (uses `item.width` / `item.height`). |
| `fit(item, box)` | Works for anything, not just shapes: the `scale` that makes content drawn in a square design box of `box` units (a path, an SVG, a 24px icon) fill `item`. |

### Writing a delegate

The delegate is created inside a slot that is already **sized** (`itemWidth × itemHeight`), **positioned** and **rotated**. Fill it and draw. Don't set `x`, `y`, `rotation` or the size yourself.

The ring fills in these properties, **if your delegate declares them**:

| Declare | Type | Gets |
|---|---|---|
| `property int listIndex` | int | Which list item this slot is showing. Any integer, which you wrap or clamp yourself. Changes only while the slot is off-screen. |
| `property real ringDeg` | real | The slot's current angle on the circle, updated every frame. |
| `property bool selected` | bool | `true` while this item is the one closest to the mark (`anchorDeg`, the 45° point), within half a step. Only one item is selected at a time, and it switches while spinning. |
| `property int itemIndex` | int | `listIndex` wrapped into `0 … count-1` (set `count` on the ring). Use it to index your array directly. |
| `property bool clicked` | bool | `true` while this item is `selected` **and** the dial is pressed (mouse button held). Set the ring's `pressed: dial.pressed`. |

```qml
delegate: Item {
    property int listIndex
    property real ringDeg
    // fade items as they leave the mark:
    opacity: 1 - Math.min(1, Math.abs(ringDeg - (dial.startDeg + 45)) / 60)
    ...
}
```

Orientation: each slot is rotated `ringDeg + 90`. Its **top edge faces away from the centre**, and its width follows the curve.

### Matching the selected item

When the ring and the rotation share `stepDeg`, the delegate at the mark has `listIndex === spin.pos`. That's how you know which item was picked:

```qml
onActivated: open(myModel.get(wrap(spin.pos)))
```

### Spacing items without overlap

Tilted items get closest on the ring's **inner** edge. To keep a gap of `gap` px there:

```qml
stepDeg: (itemWidth + gap) / (radius - itemHeight / 2) * 180 / Math.PI
```

HOW-IT-WORKS explains where this comes from.

---

## DialBand

A thick arc drawn behind a ring, like a film strip. It can have sprocket holes that turn with the dial.

```qml
DialBand {
    anchors.fill: parent
    cx: dial.centerX; cy: dial.centerY
    radius: 300                     // same as the ring
    frameHeight: 54                 // same as the ring's itemHeight
    startDeg: dial.startDeg - 15    // a bit wider than the visible quarter
    sweepDeg: 120
    bandColor: "#333"
}
```

Declare it **before** the `DialRing` so it's drawn underneath.

### Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `cx`, `cy` | real | `width`, `height` | Circle centre. |
| `radius` | real | `350` | Centre line of the band. |
| `frameHeight` | real | `64` | Height of the items it sits behind. |
| `edgeMargin` | real | `16` | Extra thickness. Total band width = `frameHeight + edgeMargin`. |
| `bandColor` | color | **required** | Band colour. No default: leaving it out logs an ERROR. |
| `startDeg`, `sweepDeg` | real | `165`, `120` | Drawn arc. **The default is for bottom-right.** For other corners use `startDeg: dial.startDeg - 15`. Draw a bit more than 90° so the ends are never visible. |
| `showHoles` | bool | `false` | Draw sprocket holes along both edges. |
| `holeColor` | color | **required** | Hole colour. No default: leaving it out logs an ERROR. |
| `holeSize` | real | `6` | Hole size across the band, px. |
| `holeLength` | real | `6` | Hole size along the band, px. |
| `holesPerFrame` | int | `2` | Holes per `stepDeg`. |
| `stepDeg`, `scroll` | real | `10`, `0` | Only used for the holes, so they line up with the items and move with them. |

---

## CrossfadeImage

An image that crossfades when its `source` changes. The old picture stays visible until the new one has **finished loading**, then the new one fades in on top, so there's never a blank frame.

```qml
CrossfadeImage {
    width: 300                  // height follows from aspect
    source: selectedUrl
    fadeDuration: 150
}
```

| Property | Type | Default | Description |
|---|---|---|---|
| `source` | url | — | Image to show. |
| `aspect` | real | `16/9` | `height` is set to `width / aspect`. |
| `fadeDuration` | int | `100` | Fade length, ms. |

Images are cropped to fill (`PreserveAspectCrop`) and decoded at 2× display size so they stay sharp.

---

## SpringValue

A number that moves toward `to` like a real M3E spring, using the same `dampingRatio` and `stiffness` as the design language (`Vars.springs`). Unlike a curve it has no fixed duration: if `to` changes mid-move it keeps its speed and bends toward the new target, and it can start with a speed. `DialDelegate` uses it for growing/shrinking and `DialRotation` for snapping; you can use it for anything.

```qml
SpringValue {
    id: grow
    to: hovered ? 1.2 : 1
    stiffness: Vars.springs.expressive.fast.spatial.stiffness
    dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
}
// elsewhere:
scale: grow.value
```

It's a `QtObject`, so it has no size and can be declared anywhere.

### Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `to` | real | `0` | Target. Changing it starts the motion. Binding it is fine. |
| `value` | real | `0` | The current value. Read this. |
| `velocity` | real | `0` | Current speed, units per second. Set it before changing `to` to start with a push. |
| `stiffness` | real | `380` | M3E stiffness: higher = faster. |
| `dampingRatio` | real | `0.8` | `1` = no bounce, lower = bouncier. |
| `epsilon` | real | `0.01` | How close counts as arrived, in the value's own units (use ~`0.2` for pixels). |
| `running` | bool | read-only | Moving right now. |

### Functions and signals

| | Description |
|---|---|
| `snap(v)` | Jump to `v` with no motion. Doesn't touch `to`, so a binding on `to` keeps working. |
| `start()`, `stop()` | Start or pause the motion by hand. |
| `settled()` | Signal: it has arrived at `to`. |

> Never assign `to` from JavaScript if it has a binding: QML would drop the binding for good. Use `snap()` to reset.

---

## SearchBar

A curved, pill-shaped search bar that follows the dial's rim. It only draws, takes the typing and reports what happened; **you** decide what searching does.

```qml
SearchBar {
    id: searchBar
    anchors.fill: parent
    cx: dial.centerX; cy: dial.centerY
    radius: dial.expandedSize * 0.9
    fromDeg: dial.startDeg + 5
    barColor: Colors.surface_container_high
    borderColor: Colors.primary
    letterColor: Colors.on_surface
    errorColor: Colors.error
    blobColor: Colors.primary
    blobLetterColor: Colors.on_primary
    searching: dial.searching
    onClicked: dial.searching = true
    onTextChanged: dial.searchText = text
    onAccepted: dial.applySelected()
    onCancelled: dial.searching = false
}
// elsewhere, when the dial should take the keyboard:
searchBar.focusInput()
```

It sits on top of the dial's own click area, but only the curved bar itself counts as clicked, so clicks elsewhere still reach the dial.

### Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `cx`, `cy` | real | `width`, `height` | Centre of the circle the bar follows. Pass `dial.centerX/Y`. |
| `radius` | real | `360` | Distance from the centre to the middle of the bar. |
| `fromDeg`, `sweep` | real | `180`, `80` | Where the bar starts and how long it is, in degrees. |
| `barWidth` | real | `26` | Thickness of the bar, px. |
| `borderWidth` | real | `3` | Ring drawn around the bar while `searching`. |
| `letterWidth` | real | `9` | Room one letter takes along the bar, px (letter spacing). |
| `fontSize` | real | `14` | Letter size. |
| `shape`, `blobSize`, `blobHold` | string, real, int | `"4SidedCookie"`, `18`, `350` | The M3 shape that pops up behind a letter as it's typed (with the letter on top), its size, and how many ms it stays before shrinking away. |
| `fadeLetters` | real | `3` | Letters over which the fade at the start of the bar spreads. |
| `fadeMin` | real | `0.3` | Opacity letters fade down to before they slide off the bar. |
| `placeholder` | string | `"search"` | Shown dimmed while the text is empty. |
| `barColor`, `borderColor`, `letterColor`, `errorColor`, `blobColor`, `blobLetterColor` | color | **required** | No defaults: leaving one out logs an ERROR. `errorColor` is used while `matched` is `false`. |
| `searching` | bool | `false` | Shows the border. You set it, usually from the signals below. |
| `matched` | bool | `true` | `false` turns the letters `errorColor`. |
| `text` | string | | What's been typed. Read it, or set it to `""` to clear. |

### Signals and functions

| | Description |
|---|---|
| `clicked()` | The bar was clicked. |
| `accepted()` | Enter was pressed. |
| `cancelled()` | Esc was pressed (the text is already cleared). |
| `step(int dir)` | Tab / Down (`+1`) or Shift+Tab / Up (`-1`). |
| `focusInput()` | Give the bar the keyboard. |
| `insert(s)` | Add text at the end (e.g. from a dial's `typed()` signal). |
| `clear()` | Empty the text. |

When the text is longer than the bar, it slides: the newest letter stays at the end and the oldest fade down to `fadeMin`, then disappear.

---

## Recipes

### A dial for a JavaScript array

```qml
DialDelegate {
    id: dial
    corner: "topRight"
    color: "#ffb4a2"
    borderColor: "#561f11"
    readonly property var apps: ["firefox", "kitty", "thunar", "code", "gimp"]
    function wrap(i) { return ((i % apps.length) + apps.length) % apps.length }

    onScrolled: dir => spin.scrollBy(dir)
    onActivated: launcher.exec([apps[wrap(spin.pos)]])

    Process { id: launcher }              // import Quickshell.Io
    DialRotation { id: spin; stepDeg: 22 }

    DialRing {
        anchors.fill: parent
        cx: dial.centerX; cy: dial.centerY; startDeg: dial.startDeg
        radius: 300; stepDeg: spin.stepDeg; scroll: spin.scroll
        itemWidth: 80; itemHeight: 40
        delegate: Text {
            property int listIndex
            text: dial.apps[dial.wrap(listIndex)]
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: "white"
        }
    }
}
```

### A list that doesn't loop

Hide the delegates past the ends, and refuse notches that would leave the range. Use `momentum: 0` so every notch is exactly one step and a glide can't carry the dial past the end.

```qml
DialRotation { id: spin; stepDeg: 20; momentum: 0 }

// remember: dir +1 lowers pos, dir -1 raises it
onScrolled: dir => {
    if ((dir > 0 && spin.pos > 0) || (dir < 0 && spin.pos < count - 1))
        spin.scrollBy(dir)
}

// in the delegate:
visible: listIndex >= 0 && listIndex < count
```

The slot's own visibility (off-screen hiding) still applies. Setting `visible: false` on the delegate only hides it further.

### Highlight the selected item

```qml
delegate: Rectangle {
    property int listIndex
    readonly property bool selected: listIndex === spin.pos
    scale: selected ? 1.15 : 1
    Behavior on scale { NumberAnimation { duration: 120 } }
}
```

### Two geared rings (small strip + big preview)

Run a second ring off the same rotation, with a bigger step and the scroll multiplied by the ratio of the steps. Both rings then reach the same item at the mark at the same time:

```qml
readonly property real gear: bigStep / spin.stepDeg
DialRing { stepDeg: spin.stepDeg; scroll: spin.scroll;        ... }   // small
DialRing { stepDeg: bigStep;      scroll: spin.scroll * gear; ... }   // big
```

HOW-IT-WORKS explains why this lines up. `WallpaperRing.qml` is a full example.

### A selected-item preview in the middle

```qml
CrossfadeImage {
    width: 160
    x: dial.centerX + 150 * Math.cos(dial.midDeg * Math.PI / 180) - width / 2
    y: dial.centerY + 150 * Math.sin(dial.midDeg * Math.PI / 180) - height / 2
    source: model.urlAt(spin.pos)
}
```

---

## Putting dials in a window

Dials need a full-screen, transparent layer. Give it an input **mask** so only the dials catch the mouse and everything else clicks through to your windows:

```qml
import Quickshell
import QtQuick

PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore       // don't push other windows aside
    mask: Region {
        Region { item: appsDial }
        Region { item: wallpaperDial }
    }

    // every dial needs its colours passed: there are no defaults
    AppsDial      { id: appsDial;      corner: "topLeft";     color: "#ffb4a2"; borderColor: "#561f11" }
    WallpaperDial { id: wallpaperDial; corner: "bottomRight"; color: "#ffb4a2"; borderColor: "#561f11"; reelColor: "#723425"; holeColor: "#561f11"; loadingColor: "#f1dfda" }
}
```

The mask follows the dial's size as it opens, so the hot corner is only 30×30 px while closed.

For multiple monitors, wrap the window in `Variants { model: Quickshell.screens }` and set `screen: modelData`.

---

## Keyboard

While a `DialDelegate` is open it takes key focus and handles:

| Key | Does |
|---|---|
| Up, Left, Shift+Tab | `scrolled(-1)` |
| Down, Right, Tab | `scrolled(+1)` |
| Enter, Space | `activated()`, then closes |
| Esc | closes |
| anything printable | `typed(text)` |

The window must actually receive keys. On Wayland, give it the keyboard while the dial is open:

```qml
import Quickshell.Wayland

PanelWindow {
    WlrLayershell.keyboardFocus: dial.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    ...
}
```

To open a dial from a keybind, add an `IpcHandler` (from `Quickshell.Io`) that sets `dial.open`, and bind `qs -p <config folder> ipc call <target> toggle` in your compositor.

---

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `X is not a type` | Missing `import "primitive"`, or the path is wrong relative to *this* file, or the folder is outside the Quickshell config root. |
| Can't click anything else on screen | The window has no `mask`. See above. |
| Wheel spins the wrong way | Call `spin.scrollBy(-dir)`. |
| Selected item isn't the one at the mark | `DialRing.stepDeg` and `DialRotation.stepDeg` differ, or you changed `anchorDeg`. |
| Items overlap | `stepDeg` too small for the item size. Use the spacing formula. |
| Items pop in while spinning | Raise `preload`. For images, set `asynchronous: true`. |
| Items appear in weird places / wrap into view | You set `preload: 0`. Use at least 1. |
| Spinning goes backwards or won't move | `energy` ≤ `momentum` makes the per-notch kick zero or negative. Keep `energy` > `momentum`. |
| Band ends visible / band in the wrong place | `DialBand.startDeg` still at the bottom-right default. Use `dial.startDeg - 15`. |
| Content jumps while opening | You put it directly on the delegate's size (e.g. `anchors.fill: dial`). Use children, which go into `contentItem`. |
| Dial won't stay in its corner | You anchored it yourself. Remove your anchors; `corner` does it. |
| Delegate never gets `listIndex` | It must be **declared** on the delegate's root: `property int listIndex`. |
| Keys do nothing while the dial is open | The window doesn't have the keyboard. Set `WlrLayershell.keyboardFocus` (see [Keyboard](#keyboard)). |
| A `SpringValue` stops following its binding | Something assigned `to` in JavaScript. Use `snap()` instead. |
| No tick sound | `pw-play` missing, `sounds/tick.mp3` missing, or `tickSoundEnabled` is `false`. |

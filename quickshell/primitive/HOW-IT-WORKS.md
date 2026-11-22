# How the dial primitives work

[README.md](README.md) explains how to *use* the primitives. This file explains the tricky parts inside them, in plain language with worked numbers, so you can change them without breaking anything.

Every section starts with the **short version**. Read only that if it's all you need.

The numbers in the examples come from the wallpaper dial at its default size (`expandedSize: 400`):

| | Outer ring (frames) | Inner ring (previews) |
|---|---|---|
| radius | 350 px | 190 px |
| item size | 96 × 54 px | 200 × 112.5 px |
| gap | 24 px | 40 px |

---

## Contents

1. [Angles on a screen](#1-angles-on-a-screen)
2. [Why the content doesn't move while the dial opens](#2-why-the-content-doesnt-move-while-the-dial-opens)
3. [Placing an item on the circle](#3-placing-an-item-on-the-circle)
4. [Spacing: where stepDeg comes from](#4-spacing-where-stepdeg-comes-from)
5. [scroll and pos](#5-scroll-and-pos)
6. [Recycling: an endless list with a few items](#6-recycling-an-endless-list-with-a-few-items)
7. [Preloading and hiding](#7-preloading-and-hiding)
8. [Gearing two rings together](#8-gearing-two-rings-together)
9. [Momentum, and why one notch moves one item](#9-momentum-and-why-one-notch-moves-one-item)
10. [Snapping](#10-snapping)
11. [How the delegate gets listIndex](#11-how-the-delegate-gets-listindex)
12. [The band and its holes](#12-the-band-and-its-holes)
13. [The crossfade](#13-the-crossfade)
14. [Performance notes](#14-performance-notes)
15. [Rules you must not break](#15-rules-you-must-not-break)

---

## 1. Angles on a screen

**Short version:** 0° is right, 90° is **down**. Angles go clockwise because screen y points down.

In school maths, 90° is up. On a screen, `y` grows **downwards**, so `sin(90°) = 1` moves you *down*. Same formulas, mirrored picture:

```
              270° (up)
                 │
  180° (left) ───●─── 0° (right)
                 │
              90° (down)
```

A dial in the **bottom-right** corner has its centre at that corner. The only part of the circle on screen is the part pointing **left and up**, which is 180° … 270°. Each corner gets its own quarter, and `DialDelegate.startDeg` stores which one:

```
 topLeft:     0 …  90   (right, down)     topRight:    90 … 180  (down, left)
 bottomLeft: 270 … 360  (up, right)       bottomRight: 180 … 270 (left, up)
```

The "selected" mark is in the middle of the quarter: `midDeg = startDeg + 45`.

---

## 2. Why the content doesn't move while the dial opens

**Short version:** the dial's size animates, but its content is a fixed square pinned to the corner, so the opening animation just reveals it.

`DialDelegate` animates its own `width`/`height` between `collapsedSize` (20) and `expandedSize` (400), with a spring or a curve (`useSpring`). If your content followed that size, every ring would shrink and grow during the animation.

Instead, children go into `contentItem`, which is **always** `expandedSize × expandedSize` and is positioned so its corner touches the dial's corner:

```
 bottom-right dial, half open (width 200):

   contentItem (400×400) ─┐
   ┌───────────────────────┤
   │ (clipped away)        │
   │         ┌─────────────┤ ◄─ DialDelegate (200×200), clip: true
   │         │  visible    │
   │         │  part       │
   └─────────┴─────────────● ◄─ corner = centre of every circle
```

For bottom-right: `contentItem.x = dial.width - 400`. That's negative while the dial is small, so most of the content sits outside and gets clipped. The corner point stays at `(400, 400)` in content coordinates the whole time, so `centerX`/`centerY` never change.

The background is a separate circle of diameter `2 × dial.width`, centred on the corner. That one *does* grow with the dial, and it's what you see springing open.

---

## 3. Placing an item on the circle

**Short version:** point on a circle = centre + radius × (cos, sin). Rotate by angle + 90 so the item lies along the curve.

For an item whose **centre** should be at angle `deg`, distance `r`:

```
x = cx + r · cos(deg) − width / 2
y = cy + r · sin(deg) − height / 2
rotation = deg + 90
```

- The `− width/2`, `− height/2` turn "centre position" into the top-left corner position that QML wants.
- `Math.cos`/`Math.sin` take radians, so the code multiplies by `π / 180`.
- Why `+ 90`? With `rotation: 0` an item's width runs left↔right. On the circle we want the width to follow the **tangent**, which is 90° from the radius. At the very top (`deg = 270`): `270 + 90 = 360` = upright, the top edge faces outward. Everywhere else the item stays in that same pose relative to the centre.

`DialRing` does this for every slot, so delegates never position themselves.

---

## 4. Spacing: where stepDeg comes from

**Short version:** `stepDeg = (itemWidth + gap) / innerRadius` in radians, converted to degrees. Measuring on the inner edge stops tilted items from overlapping.

`stepDeg` is the angle between two neighbouring items. We want neighbours to be `itemWidth + gap` pixels apart.

On a circle, **arc length = radius × angle (radians)**. So angle = length / radius.

But which radius? Each item is a rectangle sitting **across** the ring: its outer edge is at `r + h/2` and its inner edge at `r − h/2`. Rays from the centre fan out, so neighbouring items are **closest at their inner edges**:

```
        outer edge  ┌───┐ wide gap ┌───┐
                     \   \        /   /
        inner edge    └───┘ ◄──► └───┘   ← tightest here
                         narrow gap
                            ▼
                         centre
```

So the code measures on the inner edge:

```
stepDeg = (itemWidth + gap) / (radius − itemHeight / 2) × 180 / π
```

**Worked: outer ring.** `(96 + 24) / (350 − 27) = 120 / 323 = 0.3715 rad = 21.29°`. About 4.2 frames fit in the 90° quarter.

**Worked: inner ring.** `(200 + 40) / (190 − 56.25) = 240 / 133.75 = 1.794 rad = 102.8°`. A preview step is **wider than the whole visible quarter**, so you see one preview fully, with its neighbours only partly in view while turning.

---

## 5. scroll and pos

**Short version:** `scroll` is degrees turned, any real number. `pos` is the item at the mark, as a whole number.

`DialRotation.scroll` starts at 0 and has no limits: 7200° is twenty turns. Every item's angle is

```
angle(listIndex) = anchorDeg + scroll + listIndex × stepDeg
```

The item at the mark is the one whose angle equals `anchorDeg`:

```
anchorDeg + scroll + k × stepDeg = anchorDeg   ⇒   k = −scroll / stepDeg
```

Rounded to a whole number, that's `pos = round(−scroll / stepDeg)`. The minus sign is why **turning clockwise (scroll going up) lowers `pos`**.

`pos` is unbounded too, so it can be `−37` or `1 000 000`. Whoever owns the list decides what that means: loop with `((i % n) + n) % n`, or clamp. The primitives never assume a list length, which is what lets them be generic.

---

## 6. Recycling: an endless list with a few items

**Short version:** create just enough slots to cover the visible arc plus some spare. When a slot turns off one end, it jumps a full "span" back to the other end and shows the item that many places along.

Making one delegate per list item would mean thousands of images for a big wallpaper folder. Instead `DialRing` creates a fixed number of **slots**:

```
slots = ceil(sweepDeg / stepDeg) + 2 × preload
span  = slots × stepDeg                ← the arc all slots cover, end to end
wrapStart = startDeg − preload × stepDeg   ← where the covered arc begins
```

**Worked (outer ring, preload 5):** `ceil(90 / 21.29) = 5`, plus 10, gives **15 slots**. `span = 15 × 21.29 = 319.4°`. `wrapStart = 180 − 106.4 = 73.6°`. The slots cover 73.6° … 393°: the visible 180…270 with five steps of spare on each side.

Every slot `i` has a "raw" angle that just keeps turning:

```
rawDeg = anchorDeg + scroll + i × stepDeg
```

Left alone, slots would turn right off the screen and never come back. So each slot works out how many whole spans it has gone past the window:

```
laps = floor((rawDeg − wrapStart) / span)
deg  = rawDeg − laps × span          ← always inside [wrapStart, wrapStart + span)
listIndex = i − laps × slots
```

Picture 15 seats on a merry-go-round. When the seat at the far end goes past `wrapStart + span`, `laps` goes up by one: the seat jumps back by `span` degrees, to the start of the window. It now shows the item **15 places earlier** in the list (`i − 15`). That's exactly the item that belongs right before the one now first in line, so the sequence is seamless.

Why does `listIndex = i − laps × slots` give the right item? Plug it into the formula from section 5:

```
anchorDeg + scroll + listIndex × stepDeg
  = anchorDeg + scroll + i × stepDeg − laps × slots × stepDeg
  = rawDeg − laps × span
  = deg     ✓
```

A wrapped slot sits at exactly the angle its new item should have.

**The key consequence:** `laps` only changes at the edges of the window, which are off-screen. A slot changes its item only while nobody can see it, and **only one slot changes per step**. With images, that's one new image load per step instead of every frame reloading.

---

## 7. Preloading and hiding

**Short version:** the spare slots load their item early, while off-screen. They're set to hidden so they can't show up anywhere wrong.

The `preload` spare slots on each side exist to **load before they're needed**. When a slot wraps, its image starts loading right away, about `preload` steps before it reaches the visible edge. By the time it turns into view, it's ready.

These spares could still be drawn somewhere silly. Usually that's harmless, because they sit beyond the edge of the window and get clipped. But a ring can have a **step bigger than the visible arc**. The inner preview ring is 102.8° per step:

```
preview slots = ceil(90 / 102.8) + 10 = 11
span = 11 × 102.8 = 1131°   ← more than three full circles!
```

With 1131° of slots wrapped around a 360° circle, several slots land in the same visible spot and stack on top of each other. That was the overlapping-previews bug.

The fix is a visibility rule in each slot:

```
visible: deg > startDeg − stepDeg  &&  deg < startDeg + sweepDeg + stepDeg
```

A slot is only drawn while it's within **one step** of the visible arc. That's enough for an item to slide in from the edge (at one step out it's fully off-screen) and nothing further away can show.

**Important:** in Qt, `visible: false` does **not** stop an `Image` from loading. Hidden slots keep loading and keep their picture. That's what makes preloading work: hidden but ready.

**Why preload must be at least 1:** the slots must cover the visible arc plus one step each side, or items would wrap *inside* the visible area. With `preload: 0`, `span` is just about the arc itself, and you'd watch items jump.

---

## 8. Gearing two rings together

**Short version:** give the second ring a bigger step and multiply its scroll by `bigStep / smallStep`. Both rings then put the same item at the mark at the same time.

The wallpaper dial has small frames outside and big previews inside, driven by **one** `DialRotation`. Previews are bigger, so their step is bigger (102.8° vs 21.29°). If both rings used the same `scroll`, the outer ring would move one item while the inner one moved a fifth of one, and they'd fall out of step.

So the inner ring turns faster by the **gear ratio**:

```
gear = previewStepDeg / stepDeg = 102.8 / 21.29 ≈ 4.83
inner ring: stepDeg = previewStepDeg, scroll = scroll × gear
```

Check that item `k` reaches the mark on both rings at the same moment. On the outer ring it's at the mark when `scroll + k × stepDeg = 0`. On the inner ring:

```
scroll × gear + k × previewStepDeg
  = gear × (scroll + k × stepDeg)        (because previewStepDeg = gear × stepDeg)
  = gear × 0 = 0   ✓
```

The inner angle is just the outer angle **times a constant**, so both are zero together. Between steps the inner ring swings ~4.8× further. That's the "carried away / carried in" motion.

Gearing is also why the inner ring needs more preload. One outer notch moves a whole preview, so the next preview has to be ready **well** before the outer frames suggest it.

---

## 9. Momentum, and why one notch moves one item

**Short version:** each notch adds speed. Every frame the speed shrinks by `momentum`. The kick is sized so one notch, left alone, glides about one step.

Each frame, `DialRotation` does:

```
scroll   += velocity × frameTime              (move)
velocity *= momentum ^ (frameTime × 60)       (slow down)
```

`momentum` is "how much speed survives one 60 fps frame". At 0.98, 98% survives each frame and the speed halves after about 34 frames (~0.6 s).

The `^ (frameTime × 60)` makes this independent of frame rate. At 144 Hz each frame is shorter, so less speed is lost per frame, but the same amount is lost per second.

**How far does one notch go?** Starting at speed `v`, the distance per 60 fps frame is `v/60`, then `v/60 × m`, then `v/60 × m²` … That's a geometric series:

```
total = (v / 60) × (1 + m + m² + …) = (v / 60) / (1 − m)
```

The kick is chosen as:

```
kick = stepDeg × 60 × (energy − m)
⇒ total = stepDeg × (energy − m) / (1 − m)
```

With `energy = 1`: `total = stepDeg × (1 − m) / (1 − m) = stepDeg`, **exactly one step**, whatever the momentum. With `energy` above 1 a notch goes further, and below 1 less far. (The glide actually stops a little early, see section 10, and the snap finishes the last bit.) Momentum changes *how long* the glide takes, not how far one notch goes.

Spinning fast adds kicks on top of leftover speed, so speed builds up (capped at 40 steps/s).

**The `energy > momentum` rule:** if `energy ≤ momentum`, the kick becomes 0 or negative and notches do nothing or go backwards.

**`momentum: 0`** skips all of this: each notch calls `snapTo(pos − dir)`, so the dial moves exactly one step, no glide.

---

## 10. Snapping

**Short version:** when the glide gets slow enough, it stops and eases onto the nearest whole step.

Physics never makes the speed exactly 0, and it would stop between items anyway. So once `|velocity| < kick × snapThreshold` (by default a tenth of one notch's speed), the glide stops and `scroll` is taken to `−round(−scroll / stepDeg) × stepDeg`, the nearest item. How depends on `useSpring`:

- **Spring** (`useSpring: true`): a `SpringValue` starts at the current `scroll` **with the glide's current speed** and pulls toward the item. Because the speed carries over, the handover from glide to snap is seamless; the spring then overshoots a touch and settles.
- **Curve** (`useSpring: false`): a `snapDuration` ms animation with M3E's expressive fast spatial bezier. It starts from zero speed, so you may feel a small "catch" at the handover.

### How SpringValue moves

Every frame it applies the spring law: acceleration = `stiffness × (to − value) − c × velocity`, with `c = 2 × dampingRatio × √stiffness` (that's what "damping ratio" means: 1 is the least damping with no overshoot). It integrates in fixed 4 ms steps however long the frame was, so stiff springs stay stable even when a frame is slow. It stops when it's within `epsilon` of `to` and nearly still.

A new notch during a snap cancels the snap and adds speed again, so the dial never feels stuck.

---

## 11. How the delegate gets listIndex

**Short version:** each slot loads your delegate with a `Loader`, then uses `Binding`s to push `listIndex`/`ringDeg` into it, but only if your delegate declares those properties.

```
slot Item  (positioned, rotated, sized; computes listIndex & deg)
 └── Loader  (anchors.fill: slot, sourceComponent: ring.delegate)
       └── your delegate
 Binding { target: loader.item; property: "listIndex"; value: slot.listIndex
           when: loader.item has a "listIndex" property }
 Binding { ... "ringDeg" ... }
```

- The **slot** does all the geometry, so delegates are plain content.
- The `when:` check means a delegate that doesn't care about `ringDeg` doesn't need to declare it, and won't throw "non-existent property" errors.
- Because the Binding pushes values **in**, the property must be **declared on the delegate's root item** (`property int listIndex`). A property on a child won't be found.

---

## 12. The band and its holes

**Short version:** the band is one very thick arc stroke. The holes are a dashed stroke whose dash offset moves with the scroll.

- **Band:** a `ShapePath` with one `PathAngleArc` at `radius` and `strokeWidth = frameHeight + edgeMargin`. A thick line along an arc *is* a ring segment. `FlatCap` keeps the ends square. `Shape.CurveRenderer` antialiases it on the GPU, so it's smooth at any size without an offscreen layer.
- **Holes:** two more arcs, one per edge, drawn with `DashLine`. Qt measures a dash pattern in **multiples of the stroke width**, so the code divides pixel lengths by `holeSize`:
  - spacing between hole starts in px: `stepRad × r / holesPerFrame` (arc length of one step, split between holes)
  - pattern: `[holeLength / holeSize, (spacing − holeLength) / holeSize]`
  - `dashOffset` moves by the distance travelled (`scroll` in radians × `r`), so the holes slide in step with the items.
- The hole arcs sit at `radius ± (frameHeight/2 + edgeMargin/2)`, which is the **outer border of the band**, so the holes straddle the band's edge. If you want them inside the border, use `bandWidth = frameHeight + 2 × edgeMargin` or move them inwards.
- `showHoles: false` draws the hole paths in a transparent colour rather than removing them. That's simpler and costs almost nothing.

---

## 13. The crossfade

**Short version:** two images stacked. The new one loads hidden, fades in once ready, then becomes the "old" one.

```
source changes →
  oldImage.source = what's showing now     (so it stays on screen)
  newImage.opacity = 0; newImage.source = new url   (starts loading, invisible)
newImage finishes loading →
  fade newImage 0 → 1
fade done →
  oldImage.source = newImage.source        (ready for next time)
```

Fading starts on `status === Image.Ready`, not on the source change, so a slow load never shows a blank frame or a half-decoded picture. Changing the source again mid-fade simply restarts with the current picture as "old".

---

## 14. Performance notes

- **`asynchronous: true`** on images decodes them on a worker thread. Without it, every wrap would stall a frame. This was the main stutter in early versions.
- **`sourceSize: 2 × display size`** decodes a big wallpaper at thumbnail size instead of full 4K. That uses less memory and decodes faster, while staying sharp on HiDPI.
- **`mipmap: true`** gives smooth downscaling. **`antialiasing: true`** smooths the edges of rotated items.
- **Memory** grows with `slots`. Each slot keeps one decoded image. Raising `preload` from 5 to 8 adds 6 images per ring.
- **Per-frame work** is only maths in bindings (a few `cos`/`sin` per slot). Slots change their source only when they wrap.
- **The background** is a plain `Rectangle` with `radius`, not a Shape or layer. That avoids a dark halo where an offscreen layer would blend into the transparent window.

---

## 15. Rules you must not break

1. **Same `stepDeg`** for a `DialRotation` and the ring it drives. Otherwise `pos` isn't the item at the mark.
2. **`preload ≥ 1`**, or items wrap inside the visible area.
3. **`energy > momentum`**, or notches do nothing or go backwards.
4. **Geared rings:** `scroll × (theirStep / baseStep)`, never a made-up number, or the rings drift apart.
5. **Pass `dial.centerX/Y` and `dial.startDeg`**, don't hard-code. That's what makes a dial work in any corner.
6. **Declare `listIndex` on the delegate root**, or it is never filled in.
7. **Don't anchor a `DialDelegate`** yourself. `corner` does it.
8. **Put content inside the delegate** (it goes into `contentItem`). Don't size it from the delegate, or it moves while opening.
9. **Wrap negative indices with `((i % n) + n) % n`**. JavaScript `%` keeps the sign.

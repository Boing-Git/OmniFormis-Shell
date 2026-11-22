# ADR 0022: LoadingIndicator's polygon shapes and morph curves are precomputed offline from a faithful port of `RoundedPolygon`/`Morph`, and the indeterminate loop ships as CSS `linear()`-eased, structurally-split `@keyframes`

Status: accepted
Date: 2026-07-20
Task: T22
Amended: 2026-07-20 (T21 circular-wave follow-up)

## Context

The pinned AndroidX revision (`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`) implements
`LoadingIndicator.kt` (uncontained `LoadingIndicator`/`ContainedLoadingIndicator`,
each with a `progress`-driven determinate and an autonomous indeterminate
composable) on top of a genuinely separate geometry module,
`graphics/graphics-shapes` (`RoundedPolygon.kt`, `Cubic.kt`, `Features.kt`,
`PolygonMeasure.kt`, `FeatureMapping.kt`, `FloatMapping.kt`, `Morph.kt`,
`Point.kt`, `Utils.kt`, `Shapes.kt`, `CornerRounding.kt`), plus
`compose/material3/MaterialShapes.kt`'s named shape vertex/rounding data
(`Circle`, `SoftBurst`, `Cookie9Sided`, `Pentagon`, `Pill`, `Sunny`,
`Cookie4Sided`, `Oval`, and many more not needed here). This is a real
geometry engine: `RoundedPolygon` constructs corner-rounded cubic Bézier
outlines from vertex data, and `Morph` matches curves between two
differently-shaped `RoundedPolygon`s (by measuring both shapes' outlines
proportionally and pairing/cutting curves so both sides end up with the
same ordered cubic list) so that a plain per-coordinate `lerp` between
matched pairs produces a smooth in-between shape at any progress. `SPEC.md`
§9 names one component, `LoadingIndicator`, matching the existing
`"planned"` inventory placeholder row.

`docs/SPEC.md` §14's task-table description for T22 is "Shared polygon
shape morphing and reduced-motion fallback" — the morphing *is* the
task, unlike T21's `WavyProgress`, where the source's own
`RoundedPolygon`-morph-based radial amplitude was initially substituted with
an opacity cross-fade because porting the full geometry engine solely for
that detail was disproportionate. Once T22 had produced and validated the
faithful offline geometry port, the T21 conformance follow-up reused it to
generate `WavyProgress`'s exact matched circle/star endpoints as well. No
geometry engine ships at runtime in either component.

## Decisions

1. **Scope: uncontained `LoadingIndicator` only.** `ContainedLoadingIndicator`
   (a colored-container variant) is out of scope — `SPEC.md` §9 names only
   `LoadingIndicator`, and every prior T01–T21 component has matched §9's
   names exactly. The uncontained composable's own `containerColor` is
   `Color.Unspecified` (paints nothing), so no `container-shape`/
   `container-color` tokens are registered — there is no visible container
   to theme.

2. **The full `RoundedPolygon`/`Morph` geometry engine was ported to an
   offline Python script**, function-for-function against the pinned
   source: vector/point math (`Point.kt`, `Utils.kt`), cubic Bézier
   operations including corner-rounding's flanking-curve construction
   (`Cubic.kt`, the `RoundedCorner` class in `RoundedPolygon.kt`), polygon
   assembly from vertices into a closed, contiguous cubic list
   (`RoundedPolygon.kt`), the `circle`/`star` factory functions
   (`Shapes.kt`), and the full `Morph` matching pipeline — arc-length
   measurement (`PolygonMeasure.kt`'s `LengthMeasurer`), feature (corner)
   proportional-position mapping between the two shapes
   (`FeatureMapping.kt`'s `doMapping`/`DoubleMapper`), and the final
   cut-and-match loop that produces paired, structurally-aligned cubic
   lists (`Morph.kt`'s `match`). `MaterialShapes.kt`'s exact vertex/rounding
   data (including its `customPolygon`/`doRepeat` mirroring helper) was
   ported alongside it to construct the eight needed named shapes. Every
   shape was rendered standalone and visually cross-checked against the
   known Material 3 Expressive shape gallery (SoftBurst's ten soft bumps,
   Cookie9Sided's nine gentle scallops, Sunny's eight-point star, Pentagon,
   Cookie4Sided's four-lobed clover, the rotated Oval, Pill) before being
   trusted, and every morph transition was rendered mid-progress and
   inspected for self-intersection or degenerate geometry. This is a large
   port (~1,800 lines of ported Kotlin across the two scripts) but it is a
   *one-time, offline* cost — nothing here ships in the runtime bundle.

3. **Determinate mode ships the matched-cubic-pair output directly, as a
   flat numeric array** (`loadingIndicatorMorphs.ts`), not pre-sampled
   snapshots. `Morph`'s own interpolation (`forEachCubic`) is nothing more
   than a per-coordinate `lerp` between two already-matched cubic lists, so
   the component performs that exact same `lerp` at render time from the
   continuous `value` prop — a plain synchronous function of props, no
   `requestAnimationFrame`, matching every other determinate progress
   component's own convention. `transform: rotate(-progress*180deg)`
   matches the source's `val rotation = -progressValue * 180` exactly. A
   CSS `transition` on `d`/`transform` handles smooth value-change motion.

4. **Indeterminate mode cannot use one continuous `d` `@keyframes` rule
   across all seven shapes.** The CSS `d` property only animates between
   *structurally identical* path data (same ordered list of drawing
   commands); consecutive shape pairs in the 7-shape loop
   (`SoftBurst`→`Cookie9Sided`→`Pentagon`→`Pill`→`Sunny`→`Cookie4Sided`→
   `Oval`→`SoftBurst`) have different matched-cubic-segment counts (58, 28,
   22, 44, 48, 24, 48 respectively), so there is no single `@keyframes`
   rule whose stops are all mutually compatible. The solution: **seven
   stacked `<path>` elements**, one per shape-pair, each owning its own
   `@keyframes` rule spanning the full `4550ms` (7×650ms) loop. Within that
   rule, the path's `d` only ever interpolates between *its own* two
   endpoints (always structurally consistent, since it's one fixed shape
   pair) — flat before its `650ms` slot, animating within it, flat after.
   `opacity` hard-cuts (via `step-end`, not the default ease — see
   Consequences) so exactly one segment is visible at any moment, exactly
   reproducing the source's own instantaneous index-swap-and-snap.

5. **The per-segment morph spring is reproduced via CSS `linear()` easing
   on a two-stop `d` keyframe, not by pre-sampling the path data itself.**
   The source's morph animation spec is
   `spring(dampingRatio=0.6f, stiffness=200f, visibilityThreshold=0.1f)`,
   settling in `298ms` of each `650ms` segment (found via the same
   closed-form settling-time formula `src/tokens/css.ts`'s
   `springDurationMilliseconds` already uses for the shared
   `--m3e-sys-motion-expressive-*` tokens, at this spring's own sourced
   threshold rather than that function's generic `0.001`). Since
   `animation-timing-function: linear(<samples>)` warps *when* keyframe
   progress advances rather than pre-sampling the interpolated *value*,
   applying it to a plain `0% { d: startD } settle% { d: endD }` rule
   reproduces the exact spring-shaped motion using only the two path
   endpoints — no intermediate `d` samples needed at all, in contrast to
   `LinearProgress`'s T21 precedent (which had to pre-sample because its
   target curve was the *difference* of two independently eased values,
   not expressible as one `linear()` function). This also reproduces the
   spring's characteristic slight overshoot naturally: the `linear()`
   samples legitimately exceed `1` near the settle point (up to `~1.094`),
   and CSS keyframe interpolation extrapolates a `d`/`transform` value past
   its endpoint exactly the same way `Cubic`'s own `interpolate` does for
   `progress > 1` — matching the source's own documented use of
   out-of-range morph progress "to get an exaggerated effect (e.g., for a
   bounce or overshoot animation)," not an approximation of it.

6. **Rotation composes two independent layers**, mirroring
   `CircularProgress`/`WavyProgress`'s own nested-`<g>` technique: each
   segment's own step-plus-spring local rotation
   (`progress*90 + ((index+1)*90 % 360)` — the `+1` matches the source's
   own `morphRotationTargetAngle` starting at `QuarterRotation` rather than
   zero) is baked directly into that segment's own `transform` keyframe
   stops (sharing the identical `linear()` easing used for `d`, since both
   properties follow the same spring-eased progress). A separate,
   always-on `4666ms`/`360deg` linear rotation (`GlobalRotationDurationMillis`)
   applies to an outer wrapping `<g>` around all seven segments, composing
   additively via ordinary CSS transform nesting.

7. **No per-frame `path.getBounds()` re-centering.** `LoadingIndicator.kt`'s
   `processPath` recomputes and re-centers the *current interpolated*
   path's own bounding box every single frame — not practical to replicate
   in CSS without a `requestAnimationFrame` loop. Measured offline (bounds
   sampled at five progress steps across every one of the eight morphs),
   the true center drifts by at most `~0.006` in `[0, 1]` shape-space —
   under 0.3px at this component's 48px scale, and zero for the determinate
   morph specifically. This project instead bakes one static scale+recenter
   transform per shape set directly into the precomputed coordinates:
   `bakedCoordinate = 0.5 + (rawCoordinate - 0.5) * scaleFactor`, where
   `scaleFactor` is `calculateScaleFactor(indicatorPolygons) *
   ActiveIndicatorScale` (`ActiveSize / min(ContainerWidth, ContainerHeight)`
   = `38/48`), computed exactly per the source's own formula. This is a
   *measured*, verified-negligible simplification, not a guess.

8. **Baked coordinates use a `0`–`100` viewBox at 2 decimal places.** Two
   decimals on a `0`–`100` scale is `0.0001` in the shape's own normalized
   `[0, 1]` space — far below any visible threshold at this component's
   size — while keeping the generated stylesheet reasonably sized (the
   indeterminate keyframes file is the largest single CSS artifact in v1 by
   a wide margin, at ~50KB uncompressed, entirely path-coordinate text that
   gzips well).

9. **Reduced motion freezes indeterminate mode on one static shape** — the
   first segment's own start shape (`SoftBurst`) — rather than whatever
   frame the animation happened to reach, matching every other v1 progress
   component's "static state communicates activity without motion"
   precedent. Since disabling the segment's own `animation` removes all
   keyframe-supplied values (leaving `d` unset, rendering nothing), a
   small static fallback class ships the same start-shape `d` value as an
   ordinary (non-animated) declaration, which the running animation
   overrides via the normal CSS animation-cascade priority whenever motion
   is not reduced.

## Consequences

- This is the fourth v1 component using CSS `@keyframes` for continuous
  motion (after `LinearProgress`/`CircularProgress`/`WavyProgress`, T21),
  and the first to combine `@keyframes` with a `linear()` spring easing
  and with the SVG `d` property specifically.
- **A same-session implementation bug is worth recording as a gotcha**:
  initially, only the `[settle%, slotEnd%]` interval's `opacity: 1 → 0`
  transition was forced to `step-end`; the *entry* transition
  (`[0%, slotStart%] opacity: 0 → 1`, for every segment after the first)
  was left on the browser's default easing, which smoothly cross-faded it
  in — since `d`/`transform` are constant across that same span, this was
  invisible for those two properties but produced a multi-segment
  "ghosting" artifact for opacity, confirmed by inspecting
  `getComputedStyle(path).opacity` on every segment at a fixed point in the
  cycle (several were fractionally non-zero simultaneously) before fixing
  it. Both the entry and exit intervals need their own explicit
  `step-end`.
- The offline Python geometry port (`shapes_port.py`, `morph_port.py`,
  `materialshapes_port.py`, `generate.py` — not shipped, referenced here
  for provenance) is the largest primary-source port in the v1 rewrite to
  date. It is intentionally *not* committed to the repository: it is a
  one-time generation tool whose only artifacts that matter are its
  outputs (`loadingIndicatorMorphs.ts`, `loadingIndicatorKeyframes.css`),
  the same relationship `wavePaths.ts`'s own generation scripts (T21) have
  to their component.
- The same validated port now supplies `WavyProgress`'s 27-cubic matched
  circle/star endpoints. That later T21 repair supersedes ADR 0021's original
  sampled radial-sine/opacity-cross-fade compromise without adding runtime
  geometry code.
- Bundle budgets were raised to accommodate the precomputed geometry (see
  `docs/bundle-budgets.json`), following the T13/T15/T17/T19/T21
  proportional-raise precedent.
- Determinate mode's `d`-driven `transition` behavior (browser-interpolated
  cross-fade between two arbitrary progress values on rapid `value`
  changes) was not independently re-verified against `Morph`'s own
  behavior for such changes, since the source itself does not animate
  determinate `progress` changes at all — the caller's own value changes
  are assumed already smoothed upstream, and this project's CSS
  `transition` is an intentional, precedented (`LinearProgress`/
  `CircularProgress`/`WavyProgress`) addition for a better default web
  experience, not a source behavior being replicated.

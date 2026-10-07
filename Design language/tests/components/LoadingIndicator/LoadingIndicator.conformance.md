# LoadingIndicator conformance

Task: T22
Status: conformant
Reviewed: 2026-07-20

## Primary references

- Material Design loading indicator component guide, accessed 2026-07-20:
  <https://m3.material.io/components/loading-indicator/overview>
- Pinned current AndroidX `LoadingIndicator.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/LoadingIndicator.kt>
- Pinned `MaterialShapes.kt` (named shape vertex/rounding data), accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/MaterialShapes.kt>
- Pinned `graphics/graphics-shapes` module (`RoundedPolygon.kt`, `Cubic.kt`,
  `Morph.kt`, `PolygonMeasure.kt`, `FeatureMapping.kt`, `Features.kt`,
  `Point.kt`, `Utils.kt`, `Shapes.kt`, `CornerRounding.kt`), accessed
  2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/graphics/graphics-shapes/src/commonMain/kotlin/androidx/graphics/shapes/>
- Pinned generated AndroidX `LoadingIndicatorTokens`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/LoadingIndicatorTokens.kt>
- WAI-ARIA APG progressbar guidance, accessed 2026-07-20:
  <https://www.w3.org/WAI/ARIA/apg/patterns/meter/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`.

## Anatomy and content

- One public component: `value`/`max` determine determinate progress
  (morphs `Circle`→`SoftBurst`); omitting `value` renders indeterminate (a
  continuous, autonomous 7-shape loop). `aria-label`/`aria-labelledby`
  provide the required accessible name.
- A `48×48` SVG (`ContainerWidth`/`ContainerHeight`) containing either one
  determinate `<path>` (its `d` recomputed from `value` every render) or
  seven stacked indeterminate `<path>` segments, each owning one shape-pair
  of the loop and its own hard-cut visibility window.

## Variants, shape, color, and size

- `primary`-tinted shape (`ActiveIndicatorColor`). Only the uncontained
  `LoadingIndicator` composables are in scope — `ContainedLoadingIndicator`
  (a colored-container variant) is not, since `SPEC.md` §9 names only
  `LoadingIndicator`.
- Determinate morphs between exactly two `RoundedPolygon` shapes (`Circle`,
  rotated 18°, and `SoftBurst`). Indeterminate cycles through seven
  (`SoftBurst`, `Cookie9Sided`, `Pentagon`, `Pill`, `Sunny`, `Cookie4Sided`,
  `Oval`), matching `LoadingIndicatorDefaults`' own default polygon lists.

## States and motion

- Determinate: `transform: rotate(-progress*180deg)` (counterclockwise,
  matching the source), `d` recomputed via the exact per-coordinate `lerp`
  `Morph.forEachCubic` performs every frame against the pre-matched
  `Circle`→`SoftBurst` cubic pairs. Both transition on the shared
  `--m3e-sys-motion-expressive-default-spatial-*` slot on value change.
- Indeterminate: each of the seven segments owns a `650ms` slot within a
  `4550ms` (7×650ms) loop — a spring-eased (`dampingRatio=0.6,
  stiffness=200`) morph into the next shape, settling in `298ms`, then a
  static hold until its slot ends, then a hard cut (`opacity`, `step-end`)
  to the next segment. A separate, always-on `4666ms`/`360deg` linear
  rotation composes additively on top via an outer wrapping `<g>`.

## Accessibility

- `role="progressbar"` with `aria-valuemin="0"`/`aria-valuemax`/
  `aria-valuenow` (determinate) or no `aria-valuenow` at all
  (indeterminate).
- No interactive semantics: the indicator is not focusable and has no
  keyboard model, matching the source.

## Web-specific deviations

- **Real `RoundedPolygon`/`Morph` geometry, faithfully ported offline, not
  approximated.** Unlike `WavyProgress` (T21), which substituted a
  documented technique (opacity cross-fade) for the source's
  `RoundedPolygon`-morph radial amplitude ramp — a secondary polish detail
  — this component's entire identity *is* the shape morph, so the full
  `RoundedPolygon` construction (vertex/corner-rounding → cubic Béziers)
  and `Morph`'s curve-matching algorithm were ported to an offline Python
  script from the pinned `graphics-shapes` source files, producing exact
  matched-cubic-pair data for every needed shape transition. Every shape
  was visually verified against the known Material 3 Expressive shape
  gallery. See ADR 0022.
- **Indeterminate ships as seven stacked `<path>` elements, not one
  continuously mutating path.** The CSS `d` property can only animate
  between *structurally identical* path data, and consecutive shape pairs
  in the 7-shape loop have different cubic-segment counts — so one
  continuous `@keyframes d: ...` across all seven is not expressible in
  CSS. Each segment instead owns its own single shape-pair `@keyframes`
  rule (always structurally consistent within that rule) and a hard-cut
  `opacity` window, reproducing the source's visual result exactly without
  `requestAnimationFrame`.
- **Spring easing reproduced via CSS `linear()`, not pre-sampled `d`
  values.** The source's per-segment morph spring
  (`dampingRatio=0.6, stiffness=200, visibilityThreshold=0.1`) is baked as
  a `linear()` timing function using the same spring→`linear()` sampling
  technique `src/tokens/css.ts` already applies to the shared
  `--m3e-sys-motion-expressive-*` spring tokens, applied as the
  `animation-timing-function` for a plain two-keyframe (`d`: start → end)
  segment. Because `linear()` warps *when* progress advances rather than
  the interpolated value itself, only two path endpoints ship per segment,
  and the spring's characteristic slight overshoot-and-settle emerges
  naturally from the eased value legitimately exceeding 1 mid-segment —
  matching the source's own documented use of out-of-range morph progress
  for "bounce or overshoot" effects.
- **No per-frame `path.getBounds()` re-centering.** The source recomputes
  and re-centers the interpolated path's bounding box every frame; this
  project bakes one static scale+recenter transform per shape set directly
  into the precomputed coordinates instead. Measured offline across every
  sampled morph, the true per-frame recentering never drifts more than
  ~0.6% of the container size — sub-pixel at this component's 48px scale —
  making this a verified-negligible simplification, not a guess.
- Reduced motion freezes indeterminate mode on a static shape (the first
  segment's own start shape) rather than whatever frame the animation
  happened to reach, matching every other progress component's
  "static state communicates activity without motion" precedent.

# CircularProgress conformance

Task: T21
Status: conformant
Reviewed: 2026-07-20

## Primary references

- Material Design progress indicators component guide, accessed 2026-07-20:
  <https://m3.material.io/components/progress-indicators/overview>
- Pinned current AndroidX `ProgressIndicator.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/ProgressIndicator.kt>
- Pinned generated AndroidX `ProgressIndicatorTokens`/
  `CircularProgressIndicatorTokens`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/CircularProgressIndicatorTokens.kt>
- Pinned `tokens/MotionTokens.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/MotionTokens.kt>
- WAI-ARIA APG meter/progressbar guidance, accessed 2026-07-20:
  <https://www.w3.org/WAI/ARIA/apg/patterns/meter/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`.

## Anatomy and content

- One public component: `value`/`max` determine determinate progress;
  omitting `value` renders indeterminate. `aria-label`/`aria-labelledby`
  provide the required accessible name.
- A fixed `40x40` SVG (`Size` token) containing a `<circle>` track
  (determinate only) and a `<circle>` indicator, both driven by
  `stroke-dasharray`/`stroke-dashoffset` with an explicit `pathLength={100}`
  so every sweep value is a plain 0–100 number. A zero-length active or track
  arc is omitted so its round cap cannot paint an endpoint dot.

## Variants, shape, color, and size

- `primary`-tinted indicator (`ActiveIndicatorColor`), `secondaryContainer`
  track (`TrackColor`, determinate only — see Web-specific deviations),
  `4px` stroke width (`ActiveThickness`), round stroke caps, `4px` gap
  between indicator and track (`TrackActiveSpace`).

## States and motion

- Determinate: the sweep's `stroke-dasharray` transitions on value changes
  via the shared `--m3e-sys-motion-expressive-default-spatial-*` slot. Track
  placement reserves the requested 4px gap plus the 4px stroke-width
  allowance required by the two round caps, clamped for short active arcs.
- Indeterminate: three independently animated nested groups compose
  additively, matching the source's three composed `animateFloat` values —
  a continuous `1080deg`/`6000ms` linear global rotation, a stepped
  `90/180/270/360deg` additional rotation
  (`EasingEmphasizedDecelerateCubicBezier`), and a `0.1→0.87→0.1` sweep
  pulse (`EasingStandardCubicBezier` then linear). Each nested group uses
  the fixed SVG view box as its transform basis and resolves to the 20px/20px
  canvas center throughout the cycle. Determinate geometry starts at
  `-90deg` (12 o'clock); indeterminate preserves the source's native
  circle-path phase before those composed rotations.

## Accessibility

- `role="progressbar"` with `aria-valuemin="0"`/`aria-valuemax`/
  `aria-valuenow` (determinate) or no `aria-valuenow` at all
  (indeterminate).
- No interactive semantics: the indicator is not focusable and has no
  keyboard model, matching the source.

## Web-specific deviations

- **No track element at all when indeterminate**: the pinned source's own
  `circularIndeterminateTrackColor` default is `Color.Transparent` (unlike
  the linear indicator's own indeterminate track, which stays visible) —
  this project renders no track element rather than an explicit
  transparent one, the more direct translation of "invisible."
- **First CSS `@keyframes`-driven component** (together with
  `LinearProgress`/`WavyProgress`, T21's own siblings) — every prior
  component's motion was a `transition` on a discrete state change. The
  additional-rotation/sweep-pulse keyframe stops are literal percentage
  values (structural geometry sourced directly from the pinned
  `AnimationSpec` keyframe definitions), not registered as tokens — the
  same "hardcode the shape, token the reusable duration/easing" split
  `Checkbox`'s own checkmark path-data already used.
- Fixed intrinsic `40px` size, not responsive — unlike `LinearProgress`'s
  deliberate `inline-size: 100%` default, a circular indicator is used as
  a small, fixed-size spinner in real web usage too, matching the source's
  own fixed `Size` token with no deviation.
- This is one of three sibling components (`LinearProgress`,
  `CircularProgress`, `WavyProgress`) matching `SPEC.md` §9's own
  three-item naming; see ADR 0021 for why "wavy" is its own component
  rather than a `variant` prop on this one.

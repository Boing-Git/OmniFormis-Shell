# LinearProgress conformance

Task: T21
Status: conformant
Reviewed: 2026-07-20

## Primary references

- Material Design progress indicators component guide, accessed 2026-07-20:
  <https://m3.material.io/components/progress-indicators/overview>
- Pinned current AndroidX `ProgressIndicator.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/ProgressIndicator.kt>
- Pinned generated AndroidX `ProgressIndicatorTokens`/
  `LinearProgressIndicatorTokens`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/LinearProgressIndicatorTokens.kt>
- WAI-ARIA APG meter/progressbar guidance, accessed 2026-07-20:
  <https://www.w3.org/WAI/ARIA/apg/patterns/meter/>
- WCAG 2.2 reduced motion and forced colors, accessed 2026-07-20:
  <https://www.w3.org/TR/WCAG22/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`.

## Anatomy and content

- One public component: `value`/`max` determine determinate progress;
  omitting `value` renders indeterminate — the same contract a native
  `<progress>` element uses for its own determinate/indeterminate state.
  `aria-label`/`aria-labelledby` provide the required accessible name.
- Determinate mode renders a track, a fill, and an end-of-track stop dot.
  Indeterminate mode renders a track and two independently animated bars,
  matching the source's own two-line "chasing bars" indeterminate motion.

## Variants, shape, color, and size

- `4px` container height (`Height`), full `inline-size: 100%` by default
  (see Web-specific deviations). `primary`-tinted fill/stop
  (`ActiveIndicatorColor`/`StopColor`), `secondaryContainer` track
  (`TrackColor`), `cornerFull` shape on every part.
- `4px` gap between the fill and track (`TrackActiveSpace`), `4px` stop
  dot size (`StopSize`).

## States and motion

- Determinate: the fill's `inline-size` transitions on value changes via
  the shared `--m3e-sys-motion-expressive-default-spatial-*` slot (an
  ordinary discrete state change, unlike the indeterminate motion below).
- Indeterminate: two bars loop continuously via CSS `@keyframes` — a
  `1750ms` cycle with per-line `250`/`650`/`900ms` delays and
  `EasingEmphasizedAccelerateCubicBezier`, densely pre-sampled into
  keyframe stops (see Web-specific deviations).

## Accessibility

- `role="progressbar"` with `aria-valuemin="0"`/`aria-valuemax`/
  `aria-valuenow` (determinate) or no `aria-valuenow` at all
  (indeterminate) — the APG progressbar pattern's own documented technique
  for signaling an indeterminate state to assistive technology.
- No interactive semantics: the indicator is not focusable and has no
  keyboard model, matching the source (a progress indicator is a passive
  status display, not a control).

## Web-specific deviations

- **Responsive `inline-size: 100%` instead of the source's fixed `240dp`
  sample default** — a web progress bar is overwhelmingly used full-width
  (matching `<progress>`'s own default block-level rendering); the source's
  fixed width is a mobile-sample convenience, not a hard constraint.
- **First CSS `@keyframes`-driven component** (together with
  `CircularProgress`/`WavyProgress`, T21's own siblings) — every prior
  component's motion was a `transition` on a discrete state change. The
  two indeterminate bars' `inset-inline-start`/`inline-size` keyframes are
  numerically pre-sampled from the source's four independently
  delayed/eased curves rather than hand-derived, since a CSS keyframe
  segment can only interpolate with one easing curve and each bar's own
  motion is the *difference* of two independently timed eased curves.
- No carved gap in the indeterminate track (the track renders as one
  continuous full-width bar under the two moving indicator segments,
  rather than three dynamically-computed gapped segments) — a documented
  simplification also used by other production Material-inspired web
  implementations, not a fabrication.
- This is one of three sibling components (`LinearProgress`,
  `CircularProgress`, `WavyProgress`) matching `SPEC.md` §9's own
  three-item naming; see ADR 0021 for why "wavy" is its own component
  rather than a `variant` prop on this one.

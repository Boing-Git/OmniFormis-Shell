# WavyProgress conformance

Task: T21
Status: conformant
Reviewed: 2026-07-20

## Primary references

- Material Design progress indicators component guide, accessed 2026-07-20:
  <https://m3.material.io/components/progress-indicators/overview>
- Pinned current AndroidX `WavyProgressIndicator.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/WavyProgressIndicator.kt>
- Pinned `internal/LinearWavyProgressModifiers.kt`/
  `CircularWavyProgressModifiers.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/internal/LinearWavyProgressModifiers.kt>
- Pinned generated AndroidX `ProgressIndicatorTokens`/
  `LinearProgressIndicatorTokens`/`CircularProgressIndicatorTokens`/
  `tokens/MotionTokens.kt`, accessed 2026-07-20 (see `LinearProgress`/
  `CircularProgress` conformance for direct links).
- WAI-ARIA APG meter/progressbar guidance, accessed 2026-07-20:
  <https://www.w3.org/WAI/ARIA/apg/patterns/meter/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`.

## Anatomy and content

- One public component: `shape: 'linear' | 'circular'` (default
  `'linear'`) selects the orientation; `value`/`max` determine determinate
  progress, omitting `value` renders indeterminate. `aria-label`/
  `aria-labelledby` provide the required accessible name.
- The source itself groups both orientations' wavy treatment into one file
  (`WavyProgressIndicator.kt`, `LinearWavyProgressIndicator`/
  `CircularWavyProgressIndicator`), distinct from the plain file's own
  linear/circular split (`ProgressIndicator.kt`) — this component mirrors
  that grouping with a `shape` prop rather than two separate components.

## Variants, shape, color, and size

- `'linear'`: `10px` container height (`WaveHeight`, taller than
  `LinearProgress`'s `4px` to leave room for the wave), `40px`/`20px`
  determinate/indeterminate wavelength (`ActiveWaveWavelength`/
  `IndeterminateActiveWaveWavelength`), responsive `inline-size: 100%`
  (see `LinearProgress`'s own deviation note — the same reasoning applies).
- `'circular'`: `48px` fixed diameter (`WaveSize`, larger than
  `CircularProgress`'s plain `40px` `Size`), `15px` wavelength for both
  determinate and indeterminate (one token, unlike the linear shape's two).
- Both: `primary`-tinted indicator, `secondaryContainer` track (a straight
  rounded line for the linear shape and a circle for the circular shape),
  `4px` stroke width. Unlike plain `CircularProgress`'s transparent
  indeterminate track, the circular wavy track remains visible in both modes.

## States and motion

- Wave travel: a continuous `translateX` (linear) / `rotate` (circular)
  loop of exactly one wavelength per `wavelength / waveSpeed` — always
  `1000ms` since `waveSpeed` defaults to `wavelength` in the source,
  running continuously regardless of determinate/indeterminate mode. The
  circular path counter-rotation is paired with a synchronized one-ninth-path
  dash shift, keeping the sweep endpoints fixed while the lobes travel.
- Amplitude ramp: `WavyProgressIndicatorDefaults.indicatorAmplitude` zeroes
  the wave near `progress <= 0.1` or `>= 0.95` in determinate mode (always
  full amplitude when indeterminate, matching the source's own fixed
  `amplitude: Float = 1f` default there). `'linear'` interpolates between
  structurally identical flat/full quadratic paths; `'circular'` interpolates
  between matched 27-cubic circle/star paths. Both preserve the 4px stroke.
  Increasing amplitude uses the source's standard easing and decreasing
  amplitude uses its emphasized-accelerate easing, each over `500ms`.
- Indeterminate `'linear'` reuses `LinearProgress`'s exact pre-sampled
  head/tail keyframes for the visible clip window, layering the
  wave-travel animation on top. Indeterminate `'circular'` reuses
  `CircularProgress`'s exact three-layer rotation/sweep composition,
  adding a fourth continuous `-40deg` rotation for one nine-wave period.
  The source's static `+90deg` indeterminate orientation is included. All
  circular transform layers use the fixed 48px view box and its 24px center;
  the circle track shares those layers and pulses its open segment with the
  active sweep while preserving the adaptive cap/gap spacing.

## Accessibility

- `role="progressbar"` with `aria-valuemin="0"`/`aria-valuemax`/
  `aria-valuenow` (determinate) or no `aria-valuenow` at all
  (indeterminate), identical contract to `LinearProgress`/
  `CircularProgress`.
- No interactive semantics: the indicator is not focusable and has no
  keyboard model, matching the source.

## Web-specific deviations

- **`shape` prop instead of a fourth component**: the source's own file
  split (plain vs. wavy, each internally split by orientation) is the
  precedent this component follows, rather than one component per
  orientation × treatment combination.
- **Source-derived paths are prepared outside the render loop.** The linear
  path is the source's repeating quadratic construction with a 3px
  centerline amplitude, leaving exactly half the 4px stroke inside each edge
  of the 10px container. The circular endpoints come from the faithful T22
  offline port of the pinned `RoundedPolygon`/`Morph` implementation: a
  nine-vertex circle and rounded nine-point star, normalized and scaled into
  the source's stroke-safe 44px drawing area. Browser `d` interpolation and
  CSS transforms provide motion; there is no `requestAnimationFrame` loop or
  per-frame path regeneration.
- **Linear wave path is generated across a fixed, generous 2440px width**, not
  computed per actual rendered width — comfortably covers realistic
  layout widths; a bar stretched wider than that would see the wave
  pattern clip at the far edge, a documented, extremely unlikely edge case
  for an ultra-wide viewport.
- **No carved gap in the indeterminate linear track:** it remains one
  continuous full-width low-contrast bar beneath the moving wave windows,
  matching the existing `LinearProgress` web deviation.
- This is one of three sibling components (`LinearProgress`,
  `CircularProgress`, `WavyProgress`) matching `SPEC.md` §9's own
  three-item naming — see ADR 0021 for the full rationale, including why
  an earlier two-component-plus-`variant` draft was restructured to match
  the spec's explicit naming before this task completed.

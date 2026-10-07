import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX `ProgressIndicatorTokens`/`LinearProgressIndicatorTokens`/
 * `CircularProgressIndicatorTokens` values, plus sourced layout/motion
 * constants `WavyProgressIndicator.kt`, `internal/
 * LinearWavyProgressModifiers.kt`, `internal/CircularWavyProgressModifiers
 * .kt`, and `tokens/MotionTokens.kt` themselves define outside any token
 * file. Covers the pinned source's wavy `LinearWavyProgressIndicator`/
 * `CircularWavyProgressIndicator` composables — the plain treatment is the
 * separate `LinearProgress`/`CircularProgress` components per `SPEC.md`
 * §9's own component list. See ADR 0021.
 *
 * `active-indicator-color`/`track-color`/`track-shape` are the shared
 * `ProgressIndicatorTokens` values, registered independently here rather
 * than shared with `LinearProgress`/`CircularProgress`'s own copies — the
 * same "don't extract ahead of a second caller with a real divergent need"
 * discipline `NavigationBar`/`NavigationRail` (T20) already used.
 *
 * `linear-container-height` is `WaveHeight` (`10dp`, taller than the plain
 * bar's `4dp` `Height` to leave room for the wave's vertical excursion).
 * `linear-stroke-width` is `ActiveThickness`. `linear-stop-size` is
 * `StopSize`; unlike `LinearProgress`'s own copy, this bar's taller
 * container does leave visible headroom for `StopIndicatorTrailingSpace`
 * (`6px`, `ProgressIndicator.kt`'s internal constant), applied directly in
 * this component's stylesheet since it is a fixed, non-computed offset. The
 * stop dot itself reuses `active-indicator-color` directly rather than a
 * separate stop-color token — the source's own `drawStopIndicator` call
 * inside `LinearWavyProgressModifiers.kt` passes the indicator's own
 * `color` parameter, not a distinct `StopColor` token, unlike
 * `LinearProgress`'s plain `drawStopIndicator`, which does use
 * `ProgressIndicatorTokens.StopColor` — a genuine sourced difference
 * between the two files, not an inconsistency.
 *
 * `linear-determinate-wavelength`/`linear-indeterminate-wavelength` are
 * `ActiveWaveWavelength` (`40dp`)/`IndeterminateActiveWaveWavelength`
 * (`20dp`). `linear-indeterminate-cycle-duration` (`1750ms`) is
 * `ProgressIndicator.kt`'s internal `LinearAnimationDuration` — the same
 * cycle `LinearProgress`'s own indeterminate motion uses, since the wavy
 * indeterminate composable reuses the exact same
 * `linearIndeterminateFirstLineHeadAnimationSpec`-family keyframes for its
 * head/tail fractions, only adding the traveling-wave visual on top (see
 * this component's own stylesheet for the same pre-sampled keyframe
 * technique `LinearProgress` uses, and ADR 0021 for why).
 *
 * `circular-diameter` is `WaveSize` (`48dp`, larger than
 * `CircularProgress`'s own plain `Size` of `40dp`). `circular-stroke-width`
 * is `ActiveThickness`. `circular-wavelength` is `ActiveWaveWavelength`
 * (`15dp`) — one value for both determinate and indeterminate circular
 * wavy, unlike the linear shape's two. `circular-amplitude` retains the
 * generated `ActiveWaveAmplitude` (`1.6dp`) token for compatibility, though
 * the pinned implementation's actual radial outline is governed by its
 * normalized `RoundedPolygon.star(innerRadius = .75)` geometry rather than
 * reading that generated token. `wavePaths.ts` now carries the exact
 * stroke-safe circle/star Morph endpoints.
 * `circular-indeterminate-cycle-duration` (`6000ms`) is
 * `CircularAnimationProgressDuration`. The additional-rotation and
 * progress-sweep keyframe stops are expressed directly as literal CSS
 * `@keyframes` percentage stops in this component's stylesheet (structural
 * geometry, not registered as tokens), matching `CircularProgress`'s own
 * copy of this same split; `indeterminate-additional-rotation-easing`/
 * `indeterminate-sweep-easing` come from `MotionTokens.kt`'s
 * `EasingEmphasizedDecelerateCubicBezier`/`EasingStandardCubicBezier`.
 *
 * `wave-travel-duration` (`1000ms`) is shared by both shapes: it is
 * `wavelength / waveSpeed` where `waveSpeed` defaults to `wavelength` (one
 * wavelength of travel per second), which always evaluates to exactly
 * `1000ms` regardless of which wavelength is in play — true for all three
 * of this component's wavelength tokens.
 *
 * `amplitude-transition-duration`/`-easing` are `MotionTokens.DurationLong2`
 * (`500ms`)/`EasingStandardCubicBezier` for increasing amplitude;
 * `amplitude-decreasing-transition-easing` is the source's distinct
 * `EasingEmphasizedAccelerateCubicBezier` for flattening the wave.
 *
 * This is the first v1 component to use CSS `@keyframes` for continuous,
 * looping motion (every prior component only ever used `transition` on a
 * discrete state change, and `LinearProgress`/`CircularProgress`, T21's own
 * plain siblings, are the second and third) — the `*-cycle-duration`/
 * `wave-travel-duration`/`amplitude-transition-*`/easing tokens are
 * registered as this component's own string-kind values rather than reused
 * from `--m3e-sys-motion-*`, since they are fixed Material-spec constants
 * intrinsic to this component's established motion identity, not a generic
 * spatial transition a consumer's theme-level motion scheme should be able
 * to retune. Determinate value-change transitions, by contrast, are
 * ordinary discrete state changes, so they reuse
 * `--m3e-sys-motion-expressive-default-spatial-*` directly in CSS rather
 * than registering a duplicate component token for them.
 */
export const defaultWavyProgressTokens = {
  component: 'wavy-progress',
  task: 'T21',
  source: {
    id: 'androidx-material3-wavy-progress-indicator',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/WavyProgressIndicator.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-20',
  },
  tokens: {
    'active-indicator-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'track-color': { kind: 'color', value: { $ref: 'sys.color.secondaryContainer' } },
    'track-shape': { kind: 'shape', value: { $ref: 'sys.shape.corners.cornerFull' } },

    'linear-container-height': { kind: 'dimension', value: '10px' },
    'linear-stroke-width': { kind: 'dimension', value: '4px' },
    'linear-stop-size': { kind: 'dimension', value: '4px' },
    'linear-track-gap': { kind: 'dimension', value: '4px' },
    'linear-determinate-wavelength': { kind: 'dimension', value: '40px' },
    'linear-indeterminate-wavelength': { kind: 'dimension', value: '20px' },
    'linear-indeterminate-cycle-duration': { kind: 'string', value: '1750ms' },

    'circular-diameter': { kind: 'dimension', value: '48px' },
    'circular-stroke-width': { kind: 'dimension', value: '4px' },
    'circular-track-gap': { kind: 'dimension', value: '4px' },
    'circular-wavelength': { kind: 'dimension', value: '15px' },
    'circular-amplitude': { kind: 'dimension', value: '1.6px' },
    'circular-indeterminate-cycle-duration': { kind: 'string', value: '6000ms' },
    'indeterminate-additional-rotation-easing': {
      kind: 'string',
      value: 'cubic-bezier(0.05, 0.7, 0.1, 1)',
    },
    'indeterminate-sweep-easing': { kind: 'string', value: 'cubic-bezier(0.2, 0, 0, 1)' },

    'wave-travel-duration': { kind: 'string', value: '1000ms' },

    'amplitude-transition-duration': { kind: 'string', value: '500ms' },
    'amplitude-transition-easing': { kind: 'string', value: 'cubic-bezier(0.2, 0, 0, 1)' },
    'amplitude-decreasing-transition-easing': {
      kind: 'string',
      value: 'cubic-bezier(0.3, 0, 0.8, 0.15)',
    },
  },
} as const satisfies ComponentTokenRegistration

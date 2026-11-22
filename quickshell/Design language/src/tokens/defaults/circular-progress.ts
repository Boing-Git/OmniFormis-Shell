import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX `ProgressIndicatorTokens`/`CircularProgressIndicatorTokens`
 * values, plus sourced layout/motion constants `ProgressIndicator.kt`
 * itself defines outside any token file. Covers only the pinned source's
 * plain (non-wavy) `CircularProgressIndicator` composables — the wavy
 * treatment is `WavyProgress` (`shape="circular"`), a separate component
 * per `SPEC.md` §9's own component list, not a variant of this one. See
 * ADR 0021.
 *
 * `ProgressIndicatorTokens` is registered independently here rather than
 * shared with `LinearProgress`'s own copy — see that component's token
 * file for why.
 *
 * `diameter` comes from `Size` (`40dp`). `indeterminate-cycle-duration`
 * (`6000ms`) is `CircularAnimationProgressDuration`. The additional-rotation
 * keyframe stops (`90/180/270/360deg` at `300/1800/3300/4800ms`, holding
 * until `1500/3000/4500/6000ms`) and the progress-sweep keyframe stops
 * (`0.1→0.87` at `3000ms`, back to `0.1` at `6000ms`) are `ProgressIndicator
 * .kt`'s own `circularIndeterminateRotationAnimationSpec`/
 * `circularIndeterminateProgressAnimationSpec` keyframes — expressed
 * directly as literal CSS `@keyframes` percentage stops in this
 * component's stylesheet (structural geometry, not registered as tokens,
 * the same "hardcode the shape, token the reusable duration/easing" split
 * `Checkbox`'s own checkmark path-data already used). `indeterminate-
 * additional-rotation-easing`/`indeterminate-sweep-easing` come from
 * `MotionTokens.kt`'s `EasingEmphasizedDecelerateCubicBezier`/
 * `EasingStandardCubicBezier`; the global rotation and the second half of
 * the sweep both use a plain linear easing, needing no token.
 */
export const defaultCircularProgressTokens = {
  component: 'circular-progress',
  task: 'T21',
  source: {
    id: 'androidx-material3-progress-indicator',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/ProgressIndicator.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-20',
  },
  tokens: {
    'active-indicator-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'track-color': { kind: 'color', value: { $ref: 'sys.color.secondaryContainer' } },
    'active-indicator-shape': { kind: 'shape', value: { $ref: 'sys.shape.corners.cornerFull' } },
    'track-shape': { kind: 'shape', value: { $ref: 'sys.shape.corners.cornerFull' } },

    diameter: { kind: 'dimension', value: '40px' },
    'stroke-width': { kind: 'dimension', value: '4px' },
    'track-gap': { kind: 'dimension', value: '4px' },

    'indeterminate-cycle-duration': { kind: 'string', value: '6000ms' },
    'indeterminate-additional-rotation-easing': {
      kind: 'string',
      value: 'cubic-bezier(0.05, 0.7, 0.1, 1)',
    },
    'indeterminate-sweep-easing': { kind: 'string', value: 'cubic-bezier(0.2, 0, 0, 1)' },
  },
} as const satisfies ComponentTokenRegistration

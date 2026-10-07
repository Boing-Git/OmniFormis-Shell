import type { ComponentTokenRegistration } from '../schema'

/**
 * `LoadingIndicatorTokens` values, plus sourced motion constants
 * `LoadingIndicator.kt` itself defines outside any token file. Covers only
 * the pinned source's uncontained `LoadingIndicator` composables (the
 * `progress`-driven determinate one and the autonomous indeterminate one) —
 * `ContainedLoadingIndicator` (a colored-container variant) is out of
 * scope, since `SPEC.md` §9 names only `LoadingIndicator`, and the
 * uncontained composable's own `containerColor` is `Color.Unspecified`
 * (paints nothing), so `container-shape`/`container-color` tokens are not
 * registered here — there is no visible container to theme.
 *
 * `container-width`/`container-height` are `ContainerWidth`/
 * `ContainerHeight` (`48dp` each). `active-indicator-color` is
 * `ActiveIndicatorColor`. The shape geometry itself (a `RoundedPolygon`
 * corner-rounded from vertex data, then `Morph`-matched between shape
 * pairs) is not expressible as CSS custom properties — it is precomputed
 * offline and baked into `loadingIndicatorMorphs.ts` (the determinate
 * `Circle`→`SoftBurst` morph, sampled at runtime from the continuous
 * `value` prop) and `loadingIndicatorKeyframes.css` (the indeterminate
 * 7-shape loop's `d`/`transform`/`opacity` `@keyframes`, one per segment,
 * generated statically since the timeline is fixed and autonomous, not
 * prop-driven). See ADR 0022 for the full geometry/motion port.
 *
 * `indeterminate-cycle-duration` (`4550ms`) is 7 × `MorphIntervalMillis`
 * (`650ms`) — one full loop through all seven indeterminate shapes.
 * `global-rotation-duration` (`4666ms`) is `GlobalRotationDurationMillis`,
 * the continuous outer rotation composed additively with each segment's own
 * step+spring local rotation (the same nested-`<g>` composition technique
 * `CircularProgress`/`WavyProgress` already use for their own indeterminate
 * rotation layers). The per-segment spring easing itself
 * (`spring(dampingRatio=0.6, stiffness=200, visibilityThreshold=0.1)`,
 * settling in `298ms` of each `650ms` segment) is baked directly as a CSS
 * `linear()` easing function into `loadingIndicatorKeyframes.css`, using
 * the same spring→`linear()` sampling technique `src/tokens/css.ts`
 * already applies to the shared `--m3e-sys-motion-expressive-*` spring
 * tokens — not registered as a component token itself, since (unlike those
 * shared tokens) it is baked directly into the generated keyframe text, not
 * referenced live via `var()`.
 *
 * Determinate value-change transitions reuse
 * `--m3e-sys-motion-expressive-default-spatial-*` directly in CSS, matching
 * every other progress component's own convention for ordinary discrete
 * state changes.
 */
export const defaultLoadingIndicatorTokens = {
  component: 'loading-indicator',
  task: 'T22',
  source: {
    id: 'androidx-material3-loading-indicator',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/LoadingIndicator.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-20',
  },
  tokens: {
    'active-indicator-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'container-width': { kind: 'dimension', value: '48px' },
    'container-height': { kind: 'dimension', value: '48px' },

    'indeterminate-cycle-duration': { kind: 'string', value: '4550ms' },
    'global-rotation-duration': { kind: 'string', value: '4666ms' },
  },
} as const satisfies ComponentTokenRegistration

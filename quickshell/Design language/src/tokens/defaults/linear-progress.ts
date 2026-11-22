import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX `ProgressIndicatorTokens`/`LinearProgressIndicatorTokens`
 * values, plus sourced layout constants `ProgressIndicator.kt` itself
 * defines outside any token file. Covers only the pinned source's plain
 * (non-wavy) `LinearProgressIndicator` composables — the wavy treatment is
 * `WavyProgress` (`shape="linear"`), a separate component per `SPEC.md`
 * §9's own component list, not a variant of this one. See ADR 0021.
 *
 * `ProgressIndicatorTokens` (`ActiveIndicatorColor`/`TrackColor`/
 * `ActiveShape`/`TrackShape`/`StopColor`/`StopShape`) is shared between
 * `LinearProgress` and `CircularProgress`, so both components register the
 * same values independently rather than through a third shared token file
 * — the same "don't extract ahead of a second caller with a real divergent
 * need" discipline `NavigationBar`/`NavigationRail` (T20) already used for
 * their own duplicated item visual language.
 *
 * `container-height`/`stroke-width`/`track-thickness` all come from
 * `Height`/`ActiveThickness`/`TrackThickness`, which are all `4dp` in the
 * pinned source — registered as separate tokens since they mean different
 * things (a flat bar's total height vs. its stroke width) even though they
 * share a value today.
 *
 * `stop-trailing-space` (`6px`) is `ProgressIndicator.kt`'s own internal
 * `StopIndicatorTrailingSpace` constant, not the *token* file's
 * `StopTrailingSpace` (`0dp`) — the token is defined but never actually
 * read by `drawStopIndicator`, which uses the hardcoded `6.dp` instead; this
 * project surfaces the value that actually renders, the same "prefer the
 * value the code actually uses over an unread token" reasoning `Tabs`' own
 * `divider-color` registration already used. Since this bar's own height
 * (`4px`) already equals the stop dot's size, no trailing-space offset is
 * actually visible here in practice (see `WavyProgress`'s own copy of this
 * token, where the taller wavy container does leave headroom for it).
 */
export const defaultLinearProgressTokens = {
  component: 'linear-progress',
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
    'stop-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'stop-shape': { kind: 'shape', value: { $ref: 'sys.shape.corners.cornerFull' } },

    'container-height': { kind: 'dimension', value: '4px' },
    'stroke-width': { kind: 'dimension', value: '4px' },
    'track-thickness': { kind: 'dimension', value: '4px' },
    'stop-size': { kind: 'dimension', value: '4px' },
    'track-gap': { kind: 'dimension', value: '4px' },

    'indeterminate-cycle-duration': { kind: 'string', value: '1750ms' },
  },
} as const satisfies ComponentTokenRegistration

import type { ComponentTokenRegistration } from '../schema'

/**
 * `ButtonGroupSmallTokens` values, plus a documented CSS-transform
 * approximation of the source's press-triggered neighbor-compression
 * interaction. Only the source's *standard* (non-connected) `ButtonGroup`
 * treatment is covered — `ConnectedButtonGroup`'s asymmetric pill/
 * small-radius shape variant is out of scope; `SegmentedButtonGroup`
 * (T15) already serves the connected single/multi-select row use case.
 * See ADR 0023.
 *
 * The source only ever defines a `Small` token set for `ButtonGroup`
 * (unlike `SplitButton`, which defines all five sizes) — `children` are
 * expected to be already-sized `Button`/`IconButton` elements, so
 * `ButtonGroup` itself owns only the shared row gap and the compression
 * interaction, not a size scale of its own.
 *
 * `between-space` is `BetweenSpace` (`12dp`). `pressed-scale`/
 * `neighbor-scale` are this project's own CSS-transform values
 * approximating the source's `ExpandedRatio` (`0.15`, a 15% width growth
 * on press, propagated to compress neighbors) — a real reflow isn't
 * practical in pure CSS for a content-sized row (there is no free space
 * for `flex-grow` to redistribute against), so this project instead
 * scales the pressed child up and its immediate siblings down, reusing
 * `MotionSchemeKeyTokens.FastSpatial` (the same spec the source's own
 * `pressedAnimatable` uses) as the transition.
 */
export const defaultButtonGroupTokens = {
  component: 'button-group',
  task: 'T23',
  source: {
    id: 'androidx-material3-button-group',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/ButtonGroup.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-20',
  },
  tokens: {
    'between-space': { kind: 'dimension', value: '12px' },
    'pressed-scale': { kind: 'string', value: '1.08' },
    'neighbor-scale': { kind: 'string', value: '0.94' },
  },
} as const satisfies ComponentTokenRegistration

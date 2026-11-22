# ButtonGroup conformance

Task: T23
Status: conformant
Reviewed: 2026-07-20

## Primary references

- Material Design button groups component guide, accessed 2026-07-20:
  <https://m3.material.io/components/button-groups/overview>
- Pinned current AndroidX `ButtonGroup.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/ButtonGroup.kt>
- Pinned generated AndroidX `ButtonGroupSmallTokens`/
  `ConnectedButtonGroupSmallTokens`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/ButtonGroupSmallTokens.kt>
- WAI-ARIA APG group/toolbar guidance, accessed 2026-07-20:
  <https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`.

## Anatomy and content

- One public component: a `role="group"` row (overridable, e.g. to
  `toolbar`) wrapping consumer-provided `children` — typically
  `Button`/`IconButton` elements — with the sourced `BetweenSpace` gap.

## Variants, shape, color, and size

- No component-owned color or size scale — children carry their own
  variant/size, exactly as the source expects callers to size their own
  button-group items.
- Only the source's *standard* (non-connected) treatment is covered. The
  "connected" asymmetric pill/small-radius-middle variant is out of
  scope for this task — `SegmentedButtonGroup` (T15) already serves the
  connected single/multi-select row use case. See ADR 0023.

## States and motion

- Pressing a child grows it and compresses its immediate siblings via a
  CSS `transform: scale()` pair reading each child's own native `:active`
  state (`:has()`-based sibling selectors), transitioning on
  `--m3e-sys-motion-expressive-fast-spatial-*` — the same
  `MotionSchemeKeyTokens.FastSpatial` spec the source's own
  `pressedAnimatable` uses.

## Accessibility

- `role="group"` by default (overridable); `aria-label`/`aria-labelledby`
  provide the group's own accessible name. Every child remains
  independently focusable via native tab order — `ButtonGroup` adds no
  roving-tabindex or other custom keyboard model.

## Web-specific deviations

- **Plain `children`, not the source's `ButtonGroupScope` DSL.** The
  source's `clickableItem`/`toggleableItem`/`customItem` builder and
  `Modifier.weight`/`Modifier.animateWidth` scope functions have no React
  equivalent (they rely on Compose's `Modifier` chaining); ordinary React
  children are the idiomatic translation, matching every other layout
  composite.
- **No automatic overflow-into-a-dropdown-menu.** The source's overflow
  behavior needs either a `ResizeObserver`-driven client-only measurement
  effect or a reimplementation of its custom intrinsic-width
  `MeasurePolicy`. Out of scope for this task; consumers needing overflow
  can use `flex-wrap` or their own responsive logic. See ADR 0023.
- **Press-compression is a CSS `transform: scale()` pair, not a real
  reflow.** The source measures each child's actual width and shrinks/
  grows the underlying layout box. A content-sized flex row has no free
  space for `flex-grow` to redistribute against, so a literal
  reflow-based port isn't practical in pure CSS; this project instead
  reads native `:active` state via `:has()` and applies a visual scale
  transform — a documented technique substitution, not a literal port of
  the measured-width interaction.
- No component-owned forced-colors styling: `ButtonGroup` renders no
  visible fill of its own (only `display`/`gap`/`transform`), so there is
  nothing here for forced-colors mode to override — children handle their
  own forced-colors contrast independently.

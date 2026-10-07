# SplitButton conformance

Task: T23
Status: conformant
Reviewed: 2026-07-20

## Primary references

- Material Design split button component guide, accessed 2026-07-20:
  <https://m3.material.io/components/split-buttons/overview>
- Pinned current AndroidX `SplitButton.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/SplitButton.kt>
- Pinned generated AndroidX `SplitButtonXSmallTokens` through
  `SplitButtonXLargeTokens`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/SplitButtonSmallTokens.kt>
- WAI-ARIA APG button guidance, accessed 2026-07-20:
  <https://www.w3.org/WAI/ARIA/apg/patterns/button/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`.

## Anatomy and content

- One public component: a leading action button (`children` label,
  optional `leadingIcon`, `onClick`) and a trailing icon-only toggle
  button (`trailingIcon`, required `trailingLabel` accessible name,
  `selected`/`defaultSelected`/`onSelectedChange`), laid out in a row with
  the sourced `BetweenSpace` gap.

## Variants, shape, color, and size

- Four variants (`filled`, `tonal`, `elevated`, `outlined`), matching the
  source's `LeadingButton`/`TonalLeadingButton`/`ElevatedLeadingButton`/
  `OutlinedLeadingButton` family — no `text` variant, matching the source
  (a text-only split button isn't offered).
- Five sizes (`extra-small`, `small`, `medium`, `large`, `extra-large`),
  matching `SplitButtonXSmallTokens` through `SplitButtonXLargeTokens`.
- The leading button's trailing corners and the trailing button's leading
  corners share a small "inner corner" radius that visibly *expands* on
  hover/press (the opposite of `Button`'s own round-to-square press morph
  — a genuine source behavior, not a bug). The trailing button becomes a
  full circle while `selected`.

## States and motion

- Hover/press state layers and shape transitions on
  `--m3e-sys-motion-expressive-default-effects-*`, matching `Button`'s own
  motion convention. The trailing toggle's `aria-pressed`/shape update
  synchronously with `selected`.

## Accessibility

- The leading button's accessible name comes from its own visible label
  (`children`), matching a native `<button>`. The trailing button is
  icon-only and requires `trailingLabel` for its accessible name, exposed
  as `aria-pressed` (not a custom attribute alone) reflecting its toggle
  state. Both buttons are independently focusable via native tab order.

## Web-specific deviations

- **Renders its own two `<button>` elements directly**, not by nesting
  the public `Button`/`IconButton` components — the same "composite
  components own their internal buttons" precedent `SegmentedButtonGroup`
  (T15) already established, avoiding CSS specificity/import-order
  coupling to another component's internal custom-property names. See
  ADR 0023.
- **`leading-icon-size` is not sourced from `SplitButtonDefaults
  .LeadingIconSize`** (a single fixed value for every size in the pinned
  source, seemingly an oversight since every other leading-button
  dimension scales per size) — this project instead reuses `Button`'s own
  already-established per-size icon scale for consistency, a small,
  deliberate, documented deviation.
- **The trailing button is always a toggle** (unlike the source, where
  `TrailingButton`/`UncheckableTrailingButton` are separate composables) —
  wiring `selected`/`onSelectedChange` to an actual menu (e.g. this
  project's own `Menu`, T17) is left to the consumer, the same
  "expose the toggle state, don't own the overlay" scoping `IconButton`
  itself already uses. A non-toggling trailing button is simply a
  `SplitButton` whose consumer never reads `selected`.
- **A single `disabled` prop disables both buttons together** — the
  source allows independently disabling each button since they are
  separate composables; this project's flat prop surface covers the
  overwhelmingly common case (the whole control is or isn't available)
  and omits the rarer independent-disable case as a documented scope cut.

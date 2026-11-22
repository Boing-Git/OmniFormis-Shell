# ADR 0023: `ButtonGroup` reads press state with CSS `:has()` instead of measuring layout, and `SplitButton` renders its own buttons instead of nesting `Button`/`IconButton`

Status: accepted
Date: 2026-07-20
Task: T23

## Context

The pinned AndroidX revision (`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`)
implements `ButtonGroup.kt` and `SplitButton.kt`, matching `docs/SPEC.md`
§9's "Actions and containment" list and the matching `docs/component-
inventory.json` placeholder rows.

`ButtonGroup` is a `ButtonGroupScope.clickableItem`/`toggleableItem`/
`customItem` DSL wrapped around a custom `MultiContentMeasurePolicy` that:
reads each child's `Animatable` press state (via a `Modifier.animateWidth`-
attached `InteractionSource`), grows the pressed child's *measured width*
by up to `ExpandedRatio` (`0.15`) and shrinks its neighbors' widths to
compensate, and separately overflows excess children into a `DropdownMenu`
once they no longer fit the available width (using `maxIntrinsicWidth`
measurement). A separate "connected" treatment uses asymmetric pill/
small-radius shapes with a checked-state circle morph.

`SplitButton` is a two-slot `Layout` (`leadingButton`, `trailingButton`)
with a custom `measurePolicy` that measures the trailing button's
intrinsic width first, then gives the leading button the remainder.
`SplitButtonDefaults` provides five size tiers (`SplitButtonXSmallTokens`
through `SplitButtonXLargeTokens`), each with sourced content padding,
icon sizes, and two "inner corner" radii — a resting value and a larger
hover/pressed value (the corners *expand* toward each other, the opposite
of `Button`'s own round-to-square press morph).

## Decisions

1. **`ButtonGroup` takes plain React `children`, not a scope-DSL.** A
   Kotlin `Modifier`-chaining scope builder (`Modifier.weight`,
   `Modifier.animateWidth`) has no React equivalent; ordinary children are
   the idiomatic translation, matching how every other v1 layout
   composite works.

2. **Press-triggered neighbor compression is read with CSS `:has()`
   sibling selectors and expressed as a `transform: scale()` pair, not a
   measured layout reflow.** The source genuinely changes each child's
   *measured width* (reading a per-child `Animatable` driven by that
   child's own `InteractionSource`). A CSS port needs some way to know
   "is my sibling currently pressed" without JavaScript — `:has()`
   (`.m3e-button-group > *:has(+ *:active)` for "the sibling before a
   pressed one", `.m3e-button-group > *:active + *` for "the sibling
   after") does exactly this, natively, with no measurement or
   `ResizeObserver`. It's supported at this project's browser floor
   (Chrome 105+, Firefox 121+ — exactly the floor — Safari 15.4+, all
   below this project's stated minimums). A true width-based reflow isn't
   practical to reproduce this way, though: a content-sized flex row (no
   `flex-grow`/`flex-shrink` slack by default) has no free space for
   `flex-grow` to redistribute against, so "grow beyond content size,
   shrink below it" can't be expressed as a flex-grow ratio change. This
   project instead scales the pressed child up and its immediate
   siblings down as a *visual* transform — a documented technique
   substitution that keeps the "something reacts near your press" feeling
   without needing a JS layout engine.

3. **No automatic overflow-into-a-dropdown-menu.** The source's
   `ButtonGroupOverflowState`/intrinsic-width `MeasurePolicy` combination
   needs either a client-only `ResizeObserver` measurement effect or a
   from-scratch reimplementation of that measure policy in JS — a large
   scope addition for a single task that also covers `SplitButton`, with
   T24 immediately following. Consumers who need overflow can use CSS
   `flex-wrap` or their own responsive logic.

4. **No "connected" button-group shape variant.** The source's asymmetric
   pill-leading/small-radius-middle/pill-trailing row (with a checked-
   state circle morph) targets the same single/multi-select connected-row
   use case `SegmentedButtonGroup` (T15) already serves in this project.
   Building a second, separately-shaped implementation of essentially the
   same interaction pattern — one that would also need deep coupling into
   arbitrary children's internal shape CSS, since `ButtonGroup`'s
   `children` could be anything — isn't a good use of this task's scope.
   `ButtonGroup` here covers only the source's *standard* treatment.

5. **`SplitButton` renders its own two `<button>` elements directly**,
   not by composing the public `Button`/`IconButton` React components.
   `Button`'s own shape-morph mechanism lives on internal custom
   properties (`--m3e-button-container-shape`, set per size via
   `[data-m3e-size]` selectors); overriding those from outside to get
   `SplitButton`'s asymmetric pill shapes would need either fragile
   equal-specificity import-order dependence or an artificially inflated
   selector just to win the cascade. Rendering its own markup avoids the
   coupling entirely and matches the "composite components own their
   internal buttons" precedent `SegmentedButtonGroup` (T15) already
   established for exactly this kind of composite-button scenario.

6. **`SplitButton` supports the full five-size scale**
   (`extra-small`/`small`/`medium`/`large`/`extra-large`), matching
   `Button`/`IconButton`'s own established size system from T07/T08. The
   source itself defines all five `SplitButtonXSmallTokens` through
   `SplitButtonXLargeTokens` (unlike `ButtonGroup`, which the source only
   ever defines a `Small` token set for) — every other action component in
   this project commits to this scale, so `SplitButton` does too.

7. **`leading-icon-size` deviates from the sourced
   `SplitButtonDefaults.LeadingIconSize`.** The source hard-codes this to
   a single fixed value (`ButtonSmallTokens.IconSize`) for every
   `SplitButton` size tier — every *other* leading-button dimension in
   `SplitButtonDefaults` (content padding, container height) scales per
   tier, making this one fixed value read as a likely oversight rather
   than an intentional design choice. This project instead reuses
   `Button`'s own already-established per-size icon scale (T07), which
   scales consistently the way every sibling dimension already does.

8. **The trailing button is always a toggle**, unlike the source's
   separate `TrailingButton`/`UncheckableTrailingButton` composables — a
   `SplitButton` whose consumer never reads `selected` is functionally
   identical to an "uncheckable" trailing button, so a single prop surface
   covers both cases without a boolean mode switch. Wiring the toggle to
   an actual menu is left to the consumer, the same "expose the toggle
   state, don't own the overlay" scoping `IconButton` itself already uses.

9. **A single `disabled` prop disables both buttons together**, rather
   than the source's two independently-disableable composables. The
   overwhelmingly common case is "the whole control is or isn't
   available"; independent disabling is a documented, minor scope cut.

## Consequences

- `ButtonGroup`'s press-compression is the first v1 interaction driven
  entirely by a `:has()` selector rather than a `:active`/`:focus`
  pseudo-class alone or a JS-tracked state — worth watching if this
  project's browser-support floor is ever raised further, since `:has()`
  support is exactly at today's floor for Firefox.
- Both components register their own copies of `Button`'s variant color
  tokens rather than sharing a single source of truth — the established
  duplication-over-premature-extraction precedent `WavyProgress`/
  `CircularProgress` (T21) already used for `ProgressIndicatorTokens`.
- Bundle budgets were raised to accommodate two new components' full CSS
  (`SplitButton`'s five-size, four-variant matrix in particular),
  following the established proportional-raise precedent, if measured
  output justified it.

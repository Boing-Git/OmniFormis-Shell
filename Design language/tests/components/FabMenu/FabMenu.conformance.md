# FabMenu conformance

Task: T24
Status: conformant
Reviewed: 2026-07-20

## Primary references

- Material Design FAB menu component guide, accessed 2026-07-20:
  <https://m3.material.io/components/fab/overview>
- Pinned current AndroidX `FloatingActionButtonMenu.kt`, accessed
  2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/FloatingActionButtonMenu.kt>
- Pinned generated AndroidX `FabBaselineTokens`/`FabMenuBaselineTokens`,
  accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/FabMenuBaselineTokens.kt>
- WAI-ARIA APG disclosure pattern guidance, accessed 2026-07-20:
  <https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`.

## Anatomy and content

- Two public components: `FabMenu` (`triggerLabel`, `icon`, `closeIcon`,
  `expanded`/`defaultExpanded`/`onExpandedChange`, `children`) renders its
  own trigger FAB and positions `FabMenuItem` children in a column above
  it; `FabMenuItem` (`icon`, `children` as its label, `onClick`,
  `disabled`) is a pill-shaped row button.

## Variants, shape, color, and size

- Trigger: `56×56dp` fixed size at both states (see Web-specific
  deviations). Collapsed: `CornerLarge` (`16dp`) shape,
  `primaryContainer`/`onPrimaryContainer`, `24dp` icon. Expanded:
  `CornerFull` shape, `primary`/`onPrimary`, `20dp` icon.
- Items: `56dp` height, fully round shape, `primaryContainer`/
  `onPrimaryContainer`, `24dp` icon, `24dp` leading/trailing padding,
  `8dp` icon-label gap.

## States and motion

- The trigger's shape/color/icon-size transition on
  `--m3e-sys-motion-expressive-fast-spatial-*` (matching the source's
  `MotionSchemeKeyTokens.FastSpatial` for the checked-progress
  animation). Items reveal with a staggered fade+scale, the item closest
  to the trigger animating first (`transition-delay` computed per item,
  matching the source's own bottom-up stagger direction, sourced from
  `MotionSchemeKeyTokens.SlowEffects` for the item-count stagger and
  `FastSpatial`/`FastEffects` for each item's own width/alpha).

## Accessibility

- The trigger exposes `aria-expanded`, `aria-haspopup="true"`, and
  `aria-controls` pointing at the items container — the WAI-ARIA APG
  disclosure pattern, matching this component's actual interaction model
  (a button revealing more buttons) rather than the `menu`/`menuitem`
  pattern (which implies arrow-key roving navigation the source itself
  doesn't implement for the item list). Collapsed items are marked
  `inert`, removing them from both the accessibility tree and tab order
  while preserving them in the DOM for the reveal transition. `ArrowDown`
  (or `Tab`) from a focused, expanded trigger moves focus to the first
  item, matching the source's own `FocusRequester` behavior.

## Web-specific deviations

- **Renders its own trigger FAB directly** rather than requiring a
  separately-composed toggle FAB — the inventory placeholder names only
  `FabMenu`/`FabMenuProps`, no second public toggle-FAB export.
- **The trigger's size never changes.** Reading the actual sourced token
  values (`FabBaselineTokens.ContainerHeight` and `FabMenuBaselineTokens
  .CloseButtonContainerHeight` are both `56dp`), only shape, color, and
  icon size morph — not the width/height interpolation the source's
  generic `containerSize: (Float) -> Dp` callback API suggests it might
  need. `trigger-shape-collapsed` (`16dp`, `CornerLarge`) is sourced from
  `FloatingActionButtonMenu.kt`'s own internal `FabInitialCornerRadius`
  constant, since the pinned source hasn't yet promoted it to a generated
  token file.
- **`icon`/`closeIcon` are both required props**, cross-faded by this
  component via CSS opacity — the source instead exposes a generic
  `Modifier.animateIcon` the caller must apply to their own conditionally
  swapped icon composable.
- **Uses `inert` (a standard HTML global attribute) to hide collapsed
  items**, rather than removing them from the DOM outright — this keeps
  the reveal transition working (a removed-and-re-added element can't
  transition) while fully removing them from keyboard and assistive
  technology navigation, a more direct web-native equivalent to the
  source's `SemanticsModifierNode.shouldClearDescendantSemantics`
  (semantics only) combined with its width-collapse-to-zero (removes
  hit-testing and tab stops via zero size) than either alone would be.

## T29 repair — item elevation was clipped to a rectangle

`.m3e-fab-menu__item-slot` set `overflow: hidden`. The slot is exactly the size
of the item it wraps, and the item carries
`--m3e-comp-fab-menu-item-elevation`, which paints outside its border box, so
the clip removed everything but the shadow's four corners: a fully rounded item
rendered with a hard square halo. Nothing in jsdom can observe this, so every
existing gate passed while it shipped.

The clip served no purpose. The staged reveal is `scaleY` plus `opacity` on the
slot itself and the item scales with it, so removing the declaration leaves the
animation untouched. Verified after the repair: the reveal is still staged
closest-to-trigger first, it is immediate under
`prefers-reduced-motion: reduce`, it still stages under
`forced-colors: active`, and collapse returns every slot to opacity 0 in all
three.

`FabMenu.css.test.ts` now asserts the slot declares no clipping overflow, and
`scripts/audit-rendering.mjs` catches the general class — a shadowed child cut
by an ancestor that has no shape of its own — in a real browser.

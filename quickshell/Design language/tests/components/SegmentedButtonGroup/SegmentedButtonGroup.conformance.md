# SegmentedButtonGroup conformance

Task: T15
Status: conformant
Reviewed: 2026-07-20

## Primary references

- AndroidX Material 3 Segmented buttons component guide, accessed 2026-07-20:
  <https://m3.material.io/components/segmented-buttons/overview>
- Pinned current AndroidX `SegmentedButton.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/SegmentedButton.kt>
- Pinned generated AndroidX `OutlinedSegmentedButtonTokens`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/OutlinedSegmentedButtonTokens.kt>
- Pinned `androidx.compose.material3.internal.Icons.Filled.Check` vector data,
  accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/internal/Icons.kt>
- WAI-ARIA APG radio group pattern, accessed 2026-07-20:
  <https://www.w3.org/WAI/ARIA/apg/patterns/radio/>
- WCAG 2.2 focus visible, target size, and reduced motion, accessed 2026-07-20:
  <https://www.w3.org/TR/WCAG22/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`. `SegmentedButton.kt` blob
`295bc3889b25193473d4e4670b98c1d33aaa2663`, `OutlinedSegmentedButtonTokens.kt`
blob `2530ef60381d2ab54edb097c1a35dcc97d6c391c` at `VERSION: v0_162`, adapted
to native `<input type="radio">`/`<input type="checkbox">` controls wrapped in
native `<label>`s.

## Anatomy and content

- One group root (`role="radiogroup"` single-choice, `role="group"`
  multi-choice) owns the resolved disabled attribute, the consumer class and
  style, and the forwarded ref.
- One native `<label>` per segment wraps one native `<input>` (`radio` or
  `checkbox`), an icon slot, and the segment's visible label text — the
  label text is the control's accessible name, with no separate `id`
  plumbing.
- An optional per-segment icon slot that always also contains the built-in
  checkmark glyph, the two crossfading or one revealing over the other
  depending on whether an icon was supplied.
- Content, selection, and count are entirely declared through one
  `segments` array prop — there is no children-based composition, since the
  pinned source's two row composables exist only to compute per-item
  shape/semantics from index, count, and selection, which an array
  computes directly with no `Children.map`/context indirection.

## Variants, shape, color, and size

- `multiple` (default `false`) selects single-choice (native radio group,
  mutually exclusive, matching the pinned source's own `Role.RadioButton`
  choice) or multi-choice (independent native checkboxes) — the direct web
  equivalent of `SingleChoiceSegmentedButtonRow`/`MultiChoiceSegmentedButtonRow`.
- Geometry: 40×58px minimum segment size (the pinned source applies no
  `minimumInteractiveComponentSize`-equivalent modifier here, unlike
  Checkbox/Radio/Switch, so no touch-target inflation is added), 1px border,
  18px icon, 8px icon-content gap, 12px/8px inline/block content padding.
- Shape: the first segment rounds only its inline-start corners, the last
  rounds only its inline-end corners, interior segments stay square, and a
  lone segment is fully rounded, using the four logical corner-radius
  properties — the web equivalent of `SegmentedButtonDefaults.itemShape`'s
  `baseShape.start()`/`.end()`/`RectangleShape`/`baseShape` branches.
- `defaultSegmentedButtonColors()` reads the exact same `OutlineColor`
  constant for both the active and inactive border, and the exact same
  `DisabledLabelTextColor`/`DisabledLabelTextOpacity` for both the disabled
  active and disabled inactive content color, so each is registered once
  here instead of as an active/inactive pair, matching the T14
  content-color consolidation precedent.
- The disabled active container color reuses the enabled
  `SelectedContainerColor` undimmed, and the disabled inactive container
  stays the same `Color.Transparent` literal as the enabled inactive
  container — the token file defines no disabled container role at all, so
  a disabled selected segment keeps its full tonal fill.
- Every `Hover*`/`Focus*`/`Pressed*`-suffixed role, and even the base
  `SelectedIconColor`/`UnselectedIconColor`/`DisabledIconColor`/
  `DisabledIconOpacity` roles, are unread: `SegmentedButtonContent` never
  tints its `Icon` explicitly, so the icon always inherits the same
  `LocalContentColor` the label text resolves, extending the unread-role
  precedent from every prior selection control to roles the source defines
  but never connects to any resolution path at all.

## States and motion

- Enabled, disabled (group-level or per-segment), checked/unchecked, hover,
  press, and keyboard focus are implemented. There is no error state in
  this component's contract.
- Checked, hover, press, and focus visuals are all read from the native
  input's own pseudo-classes (`:checked`, `:hover`, `:active`,
  `:focus-visible`, reached from the wrapping label through `:has()`), not
  a React-rendered attribute, so a native radio-group side effect (the
  browser unchecking a sibling with no change event on that sibling)
  cannot desync the visuals, the same native-truth precedent ADR 0012
  established for Radio.
- Stacking order is the ordinal flattening of the pinned source's
  `interactionCount + (checked ? CheckedZIndexFactor : 0)` z-index: a
  checked segment always outranks a merely-interacting neighbor, and a
  checked, interacting segment outranks both, preserving the same relative
  ranking with a small fixed scale instead of literally counting
  interactions.
- A segment without a supplied `icon` shows only a checkmark, entering with
  a fade+scale transition from its inline-start/block-end origin and
  disappearing with no exit transition, matching
  `AnimatedVisibility(exit = ExitTransition.None)` exactly. A segment with
  a supplied `icon` shows a constant-width icon column whose content
  crossfades symmetrically between the icon and the checkmark, matching
  `Crossfade`.
- The sourced `Animatable<Int>`-driven horizontal content recentering when
  the icon column's width changes is reproduced as a CSS width/margin
  transition inside a centered flex row, not a ported measure policy,
  consistent with every prior spring-to-CSS-transition flattening in this
  library.
- Reduced motion removes every transition and preserves the resolved state
  immediately.

## Component token mapping

- Shared: container height, minimum width, container shape, border width,
  icon size, icon spacing, content padding (inline/block), focus-ring
  width/offset/color.
- Color: active container/content, inactive content (the inactive
  container is the sourced `Color.Transparent` literal, expressed directly
  in the stylesheet rather than registered), border, disabled content
  color/opacity, disabled border opacity.

All values live in the T15 `segmented-button-group` registration. Production
CSS validation requires every literal `--m3e-comp-segmented-button-group-*`
reference to resolve.

## DOM, forms, and behavior

- Rendered DOM: `<div role="radiogroup"|"group">` wrapping one
  `<label class="m3e-segmented-button" data-m3e-position data-m3e-disabled>`
  per segment, each containing the native control first (required so every
  sibling can read its pseudo-class state through a plain CSS combinator),
  then the icon slot, then the label text.
- `disabled` is the only state mirrored onto a segment root as a
  `data-m3e-*` attribute: it is fully determined by props on every render
  (group-level `disabled` or a segment's own `disabled`), so nothing
  outside this component instance can change it without a re-render,
  unlike Radio's checked state.
- Single-choice mode renders one native radio per segment sharing one
  `name` (auto-generated with `useId()` when the caller supplies none),
  giving native mutual exclusivity and roving-tabindex keyboard behavior
  with no custom keyboard handling. Multi-choice mode renders independent
  checkboxes sharing one `name` so `FormData.getAll(name)` yields every
  checked value natively.
- Each input is `checked`-controlled when the group's own `value` prop is
  set, or `defaultChecked`-uncontrolled otherwise — matching Radio's own
  per-item pattern — so an uncontrolled single-choice group's native
  radio-group exclusivity is entirely browser-owned once mounted.
- A native form reset restores every input's own `defaultChecked` with no
  React update; an uncontrolled group's own `value` state resynchronizes
  from the same `reset` event, matching the Radio/Checkbox reset precedent
  (this is about the JS-level `value`/`onValueChange` state staying
  accurate, not the visuals, which are native-truth-driven either way).
- Server markup and hydration are deterministic and inject no styles.

## Accessible name, description, role, state, and keyboard

- The group root carries `role="radiogroup"` (single-choice) or
  `role="group"` (multi-choice); its accessible name comes from a
  caller-supplied `aria-label`/`aria-labelledby`.
- Each segment's accessible name is its own native `<label>` text, with no
  extra `id` plumbing.
- Single-choice keyboard behavior — one tab stop reaching the checked (or
  first) radio, arrow keys roving selection among siblings — is entirely
  native `<input type="radio">` grouping behavior; no key handler is added.
  Multi-choice checkboxes reach sequential focus independently, matching
  native checkbox behavior.
- Disabled segments leave sequential focus; a fully disabled group leaves
  sequential focus entirely.

## Bidirectional, forced-color, and adaptive behavior

- Shape and stacking use logical corner-radius and margin properties
  throughout, so the rounded/square corner assignment and the
  overlap-toward-the-next-segment direction both mirror correctly in RTL.
- Forced colors keeps the segment boundary, uses Highlight/HighlightText for
  the checked segment and the focus ring, and GrayText for disabled
  treatment.
- Default, custom, and nested themes scope every SegmentedButtonGroup
  variable.

## Web-specific deviations

- The pinned source's two composables
  (`SingleChoiceSegmentedButtonRow`/`MultiChoiceSegmentedButtonRow` plus a
  child-scope `SegmentedButton`) are reproduced as one data-driven
  component instead of a compound children API: an index/count computed
  from one `segments` array is the direct equivalent of what those row
  composables compute for their children, with no `Children.map`/context
  machinery needed, and it matches the single export already named in the
  component inventory.
- The pinned source's `interactionCount + (checked ? CheckedZIndexFactor :
  0)` numeric z-index is flattened to a small ordinal scale (0/1/2/3)
  driven by `:has(:checked)`/`:hover`/`:active`/`:has(:focus-visible)`
  instead of literally counting simultaneous interactions; the same
  relative ranking is preserved.
- The checkmark reproduces
  `androidx.compose.material3.internal.Icons.Filled.Check` as a static
  inline SVG path — a solid filled glyph, not the Checkbox stroke-draw
  polyline technique, matching what the pinned source itself paints here.
- The sourced `Animatable<Int>`-driven horizontal content recentering when
  the icon column's width changes is reproduced as a CSS width/margin
  transition inside a centered flex row instead of a ported measure
  policy, consistent with every other spring/measure-policy flattening in
  this library.
- Prefix-only icon layouts, a segment count/overflow policy, and the
  Expressive `roundedShape`/tonal-color provisional additions (marked
  `TODO(b/448727879)` in the pinned source itself, with no shipped token
  yet — the same exclusion basis as T14) are not claimed.

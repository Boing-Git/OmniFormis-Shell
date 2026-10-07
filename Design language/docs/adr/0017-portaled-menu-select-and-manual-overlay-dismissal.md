# ADR 0017: Portaled Menu/Select, manual overlay positioning and dismissal, and TextField/Menu token reuse

Status: accepted
Date: 2026-07-20
Task: T17

## Context

The pinned AndroidX revision (`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`)
implements menus across `Menu.kt` (`DropdownMenu`/`DropdownMenuItem`, an
`androidx.compose.ui.window.Popup` positioned by
`DropdownMenuPositionProvider` — start-of-anchor then end-of-anchor then the
window edge horizontally, below-anchor then above-anchor then the window
edge vertically) and `ExposedDropdownMenu.kt` (`ExposedDropdownMenuBox`,
which composes a real `TextField`/`OutlinedTextField` plus that same
`DropdownMenu` machinery width-matched to the field). `MenuTokens`,
`ListTokens`, and `StandardMenuTokens` supply container/item color, shape,
and elevation; `MenuDefaults` supplies the `112`–`280px` intrinsic width
bounds, `48px` item height, `8px` item padding, and the `0.8`→`1` scale plus
alpha entrance/exit animation on `FastSpatial`/`FastEffects`. A newer
Expressive layer (`DropdownMenuGroup`, `MenuGroupShapes`, `SegmentedMenuTokens`,
cascading menus, drag-select) adds per-item hover/press shape morphing and
grouped/segmented menus — gesture- and composition-heavy machinery with no
clean web equivalent and no accompanying gesture surface in this port.

The component inventory names two tasks' worth of exports here: `Menu`/
`MenuProps` (kind `overlay`) and `Select`/`SelectProps` (kind `input`).
Neither native web primitive available across this library's browser floor
(Chrome 120, Edge 120, Firefox 121, Safari/iOS 17.2) can host either: the
Popover API reaches Firefox only at 125, and CSS anchor positioning is
further out still, both postdating the floor as load-bearing requirements
(unlike `@starting-style` in ADR 0016, which was safe specifically because
it was a pure progressive enhancement on top of otherwise-complete native
`<dialog>` behavior — positioning and dismissal here have no such native
fallback to degrade to). No native `<select>` element can host Material's
opinionated option rows either, for the same styling-surface reason.

## Decision

1. Two public, data-driven components replace the pinned source's
   children-composable APIs: `Menu` takes `items: readonly MenuItem[]`
   (`{ value, label, onSelect?, leadingIcon?, trailingIcon?, disabled?,
   checked?, onCheckedChange? }`) and `Select` takes `options: readonly
   SelectOption[]` (`{ value, label: string, disabled? }`), extending the
   T15 SegmentedButtonGroup data-array precedent to two more components and
   matching the inventory's named exports plus one added data type each
   (`MenuItem`, `SelectOption`), the same shape T15 added
   `SegmentedButtonGroupSegment`. `SelectOption.label` is narrower than
   `MenuItem.label` (`string`, not `ReactNode`) because it serves double
   duty as the trigger's own displayed input value, the same constraint a
   native `<select>`'s `<option>` text already has.
2. A new, non-exported `src/internal` pair — `overlayPosition.ts` (a pure
   function reproducing `DropdownMenuPositionProvider`'s own start/end/clamp
   and below/above/clamp behavior) and `useAnchoredOverlay.ts` (portal
   mount lifecycle, live repositioning, outside-click/Escape dismissal, and
   deferred-unmount exit animation) — is shared by `Menu` and `Select`'s
   popup. This is genuinely new v1 infrastructure: Dialog needed none of it,
   since native `<dialog>` supplies top-layer promotion, a backdrop, and
   closing-step focus restoration for free. Neither is available here, so
   the library owns all of it explicitly for the first time.
3. The viewport clamp margin (`8px`) reuses the pinned source's own
   `MenuHorizontalMargin` on both axes rather than inventing a web-specific
   number. Android's separate, larger `MenuVerticalMargin` (`48dp`) exists
   only to clear the system status/navigation bars, which have no web
   equivalent, so it is not ported as a second value — the same "no
   fabricated values" discipline ADR 0016 applied to Dialog's own viewport
   margin, here resolved by omission instead of cross-validation since no
   second axis-specific number is needed at all.
4. Entrance/exit motion (fade + scale, `0.8`→`1`, the sourced
   `ExpandedScaleTarget`/`ClosedScaleTarget` on `FastSpatial`/`FastEffects`)
   is a plain CSS transition on a conditionally-mounted portaled `div`, not
   `@starting-style`/`allow-discrete`: there is no native top-layer element
   here to transition across, so the technique ADR 0016 needed for Dialog
   would add complexity with no corresponding benefit. Exit motion is real,
   matching the pinned source's own enter/exit `AnimatedVisibility`:
   closing defers actual unmount until the popover's `transitionend` fires
   (with a fallback timer and an immediate-unmount path under reduced
   motion or before the entrance transition ever completed), rather than a
   hard cut.
5. `Menu` follows the APG menu-button pattern exactly: opening moves real
   DOM focus to the first enabled item (roving `tabindex`, matching
   material-web's own per-option `tabindex="0"` convention and the
   pattern's own recommendation); ArrowDown/ArrowUp/Home/End/typeahead move
   it; Enter/Space activates; Escape closes and restores focus to the
   anchor; Tab closes without trapping focus, letting the browser's own tab
   order continue — no focus trap and no inert background exist here,
   unlike Dialog's modal pattern. A non-checkable item's activation closes
   the menu; a checkable item's activation does not, matching the pattern's
   own checkbox-item example of letting a user toggle several settings in
   one visit.
6. `Select` follows the APG select-only combobox pattern instead: the
   trigger is `role="combobox"` with `aria-haspopup="listbox"`,
   `aria-expanded`, `aria-controls`, and `aria-activedescendant` (present
   only while open); DOM focus never leaves the trigger. This is a
   deliberate divergence from `Menu`'s own real per-item focus movement —
   each component follows its own distinct, authoritative APG pattern
   rather than one shared technique forced across both. `aria-autocomplete
   ="none"` reflects that this is a value-picker, not a filterable/editable
   combobox; the visible trigger is a read-only native `input`, following
   the pinned source's own `ExposedDropdownMenuBox`, which composes a real
   `TextField`/`OutlinedTextField` rather than any native platform picker.
7. `Select`'s field chrome reuses T14's `TextFieldChrome` internal
   primitive verbatim — a third component built on it, after `TextField`
   and `TextArea` — and registers no component tokens of its own for any of
   it: every color/shape/spacing role comes from the existing
   `--m3e-comp-text-field-*` domain, exactly reproducing how
   `ExposedDropdownMenuBox` reads the same `TextFieldColors`/
   `TextFieldTokens` as a plain `TextField` with no distinct token file of
   its own. `Select`'s popup listbox reuses this task's own `Menu`
   `--m3e-comp-menu-*` domain and CSS classes unchanged (only forcing width
   to match the trigger, `ExposedDropdownMenuBox`'s own
   `matchAnchorWidth = true` default, in place of `Menu`'s 112–280px
   intrinsic bounds), matching how `ExposedDropdownMenuDefaults` itself
   resolves straight through to `MenuDefaults.shape`/`containerColor`/
   `TonalElevation`/`ShadowElevation` — the exact same values plain
   `DropdownMenu` uses. This mirrors the T14 TextField/TextArea precedent of
   one shared token domain (and, here, shared CSS classes) serving multiple
   public components.
8. `Select`'s trailing chevron is a fixed inline SVG, not a Material Symbols
   glyph: baking in a font dependency the consumer has not opted into would
   break this library's "font loading remains consumer-owned" posture. It
   fills `TextFieldChrome`'s existing `trailingIcon` slot, inheriting the
   same enabled/disabled/error color handling with no new token, and
   rotates off the trigger's own `aria-expanded` attribute via a CSS
   sibling selector — the same native-truth precedent ADR 0016 established
   for reading Dialog's dismissal state directly off the DOM.
9. `Select`'s `name` prop, when supplied, renders a companion native
   `<input type="hidden">` carrying the current value — the first
   hidden-input forms shim in v1, necessary specifically because no native
   form-associated element can render Material's option rows, unlike every
   prior form control (Checkbox, Radio, Switch, TextField, TextArea,
   SegmentedButtonGroup), which all use a real native form-associated
   element directly and need no such shim.
10. T17 is the first task since the T15 ceiling raise whose measured output
    exceeds a bundle-budget ceiling — the public v1 JavaScript closure and
    its declaration closure both overshoot, driven by two new components
    plus the portal/positioning/dismissal primitives they share. Per §11.3
    of `docs/SPEC.md`, this is that recorded decision. As at T13/T15,
    every artifact except one gzip metric with already-adequate headroom
    receives fresh headroom in the same proportion (roughly 11% above the
    new baseline), since the full-CSS and packed-package ceilings were also
    down to single-digit headroom (`228,816`/`245,000`, 6.6% remaining, and
    `320,501`/`330,000`, 2.9% remaining):

    - public v1 JavaScript closure: 192,722 bytes / 34,924 gzip; ceiling
      raised 180,000 → 216,000 / 33,000 → 39,500;
    - public v1 declaration closure: 53,007 / 13,465 gzip; ceiling raised
      52,000 → 59,500 / 13,300 → 15,100;
    - full CSS: 228,816 / 20,706 gzip; ceiling raised 245,000 → 257,000 /
      22,000 → 23,200;
    - token CSS: 96,080 / 8,210 gzip; ceiling raised 105,000 → 108,000; the
      gzip ceiling (9,500) already had adequate headroom and is unchanged,
      the same pattern T15 recorded for this exact metric;
    - packed package: 320,501 bytes; ceiling raised 330,000 → 359,000.

    The pre-task reference is the T16 Dialog commit
    `ebcacd444ee919b2de962c6f508533c23ec6d819`. The increase comprises 29
    sourced `menu` component tokens, two new public components, and the new
    `overlayPosition`/`useAnchoredOverlay` internal primitives — the first
    task to add shared non-component internal infrastructure of comparable
    size to a component itself.

11. Every `DropdownMenuGroup`/`MenuGroupShapes`/`SegmentedMenuTokens`
    grouped-menu system, cascading submenus, and drag-select gesture
    behavior are excluded, same exclusion basis as prior tasks'
    provisional/gesture-specific-feature exclusions — this Expressive layer
    has no clean web equivalent and no accompanying gesture surface here.
    The plain, non-selectable `DropdownMenuItemContent` the source resolves
    to for ungrouped items has no independent shape or background of its
    own (a bare `Row` with only ripple indication), so `Menu`'s item rows
    carry no corner radius either, relying entirely on the shared
    `--m3e-sys-state-*` state-layer system every other v1 interactive
    component already applies rather than porting the separate Expressive
    per-item hover/press shape-morph tokens that belong to that excluded
    layer.

## Consequences

- v1 gains its first portal-based, manually-positioned, manually-dismissed
  overlay pattern. Any future overlay component that cannot use `<dialog>`
  (Tooltip, Snackbar in T18) has `useAnchoredOverlay`/`overlayPosition` to
  build on rather than reinventing portal/positioning/dismissal machinery
  from scratch.
- `Menu` and `Select` deliberately use two different focus-management
  models for their popups (`Menu`: real roving focus; `Select`:
  `aria-activedescendant`) — this is a considered, per-pattern decision, not
  an inconsistency, and future overlay components should pick whichever
  APG pattern is actually authoritative for their own role rather than
  copying either wholesale.
- `Select`'s zero-new-tokens design means a future visual change to
  `TextField`'s field chrome or `Menu`'s popup/item styling propagates to
  `Select` automatically; a genuine `Select`-only visual need (should one
  arise) would be the first token this component registers, not a
  refactor of an existing assumption.
- The hidden-input forms shim is a new, deliberate pattern specific to
  components with no viable native form-associated element; it should not
  be reached for by future form controls that do have one.
- Every raised ceiling sits at roughly the same ~11% headroom above its new
  baseline (packed package and full-CSS gzip are jointly tightest at
  10.7%); a task with comparably large JavaScript or CSS may need another
  recorded budget decision within a few tasks, consistent with the cadence
  T10 through T15 already showed.

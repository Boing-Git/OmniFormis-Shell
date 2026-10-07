# Menu conformance

Task: T17
Status: conformant
Reviewed: 2026-07-20

## Primary references

- Material Design menus component guide, accessed 2026-07-20:
  <https://m3.material.io/components/menus/overview>
- Pinned current AndroidX `Menu.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/Menu.kt>
- Pinned current AndroidX `MenuDefaults.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/MenuDefaults.kt>
- Pinned generated AndroidX `MenuTokens`/`ListTokens`/`StandardMenuTokens`,
  accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/MenuTokens.kt>
- material-web menu implementation, cross-validating the 112px minimum
  intrinsic width, accessed 2026-07-20:
  <https://github.com/material-components/material-web/blob/main/menu/internal/_menu.scss>
- WAI-ARIA APG menu button pattern, accessed 2026-07-20:
  <https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/>
- WCAG 2.2 focus visible, target size, and reduced motion, accessed 2026-07-20:
  <https://www.w3.org/TR/WCAG22/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`, adapted to a portaled,
JavaScript-positioned popup instead of the pinned source's own `Popup`
composable, since neither the Popover API nor CSS anchor positioning is
available across this library's browser floor (Firefox reaches the Popover
API only at 125, after the pinned 121 floor).

## Anatomy and content

- One public, data-driven `Menu` component: `items: readonly MenuItem[]`
  replaces the pinned source's children-composable API, extending the T15
  SegmentedButtonGroup data-array precedent and matching the single
  `Menu`/`MenuProps` export the component inventory already named, plus one
  added `MenuItem` data type (the same shape T15 added
  `SegmentedButtonGroupSegment`).
- `Menu` renders no trigger of its own — `anchorRef` points at a
  consumer-owned, already-rendered trigger, matching Dialog's own
  trigger-agnostic precedent. The consumer's trigger owns its own
  `aria-haspopup="menu"`/`aria-expanded`/click wiring.
- Each `MenuItem` renders `role="menuitem"` by default, or
  `role="menuitemcheckbox"` with `aria-checked` when `checked` is defined —
  folding the pinned source's separate checked/selected `DropdownMenuItem`
  overloads into one boolean toggle mechanism, a documented flattening since
  `Select` already owns the real single-choice-from-a-list use case.

## Variants, shape, color, and size

- Container: `MenuTokens.ContainerColor` (surfaceContainer),
  `ContainerShape` (cornerExtraSmall), `ContainerElevation` (level2, as
  shadow), `112`–`280px` intrinsic width bounds
  (`DropdownMenuItemDefaultMinWidth`/`MaxWidth`), `8px` block padding
  (`DropdownMenuVerticalPadding`).
- Items: `48px` minimum height (the source's own menu-specific
  `MenuListItemContainerHeight`), `12px` horizontal padding
  (`DropdownMenuItemHorizontalPadding`), `onSurface`/`onSurfaceVariant`
  label/icon roles with a disabled-0.38 pair (`ListTokens`) — the plain,
  non-selectable `DropdownMenuItemContent` the source resolves to has no
  independent shape or background of its own, so item rows carry no corner
  radius and rely on the shared `--m3e-sys-state-*` state-layer system every
  other interactive component already applies.
- Checked items: `tertiaryContainer`/`onTertiaryContainer` roles
  (`StandardMenuTokens`, the values `defaultMenuSelectableItemColors`
  actually reads) with a disabled-0.38 pair.
- A visible keyboard focus ring (`MenuTokens.FocusIndicatorColor`, secondary)
  is a deliberate web addition, the same accessibility-driven registration
  Checkbox/Radio already made for an upstream-unread role.
- Label typography reuses the theme's own `label-large` typescale role
  directly, matching every prior task's unread-typography-role precedent.

## States and motion

- Enabled/hovered/focused/pressed/disabled/checked/checked-disabled are all
  covered; hover/focus/pressed use the shared state-layer opacities since
  `MenuItemColors`' own resolution takes only `(enabled, selected)` — no
  separate hover/focus/pressed color axis exists in the source.
- Positioning reproduces `DropdownMenuPositionProvider`'s own behavior: try
  the anchor's own start alignment, then end alignment, then clamp inside an
  `8px` viewport margin (`MenuHorizontalMargin`, reused on both axes; the
  source's separate 48dp vertical margin exists only to clear Android's
  system bars and has no web equivalent) — vertically below-anchor, then
  above-anchor, then clamped.
- Entrance/exit motion is a fade + scale (`0.8` → `1`, the sourced
  `ExpandedScaleTarget`/`ClosedScaleTarget`) using the sourced
  `FastSpatial`/`FastEffects` motion slots, a plain CSS transition on a
  conditionally-mounted portaled `div` — not `@starting-style`, since there
  is no native top-layer element here to transition across, unlike Dialog.
  Exit motion is real: closing defers unmount until the transition finishes
  (or immediately, under reduced motion or before the entrance transition
  ever completed).

## Accessibility

- Keyboard, matching the APG menu-button pattern: opening moves real DOM
  focus to the first enabled item (roving `tabindex`); ArrowDown/ArrowUp
  move cyclically across enabled items; Home/End jump to the first/last
  enabled item; typing jumps to the next item whose label starts with that
  character; Enter/Space activates the focused item; Escape closes and
  restores focus to the anchor; Tab closes without trapping focus, letting
  the browser's own tab order continue.
- No focus trap and no inert background: the APG menu-button pattern does
  not require either, unlike Dialog's modal focus trap.
- A non-checkable item's activation closes the menu; a checkable item's
  activation does not, matching the APG pattern's own checkbox-item example
  of letting a user toggle several items in one visit.
- Disabled items are skipped by keyboard navigation, excluded from
  typeahead matching consideration in effect (never focusable), and inert to
  click.

## Web-specific deviations

- No portal or manual dismissal machinery was needed by any prior
  component; `Menu` (and `Select`) are the first to require a
  `ReactDOM.createPortal` target, manual outside-click/Escape dismissal via
  `useAnchoredOverlay`, and manual focus restoration, since neither the
  Popover API nor CSS anchor positioning is available across this library's
  browser floor.
- Typeahead only matches items whose `label` is a plain string; a `label`
  containing richer content is reachable by arrow keys but not typeahead, a
  documented limitation of accepting `ReactNode` labels.
- Outside-click dismissal never restores focus (the click's own natural
  focus target stands undisturbed); only Escape and an item activation
  restore focus to the anchor — a deliberate, documented split from a single
  blanket "always restore on close" rule.

# NavigationBar conformance

Task: T20
Status: conformant
Reviewed: 2026-07-20

## Primary references

- Material Design navigation bar component guide, accessed 2026-07-20:
  <https://m3.material.io/components/navigation-bar/overview>
- Pinned current AndroidX `NavigationBar.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/NavigationBar.kt>
- Pinned generated AndroidX `NavigationBarTokens`/`NavigationBarVerticalItemTokens`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/NavigationBarTokens.kt>
- WAI-ARIA `aria-current` and navigation landmark guidance, accessed 2026-07-20:
  <https://www.w3.org/TR/wai-aria-1.2/#aria-current>
- WCAG 2.2 focus visible, target size, and reduced motion, accessed 2026-07-20:
  <https://www.w3.org/TR/WCAG22/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`.

## Anatomy and content

- One public, data-driven `NavigationBar` component:
  `items: readonly NavigationItem[]` (`{ value, label, icon, selectedIcon?,
  disabled?, href? }`), the same shared type `NavigationRail`/
  `NavigationDrawer`/`NavigationSuite` all reuse.
- **Web-native navigation semantics, not the pinned source's ported
  `Role.Tab`**: renders `<nav>` containing plain `<a href>` (when `href` is
  supplied) or `<button>` items, each carrying `aria-current="page"` when
  selected — not `role="tab"`/`aria-selected`, which `Tabs` (T19) already
  owns for in-page panel switching. No roving `tabindex`; items sit in
  normal tab order like any navigation link list, since APG has no
  composite-widget requirement for a navigation menu the way it does for
  tabs. A disabled `href` item omits `href` (anchors have no native
  disabled state) but keeps an explicit `role="link"` so assistive
  technology still identifies it as a (disabled) link.

## Variants, shape, color, and size

- Container: `NavigationBarTokens.ContainerColor` (surfaceContainer),
  `ContainerElevation` (level2, as shadow), `64px` height
  (`ContainerHeight`).
- Item: `56×32px` pill indicator (`NavigationBarVerticalItemTokens.
  ActiveIndicatorWidth`/`Height`), `cornerFull` shape, `secondaryContainer`
  background when selected. Active icon tints `onSecondaryContainer`;
  active **label** tints `secondary` — a genuine sourced split, not a
  simplification. Inactive icon/label both tint `onSurfaceVariant`. `24px`
  icon, `4px` icon-label gap (`ItemActiveIndicatorIconLabelSpace`),
  `labelMedium` typography.
- Disabled items dim to the universal `onSurface`-at-`0.38`-opacity
  treatment every other interactive component already uses — the
  source has no disabled color axis for navigation items at all.

## States and motion

- Enabled/hovered/focused/pressed/selected/disabled are all covered; hover/
  focus/pressed reuse the shared `--m3e-sys-state-*` system via
  `currentColor`, the same `Menu`/`Tabs` precedent (the source's own color
  model has only a selected/unselected axis).
- The pinned source measures the 24px icon separately from a fixed-height
  indicator whose width animates from zero to 56px. The web translation uses
  the same separation: a centered background layer fades and expands
  horizontally while the 56×32px interaction layer, 24×24px icon, and item
  footprint stay fixed. It uses the `FastSpatial`/`FastEffects` motion slots
  independently per item; no shared/measured indicator is needed as in
  `Tabs`.

## Web-specific deviations

- Web-native `<nav>`/`aria-current` navigation semantics instead of the
  pinned source's ported `role="tab"` (see Anatomy) — the first time
  SPEC §3's "web semantic wins" clause is applied to a *pattern*
  choice, not just a color/shape value.
- `selectedIcon` (swap the icon on selection) has no dedicated pinned-
  source parameter but is a well-established Material icon-swap
  convention (e.g. outlined → filled) other Google Material
  implementations already use; omitting it reuses `icon` for both states.

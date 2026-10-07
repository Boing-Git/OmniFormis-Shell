# NavigationRail conformance

Task: T20
Status: conformant
Reviewed: 2026-07-20

## Primary references

- Material Design navigation rail component guide, accessed 2026-07-20:
  <https://m3.material.io/components/navigation-rail/overview>
- Pinned current AndroidX `NavigationRail.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/NavigationRail.kt>
- Pinned generated AndroidX `NavigationRailColorTokens`/
  `NavigationRailVerticalItemTokens`/`NavigationRailCollapsedTokens`,
  accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/NavigationRailColorTokens.kt>
- WAI-ARIA `aria-current` guidance, accessed 2026-07-20:
  <https://www.w3.org/TR/wai-aria-1.2/#aria-current>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`.

## Anatomy and content

- Reuses `NavigationBar`'s own `NavigationItem` data type and shares its
  web-native `<nav>`/`aria-current` navigation semantics (not the pinned
  source's ported `role="tab"`) and item visual language, oriented
  vertically. `header` is a consumer-owned region above the items,
  matching the pinned source's own `header` composable slot (typically a
  FAB or menu button).

## Variants, shape, color, and size

- Container: `NavigationRailColorTokens`/`NavigationRailCollapsedTokens`
  (`ContainerColor` surface, `96px` width, `44px` top padding
  (`TopSpace`), `8px` header-to-items gap
  (`NavigationRailHeaderPadding`, a plain layout constant from
  `NavigationRail.kt` itself, not a token file value), `4px` item gap
  (`ItemVerticalSpace`)). Item: the same `56×32px` pill, `cornerFull`,
  `secondaryContainer` selected background, `secondary`/
  `onSecondaryContainer` active label/icon split as `NavigationBar`, `80px`
  item width (`NavigationRailCollapsedTokens.NarrowContainerWidth`).
- Disabled items dim to the universal `onSurface`-at-`0.38`-opacity
  treatment, the same web addition `NavigationBar`'s own registration
  already makes (no disabled color axis in the source).

## States and motion

- Enabled/hovered/focused/pressed/selected/disabled all covered, the same
  shared-state-layer-via-`currentColor` model `NavigationBar` uses. As in the
  pinned layout, each 24×24px icon stays fixed while only a separate,
  centered indicator background fades and expands from zero width to 56×32px;
  the full-size interaction layer and item footprint do not scale.

## Web-specific deviations

- Web-native `<nav>`/`aria-current` navigation semantics instead of the
  pinned source's ported `role="tab"`, the same deviation `NavigationBar`'s
  own conformance record already documents.

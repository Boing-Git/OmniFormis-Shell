# Tooltip conformance

Task: T18
Status: conformant
Reviewed: 2026-07-20

## Primary references

- Material Design tooltips component guide, accessed 2026-07-20:
  <https://m3.material.io/components/tooltips/overview>
- Pinned current AndroidX `Tooltip.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/Tooltip.kt>
- Pinned generated AndroidX `PlainTooltipTokens`/`RichTooltipTokens`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/RichTooltipTokens.kt>
- Pinned `BasicTooltip.kt` internal gesture handling, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/internal/BasicTooltip.kt>
- WAI-ARIA APG tooltip pattern, accessed 2026-07-20:
  <https://www.w3.org/WAI/ARIA/apg/patterns/tooltip/>
- WCAG 2.2 content on hover or focus (1.4.13) and reduced motion, accessed 2026-07-20:
  <https://www.w3.org/TR/WCAG22/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`, adapted to a portaled,
JavaScript-positioned popup reusing T17's `useAnchoredOverlay`/
`overlayPosition` infrastructure, since neither the Popover API nor CSS
anchor positioning is available across this library's browser floor.

## Anatomy and content

- One public `Tooltip` component: `anchorRef` (required) + `content`
  (required body). `variant?: 'plain' | 'rich'` (default `'plain'`); `rich`
  adds an optional `subhead` above `content`.
- Unlike `Menu`/`Select`, `Tooltip` wires its own show/hide interaction
  directly on `anchorRef.current` (hover, focus, `Escape`) rather than
  asking the consumer to — hover/focus tooltip triggering is a single,
  standardized WAI-ARIA APG interaction with no app-specific ambiguity,
  unlike `Menu`'s click semantics. `open`/`defaultOpen`/`onOpenChange` still
  exist as a controlled escape hatch.
- Both variants are always non-interactive. The pinned source's
  `RichTooltip` action button is **excluded**: WAI-ARIA explicitly
  disallows interactive content inside `role="tooltip"`, a direct conflict
  with the native web semantic, which wins per `SPEC.md` §3.

## Variants, shape, color, and size

- Plain: `PlainTooltipTokens.ContainerColor` (inverseSurface),
  `ContainerShape` (cornerExtraSmall), `SupportingTextColor`
  (inverseOnSurface), `8px`/`4px` inline/block padding
  (`PlainTooltipContentPadding`), `200px` max width
  (`plainTooltipMaxWidth`).
- Rich: `RichTooltipTokens.ContainerColor` (surfaceContainer),
  `ContainerShape` (cornerMedium), `ContainerElevation` (level2, as
  shadow), `SubheadColor`/`SupportingTextColor` (onSurfaceVariant), `16px`
  inline padding (`RichTooltipHorizontalPadding`), `320px` max width
  (`richTooltipMaxWidth`). `rich-padding-block`/`rich-subhead-gap`
  approximate the source's baseline-relative padding constants as ordinary
  CSS block padding/margin — a documented simplification, not a claim of
  pixel-exact baseline reproduction.
- Both: `40px`/`24px` min width/height (`TooltipMinWidth`/`MinHeight`),
  `4px` anchor gap (`SpacingBetweenTooltipAndAnchor`).
- Typography reuses the theme's own `body-small`/`title-small`/
  `body-medium` typescale roles directly, matching every prior task's
  unread-typography-role precedent.

## States and motion

- Shown/hidden immediately on hover/focus of the anchor, matching the
  pinned source's own `handleGestures` — no invented warm-up delay.
- Positioning reproduces `TooltipPositionProviderImpl`'s own behavior:
  center-aligned on the cross axis, a single flip to the opposite side on
  collision, then clamped flush to the viewport edge with **zero** margin
  (the source's own `coerceIn(0, ...)`).
- Entrance/exit motion is a fade + scale (`0.8` → `1`) using the sourced
  `FastSpatial`/`FastEffects` motion slots, the same technique and tokens
  `Menu` already uses. Exit motion is real: closing defers unmount until the
  transition finishes (or immediately, under reduced motion or before the
  entrance transition ever completed).

## Accessibility

- `role="tooltip"` throughout; `aria-describedby` is set imperatively on
  the anchor while mounted (merging with, not clobbering, an existing
  value) — the first imperative ARIA-attribute technique here, extending
  the same "library owns unambiguous wiring" reasoning as Dialog's
  imperative native calls and Menu/Select's imperative focus calls.
- Dismissible: `Escape` always closes (WCAG 1.4.13). Hoverable: the popover
  itself also participates in the show/hide evaluation, so a pointer
  crossing from the anchor to the popover does not flicker-close it —
  bridged by the deferred-unmount fade-out window `useAnchoredOverlay`
  already provides, not a fabricated timing buffer. Persistent: the source
  has no interactive content in either variant, so WCAG 1.4.13's intent
  (letting a user reach revealed interactive content) is inherently
  satisfied.

## Web-specific deviations

- No caret/pointer triangle: the pinned source draws it via
  `CacheDrawScope`/`LayoutCoordinates` custom geometry with no clean web
  equivalent, the same basis prior tasks already excluded
  Compose-specific-drawing features on.
- The rich tooltip's action button has no web port at all (see Anatomy) —
  a genuine ARIA spec conflict, not merely a missing browser API.

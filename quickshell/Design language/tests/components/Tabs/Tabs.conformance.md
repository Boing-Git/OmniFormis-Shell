# Tabs conformance

Task: T19
Status: conformant
Reviewed: 2026-07-20

## Primary references

- Material Design tabs component guide, accessed 2026-07-20:
  <https://m3.material.io/components/tabs/overview>
- Pinned current AndroidX `Tab.kt`/`TabRow.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/TabRow.kt>
- Pinned generated AndroidX `PrimaryNavigationTabTokens`/
  `SecondaryNavigationTabTokens`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/PrimaryNavigationTabTokens.kt>
- WAI-ARIA APG tabs pattern, accessed 2026-07-20:
  <https://www.w3.org/WAI/ARIA/apg/patterns/tabs/>
- WCAG 2.2 focus visible, target size, and reduced motion, accessed 2026-07-20:
  <https://www.w3.org/TR/WCAG22/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`.

## Anatomy and content

- One public, data-driven `Tabs` component: `items: readonly TabItem[]`
  (`{ value, label?, icon?, disabled?, href?, panel? }`), extending the
  Menu/SegmentedButtonGroup data-array precedent. `aria-label`/
  `aria-labelledby` describe the `role="tablist"` region, matching every
  other group-role component's own required-naming contract.
- An item with `href` renders a real `<a role="tab" href>` instead of
  `<button role="tab">` — a link-safe API for router-driven navigation
  tabs, letting a consumer drive `Tabs` from a router's current route
  without `Tabs` owning any routing concept itself. Arrow-key movement
  still updates the local selected/indicator state; actual navigation is
  left entirely to the browser's native anchor behavior.
- An item with `panel` gets one `role="tabpanel"` region for the selected
  item only, associated via `id`/`aria-controls`/`aria-labelledby`. No
  tabpanel region exists at all when no item defines `panel` — a pure
  link-tabs usage where a router owns the destination content.

## Variants, shape, color, and size

- `'primary'` (default): indicator is a short, rounded (`3px`,
  `RoundedCornerShape(3dp)`), content-width-hugging pill (source's own
  `matchContentSize = true`) tinted `primary`; active label/icon tint
  `primary`, inactive tint `onSurfaceVariant`.
- `'secondary'`: indicator is a full-tab-width underline reusing the same
  `ActiveIndicatorColor`/`Height` the `'primary'` token file defines —
  `SecondaryNavigationTabTokens` has no indicator fields of its own, and
  the pinned source's own `SecondaryIndicator` reads the primary token
  file directly; active label/icon tint plain `onSurface` (deliberately
  more subdued than `'primary'`, not brand-colored), inactive tint
  `onSurfaceVariant`.
- Both: `48px` row height (`ContainerHeight`) when every item has only a
  label or only an icon; `72px` (`LargeTabHeight`, the value the source's
  own `TabBaselineLayout` actually uses, not the token file's unread `64px`
  `IconAndLabelTextContainerHeight`) when any item combines both, stacked
  icon-above-label. `24px` icon size, `16px` label inline padding
  (`HorizontalTextPadding`). A full-width divider under the tablist for
  both variants (`SecondaryNavigationTabTokens.DividerColor`/
  `DividerHeight` — see Web-specific deviations).
- Label typography reuses the theme's own `title-small` typescale role
  directly, matching every prior task's unread-typography-role precedent.
- Disabled tabs dim to the universal `onSurface`-at-`0.38`-opacity
  treatment (see Web-specific deviations — the source has no disabled
  color axis at all).

## States and motion

- Enabled/hovered/focused/pressed/selected/disabled are all covered; hover/
  focus/pressed reuse the shared `--m3e-sys-state-*` state-layer system via
  `currentColor`, the same `Menu`/`Select`/`Snackbar` precedent (`Tab`'s own
  color model has only a selected/unselected axis, no separate hover/
  focus/pressed color role).
- The indicator slides (and, in `'primary'`, resizes) between tab
  positions using the sourced `DefaultSpatial` motion slot — not
  `FastSpatial` like every prior overlay-entrance task; the source itself
  specifically animates this with `MotionSchemeKeyTokens.DefaultSpatial`,
  since it is a content-shift transition, not an overlay entrance.
- `scrollable` keeps the newly selected tab in view via `scrollIntoView`,
  the same technique `Select` already uses for its active option.

## Accessibility

- Keyboard, matching the APG tabs pattern's automatic-activation model:
  ArrowLeft/ArrowRight move focus and select (no RTL-direction flip — the
  same no-JS-direction-branching precedent `Menu`/`Select`'s own physical-
  coordinate positioning already established); Home/End jump to the
  first/last enabled tab and select. A disabled tab is skipped by keyboard
  navigation and inert to click (native `disabled` for a button item; no
  `href` attribute at all for a disabled link item, since anchors have no
  native disabled state).
- Roving `tabindex`: only the selected tab is in the page tab order.

## Web-specific deviations

- **First sliding-indicator infrastructure**: no prior component
  measures and animates a shared element between sibling positions. A
  plain `useEffect` (not `useLayoutEffect`, to avoid an SSR warning, since
  `Tabs` renders its full tree during server rendering unlike `Menu`/
  `Snackbar`'s client-only portal) measures the selected tab's own
  bounding rect (or, for `'primary'`, its inner content-wrapper rect, to
  reproduce `matchContentSize`) relative to the tablist, applied as the
  indicator's `transform`/`inline-size`; a `ResizeObserver` and a window
  `resize` listener keep it correct across container reflow.
- The source's separate side-by-side `LeadingIconTab` composable is
  excluded — `Tabs` only supports the stacked icon-above-label combined
  layout, the same "one clean composition over several alternate overload
  variants" precedent prior tasks already applied.
- Disabled-tab dimming and the divider's traceable-token color (see
  Anatomy) are both deliberate web additions/choices beyond a literal
  source reading.

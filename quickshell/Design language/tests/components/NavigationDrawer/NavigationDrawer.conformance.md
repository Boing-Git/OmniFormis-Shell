# NavigationDrawer conformance

Task: T20
Status: conformant
Reviewed: 2026-07-20

## Primary references

- Material Design navigation drawer component guide, accessed 2026-07-20:
  <https://m3.material.io/components/navigation-drawer/overview>
- Pinned current AndroidX `NavigationDrawer.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/NavigationDrawer.kt>
- Pinned generated AndroidX `NavigationDrawerTokens`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/NavigationDrawerTokens.kt>
- ADR 0016 (native Dialog modal lifecycle), whose native-`<dialog>`
  technique this component's `'modal'` variant reuses.

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`.

## Anatomy and content

- `variant: 'modal' | 'dismissible' | 'permanent'` (default `'modal'`),
  reusing `NavigationBar`'s own `NavigationItem` data type and web-native
  `<nav>`/`aria-current` semantics.
- `'modal'`: a native `<dialog>` (the same `showModal()`/`close()`/native
  `close` event technique ADR 0016 established for `Dialog`, independently
  duplicated rather than shared — see Web-specific deviations) sliding in
  from the logical start edge.
- `'dismissible'`: a non-modal panel that collapses its own `inline-size`
  to `0`, participating in normal document flow (pushes adjacent content),
  matching the pinned source's own non-scrimmed reveal.
- `'permanent'`: always rendered, no open/close state — `open`/
  `onOpenChange` are accepted but ignored, matching the pinned source's
  own `PermanentNavigationDrawer`, which has no visibility parameter at
  all.

## Variants, shape, color, and size

- `360px` container width (`ContainerWidth`), `cornerLargeEnd` shape
  (`ContainerShape`, `'modal'` only — the non-modal variants have no
  independent shape). `'modal'`: `surfaceContainerLow`/level1
  (`ModalContainerColor`/`Elevation`). `'dismissible'`/`'permanent'`: plain
  `surface`/level0 (`StandardContainerColor`/`Elevation`) — the source
  uses the same "standard" pair for both.
- Item: full-width `336×56px` pill (`ActiveIndicatorWidth`/`Height`,
  `cornerFull`), `secondaryContainer` background, `onSecondaryContainer`
  icon **and** label when selected (unlike `NavigationBar`/`NavigationRail`,
  drawer items tint icon and label identically) — a genuine sourced
  difference, not an inconsistency. `16px`/`24px` asymmetric inline
  padding, `12px` icon-label gap (`Modifier.padding(start=16dp,
  end=24dp)`/`Spacer(width=12dp)` in `NavigationDrawerItem` itself, not a
  token-file value), `labelLarge` typography (larger than `NavigationBar`/
  `NavigationRail`'s `labelMedium` — another genuine sourced difference).
- A visible keyboard focus ring (`FocusIndicatorColor`, secondary) is a
  deliberate web addition, the same accessibility-driven registration
  `Menu`'s own `item-focus-ring-color` already made.
- Disabled items dim to the universal `onSurface`-at-`0.38`-opacity
  treatment (no disabled color axis in the source).

## States and motion

- `'modal'` uses the sourced `DefaultSpatial`/`DefaultEffects` motion slots
  for its slide/scrim (matching `Dialog`'s own motion category), animating
  `inset-inline-start` rather than `transform` so the slide direction
  auto-corrects under RTL with no JS branching. `'dismissible'` animates
  `inline-size` with the same `DefaultSpatial` slot.

## Web-specific deviations

- Web-native `<nav>`/`aria-current` navigation semantics instead of the
  pinned source's ported `role="tab"` on `NavigationDrawerItem`, the same
  deviation `NavigationBar`'s own conformance record documents.
- The `'modal'` variant independently duplicates Dialog's own small
  native-`<dialog>` lifecycle (~20 lines) rather than sharing an extracted
  primitive — the two components' exact backdrop/escape nuances differ
  enough that a forced shared abstraction would need its own
  parameterization; see the T20 ADR.
- The source's drag-to-dismiss gesture on the modal variant is excluded —
  Compose-specific gesture machinery with no clean web equivalent, the
  same basis Menu's excluded drag-select uses.

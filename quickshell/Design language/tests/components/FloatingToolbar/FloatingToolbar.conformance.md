# FloatingToolbar conformance

Task: T24
Status: conformant
Reviewed: 2026-07-20

## Primary references

- Material Design floating toolbars component guide, accessed 2026-07-20:
  <https://m3.material.io/components/toolbars/overview>
- Pinned current AndroidX `FloatingToolbar.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/FloatingToolbar.kt>
- Pinned generated AndroidX `FloatingToolbarTokens`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/FloatingToolbarTokens.kt>
- WAI-ARIA APG toolbar guidance, accessed 2026-07-20:
  <https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`.

## Anatomy and content

- One public component: a floating pill container (`role="toolbar"`,
  `aria-orientation`) around `children`, typically `IconButton`s.
  `orientation` (`horizontal`/`vertical`) unifies the source's two
  near-identical composables into one prop.

## Variants, shape, color, and size

- `standard` (`surfaceContainer`/`onSurface`) and `vibrant`
  (`primaryContainer`/`onPrimaryContainer`) color pairings, matching
  `FloatingToolbarDefaults.standardFloatingToolbarColors`/
  `vibrantFloatingToolbarColors`. Fixed `64dp` cross-axis size, fully
  round shape, `8dp` content padding, `4dp` item gap — all directly
  sourced from `FloatingToolbarTokens`.

## States and motion

- `expanded`/`defaultExpanded`/`onExpandedChange` control a visible
  collapse (`max-inline-size`/`max-block-size` + opacity) transitioning
  on `--m3e-sys-motion-expressive-fast-spatial-*`, matching the source's
  own `FloatingToolbarDefaults.animationSpec()` (`MotionSchemeKeyTokens
  .FastSpatial`).

## Accessibility

- `role="toolbar"` with `aria-orientation` and `aria-label`/
  `aria-labelledby` for the toolbar's own accessible name. Roving
  focus/tabindex, matching the WAI-ARIA APG toolbar pattern: arrow keys
  (`ArrowLeft`/`ArrowRight` horizontal, `ArrowUp`/`ArrowDown` vertical)
  move focus among direct children with wraparound, `Home`/`End` jump to
  the first/last. Only the current item has `tabindex="0"`; every other
  item has `tabindex="-1"`, so the toolbar occupies exactly one stop in
  the surrounding page's own tab sequence.

## Web-specific deviations

- **One component with an `orientation` prop**, not two separate
  `HorizontalFloatingToolbar`/`VerticalFloatingToolbar` exports — the
  inventory placeholder names only `FloatingToolbar`, and the two source
  composables share every default value, differing only in main-axis
  direction.
- **No integrated FAB slot, no `FloatingToolbarScrollBehavior`, no
  touch-exploration force-expand.** The FAB-integrated overload is a
  materially different layout/animation contract this session's
  `FabMenu` already covers the FAB-morph portion of; the scroll behavior
  is a Compose-specific `NestedScrollConnection` API with no direct web
  analog short of a real scroll-listener-plus-physics implementation;
  touch exploration detection is an Android-platform API not observable
  from web content at all. `expanded`/`onExpandedChange` are exposed
  directly so a consumer can wire their own scroll listener. See
  ADR 0024.
- **Roving focus reads and clones direct children** (`cloneElement` to
  set `tabIndex` and compose a focus-tracking ref, via this project's
  existing `composeRefs` utility) rather than requiring a structured
  `items` array — matching `ButtonGroup`'s (T23) own "arbitrary children,
  not a data-driven API" precedent for this exact category of composite.

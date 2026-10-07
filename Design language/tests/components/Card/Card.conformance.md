# Card conformance

Task: T10
Status: conformant
Reviewed: 2026-07-19

## Primary references

- AndroidX Card component guide, including coherent-content purpose, filled,
  elevated, outlined, passive, clickable, color, elevation, and enabled
  behavior, accessed 2026-07-19:
  <https://developer.android.com/develop/ui/compose/components/card>
- AndroidX Card API reference, including passive and clickable overloads,
  accessed 2026-07-19:
  <https://developer.android.com/reference/kotlin/androidx/compose/material3/Card.composable>
- Pinned current AndroidX `Card.kt`, including all three variants, native
  interaction states, colors, border composition, and elevation behavior,
  accessed 2026-07-19:
  <https://android.googlesource.com/platform/frameworks/support/+/0be207d91046b7376beeef5544d331a02d6fa87c/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/Card.kt>
- Pinned generated AndroidX `FilledCardTokens`, `ElevatedCardTokens`, and
  `OutlinedCardTokens`, accessed 2026-07-19:
  <https://android.googlesource.com/platform/frameworks/support/+/0be207d91046b7376beeef5544d331a02d6fa87c/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/>
- HTML button element, content model, activation, form, disabled, and default
  type behavior, accessed 2026-07-19:
  <https://html.spec.whatwg.org/multipage/form-elements.html#the-button-element>
- WAI-ARIA APG Button Pattern, including native button preference, Enter, and
  Space interaction, accessed 2026-07-19:
  <https://www.w3.org/WAI/ARIA/apg/patterns/button/>
- WCAG 2.2 focus visible, target size, contrast, use of color, reflow, and
  reduced motion, accessed 2026-07-19:
  <https://www.w3.org/TR/WCAG22/>

Supported Material baseline: AndroidX Material 3 revision
`0be207d91046b7376beeef5544d331a02d6fa87c`, generated Card token versions
v0_210 (filled/elevated) and v0_192 (outlined), adapted to native HTML
containment and button semantics.

## Anatomy and content

- One Card root owns variant color, medium shape, border, shadow, clipping,
  native semantics, stable data attributes, classes/styles, and forwarded ref.
- One internal content wrapper establishes a column without imposing padding,
  typography, named slots, media behavior, or application data.
- Passive mode uses a `div` wrapper so arbitrary rich flow content remains
  valid. Interactive mode uses a `span` wrapper and requires phrasing content
  because the semantic root is a native button.
- Headings, body, media, actions, and layout remain consumer-owned.

## Variants, shape, color, and elevation

- Filled: surface-container-highest/on-surface, medium corner, no outline,
  Level 0 rest/focus/press/disabled, Level 1 hover.
- Elevated: surface-container-low/on-surface, medium corner, no outline, Level 1
  rest/focus/press/disabled, Level 2 hover.
- Outlined: surface/on-surface, medium corner, 1px outline-variant border,
  on-surface focus border, Level 0 rest/focus/press/disabled, Level 1 hover.
- The pinned source has dragged Levels 3/4/3, but Card owns no drag operation in
  T10 and therefore does not claim or emit a dragged state.
- Card owns no fixed dimensions or content padding. Interactive mode alone
  reserves a minimum 48 by 48 CSS-pixel target.

## States and motion

- Passive cards have no hovered, focused, pressed, disabled, selected, checked,
  dragged, loading, or error behavior; consumer descendants remain independent.
- Interactive cards use native enabled/disabled, hover, focus-visible, and
  pressed states. State layers use system hover/focus/pressed opacity.
- Disabled filled container composites surface-variant at 0.38 over its normal
  container. Elevated composites surface at 0.38 over surface, matching the
  pinned implementation. Outlined stays surface and composites outline at 0.12
  over surface-container-low. Content uses on-surface at 0.38.
- Container, border, and elevation use Expressive default-effects motion; the
  state layer uses fast-effects. No Card-specific shape or spatial transition
  exists in the pinned first-party API. Reduced motion removes transitions and
  preserves immediate state.
- Selected, checked, indeterminate, error, dragged, and loading are not T10 Card
  states. `aria-pressed` is rejected rather than implying an unsupported toggle.

## Component token mapping

- Global: minimum target, medium container shape, focus ring, disabled content
  color, and disabled content opacity.
- Per variant: container/content colors; rest, hover, focus, pressed, and
  disabled shadows; disabled container color/base/opacity.
- Outlined: normal, hovered, focused, pressed, and disabled outline roles plus
  width and disabled compositing base/opacity.

All values live in the T10 `card` registration. Production CSS validation
requires every literal `--m3e-comp-card-*` reference to resolve.

## DOM, forms, and behavior

- Passive default DOM starts with `<article class="m3e-card"
  data-m3e-variant="filled" data-m3e-interactive="false">`. `as` supports
  `article`, `div`, `section`, and `aside`, with corresponding props and ref.
- Passive types reject click, keyboard activation, focus, form, disabled, and
  toggle props. Untyped callers receive a development warning and the component
  discards those values rather than emitting accidental interaction.
- Interactive DOM starts with `<button type="button" class="m3e-card"
  data-m3e-variant="filled" data-m3e-interactive="true"
  data-m3e-disabled="false">`.
- Submit/reset, form owner, name/value, IDs, descriptions, data, class/style,
  native handlers, and the `HTMLButtonElement` ref are forwarded.
- The browser owns pointer, Enter, Space, form, focus, and disabled behavior.
  Card adds no key handlers or duplicate activation callback.
- Server markup and hydration are deterministic and inject no styles.

## Accessible name, role, state, and keyboard

- Passive Card adds no role or tab stop. Selected semantic elements retain
  their native document/region relationships.
- Interactive Card exposes one native button role and derives its accessible
  name/description through ordinary button content and ARIA relationships.
- Interactive descendants must be phrasing, noninteractive, and nonfocusable.
  Detectable intrinsic violations warn in development; custom component output
  remains a documented consumer responsibility.
- Disabled native buttons do not activate and leave sequential focus. Card does
  not expose pressed, selected, checked, expanded, busy, or draggable state.

## Bidirectional, forced-color, and adaptive behavior

- Layout uses logical inline/block sizing and `text-align: start`; RTL changes
  alignment without reordering content.
- Card has no viewport positioning, breakpoint, or media-loading behavior.
  Consumer layout determines width and reflow; interactive Card defaults to the
  available inline size and may be overridden through class/style.
- Forced colors uses Canvas/CanvasText, Highlight focus, GrayText disabled
  treatment, an explicit border, and no authored shadow or state layer.
- Default, custom, and nested themes scope Card and derived motion variables.

## Web-specific deviations

- Compose's `Column` content accepts arbitrary composables in both overloads.
  Native HTML button content is restricted, so rich flow content stays passive
  and whole-card buttons accept only phrasing, noninteractive descendants.
- Compose exposes separate Card/ElevatedCard/OutlinedCard functions. React uses
  one literal `variant` union and one predictable owner directory.
- Compose accepts arbitrary shapes, colors, elevations, borders, and interaction
  sources. This library exposes the sourced Material variants and theme tokens, preventing
  per-instance values from bypassing the design system.
- Compose has dragged elevation tokens and can observe drag interactions. Web
  Card does not invent a drag operation in T10.
- Current first-party Card has no separate Expressive overload. Web Card uses
  the library's Expressive motion scheme for state effects without claiming
  unsupported size, selection, or shape morph behavior.

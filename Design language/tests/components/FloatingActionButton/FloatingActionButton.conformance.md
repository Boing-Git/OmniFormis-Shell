# FloatingActionButton conformance

Task: T09
Status: conformant
Reviewed: 2026-07-19

## Primary references

- AndroidX `FloatingActionButtonDefaults` API, including current standard,
  medium, large, extended-shape, normal elevation, and lowered-elevation
  surface, accessed 2026-07-19:
  <https://developer.android.com/reference/kotlin/androidx/compose/material3/FloatingActionButtonDefaults>
- Pinned current AndroidX `FloatingActionButton.kt`, including FAB and
  size-aware extended anatomy, dimensions, typography, spacing, shapes, and
  elevation behavior, accessed 2026-07-19:
  <https://android.googlesource.com/platform/frameworks/support/+/b0ef6d36c141931a051272e39ad3f4783dcb28e0/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/FloatingActionButton.kt>
- Pinned current AndroidX `FloatingActionButtonMenu.kt`, including toggle FAB
  size, shape, color, icon, alignment, semantics, and spatial motion, accessed
  2026-07-19:
  <https://android.googlesource.com/platform/frameworks/support/+/b0ef6d36c141931a051272e39ad3f4783dcb28e0/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/FloatingActionButtonMenu.kt>
- Pinned generated AndroidX FAB and extended-FAB token directory, accessed
  2026-07-19:
  <https://android.googlesource.com/platform/frameworks/support/+/b0ef6d36c141931a051272e39ad3f4783dcb28e0/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/>
- WAI-ARIA APG Button Pattern, including toggle-button `aria-pressed`, stable
  names, Enter, and Space interaction, accessed 2026-07-19:
  <https://www.w3.org/WAI/ARIA/apg/patterns/button/>
- HTML button element, form, activation, disabled, and default type behavior,
  accessed 2026-07-19:
  <https://html.spec.whatwg.org/multipage/form-elements.html#the-button-element>
- WCAG 2.2 focus visible, target size, contrast, use of color, reflow, and
  reduced motion, accessed 2026-07-19:
  <https://www.w3.org/TR/WCAG22/>

Supported Material baseline: AndroidX Material 3 revision
`b0ef6d36c141931a051272e39ad3f4783dcb28e0`, including experimental Expressive
medium, size-aware extended, and toggle surfaces, adapted to native HTML and
ARIA toggle-button semantics.

## Anatomy and slots

- One native button owns form behavior, name, activation, focus, disabled,
  optional `aria-pressed`, native props, stable data state, and forwarded ref.
- One visual container owns primary-container color, state layer, sourced
  shape, dimensions, shadow, clipping, and size transitions.
- `icon` is required visual artwork and always hidden from the accessibility
  tree. `selectedIcon` is an optional alternate decorative toggle artwork.
- `label` creates an extended FAB. It remains in the accessibility tree while
  `expanded={false}` visually collapses it, preserving the button name.
- Positioning, tooltip, loading, menu items, link, scroll visibility, and
  arbitrary shape/color slots are absent.

## Variants, dimensions, shape, and color

- Sizes are standard, medium, and large with 56/80/96px square containers,
  24/28/36px icons, and 16/20/28px corners. All exceed the 48px target.
- Extended layouts preserve each height and use title-medium/title-large/
  headline-small typography. Leading/trailing spaces are 16/16, 26/26, and
  28/28px; icon-label spaces are current source-corrected 8/12/16px.
- Ordinary and extended FABs use primary-container/on-primary-container.
- Selected toggles interpolate to primary/on-primary, a 56px container, 28px
  full corner, and 20px icon. Medium/large retain an 80/96px initial footprint,
  with the selected visual logically aligned top-end.
- Small 40px FAB is omitted from T09's approved stable surface.

## States, elevation, and motion

- Enabled/disabled are native. Disabled removes elevation and uses on-surface
  container/content with 0.12/0.38 opacity.
- Hover, focus-visible, and pressed use corresponding system state opacities.
- Default shadow is Level 3 at rest/focus/press and Level 4 on hover. Lowered
  is Level 1 at rest/focus/press and Level 2 on hover. `none` resolves Level 0.
- First-party toggle elevation is fixed at Level 3; its public type rejects the
  ordinary elevation prop and runtime warns untyped callers.
- Extended width uses Expressive fast-spatial while label opacity uses
  fast-effects. Toggle size/shape/icon use fast-spatial; color/state opacity use
  fast-effects. Shadow changes use default-effects. Reduced motion removes all
  transitions without removing state.
- Selected and expanded are applicable. Checked, indeterminate, error, dragged,
  and loading are not FAB states.

## Component token mapping

- Global: minimum target, focus ring, ordinary/selected/disabled colors and
  disabled opacities.
- Per size: container size/shape, icon size, extended leading/trailing space,
  and corrected icon-label space.
- Toggle final: container size/shape and icon size.
- Elevation: normal and lowered rest/hover/focus/press shadows plus Level 0.

All values live in the T09 `floating-action-button` registration. Production
CSS checks require every literal custom-property reference to resolve.

## DOM, forms, and behavior

- Default DOM starts with `<button type="button" class="m3e-fab"
  data-m3e-size="standard" data-m3e-elevation="default"
  data-m3e-extended="false" data-m3e-toggle="false"
  data-m3e-disabled="false">`.
- Submit/reset, form owner, name/value, descriptions, IDs, consumer data,
  class/style, button handlers, and the HTML button ref are forwarded.
- Controlled selection never mirrors into local state. Uncontrolled selection
  initializes deterministically from `defaultSelected`.
- Consumer `onClick` runs first. `preventDefault()` cancels internal selection
  and `onSelectedChange`; otherwise one activation produces one state request.
- Server markup and hydration are deterministic and inject no styles.

## Accessible name, role, state, and keyboard

- Native button semantics supply the role; no redundant role or tab index is
  added. Native Enter and Space activate once; disabled prevents activation and
  sequential focus.
- Icon-only momentary and toggle FABs require non-empty `aria-label` or
  `aria-labelledby`. Extended label content supplies the accessible name.
- Icon artwork is always hidden, preventing third-party Icons from adding image
  roles or duplicate names.
- Momentary mode omits `aria-pressed`. Toggle mode exposes boolean
  `aria-pressed` and a stable name while state changes.

## Bidirectional, forced-color, and adaptive behavior

- Sizing and spacing use logical block/inline properties. Toggle selection
  aligns to logical top-end, so RTL changes its horizontal edge automatically.
- Extended labels can collapse and consumer layout can wrap. The control owns
  no viewport positioning or safe-area behavior.
- Forced colors uses ButtonFace/ButtonText, Highlight/HighlightText for
  selected, GrayText for disabled, a visible outline, and no translucent state
  layer or authored shadow.
- Default, custom, and nested themes scope FAB and derived motion values.

## Web-specific deviations

- Compose publishes separate FAB, extended FAB, and toggle FAB composables.
  This library uses one discriminated component whose `label` selects extended
  layout and `toggle={true}` selects icon-only toggle state.
- Compose requires externally owned checked state. React also supports an
  uncontrolled toggle and selected artwork through the shared web state model.
- Compose toggle semantics uses a selectable primitive. Web follows the APG
  toggle-button contract on a native button and exposes `aria-pressed`.
- Compose can let a collapsed extended label leave semantics to icon content.
  Web keeps the label in the accessibility tree so its control name is stable.
- Compose accepts custom colors, shapes, callbacks, alignment, and progress
  functions. This library exposes searchable Material modes and theme tokens, keeping
  animation internals and invalid combinations out of public API.
- CSS consumes the existing deterministic spring projection rather than a
  client animation runtime or Compose physics.

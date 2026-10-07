# Surface conformance

Task: T04
Status: conformant
Reviewed: 2026-07-19

## Primary references

- AndroidX Material 3 `Surface` API, accessed 2026-07-19:
  <https://developer.android.com/reference/kotlin/androidx/compose/material3/Surface.composable>
- Pinned AndroidX `Surface.kt` revision, accessed 2026-07-19:
  <https://android.googlesource.com/platform/frameworks/support/+/0be207d91046b7376beeef5544d331a02d6fa87c/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/Surface.kt>
- AndroidX Material 3 `ColorScheme` role definitions, accessed 2026-07-19:
  <https://developer.android.com/reference/kotlin/androidx/compose/material3/ColorScheme>
- HTML semantics, accessed 2026-07-19:
  <https://html.spec.whatwg.org/multipage/sections.html>
- WCAG 2.2, accessed 2026-07-19:
  <https://www.w3.org/TR/WCAG22/>

Supported Material baseline: AndroidX Material 3 revision
`0be207d91046b7376beeef5544d331a02d6fa87c`, with the token defaults sourced
from Material Web 34.0.21 where the web token generation differs.

## Anatomy and slots

- One semantic container element.
- Consumer children form the content slot.
- Container background, inherited content color, clipping shape, tonal
  treatment, and projected shadow are applied to the same element.
- Surface provides no padding or layout recipe.

## Variants, sizes, widths, and color roles

- Default: `surface` / `onSurface`, rectangular, tonal level 0, shadow level 0.
- Surface hierarchy: `surface`, `surfaceDim`, `surfaceBright`, and container
  lowest/low/base/high/highest, all paired with `onSurface`.
- Accent hierarchy: primary, secondary, and tertiary base/container/fixed/fixed
  dim roles paired with the corresponding high-emphasis `on` role.
- Feedback and inverse: error/error-container and inverse-surface pairs.
- Surface has no intrinsic size or width. Native CSS/layout context owns both.
- Arbitrary background values are not variants; consumer inline or authored CSS
  may override presentation without changing the typed Material role contract.

## States

Surface is passive, so enabled, disabled, hovered, focused, pressed, selected,
checked, indeterminate, loading, dragged, and error states are not component
states. Error is available only as a semantic color role. Consumer event and
ARIA attributes are forwarded but never interpreted into a Surface state.

Interactive behavior belongs to Button, Card, and selection components. This
prevents a styled container from acquiring incomplete keyboard semantics.

## Shape and transitions

- All current system corner roles are exposed, including top-only, increased,
  full, and start/end shapes.
- The selected radius clips both background and descendant paint.
- Start and end shapes exchange their system values in RTL.
- Surface has no state transition and therefore no shape motion.

## Motion and user preferences

Surface performs no animation. Reduced motion requires no alternate outcome.
It does not disable forced-color adjustment, so user-agent forced colors remain
authoritative. There is no focus indicator because Surface is not focusable.

## Component token mapping

| Component token | Default system token |
| --- | --- |
| `container-color` | `sys.color.surface` |
| `content-color` | `sys.color.onSurface` |
| `container-shape` | `sys.shape.corners.cornerNone` |
| `container-shadow` | `sys.elevation.level0.shadow` |
| `tonal-overlay-opacity` | `sys.elevation.level0.tonalOverlayOpacity` |

Explicit color variants map to their `sys.color` container/content pair. Shape
variants map to `sys.shape.corners`; tonal and shadow levels independently map
to `sys.elevation.level{0..5}`. The registration source is pinned in the token
data and the generated properties are checked for unresolved references.

## DOM and native behavior

- Default DOM: `<div class="m3e-surface" ...>`.
- `as` supports `div`, `section`, `article`, `aside`, `main`, `header`, `footer`,
  and `nav`; native props and the ref narrow to that element.
- No wrapper, role, tab index, event handler, or accessible state is generated.
- Consumer class names, styles, IDs, native handlers, ARIA attributes, and data
  attributes are preserved. Internal visual data attributes have stable names.
- Server output is deterministic and hydrates without recoverable errors.

## Accessible name, role, state, and keyboard

- Default div Surface has no role or accessible name.
- A semantic element keeps its native role. Consumers provide landmark names
  with native heading relationships or `aria-label`/`aria-labelledby` when page
  context requires them.
- Surface has no accessible state and no keyboard interaction.
- Tab navigation skips a default Surface.
- Pointer handlers passed as native attributes are preserved, but consumers must
  not treat that forwarding as an accessible control implementation.

## Bidirectional and adaptive behavior

- Surface adds no physical margin, padding, sizing, or positioning.
- Start/end corner variants are direction-aware; other shapes are symmetric.
- The component has no breakpoint behavior. It follows the consumer's layout
  and remains valid in any container size.

## Web-specific deviations

- Compose draws into a graphics layer and exposes arbitrary `Shape`, `Color`,
  `Dp`, and border objects. The React API exposes finite validated Material roles
  and uses normal CSS overrides for application-specific presentation.
- Compose provides separate clickable/selectable/toggleable overloads. This library keeps
  Surface passive and delegates interaction to native-purpose components.
- Compose blocks touch propagation behind its drawn surface. A normal HTML
  element uses standard hit testing and does not install an event interceptor.
- Compose accumulates absolute tonal elevation through composition locals. The
  static web implementation uses explicit discrete levels per Surface; nested
  hierarchy should use surface-container roles or an explicit child level.
- The optional Compose border parameter is omitted from the foundation because
  borders are component-specific in the stable web scope; consumer CSS remains
  available for non-component layout decoration.

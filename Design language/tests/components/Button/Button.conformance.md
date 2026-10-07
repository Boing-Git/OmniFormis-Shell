# Button conformance

Task: T07
Status: conformant
Reviewed: 2026-07-19

## Primary references

- AndroidX Material 3 `ButtonDefaults`, including current Expressive sizes,
  content padding, icon metrics, type selection, resting shapes, and pressed
  shapes, accessed 2026-07-19:
  <https://developer.android.com/reference/kotlin/androidx/compose/material3/ButtonDefaults>
- Android Compose Button guide and the five emphasis variants, accessed
  2026-07-19:
  <https://developer.android.com/develop/ui/compose/components/button>
- Pinned current AndroidX Material 3 `Button.kt`, including Expressive overloads
  and `DefaultEffects` pressed-shape animation, accessed 2026-07-19:
  <https://android.googlesource.com/platform/frameworks/support/+/dd849e200f5046c2f2ca904e821fc9d42cbd0256/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/Button.kt>
- Pinned generated AndroidX Button size and variant token directory, accessed
  2026-07-19:
  <https://android.googlesource.com/platform/frameworks/support/+/dd849e200f5046c2f2ca904e821fc9d42cbd0256/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/>
- Material minimum interactive component size API, accessed 2026-07-19:
  <https://developer.android.com/reference/kotlin/androidx/compose/material3/package-summary#minimumInteractiveComponentSize()>
- HTML button element, including form, activation, disabled, and default type
  behavior, accessed 2026-07-19:
  <https://html.spec.whatwg.org/multipage/form-elements.html#the-button-element>
- CSS linear easing function, used for the deterministic spring projection,
  accessed 2026-07-19:
  <https://www.w3.org/TR/css-easing-2/#the-linear-easing-function>
- WCAG 2.2 focus visible, target size, contrast, and reflow criteria, accessed
  2026-07-19:
  <https://www.w3.org/TR/WCAG22/>

Supported Material baseline: AndroidX Material 3 revision
`dd849e200f5046c2f2ca904e821fc9d42cbd0256`, whose current Button Expressive
surface is marked experimental upstream, adapted to native HTML button and CSS
semantics.

## Anatomy and slots

- One semantic native `button` root owns form behavior, focus, activation,
  disabled state, accessible naming, native consumer props, stable state data,
  layout target, and the forwarded ref.
- One visual container span owns background, outline, elevation, state layer,
  resting/pressed corner shape, padding, and visual minimum height.
- One public `Text` span owns the size-selected Material type role and label
  content.
- Optional leading and trailing visual spans are hidden from assistive
  technology and constrain icon artwork to sourced size metrics.
- There are no link, toggle, loading-indicator, menu, split, badge, or tooltip
  slots.

## Variants, sizes, widths, shapes, and color

- Variants: filled, filled tonal (`tonal`), elevated, outlined, and text.
- Sizes: extra-small 32px, small 40px, medium 56px, large 96px, and extra-large
  136px visual minimum heights.
- Default size is small, matching AndroidX Button. Every semantic root has a
  minimum 48px block and inline target. The visual container may be 32px or
  40px while the root reserves the larger hit area.
- Width: intrinsic `fit` default or containing-block `full`. Native class/style
  remains available for deliberate application layout.
- Shape: round or size-aware square resting shape. Round radii are exact half-
  height CSS values so they interpolate correctly; square and pressed shapes
  map to system corner roles.
- Filled maps primary/on-primary; tonal maps secondary-container/on-secondary-
  container; elevated maps surface-container-low/primary; outlined maps a
  transparent container with outline-variant and on-surface-variant; text maps
  transparent/on-surface-variant.
- Disabled roles and opacities follow each current generated variant token.
  Filled and elevated containers use on-surface at 10%; tonal uses on-surface at
  12%; all content uses its sourced role at 38%. Outlined border uses outline-
  variant at 10%.

## States

- Enabled: native default. Stable `data-m3e-disabled="false"` is present.
- Disabled: native `disabled` blocks activation and keyboard focus; the stable
  data value becomes `true` and state layer/elevation are absent.
- Hovered: state-layer opacity uses `sys.state.hover`; filled and tonal move
  from elevation level 0 to 1, elevated from 1 to 2.
- Focused: only `:focus-visible` renders the primary token-backed focus ring and
  `sys.state.focus` layer. Native focus itself is not suppressed.
- Pressed: native `:active` selects the size-aware pressed corner, source pressed
  elevation, and `sys.state.pressed` layer.
- Selected, checked, indeterminate, dragged, loading, and error are not Button
  states. They emit no corresponding ARIA or data state.

## Shape and motion

- Round resting radii: 16, 20, 28, 48, and 68px for extra-small through extra-
  large.
- Square resting roles: medium, medium, large, extra-large, and extra-large.
- Pressed roles: small, small, medium, large, and large.
- AndroidX explicitly selects `DefaultEffects` for Button pressed shape to
  prevent bounce. The token CSS serializer projects spring damping/stiffness
  into a settlement duration and ten-sample CSS `linear()` curve. It emits the
  derived pair for every standard/expressive, speed, and category slot so theme
  overrides remain deterministic and reusable.
- Button consumes `sys.motion.expressive.default.effects.duration/easing`. The
  default spring (damping 1, stiffness 1600) settles at 231ms in this web
  projection and has no overshoot.
- Reduced motion removes container and state-layer transitions. Resting and
  pressed states remain visually distinct with an immediate change.

## Component token mapping

- Global: minimum interactive target, 58px visual minimum width, focus ring
  color/width/offset.
- Per size: visual height, block/inline padding, icon size/spacing, round/square
  resting shape, pressed shape, and outline width.
- Per filled/tonal/elevated variant: enabled/disabled container and content
  colors, disabled opacities, default and hover shadow.
- Outlined: enabled/disabled content and outline roles/opacities.
- Text: enabled/disabled content role and disabled opacity.
- Typography is not duplicated as a Button component token. The internal public
  `Text` component consumes labelLarge for extra-small/small, titleMedium for
  medium, headlineSmall for large, and headlineLarge for extra-large.

All component values live in the T07 `button` registration. CSS tests and
distribution checks require literal namespaced references and reject unresolved
variables.

## DOM, form, and native behavior

- Default DOM starts with `<button type="button" class="m3e-button"
  data-m3e-variant="filled" data-m3e-size="small" data-m3e-width="fit"
  data-m3e-shape="round" data-m3e-disabled="false">`.
- Explicit native `submit` and `reset` types, name, value, form owner, disabled,
  ARIA descriptions, IDs, data props, class, style, and handlers are forwarded.
- The component does not synthesize pointer or key activation and does not call
  a consumer callback outside the normal native/React event path.
- The ref points to `HTMLButtonElement`. The root is not polymorphic and cannot
  become a link or non-interactive element.
- Server output is deterministic, hydration produces no recoverable error, and
  rendering injects no style element.

## Accessible name, role, state, and keyboard

- Native button semantics supply the role. No redundant role or tab index is
  added.
- Label content supplies the normal accessible name. Native `aria-label` and
  `aria-labelledby` remain supported; development warns when every naming path
  is empty.
- Leading/trailing wrappers use `aria-hidden="true"`, hiding even a mistakenly
  meaningful nested Icon so its label cannot duplicate the button name.
- Enter activates once while focused. Space activates once through native
  key-up behavior. Pointer click activates once. Disabled blocks each path.
- Icon-only naming is possible through native ARIA but is not the advertised
  Button recipe; T08 provides the purpose-built `IconButton` contract.

## Bidirectional, adaptive, forced-color, and zoom behavior

- Logical inline/block sizing and padding make the layout direction-neutral.
  Flex source order places leading at logical start and trailing at logical end
  without mutating DOM or accessible order under RTL.
- Labels can wrap and visual containers use minimum rather than fixed block
  size, preserving content at text zoom and narrow full-width layouts.
- Forced colors uses ButtonFace/ButtonText, GrayText for disabled, Highlight for
  focus, a visible border for every variant, no authored translucent state
  layer, and no shadow.
- Nested themes scope all component and derived motion custom properties.

## Web-specific deviations

- Compose exposes separate Button, FilledTonalButton, ElevatedButton,
  OutlinedButton, and TextButton composables. This library uses one named Button
  with a literal `variant` union to keep form behavior identical and the API
  searchable.
- Compose consumers select size, width, and square shape through modifier,
  padding, and shape objects. This library exposes bounded size/width/shape props and
  normal class/style layout escape hatches; arbitrary shape objects are not
  accepted.
- Compose places minimum-target expansion outside the measured visual. The web implementation
  uses the semantic root as that reserved target and an inner visual container,
  avoiding unsupported hit-area pseudo-element behavior.
- Compose animates a platform Shape using a finite spring spec. Web CSS cannot
  consume damping/stiffness directly, so the deterministic token serializer
  produces a settlement duration and sampled `linear()` curve from the same
  spring inputs with no runtime animation library.
- Native HTML defines `type`, forms, Enter/Space timing, disabled focus, and
  event objects. Those semantics override Compose callback conventions.

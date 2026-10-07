# IconButton conformance

Task: T08
Status: conformant
Reviewed: 2026-07-19

## Primary references

- AndroidX `IconButtonDefaults` API, including current Expressive size, width,
  icon, shape, and toggle-shape surface, accessed 2026-07-19:
  <https://developer.android.com/reference/kotlin/androidx/compose/material3/IconButtonDefaults>
- Pinned current AndroidX `IconButton.kt`, including native Material variants,
  action/toggle anatomy, minimum target, state semantics, and default-effects
  animation, accessed 2026-07-19:
  <https://android.googlesource.com/platform/frameworks/support/+/f0793303999c933a40c10d79212e0580d21bdc68/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/IconButton.kt>
- Pinned current AndroidX `IconButtonDefaults.kt`, accessed 2026-07-19:
  <https://android.googlesource.com/platform/frameworks/support/+/f0793303999c933a40c10d79212e0580d21bdc68/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/IconButtonDefaults.kt>
- Pinned generated AndroidX IconButton variant and size token directory,
  accessed 2026-07-19:
  <https://android.googlesource.com/platform/frameworks/support/+/f0793303999c933a40c10d79212e0580d21bdc68/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/>
- Material Web icon-button variants, explicit toggle/selected contract, selected
  visual slot, and naming guidance, accessed 2026-07-19:
  <https://material-web.dev/components/icon-button/>
- WAI-ARIA APG Button Pattern, including toggle-button `aria-pressed`, stable
  labels, Enter, and Space interaction, accessed 2026-07-19:
  <https://www.w3.org/WAI/ARIA/apg/patterns/button/>
- HTML button element, form, activation, disabled, and default type behavior,
  accessed 2026-07-19:
  <https://html.spec.whatwg.org/multipage/form-elements.html#the-button-element>
- WCAG 2.2 focus visible, target size, use of color, contrast, and reflow,
  accessed 2026-07-19:
  <https://www.w3.org/TR/WCAG22/>

Supported Material baseline: AndroidX Material 3 revision
`f0793303999c933a40c10d79212e0580d21bdc68`, whose current size/width/shape
surface remains experimental upstream, adapted to native HTML and ARIA toggle-
button semantics.

## Anatomy and slots

- One native button owns name, form behavior, activation, focus, disabled,
  `aria-pressed`, native props, data state, target sizing, and forwarded ref.
- One decorative visual container owns the background, outline, state layer,
  shape, fixed visual dimensions, and all icon content.
- The default visual slot is always present. An optional selected slot stays in
  source order and is selected by state without altering the accessible name.
- There are no text label, link, tooltip, badge, menu, loading, long-press, or
  FAB slots.

## Variants, dimensions, shape, and color

- Variants: standard, filled, filled tonal (`tonal`), and outlined.
- Sizes: extra-small, small, medium, large, and extra-large, with visual heights
  32/40/56/96/136px and icons 20/24/24/32/40px.
- Widths narrow/uniform/wide map by size to 28/32/48/64/104px,
  32/40/56/96/136px, and 40/52/72/128/184px respectively.
- Outline widths by size are 1/1/1/2/3px. Every root independently has a 48px
  minimum inline and block target.
- Resting shape is round or size-aware square. Pressed shape is size-aware.
  Toggle selection turns round toward its square corner role and square toward
  a full half-height radius.
- Standard uses transparent/on-surface-variant and selected primary content.
  Filled action uses primary/on-primary; an unselected filled toggle uses
  surface-container/on-surface-variant and selected uses primary/on-primary.
  Tonal uses secondary-container/on-secondary-container and selected uses
  secondary/on-secondary. Outlined uses outline-variant/on-surface-variant and
  selected inverse-surface/inverse-on-surface without a border.

## States and motion

- Enabled and disabled are native; `data-m3e-disabled` mirrors the boolean.
- Hover, focus-visible, and pressed use the system state opacity roles. Pressed
  changes to the sourced pressed shape and takes precedence over selected shape.
- Momentary mode has no selected state. Toggle mode exposes boolean
  `data-m3e-selected` and `aria-pressed` from controlled or uncontrolled state.
- Selected color, shape, and optional artwork change together. Forced colors
  uses Highlight plus the shape/artwork state, avoiding a color-only result.
- Indeterminate, checked, dragged, loading, and error are not IconButton states.
- Shape/color/state-layer transitions use
  `sys.motion.expressive.default.effects.duration/easing`. Reduced motion
  removes transitions without removing any state.

## Component token mapping

- Global: 48px minimum target and focus-ring color/width/offset.
- Per size: height, narrow/uniform/wide width, icon size, round/square resting
  shape, pressed shape, selected-round/selected-square shape, and outline width.
- Per variant: default/unselected/selected container and content roles as
  applicable, plus disabled content/container/outline roles.
- Shared disabled container, content, and outline opacities are 0.1, 0.38, and
  0.38.

All values live in the T08 `icon-button` registration. Production CSS checks
require every literal reference to resolve.

## DOM, forms, and behavior

- Default DOM starts with `<button type="button" class="m3e-icon-button"
  data-m3e-variant="standard" data-m3e-size="small"
  data-m3e-width="uniform" data-m3e-shape="round"
  data-m3e-toggle="false" data-m3e-disabled="false">`.
- Submit/reset, form owner, name/value, disabled, descriptions, IDs, consumer
  data, class, style, and relevant button handlers are forwarded.
- Controlled selection never mirrors into local state. Uncontrolled selection
  initializes deterministically from `defaultSelected`.
- Consumer `onClick` executes first. If it prevents default, internal selection
  and `onSelectedChange` do not run. Otherwise one native activation produces
  one callback and one uncontrolled mutation.
- Server rendering and hydration are deterministic and inject no styles.

## Accessible name, role, state, and keyboard

- Native button semantics supply the role; no redundant role or tab index is
  added.
- A non-empty `aria-label` or `aria-labelledby` is required. Development warns
  when neither exists.
- The visual container is `aria-hidden`, so nested default and selected Icons
  never add image roles or duplicate names.
- Toggle mode uses boolean `aria-pressed`; momentary mode omits it. The label
  remains stable as recommended by the APG toggle-button pattern.
- Enter and Space activate exactly once through native behavior. Disabled
  blocks activation and sequential focus.

## Bidirectional, forced-color, and adaptive behavior

- All component dimensions use inline/block logical properties and contain no
  physical left/right sizing. Directional artwork opts into Icon mirroring.
- Fixed visual geometry follows Material, while the semantic root expands to
  the target and normal consumer layout may wrap controls.
- Forced colors uses ButtonFace/ButtonText, Highlight/HighlightText for
  selected, GrayText for disabled, a visible size-aware border, and no authored
  translucent state layer.
- Nested themes scope component and derived motion values independently.

## Web-specific deviations

- Compose publishes separate action/toggle and emphasis composables. This library
  uses one discriminated component: `toggle={true}` enables selected props,
  while a literal variant chooses emphasis.
- Compose toggle semantics currently assigns a checkbox role. This library follows
  the APG toggle-button pattern on its native button and uses `aria-pressed`.
- Compose takes modifiers, `DpSize`, and Shape objects. React exposes bounded,
  searchable size/width/shape props plus normal class/style layout hooks.
- Compose content can branch on externally owned checked state. This library also
  supports uncontrolled state and therefore offers an optional selected visual
  slot, aligned with Material Web.
- Compose expands a minimum target around the measured visual. This library reserves
  that target on the semantic root and centers the sourced visual container.
- CSS consumes the deterministic spring projection established by T07 rather
  than running Compose shape physics or a client animation runtime.

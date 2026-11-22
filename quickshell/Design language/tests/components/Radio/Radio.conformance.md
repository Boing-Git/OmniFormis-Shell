# Radio conformance

Task: T12
Status: conformant
Reviewed: 2026-07-20

## Primary references

- AndroidX Material 3 RadioButton component guide, accessed 2026-07-20:
  <https://developer.android.com/develop/ui/compose/components/radio-button>
- Pinned current AndroidX `RadioButton.kt`, including `RadioButton`,
  `RadioButtonColors`, `RadioButtonDefaults`, `radioColor`, and the geometry
  and animation constants, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/RadioButton.kt>
- Pinned generated AndroidX `RadioButtonTokens` (`VERSION: v0_117`), accessed
  2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/RadioButtonTokens.kt>
- HTML radio button state, native grouping, form participation, and
  activation behavior, accessed 2026-07-20:
  <https://html.spec.whatwg.org/multipage/input.html#radio-button-state-(type=radio)>
- WAI-ARIA APG Radio Group Pattern, including roving tabindex and arrow-key
  behavior, accessed 2026-07-20:
  <https://www.w3.org/WAI/ARIA/apg/patterns/radio/>
- WCAG 2.2 focus visible, target size, contrast, use of color, and reduced
  motion, accessed 2026-07-20:
  <https://www.w3.org/TR/WCAG22/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`, `RadioButton.kt` blob
`02bdd9c675137bb277e454b21ffec58fc4ff6dfb`, `RadioButtonTokens.kt` blob
`9c3d1a69f1dada4962d9f3f68a40a36f26824683`, adapted to the native HTML radio
control.

## Anatomy and content

- One radio root owns the 48px interaction target, the resolved state
  attributes, the consumer class and style, and the layout box.
- One native `input type="radio"` owns semantics, focus, activation,
  grouping, forms, disabled state, and the forwarded ref. It covers the whole
  target and is visually transparent.
- One decorative container owns the 20px circle and the inset outline ring.
  One decorative inner element owns the selected dot.
- Radio owns no label, supporting text, error text, or layout of adjacent
  content. The pinned first-party API has no label parameter either.

## Variants, shape, color, and size

- The pinned API has no variant, size, or error parameter, so this component
  ships exactly one form.
- Geometry: 20px container (`RadioButtonTokens.IconSize`), 2px ring stroke
  (`RadioStrokeWidth`), 10px drawn dot diameter (`RadioButtonDotSize / 2 -
  RadioStrokeWidth / 2`, doubled), 40px state layer
  (`RadioButtonTokens.StateLayerSize`).
- The source paints the outer ring and the inner dot with the same
  `radioColor` value, so one icon-color role covers both per state instead of
  separate ring/dot roles.
- `RadioButtonTokens` also generates `SelectedFocusIconColor`,
  `SelectedHoverIconColor`, `SelectedPressedIconColor`, and their unselected
  counterparts. `RadioButtonColors`/`radioColor()` never read them, so they
  are not registered, matching the Checkbox precedent for unread roles.
- Disabled roles apply the sourced 0.38 opacity to both the selected and
  unselected icon color, kept as two separate tokens because the source reads
  them from two different constants (`DisabledSelectedIconOpacity` and
  `DisabledUnselectedIconOpacity`) even though their resolved values are
  currently identical.

## States and motion

- Enabled, disabled, hovered, focused, pressed, checked, and unchecked are
  implemented. Selected-as-a-distinct-state, loading, and error are not
  first-party RadioButton states and are not claimed.
- Hover, focus, and pressed use system state opacity on the 40px circular
  layer.
- The dot's `animateDpAsState` scale-in/out reproduces onto a CSS `transform:
  scale()` transition over Expressive fast-spatial motion, matching
  `MotionSchemeKeyTokens.FastSpatial`.
- `radioColor()` animates the shared icon color over Expressive default
  effects motion (`MotionSchemeKeyTokens.DefaultEffects`) while enabled, and
  reads `rememberUpdatedState` instead while disabled, snapping immediately
  with no transition. The web control reproduces this exact asymmetry: the
  dot's scale transition is unconditional; the icon color transition is
  removed only while `data-m3e-disabled="true"`.
- Reduced motion removes both the scale and color transitions and preserves
  the resolved state immediately.

## Component token mapping

- Geometry: minimum target, container size, outline width, dot size, and
  state-layer size.
- Color: selected and unselected icon color (shared by ring and dot);
  disabled-selected and disabled-unselected icon color with their separate
  opacities; selected and unselected state-layer color; and the focus ring.

All values live in the T12 `radio` registration. Production CSS validation
requires every literal `--m3e-comp-radio-*` reference to resolve.

## DOM, forms, and behavior

- Rendered DOM starts with `<span class="m3e-radio" data-m3e-state="unchecked"
  data-m3e-disabled="false">` wrapping `<input type="radio"
  class="m3e-radio__input">`.
- `name` is a required prop, not an optional pass-through: a nameless radio
  cannot form a native group, and grouping is this task's required result.
- Visual state is driven entirely by the input's own `:checked`/`:disabled`
  pseudo-classes, not by the `data-m3e-state`/`data-m3e-disabled` attributes
  the root still carries for deterministic server markup. A native radio can
  become unchecked purely as a side effect of a sibling in the same `name`
  group being checked, and the browser fires no event on this element when
  that happens, so an attribute driven by this component's own React state
  would go stale for that sibling; `:checked` stays correct because the
  browser, not this component's re-render, owns it.
- `value`, `form`, `required`, `id`, ARIA and data attributes, native
  handlers, and the `HTMLInputElement` ref are forwarded to the input.
  `className` and `style` describe the root.
- Controlled `checked` stays authoritative; uncontrolled `defaultChecked`
  leaves checkedness to the DOM, including native mutual exclusivity inside
  the shared `name` group. Native form reset restores the default and
  resynchronizes the resolved visual state for every radio in the group.
- `onChange` runs before the library updates state, and `preventDefault()`
  cancels that update.
- Server markup and hydration are deterministic and inject no styles.

## Accessible name, description, role, state, and keyboard

- The native radio role, checked state, required state, and name come from
  the platform. Wrapping `label`, `label for`, `aria-label`, and
  `aria-labelledby` all work; the component adds no naming of its own.
- Space activates the focused, unchecked radio through the browser. Arrow
  keys move focus and selection to the adjacent radio inside the same native
  `name` group; this is entirely native behavior, so the component adds no
  keyboard handling of its own. No key handler is added, and Enter does not
  activate a radio.
- Disabled inputs do not activate and leave sequential focus.

## Bidirectional, forced-color, and adaptive behavior

- Layout uses logical inline and block sizing. The state layer centres
  through `inset: 0` with automatic margins so it does not depend on writing
  direction.
- Forced colors keeps the ring outline, uses CanvasText for unselected and
  Highlight for selected ring/dot, and GrayText for disabled treatment, while
  removing the translucent state layer.
- Default, custom, and nested themes scope every Radio variable.

## Web-specific deviations

- Compose names the parameters `selected`/`onClick`. The web control is a
  native input whose IDL property is literally `checked`, and this library's
  sibling `Checkbox` already established `checked`/`onCheckedChange` for a
  native boolean form control, so Radio matches that shape instead of
  Compose's naming.
- The pinned `ripple()` call passes no explicit per-state color, so its
  resolved tint is ambient `LocalContentColor`, not `radioColor`. The web
  state layer uses the same-state sourced icon-color role instead, so hover,
  focus, and pressed feedback stay perceivable and state-dependent, matching
  the Checkbox precedent for its unchecked state layer.
- The source defines no RadioButton focus-indicator token. The web control
  draws a token-backed focus ring from the secondary role, matching the
  Checkbox precedent, because visible focus is required.
- `RadioGroup`-style parent orchestration is not implemented; native grouping
  through a shared `name` already provides mutual exclusivity and roving
  keyboard focus without a wrapper component.

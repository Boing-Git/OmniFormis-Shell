# TextField conformance

Task: T14
Status: conformant
Reviewed: 2026-07-21

## Primary references

- AndroidX Material 3 Text fields component guide, accessed 2026-07-20:
  <https://developer.android.com/develop/ui/compose/components/text-fields>
- Pinned current AndroidX `TextField.kt`/`OutlinedTextField.kt`/
  `TextFieldDefaults.kt`/`internal/TextFieldImpl.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/TextField.kt>
- Pinned generated AndroidX `FilledTextFieldTokens`/`OutlinedTextFieldTokens`,
  accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/FilledTextFieldTokens.kt>
- Pinned first-party Material Web outlined-field layout, accessed 2026-07-20:
  <https://github.com/material-components/material-web/blob/b4de401eb665ec63474f39319a4ba8f2145974cc/field/internal/_outlined-field.scss>
- Pinned first-party Material Web shared field template and start/middle/end
  content layout, accessed 2026-07-21:
  <https://github.com/material-components/material-web/blob/b4de401eb665ec63474f39319a4ba8f2145974cc/field/internal/field.ts>
  and
  <https://github.com/material-components/material-web/blob/b4de401eb665ec63474f39319a4ba8f2145974cc/field/internal/_content.scss>
- WCAG 2.2 focus visible, target size, labels/descriptions, and reduced
  motion, accessed 2026-07-20:
  <https://www.w3.org/TR/WCAG22/>
- WAI-ARIA APG form-field labeling guidance, accessed 2026-07-20:
  <https://www.w3.org/WAI/ARIA/apg/practices/names-and-descriptions/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`. `FilledTextFieldTokens.kt` blob
`431029bad8804cec683c3077744f8783ca0ced56`, `OutlinedTextFieldTokens.kt` blob
`13f1d6b644376e767ea30def343065ccc274f6ce`, `TextField.kt` blob
`8ab78a33b00ae71c95b3365a499d8e3ba3a44c6b`, `OutlinedTextField.kt` blob
`2ab214785791a321fb4902b1b52598370c8e4675`, `TextFieldDefaults.kt` blob
`5de6b4accca335b84cd4b10dd808940b0fed9667`, adapted to a native `input`
associated with a native `label`.

This revision is a recent, Expressive-era snapshot noticeably ahead of public
documentation: it introduces experimental `styleable {}`-DSL styling, a
`TextFieldLabelPosition` sealed type (`Inside`/`Cutout`/`Above`, plus
deprecated `Attached`), and provisional Expressive additions
(`roundedShape`, `tonalColors()`) explicitly marked
`TODO(b/448727879): reference the actual token once it is in place`. Those
provisional additions are out of scope here; see Web-specific deviations.

## Anatomy and content

- One field root owns the resolved variant/error/disabled attributes, the
  consumer class and style, and the layout box.
- One native `input` (`TextField`) or `textarea` (`TextArea`) owns
  semantics, focus, typing, forms, disabled state, and the forwarded ref,
  built on a shared internal `TextFieldChrome` primitive — the direct web
  equivalent of the one decoration layer the pinned source itself reuses for
  both single- and multi-line fields (there is no separate multiline
  composable upstream).
- One `label`, associated through `htmlFor`/`id`, floats between a large
  resting position/type size and a small top-aligned position/type size.
- One optional supporting/error text block, associated through
  `aria-describedby`.
- Optional leading/trailing icon slots.
- Filled adds one bottom indicator line. Outlined adds one bordered,
  label-notched container built from three intrinsic-width CSS flex panels.
- The field's horizontal layout has three logical grid regions: a 16px ordinary
  start/end region or a 52px icon-bearing region (48px interactive target plus
  4px gap), with the native control confined to the middle. A transparent
  associated label behind the control preserves whole-field click-to-focus.
- Its block layout has three structural rows too. Filled uses 24/24/8px, where
  the first row contains the 8px top inset plus minimized 16px label;
  outlined uses 16/24/16px. The native control occupies only the middle row,
  so neither placement depends on native-control padding.

## Variants, shape, color, and size

- `variant`: `filled` (default) and `outlined`, matching the pinned
  `TextField`/`OutlinedTextField` defaults. `Above`, deprecated `Attached`,
  and the provisional Expressive `roundedShape`/`tonalColors()` are not
  claimed.
- Geometry: 56×280px minimum field size (already well above the 48×48
  target rule, which the pinned source itself only applies to the icon
  slots, not the field), filled uses a top-only-rounded container, outlined
  uses a fully rounded container.
- Horizontal content begins at 16px without a leading icon and 52px with one;
  trailing content reserves the symmetric end region. These offsets belong to
  the field grid rather than native-control padding, matching the source's
  separately measured icon/control placeables and Material Web's distinct
  start/middle/end regions.
- Filled minimized-label and input line boxes meet exactly at 24px, matching
  `TextFieldWithLabelVerticalPadding + labelPlaceable.height` in the pinned
  measure policy; no additional visual gap is invented. Outlined centers the
  24px input row between its two 16px content insets. Explicit grid rows retain
  both relationships under unlayered input/textarea padding resets.
- Every content color role — input, placeholder, label (resting/focus/
  error/disabled), leading icon, trailing icon, and supporting text — is
  identical between `FilledTextFieldTokens` and `OutlinedTextFieldTokens`;
  Kotlin has no shared-token-file mechanism, so AndroidX repeats each
  constant under both names. This registration keeps one unprefixed copy of
  each instead of a `filled-*`/`outlined-*` pair that would only ever hold
  identical values. Only the container fill/shape and the indicator/outline
  border itself are registered per variant.
- Every `Hover*`-suffixed role in both token files is unread:
  `TextFieldColors`' accessors take only `(enabled, isError, focused)`, so
  there is no fourth "hovered" axis anywhere in the resolved color model.
  Matches the unread-role precedent from Checkbox, Radio, and Switch.
- `FilledTextFieldTokens.DisabledContainerColor`/`DisabledContainerOpacity`
  are unread: `defaultTextFieldColors()` resolves the filled container to
  the same full-opacity `ContainerColor` in every state including disabled.
  This port reproduces that actual behavior rather than the token file's
  documented, unapplied dimmed value.

## States and motion

- Enabled, disabled, focused, has-value, and error are implemented. Hover
  has no color treatment in the pinned source (see above) and none is
  added.
- The label's floating position and type size are read from the input's
  own `:focus`/`:placeholder-shown` pseudo classes, not React-rendered
  state, so a value change made outside a normal input event — browser
  autofill, a form reset, an imperative ref write — still repositions the
  label correctly. This is the same native-truth precedent ADR 0012
  established for Radio's checked state, extended here from a discrete
  boolean to a continuous has-value signal.
- The label's type size transitions between the theme's own baseline
  body-large and body-small typescale roles — the same two roles the
  pinned source's own `lerp(bodyLarge, bodySmall, progress)` interpolates
  between — rather than a scale transform, keeping the relationship between
  the theme's typography tokens and the rendered label visible in the
  stylesheet.
- The filled indicator's color follows the same disabled/error/focused
  priority every other content role uses, but its width is driven
  independently by raw focus state alone, matching the pinned source
  animating indicator thickness and indicator color as two separate
  `Animatable`s: an error field that gains focus still thickens to 2px.
- Reduced motion removes every transition and preserves the resolved state
  immediately.

## Component token mapping

- Shared content roles: input, caret (base and error), placeholder, label
  (base/focus/error/disabled), leading icon (base/disabled), trailing icon
  (base/error/disabled), and supporting text (base/error/disabled).
- Filled-specific: container color/shape, indicator color
  (base/focus/error/disabled) and height (base/focus).
- Outlined-specific: container shape, outline color
  (base/focus/error/disabled) and width (base/focus/disabled).
- Shared layout: minimum interactive target, minimum container size,
  content padding, icon-content gap, and supporting-text top gap — mirrored
  from `TextFieldDefaults`' own named `Dp` constants, not a per-token-file
  source.

All values live in the T14 `text-field` registration, shared by `TextField`
and `TextArea`. Production CSS validation requires every literal
`--m3e-comp-text-field-*` reference to resolve.

## DOM, forms, and behavior

- Rendered DOM: `<span class="m3e-text-field" data-m3e-variant data-m3e-error
  data-m3e-disabled data-m3e-multiline>` wrapping `<span class="m3e-text-field__field">`,
  which contains the native control first (required so every sibling can
  read its pseudo-class state through a plain CSS combinator), then the
  visible `label`, indicator or outline, icons, and an empty `aria-hidden`
  native-label hit target. The field is a three-track logical grid; the control
  occupies the middle while the hit target covers the complete box behind it.
  Supporting text is a final sibling of the field outside that box, matching
  the pinned source laying it out beneath the container rather than inside it.
- `error` and `disabled` are mirrored onto the root as `data-m3e-*`
  attributes because they are the only two states with no signal reachable
  by a plain sibling combinator from the control — `error` has no native
  HTML equivalent, and supporting text sits one branch away from the
  control. Both are safe as React-rendered attributes because neither can
  change without this component re-rendering, unlike Radio's checked state.
- Focus and has-value state are never mirrored this way; they are read
  directly off the control's own `:focus`/`:placeholder-shown`.
- A non-empty native `placeholder` (a single space when the caller supplies
  none) is what makes `:placeholder-shown` a reliable has-value signal
  regardless of how the value changed; its color stays transparent except
  while focused, reproducing the pinned source showing its own placeholder
  slot only once the label has floated.
- `name`, `value`/`defaultValue`, `form`, `required`, `id`, ARIA and data
  attributes, native handlers, and the element ref are forwarded to the
  control. `className` and `style` describe the root. Value state is left
  entirely to native controlled/uncontrolled `input`/`textarea` behavior;
  neither component owns derived value state, so React's own dev warnings
  for conflicting `value`/`defaultValue` already apply with no duplicate
  warning added here.
- Server markup and hydration are deterministic and inject no styles.

## Accessible name, description, role, state, and keyboard

- The label is a native `label` associated through `htmlFor`/`id`,
  generated with `useId()` when the caller supplies none. External label
  association (`label for` pointing at a caller-supplied `id`) also works.
- The second, empty label is `aria-hidden` and contributes no accessible-name
  content; it only forwards pointer activation from the field's non-control
  start/end regions to the same native input.
- `aria-describedby` composes a caller-supplied value with the generated
  supporting-text id rather than replacing either.
- `error` sets `aria-invalid="true"` unless the caller already set their own
  `aria-invalid`, reproducing the pinned source's generic
  `defaultErrorSemantics` a11y-only affordance without inventing new
  supporting-text content.
- Typing, selection, and caret behavior are entirely browser-owned; no key
  handler is added. Disabled fields do not accept input and leave sequential
  focus.

## Bidirectional, forced-color, and adaptive behavior

- Layout uses logical inline/block sizing throughout, so the start/content/end
  tracks, segmented notch, icon slots, label position, and 4px icon gap all
  mirror correctly in RTL.
- Forced colors keeps the field boundary, uses Highlight for focus and
  GrayText for disabled treatment, and fixes text/icon color to CanvasText.
- Default, custom, and nested themes scope every TextField/TextArea
  variable.

## Web-specific deviations

- The pinned source draws the outlined notch by rendering a full border and
  then clipping a label-width rectangle out of it with a `drawWithContent`,
  difference-mode clip. The web control follows Material Web's first-party
  adaptation instead: three logical flex panels draw the border, a hidden
  body-small label clone intrinsically sizes the center panel, and that
  panel's top stroke scales away for the populated/focused gap. This avoids
  canvas and JS measurement while keeping the painted border and visible
  label in one coordinate system.
- AndroidX measures and places icon and text-control content separately, while
  Material Web renders explicit start/middle/end regions inside Shadow DOM.
  This light-DOM React adaptation uses equivalent logical grid tracks and an
  empty associated-label hit target. It does not depend on Shadow DOM or JS
  focus forwarding, and it avoids using native-control inline padding as the
  icon collision boundary.
- The pinned source's disabled colors already resolve as true alpha
  (`fromToken(...).copy(alpha = ...)`), not the fixed-backdrop
  `compositeOver(colorScheme.surface)` pattern seen in Checkbox, Radio, and
  Switch. This port's `color-mix(..., transparent)` technique is therefore
  not a deviation here — it reproduces the pinned source's own semantics
  exactly, rather than correcting away from a baked-backdrop assumption.
- The label's continuous, spring-driven `TextStyle` interpolation
  (`lerp(bodyLarge, bodySmall, progress)`) is reproduced as a CSS transition
  between the same two typescale roles' concrete font-size/line-height/
  letter-spacing values, using the theme's own semantic fast-spatial motion
  token in place of the spring, consistent with how every other component's
  spring motion is flattened to a duration/easing pair at this layer.
- `TextFieldLabelPosition.Above`, deprecated `Attached`, the provisional
  Expressive `roundedShape`/`tonalColors()` (marked `TODO(b/448727879)` in
  the pinned source itself, with no shipped token yet), prefix/suffix slots,
  and a character counter (the pinned source defines none) are not claimed.

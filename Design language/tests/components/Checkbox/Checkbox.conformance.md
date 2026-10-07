# Checkbox conformance

Task: T11
Status: conformant
Reviewed: 2026-07-19

## Primary references

- AndroidX Checkbox component guide, accessed 2026-07-19:
  <https://developer.android.com/develop/ui/compose/components/checkbox>
- Pinned current AndroidX `Checkbox.kt`, including the `Checkbox` and
  `TriStateCheckbox` overloads, `CheckboxColors`, `defaultCheckboxColors`,
  `indicatorColor`, `drawCheck` geometry, and the transition specs, accessed
  2026-07-19:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/Checkbox.kt>
- Pinned generated AndroidX `CheckboxTokens` (`VERSION: 14_1_0`), accessed
  2026-07-19:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/CheckboxTokens.kt>
- HTML checkbox state, form participation, indeterminate property, and
  activation behavior, accessed 2026-07-19:
  <https://html.spec.whatwg.org/multipage/input.html#checkbox-state-(type=checkbox)>
- ARIA in HTML `aria-checked="mixed"` on a checkbox input, accessed 2026-07-19:
  <https://www.w3.org/TR/html-aria/>
- WAI-ARIA APG Checkbox Pattern, including tri-state behavior, accessed
  2026-07-19:
  <https://www.w3.org/WAI/ARIA/apg/patterns/checkbox/>
- WCAG 2.2 focus visible, target size, contrast, use of color, and reduced
  motion, accessed 2026-07-19:
  <https://www.w3.org/TR/WCAG22/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`, `Checkbox.kt` blob
`a8cb1c1edcbb50bcb4fe82dc2051b9656ee173a7`, `CheckboxTokens.kt` blob
`90342356e6b7aa7571f15fb895c29900db75749b`, adapted to the native HTML checkbox
control.

## Anatomy and content

- One checkbox root owns the 48px interaction target, the resolved state
  attributes, the consumer class and style, and the layout box.
- One native `input type="checkbox"` owns semantics, focus, activation, forms,
  disabled state, and the forwarded ref. It covers the whole target and is
  visually transparent.
- One decorative container owns the 18px box, the inset outline, and the
  40px circular state layer. One decorative SVG owns the checkmark polyline.
- Checkbox owns no label, supporting text, error text, or layout of adjacent
  content. The pinned first-party API has no label parameter either.

## Variants, shape, color, and size

- The pinned API has no variant, size, or error parameter, so this component
  ships exactly one form. `CheckboxTokens` defines 14 `*Error*` roles, but
  `Checkbox.kt` never reads them and no error state is claimed.
- Geometry follows the token-backed path that the source selects when
  `ComposeMaterial3Flags.isCheckboxStylingFixEnabled` is enabled: 18px
  container, 2px corner, 2px outline, 2px checkmark stroke, 40px state layer.
  AndroidX still ships that flag disabled, which yields a 20dp box inside 2dp
  padding and a slightly different checkmark; the open upstream `TODO(b/188529841)`
  covers that constant.
- Colors implement all thirteen first-party roles. Checked and indeterminate
  share the checked box and border colors because the source differentiates
  indeterminate only in its disabled roles. The unchecked checkmark, unchecked
  box, and disabled unchecked box are `Color.Transparent` literals in the source
  and are expressed as CSS `transparent` rather than as unthemed variables.
- Disabled roles apply the sourced 0.38 opacity to the checked box, both
  disabled borders, and the indeterminate box. `disabledCheckmarkColor` is the
  one disabled role the source leaves at full opacity.

## States and motion

- Enabled, disabled, hovered, focused, pressed, checked, unchecked, and
  indeterminate are implemented. Selected, loading, and error are not first-party
  Checkbox states and are not claimed.
- Hover, focus, and pressed use system state opacity on the 40px circular layer.
- The checkmark reveal maps the source's `PathMeasure.getSegment` draw onto a
  stroke dash reveal over Expressive default-spatial motion. Leaving the drawn
  states reproduces `snap(delayMillis = 100)` as a zero-duration transition after
  the same 100ms delay rather than reversing the draw.
- The indeterminate dash reproduces `checkCenterGravitationShiftFraction`
  exactly: the cross point moves from (0.40, 0.65) to (0.50, 0.50) and the end
  point's Y moves from 0.30 to 0.50, while both end X coordinates stay fixed.
  Expressed on the 18px container these are `M 4.5 9 L 7.2 11.7 L 13.5 5.4` and
  `M 4.5 9 L 9 9 L 13.5 9`.
- The sourced springs map onto this library's Expressive scheme without
  substitution: default spatial 0.8/380, default effects 1.0/1600, and fast
  effects 1.0/3800 are identical values.
- Reduced motion removes the reveal, morph, and color transitions and preserves
  the resolved state immediately.

## Component token mapping

- Geometry: minimum target, container size, container shape, outline width,
  state-layer size, checkmark stroke width, checkmark path length, and the
  checkmark snap delay.
- Color: checked and disabled checkmark; checked, disabled-checked, and
  disabled-indeterminate containers; checked, unchecked, disabled-checked,
  disabled-unchecked, and disabled-indeterminate outlines; checked and unchecked
  state layers; and the focus ring.
- Opacity: separate disabled-checked, disabled-unchecked, and
  disabled-indeterminate values, kept distinct because the source reads them from
  two different token constants.

All values live in the T11 `checkbox` registration. Production CSS validation
requires every literal `--m3e-comp-checkbox-*` reference to resolve.

## DOM, forms, and behavior

- Rendered DOM starts with `<span class="m3e-checkbox" data-m3e-state="unchecked"
  data-m3e-disabled="false">` wrapping `<input type="checkbox"
  class="m3e-checkbox__input">`.
- `name`, `value`, `form`, `required`, `id`, ARIA and data attributes, native
  handlers, and the `HTMLInputElement` ref are forwarded to the input.
  `className` and `style` describe the root.
- Controlled `checked` stays authoritative; uncontrolled `defaultChecked` leaves
  checkedness to the DOM. Native form reset restores the default and
  resynchronizes the resolved visual state.
- `onChange` runs before the library updates state, and `preventDefault()`
  cancels that update.
- `indeterminate` is reapplied after every commit because the browser clears the
  property on activation and never serializes it.
- Server markup and hydration are deterministic and inject no styles.

## Accessible name, description, role, state, and keyboard

- The native checkbox role, checked state, required state, and name come from
  the platform. Wrapping `label`, `label for`, `aria-label`, and
  `aria-labelledby` all work; the component adds no naming of its own.
- Indeterminate exposes `aria-checked="mixed"` so server markup and
  post-hydration assistive output agree before the DOM property can be set.
- Space activates through the browser. No key handler is added, and Enter does
  not activate a checkbox.
- Disabled inputs do not activate and leave sequential focus.

## Bidirectional, forced-color, and adaptive behavior

- Layout uses logical inline and block sizing. The state layer centres through
  `inset: 0` with automatic margins so it does not depend on writing direction.
- Forced colors keeps the box outline, uses Highlight for the checked container
  and focus ring, Canvas for the checkmark, and GrayText for disabled treatment,
  while removing the translucent state layer.
- Default, custom, and nested themes scope every Checkbox variable.

## Web-specific deviations

- Compose exposes `Checkbox` and `TriStateCheckbox`. The web control is one
  native input whose `indeterminate` prop covers the tri-state overload, because
  HTML models mixed state as a property on the same element.
- Compose's `onClick`/`onCheckedChange` fire without resolving the next state.
  Browser activation resolves checkedness itself, so `onCheckedChange` reports
  the resolved value and the consumer clears `indeterminate`.
- The source's `indicatorColor` returns the transparent unchecked box color for
  the unchecked state layer, leaving hover, focus, and pressed feedback
  invisible on that path. The web unchecked state layer uses the sourced
  unselected outline role so those states remain perceivable.
- The source draws no focus indicator itself and never reads
  `CheckboxTokens.FocusIndicatorColor`; its ripple carries an optional inset
  focus ring. The web control draws a token-backed focus ring from that unused
  `FocusIndicatorColor` secondary role, because visible focus is required.
- CSS transitions cannot select on the previous state, so the gravitation morph
  animates when entering indeterminate from unchecked, where the source snaps
  it. Both resolve within the same default-spatial window while the stroke
  reveal is still running.
- Compose accepts arbitrary `Stroke` overloads, colors, and interaction sources.
  This library exposes the sourced values through theme tokens instead of per-instance
  overrides.

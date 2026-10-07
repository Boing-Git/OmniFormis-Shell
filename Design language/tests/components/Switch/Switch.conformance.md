# Switch conformance

Task: T13
Status: conformant
Reviewed: 2026-07-20

## Primary references

- AndroidX Material 3 Switch component guide, accessed 2026-07-20:
  <https://developer.android.com/develop/ui/compose/components/switch>
- Pinned current AndroidX `Switch.kt`, including `Switch`, `SwitchImpl`,
  `ThumbElement`/`ThumbNode`'s measure function, `SwitchColors`, and
  `SwitchDefaults`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/Switch.kt>
- Pinned generated AndroidX `SwitchTokens` (`VERSION: v0_210`), accessed
  2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/SwitchTokens.kt>
- WAI-ARIA APG Switch Pattern, built on `role="switch"` over a native
  checkbox input, accessed 2026-07-20:
  <https://www.w3.org/WAI/ARIA/apg/patterns/switch/>
- ARIA in HTML `role="switch"` on `input type="checkbox"`, accessed
  2026-07-20:
  <https://www.w3.org/TR/html-aria/>
- WCAG 2.2 focus visible, target size, contrast, use of color, and reduced
  motion, accessed 2026-07-20:
  <https://www.w3.org/TR/WCAG22/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`, `Switch.kt` blob
`15dbb283ad8b99ca2aac1b665a02e2f3ebce6293`, `SwitchTokens.kt` blob
`e73c33330cdd86a2c0cfeec04d2cd12d4e01da64`, adapted to a native HTML checkbox
input exposed with `role="switch"`.

## Anatomy and content

- One switch root owns the 48px interaction target, the resolved state
  attributes, the consumer class and style, and the layout box.
- One native `input type="checkbox" role="switch"` owns semantics, focus,
  activation, forms, disabled state, and the forwarded ref. It covers the
  whole target and is visually transparent.
- One decorative track owns the 52×32px pill, its 2px outline, and its fill
  color. One decorative thumb owns the sliding circle, its own hover/focus/
  pressed state layer, and an optional icon slot.
- Switch owns no label or supporting text, matching the pinned first-party
  API, which has no label parameter either.

## Variants, shape, color, and size

- The pinned API has no variant, size, or error parameter, so this component
  ships exactly one form.
- Geometry: 52×32px track, 2px outline, 16px resting unselected thumb, 24px
  selected (or icon-bearing) thumb, 28px pressed thumb, 40px state layer,
  16px thumb icon. The icon slot centers a direct `Icon`, SVG, or image in
  that 16×16px box, leaving 4px around it inside a resting 24px icon-bearing
  thumb.
- `SwitchTokens` also generates Hover/Focus/Pressed-suffixed handle, track,
  and icon color roles. `SwitchColors`/`defaultSwitchColors` never read them,
  so they are not registered, matching the unread-role precedent from
  Checkbox and Radio; the only state-driven color change besides the
  translucent state layer is checked vs. unchecked.
- Disabled roles apply the sourced `DisabledTrackOpacity` (0.12) to the
  disabled checked track, disabled unchecked track, and disabled unchecked
  border — one shared constant across three roles, kept as one token and
  reused, matching how Checkbox kept its own duplicate opacity constants
  separate specifically because those were read from *different* constant
  names; here the source itself reuses one name three times.
  `DisabledSelectedHandleOpacity` (1.0) is a real but functionally inert
  source constant, kept as a literal opaque color rather than a no-op
  opacity token, matching the `disabledCheckmarkColor`-style precedent for
  full-opacity disabled roles.

## States and motion

- Enabled, disabled, hovered, focused, pressed, checked, and unchecked are
  implemented. Selected-as-a-distinct-state, loading, and error are not
  first-party Switch states and are not claimed.
- Hover, focus, and pressed use system state opacity on a 40px circular
  layer centered on the thumb's own current position, matching the source
  attaching its ripple `Modifier.indication` to the thumb element itself
  rather than the track.
- The thumb's press-driven size (16/24/28px) and **outer-box** inset reproduce
  the source's `ThumbNode.measure` formulas via `calc()` on the same registered
  dimension tokens. An absolutely positioned CSS child resolves its inline
  inset from the bordered track's padding box, already 2px inward, so the web
  formulas subtract that consumed outline once. The resulting LTR starts are
  8px without content, 4px with content, 24px checked, 2px pressed-unchecked,
  and 22px pressed-checked; logical placement mirrors them in RTL.
- The size/inset transition uses Expressive fast-spatial motion while
  releasing a press, and snaps to zero duration while a press is active,
  reproducing the source's own `if (isPressed) SnapSpec else animationSpec`
  asymmetry: pressing down snaps instantly to the pressed size, releasing
  animates back out.
- Track and thumb color transitions use Expressive default-effects motion.
- Reduced motion removes every transition and preserves the resolved state
  immediately.

## Component token mapping

- Geometry: minimum target, track width/height, track outline width,
  unselected/selected/pressed handle size, icon size, and state-layer size.
- Color: selected and unselected track/thumb/icon; disabled-selected and
  disabled-unselected thumb/icon with their own opacities; disabled-selected
  and disabled-unselected track color sharing one disabled-track opacity;
  disabled-unselected border color sharing that same opacity; and the focus
  ring.

All values live in the T13 `switch` registration. Production CSS validation
requires every literal `--m3e-comp-switch-*` reference to resolve.

## DOM, forms, and behavior

- Rendered DOM starts with `<span class="m3e-switch" data-m3e-state="unchecked"
  data-m3e-disabled="false" data-m3e-has-thumb-icon="false">` wrapping
  `<input type="checkbox" role="switch" class="m3e-switch__input">`.
- `role` is fixed to `"switch"`, matching how `type` is fixed to
  `"checkbox"`: both are omitted from the public prop type so a caller
  cannot override the accessible mapping this component depends on.
- `name`, `value`, `form`, `required`, `id`, ARIA and data attributes, native
  handlers, and the `HTMLInputElement` ref are forwarded to the input.
  `className` and `style` describe the root.
- Controlled `checked` stays authoritative; uncontrolled `defaultChecked`
  leaves checkedness to the DOM. Native form reset restores the default and
  resynchronizes the resolved visual state.
- `onChange` runs before the library updates state, and `preventDefault()`
  cancels that update.
- `data-m3e-has-thumb-icon` is computed once from whether `thumbIcon` is
  supplied on this render; unlike Radio's checked state, nothing else can
  change it out from under this component, so it carries no live-desync risk.
- Server markup and hydration are deterministic and inject no styles.

## Accessible name, description, role, state, and keyboard

- `role="switch"` on a native checkbox input needs no explicit `aria-checked`:
  the platform accessibility mapping derives the accessible checked state
  from the native `checked` property the same way it does for the implicit
  checkbox role. Wrapping `label`, `label for`, `aria-label`, and
  `aria-labelledby` all work; the component adds no naming of its own.
- Space activates through the browser. No key handler is added, and Enter
  does not activate a switch.
- Disabled inputs do not activate and leave sequential focus.

## Bidirectional, forced-color, and adaptive behavior

- Layout uses logical inline and block sizing; every thumb inset is computed
  with `inset-inline-start`, so it mirrors correctly in RTL.
- Forced colors keeps the track outline, uses Highlight for the checked
  track/thumb and focus ring, and GrayText for disabled treatment, while
  removing the translucent state layer.
- Default, custom, and nested themes scope every Switch variable.

## Web-specific deviations

- HTML has no native switch input type interoperable across this library's
  supported browser matrix. The web control is `input type="checkbox"
  role="switch"`, the pattern WAI-ARIA APG itself documents, rather than an
  experimental, non-interoperable `<input switch>` attribute.
- The pinned `ripple()` call passes no explicit per-state color, so its
  resolved tint is ambient `LocalContentColor`, not a Switch color role. The
  web state layer uses the primary/on-surface-variant identity pairing
  already established for Checkbox's and Radio's own unread ripple color,
  rather than the near-white selected thumb color, which would be nearly
  invisible against a primary-colored track.
- The source pre-composites disabled colors over a fixed `surface` backdrop
  (`Color.copy(alpha).compositeOver(colorScheme.surface)`). The web control
  uses the `color-mix(..., transparent)` technique already established for
  Checkbox's and Radio's disabled roles instead, so a disabled Switch
  composites correctly against whatever backdrop it actually sits on, not
  only a literal surface-colored one.
- Compose accepts an arbitrary `SwitchColors` object and interaction source.
  This library exposes the sourced values through theme tokens instead of per-instance
  color overrides.

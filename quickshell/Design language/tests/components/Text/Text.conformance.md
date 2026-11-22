# Text conformance

Task: T05
Status: conformant
Reviewed: 2026-07-19

## Primary references

- AndroidX Material 3 `Typography` API, including emphasized roles, accessed
  2026-07-19:
  <https://developer.android.com/reference/kotlin/androidx/compose/material3/Typography>
- AndroidX Material 3 `Text` API, accessed 2026-07-19:
  <https://developer.android.com/reference/kotlin/androidx/compose/material3/Text.composable>
- Pinned AndroidX `Typography.kt` revision, accessed 2026-07-19:
  <https://android.googlesource.com/platform/frameworks/support/+/0be207d91046b7376beeef5544d331a02d6fa87c/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/Typography.kt>
- Material Web 34.0.21 baseline and emphasized type-scale tokens, accessed
  2026-07-19:
  <https://github.com/material-components/material-web/blob/b4de401eb665ec63474f39319a4ba8f2145974cc/tokens/versions/latest/sass/_md-sys-typescale-values.scss>
  and
  <https://github.com/material-components/material-web/blob/b4de401eb665ec63474f39319a4ba8f2145974cc/tokens/versions/latest/sass/_md-sys-typescale-emphasized-values.scss>
- HTML grouping, heading, and text-level semantics, accessed 2026-07-19:
  <https://html.spec.whatwg.org/multipage/dom.html#semantics-2>
- WCAG 2.2, accessed 2026-07-19:
  <https://www.w3.org/TR/WCAG22/>

Supported Material baseline: AndroidX Material 3 revision
`0be207d91046b7376beeef5544d331a02d6fa87c`, including its current expressive
typography API, with default web values sourced from Material Web 34.0.21.

## Anatomy and slots

- One explicitly selected native text element.
- Consumer children form the content slot and may contain any content valid for
  that selected HTML element.
- Typography applies to the same element. There is no wrapper, icon, prefix,
  suffix, rich-text parser, or generated content.

## Variants, sizes, widths, and color

- Fifteen roles: display, headline, title, body, and label, each in large,
  medium, and small.
- Each role has a baseline and independently themeable Expressive emphasized
  style, for 30 supported combinations.
- Default: baseline `bodyLarge`, matching AndroidX MaterialTheme's provided
  default text style.
- Text has no intrinsic width or responsive breakpoint. Native layout and
  consumer CSS own line wrapping and available inline size.
- Text inherits content color. It does not expose an arbitrary color prop or
  choose a Material role independently from its container.

## States

Text is passive. Enabled, disabled, hovered, focused, pressed, selected, checked,
indeterminate, loading, dragged, and error are not component states. Consumer
native attributes and handlers are forwarded but never interpreted into a Text
state.

Baseline versus emphasized is a typography style choice, not an interactive or
accessible state.

## Shape and motion

Text has no container shape, shape transition, elevation, state layer, or
animation. Reduced motion requires no alternate outcome. It does not opt out of
forced-color adjustment, so user-agent colors remain authoritative.

## Token mapping

For every `sys.typography.{baseline|emphasized}.{role}` entry, Text consumes:

- `fontFamily`, `fontWeight`, `fontSize`, `lineHeight`, and `letterSpacing`;
- axes `CRSV`, `FILL`, `GRAD`, `HEXP`, `ROND`, `opsz`, `slnt`, `wdth`, and
  `wght` through CSS `font-variation-settings`.

The deterministic CSS names are
`--m3e-sys-typescale-{emphasis}-{kebab-role}-{property}`. Text has no component-token
registration: its system type style and inherited content color are already the
first-party contract. Tests enumerate every mapping and distributed CSS checks
reject unresolved properties.

## DOM and native behavior

- Default DOM: `<span class="m3e-text" data-m3e-variant="bodyLarge"
  data-m3e-emphasis="baseline">`.
- `as` supports `span`, `p`, `div`, `h1`–`h6`, `label`, `legend`, `strong`, `em`,
  `small`, `blockquote`, and `figcaption`.
- The selected element narrows native props and the forwarded ref. For example,
  `label` accepts `htmlFor` and a heading ref is an `HTMLHeadingElement`.
- No role, tab index, event handler, accessible state, or extra wrapper is
  generated. Native margins are reset on the component class; native display
  mode is preserved.
- Consumer class names, inline styles, IDs, native handlers, ARIA attributes,
  data attributes, and children are preserved. Server output is deterministic
  and hydrates without recoverable errors.

## Accessible name, role, state, and keyboard

- A default span has no implicit role or keyboard behavior.
- Display and headline visual roles do not create headings. Only `h1` through
  `h6` establish the corresponding native heading level.
- Native `label` activation and `legend` fieldset naming are preserved.
- The component creates no accessible state and is skipped by sequential focus.
- Consumers remain responsible for valid heading order, form relationships, and
  child content appropriate to the chosen element.

## Bidirectional and adaptive behavior

- Text adds no physical-direction spacing or alignment. It inherits direction,
  writing mode, and Unicode bidirectional behavior from normal HTML/CSS.
- Font sizes use sourced `rem` system tokens, so user root-font scaling remains
  effective.
- The type role does not change at a breakpoint. Consumers can override system
  tokens or component presentation in responsive CSS when product context
  requires adaptive type.

## Web-specific deviations

- Compose Text has no HTML element selection. React Text adds bounded `as`
  semantics because document structure cannot be inferred from a visual style.
- Compose accepts strings/annotated strings and layout controls such as
  `maxLines`, overflow, and auto-size. This library accepts React children; rich text,
  fitting, and truncation remain separate content/layout policies.
- Compose inherits `LocalContentColor`; web Text uses normal CSS color
  inheritance from Surface or another ancestor, avoiding a React subscription.
- Compose `TextStyle` can carry platform-native font features. Web Text maps the
  modeled Expressive axes to CSS `font-variation-settings`; unsupported axes are
  ignored by the selected font.
- Font resolution is consumer-owned. No equivalent of a platform font registry
  is bundled or fetched as a rendering side effect.

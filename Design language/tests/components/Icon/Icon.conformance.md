# Icon conformance

Task: T06
Status: conformant
Reviewed: 2026-07-19

## Primary references

- AndroidX Material 3 package `Icon` API, accessed 2026-07-19:
  <https://developer.android.com/reference/kotlin/androidx/compose/material3/package-summary>
- Android Compose Material icon guidance, including 24dp default size,
  inherited content color, decorative descriptions, and current Material
  Symbols recommendation, accessed 2026-07-19:
  <https://developer.android.com/develop/ui/compose/graphics/images/material>
- Pinned AndroidX Material 3 `Icon.kt`, accessed 2026-07-19:
  <https://android.googlesource.com/platform/frameworks/support/+/0be207d91046b7376beeef5544d331a02d6fa87c/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/Icon.kt>
- Google Material Symbols web guide, including styles, axes, ranges, font
  ownership, and subsetting guidance, accessed 2026-07-19:
  <https://developers.google.com/fonts/docs/material_symbols>
- WAI decorative image guidance, accessed 2026-07-19:
  <https://www.w3.org/WAI/tutorials/images/decorative/>
- WAI-ARIA `img` role, accessed 2026-07-19:
  <https://www.w3.org/TR/wai-aria-1.2/#img>
- WCAG 2.2, including non-text contrast, accessed 2026-07-19:
  <https://www.w3.org/TR/WCAG22/>

Supported Material baseline: AndroidX Material 3 revision
`0be207d91046b7376beeef5544d331a02d6fa87c`, adapted to current Google Material
Symbols web axes and native HTML/ARIA semantics.

## Anatomy and sources

- One passive `span` root owns sizing, inherited color, direction, accessibility,
  native consumer attributes, and the forwarded ref.
- SVG source: one consumer React component receives the required adapter props
  and renders its SVG visual inside the root.
- Symbol source: one nested hidden span contains a Material Symbols ligature or
  codepoint and selects the consumer-loaded font family.
- There are no icon-name lookup, image, control, badge, tooltip, or state-layer
  slots.

## Variants, sizes, widths, and color

- Sources: React SVG component or Material Symbols string.
- Symbol family styles: outlined (default), rounded, and sharp.
- Default visual size is 24px. A positive numeric size selects CSS-pixel inline
  and block size; no minimum interaction target applies because Icon is passive.
- The component is square and has no independent width variant.
- Icon inherits content color. SVG artwork receives `currentColor`; symbol text
  inherits the same color. Arbitrary colors remain a consumer CSS override.
- Symbol axes are continuous within sourced ranges: fill 0–1, weight 100–700,
  grade -50–200, optical size 20–48, and roundness 0–100.

## States

Icon is passive. Enabled, disabled, hovered, focused, pressed, selected, checked,
indeterminate, loading, dragged, and error are not Icon states. `fill`, grade,
weight, and roundness are visual symbol inputs and do not create accessible
state. Controls must own and expose their state separately.

## Shape and motion

The artwork defines its internal shape; Icon has no container shape, elevation,
state layer, or shape morph. It creates no animation or transition. Reduced
motion requires no alternate outcome. A later interactive component may animate
symbol axes only when it also preserves understandable state under reduced
motion.

## Token mapping

- `--m3e-comp-icon-size`: 24px.
- `--m3e-comp-icon-symbol-family-{outlined|rounded|sharp}`: consumer font-family
  hooks.
- `--m3e-comp-icon-symbol-fill`: 0.
- `--m3e-comp-icon-symbol-weight`: 400.
- `--m3e-comp-icon-symbol-grade`: 0.
- `--m3e-comp-icon-symbol-optical-size`: 24.
- `--m3e-comp-icon-symbol-roundness`: 50.

Explicit props map to stable `--m3e-icon-*` instance variables. The Symbol
visual consumes all five axes through one literal `font-variation-settings`
declaration. Tests and distribution checks reject unresolved variables.

## DOM and native behavior

- Decorative Symbol default: `<span class="m3e-icon" aria-hidden="true"
  data-m3e-source="symbol" data-m3e-mirrored="false"
  data-m3e-symbol-style="outlined">` with one hidden source span.
- Meaningful root: the same passive span with `role="img"` and `aria-label`.
- SVG source roots receive `.m3e-icon__svg`, `aria-hidden="true"`, and
  `focusable="false"`; their internal vector markup remains source-owned.
- The root forwards `HTMLSpanElement`, IDs, descriptive ARIA references, data
  attributes, class, style, and passive native handlers. It owns children, raw
  HTML, role, direct naming/hiding attributes, and tab index.
- Server output is deterministic and hydrates without recoverable errors. No
  style element, font face, link, or network request is generated.
- The combined root client entry means Next Server Components may
  pass the serializable string source; SVG component source functions stay in a
  client module. Ordinary React SSR supports both source forms.

## Accessible name, role, state, and keyboard

- Decorative is the default; both wrapper and source visual are hidden from the
  accessibility tree. This prevents duplicate naming inside a control.
- `decorative={false}` requires a localized, non-empty `label`. The wrapper
  exposes exactly one named `img` role, and the source remains hidden.
- Icon creates no state and is skipped by sequential focus. It is never a
  button, link, checkbox, or toggle.
- Development builds warn for an empty meaningful label. Types reject a label on
  a decorative icon and reject a missing label on an explicitly meaningful one.

## Bidirectional and adaptive behavior

- Default artwork is unchanged in RTL. `mirrored` explicitly mirrors only the
  source visual under `:dir(rtl)`.
- Material Symbols ligature source text is fixed LTR to prevent source-name
  reordering. This is independent from optional visual mirroring.
- Explicit visual sizes make their default optical axis track within 20–48.
  Consumer CSS may apply context-specific responsive presentation.
- Icon does not opt out of forced-color adjustment and keeps `currentColor` as
  the paint input.

## Web-specific deviations

- Compose accepts painter, bitmap, and image-vector platform objects. This library
  accepts SVG source components and web font glyph strings; arbitrary bitmap and
  multicolor image rendering belongs to an image primitive.
- Compose applies semantic content descriptions to its icon node. This library uses a
  named outer `img` role for meaningful icons and hides opaque source markup so
  a third-party SVG cannot manufacture a second image or name.
- Compose inherits `LocalContentColor`; web Icon uses normal CSS inheritance and
  `currentColor`, avoiding a React theme subscription.
- Compose uses a platform vector/font registry. Web consumers own Material
  Symbols loading and subsetting, and the library never bundles a private consumer's
  icon registry or fetches a font.

# Button

`Button` is a native, form-capable React button with the current Material 3
Expressive size, shape, and pressed-motion system. It has no routing or
framework dependency.

```tsx
import {
  Button,
  Icon,
} from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<Button
  variant="filled"
  size="medium"
  leadingIcon={<Icon source="add" />}
  onClick={createProject}
>
  New project
</Button>
```

## Contract

- The root is always a native `<button>` and its ref is an
  `HTMLButtonElement`. It defaults to `type="button"`, preventing accidental
  form submission. Explicit `submit` and `reset` types keep native behavior.
- `variant` is `filled` (default), `tonal`, `elevated`, `outlined`, or `text`.
- `size` is `extra-small`, `small` (default), `medium`, `large`, or
  `extra-large`.
- `shape` is `round` (default) or `square`. Both resting shapes morph to the
  current size tier's pressed shape.
- `width="fit"` is intrinsic and is the default. `width="full"` fills the
  containing block.
- `leadingIcon` and `trailingIcon` are decorative visual slots in logical
  reading order. Pass `Icon`, an SVG, or similarly sized non-interactive
  artwork. The slots are hidden from assistive technology so the label is not
  announced twice.
- Button preserves native form attributes, IDs, ARIA descriptions, data
  attributes, classes, styles, and event handlers. Activation remains owned by
  the browser rather than reimplemented in React.

`Button` does not render a link. Use a native or router link API for navigation;
a separately designed link-button adapter can style that semantic element
without putting a link inside a button. Icon-only and toggle actions belong to
`IconButton`.

## Variants

| Variant | Container | Content | Elevation |
| --- | --- | --- | --- |
| `filled` | primary | on-primary | level 0; level 1 hover |
| `tonal` | secondary-container | on-secondary-container | level 0; level 1 hover |
| `elevated` | surface-container-low | primary | level 1; level 2 hover |
| `outlined` | transparent with outline-variant border | on-surface-variant | level 0 |
| `text` | transparent | on-surface-variant | level 0 |

The roles follow the current AndroidX generated Button tokens. Hover, focus, and
pressed state layers use theme state opacities. Native `disabled` prevents
activation and selects the sourced disabled role and opacity for each variant.

## Expressive sizes

| Size | Visual minimum | Inline/block padding | Icon | Gap | Label role | Pressed corner |
| --- | ---: | ---: | ---: | ---: | --- | ---: |
| `extra-small` | 32px | 12px / 6px | 20px | 4px | label large | small |
| `small` | 40px | 16px / 10px | 20px | 8px | label large | small |
| `medium` | 56px | 24px / 16px | 24px | 8px | title medium | medium |
| `large` | 96px | 48px / 32px | 32px | 12px | headline small | large |
| `extra-large` | 136px | 64px / 48px | 40px | 16px | headline large | large |

The visual container uses `min-block-size`, so zoomed or wrapped text can grow
instead of clipping. A separate semantic root keeps every tier at least 48 by
48 CSS pixels. This lets the 32px and 40px Expressive visuals retain their
sourced proportions without shrinking the interaction target.

Large and extra-large buttons are deliberately prominent display actions, not
density substitutes for ordinary buttons.

## Accessibility and forms

Use a concise localized label. Native text content normally supplies the
accessible name; `aria-label` or `aria-labelledby` remains available when label
content is not textual. Development builds warn only when all three naming
paths are empty.

Enter, Space, focus, disabled state, form submission/reset, name/value, and form
ownership are native HTML behavior. Button does not synthesize key events or
add `role="button"`, `tabIndex`, `aria-pressed`, or `aria-busy`. Disabled buttons
are removed from sequential focus by the browser. Consumer `onClick` and form
handlers run once through normal React/native event behavior.

Keyboard focus uses a token-backed `:focus-visible` ring. Forced-colors mode
uses system ButtonFace, ButtonText, GrayText, and Highlight colors and removes
the translucent state layer rather than forcing authored colors.

## Shape and motion

The source Button API morphs resting and pressed corner shapes with
`DefaultEffects` specifically to avoid bounce. The web token serializer
projects each theme spring into two additional CSS variables:

- `--m3e-sys-motion-*-duration`
- `--m3e-sys-motion-*-easing`

The duration is the spring's calculated settlement time and the easing is a
deterministic sampled `linear()` curve. Button consumes the Expressive default-
effects pair, so nested custom themes also produce scoped motion. Under
`prefers-reduced-motion: reduce`, the transition is removed while the pressed
shape and state layer still change immediately.

## Tokens

Button component variables are grouped predictably:

- `--m3e-comp-button-{size}-container-height`
- `--m3e-comp-button-{size}-padding-{block|inline}`
- `--m3e-comp-button-{size}-icon-{size|spacing}`
- `--m3e-comp-button-{size}-container-shape-{round|square}`
- `--m3e-comp-button-{size}-pressed-container-shape`
- `--m3e-comp-button-{size}-outline-width`
- `--m3e-comp-button-{variant}-container-color`
- `--m3e-comp-button-{variant}-content-color`
- variant disabled color/opacity and container-shadow variables
- `--m3e-comp-button-minimum-{interactive-target|width}`
- `--m3e-comp-button-focus-ring-{color|offset|width}`

System color, typography, shape, state, density, elevation, and motion remain
authoritative underneath these component aliases. Theme overrides stay scoped
to `Material3Provider`; rendering a Button injects no style element.

## Bidirectionality and SSR

All spacing and sizing use logical CSS. In RTL, the leading slot appears at
logical start and the trailing slot at logical end without changing DOM or
accessible reading order. Directional icon artwork opts into its own mirroring
through `Icon`.

Button markup is deterministic under React server rendering and hydration. The
component imports React and public components only; it exposes no Next.js,
Vite, router, or application types.

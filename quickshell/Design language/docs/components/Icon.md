# Icon

`Icon` renders passive, single-color Material iconography from either a React
SVG source component or a consumer-supplied Material Symbols font. It inherits
the surrounding content color and owns a predictable accessibility boundary.

```tsx
import {
  Icon,
  type IconSourceProps,
} from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

function SearchIcon(props: IconSourceProps) {
  return (
    <svg {...props} viewBox="0 0 24 24">
      <path d="M9 3a6 6 0 1 0 0 12 6 6 0 0 0 0-12Zm4 11 6 6" />
    </svg>
  )
}

<Icon source={SearchIcon} decorative={false} label="Search results" />
```

## Contract

- `source={SvgComponent}` adapts a React component that renders one SVG. The
  source must forward the supplied `className`, `aria-hidden`, and `focusable`
  props to its root `<svg>`.
- `source="search"` renders a Material Symbols ligature. `symbolStyle` selects
  `outlined` (default), `rounded`, or `sharp`.
- `size` is a positive CSS-pixel number. The sourced default is 24. The root is
  always a passive `span`, and its ref is an `HTMLSpanElement`.
- `mirrored` opts directional artwork into horizontal mirroring under RTL. Icons
  do not mirror from their glyph name or shape automatically.
- Native IDs, data/ARIA description attributes, classes, styles, and passive
  event handlers are preserved. `children`, `role`, accessible-name attributes,
  `tabIndex`, and raw HTML are owned by the component contract.

Icon has no click, toggle, selection, disabled, or keyboard behavior. Put a
decorative Icon inside a properly named `IconButton` or another native control;
do not attach control semantics to the Icon span.

## Accessibility

Icons are decorative by default:

```tsx
<button type="button" aria-label="Search">
  <Icon source={SearchIcon} />
</button>
```

The Icon root and its source visual are hidden from assistive technology, so the
control name is announced once. When an icon conveys standalone information,
use `decorative={false}` and provide a localized, non-empty `label`. The root
then exposes exactly one named `img` role while the source remains hidden.

`fill`, grade, weight, color, or animation must never be the only way an
accessible state is communicated. Interactive components own `aria-pressed`,
`aria-selected`, checked state, labels, descriptions, and focus behavior.

## Material Symbols and Expressive axes

```tsx
<Icon
  source="favorite"
  symbolStyle="rounded"
  size={32}
  fill={1}
  weight={575}
  grade={100}
  opticalSize={32}
  roundness={100}
/>
```

The glyph adapter supports the current Material Symbols axes:

- `fill`: `FILL`, sourced range 0–1
- `weight`: `wght`, sourced range 100–700
- `grade`: `GRAD`, sourced range -50–200
- `opticalSize`: `opsz`, sourced range 20–48
- `roundness`: Expressive `ROND`, sourced range 0–100

When `opticalSize` is omitted, an explicit visual `size` also selects its
optical size, clamped to the font's 20–48 design range. Axis values are
continuous numbers so capable variable fonts are not restricted to a few named
instances. Development builds warn about values outside sourced ranges.

The library does not download, subset, or declare a Material Symbols font.
Applications should self-host or request only the glyphs and axes they use,
then load the corresponding `Material Symbols Outlined`, `Rounded`, or `Sharp`
family before rendering glyph sources. SVG sources need no font.

Both sources are deterministic under ordinary React server rendering. The
package's root entry is a client boundary for React Server Components because it
also exports the theme provider and hooks. A Next.js Server Component may pass
the serializable string source; put an SVG component source call in a client
module. This packaging constraint adds no Next.js code or types to Icon.

## Tokens and color

The default component variables are:

- `--m3e-comp-icon-size`
- `--m3e-comp-icon-symbol-family-{outlined|rounded|sharp}`
- `--m3e-comp-icon-symbol-{fill|weight|grade|optical-size|roundness}`

Explicit props set stable `--m3e-icon-*` instance variables on the root. Normal
consumer inline styles remain available for deliberate presentation overrides.
Icon uses inherited `currentColor`; a `Surface` supplies the corresponding
Material content role. Multicolor artwork and arbitrary images belong in an
image component rather than this tint-oriented icon primitive.

## Bidirectionality, motion, and forced colors

Material Symbol ligature text is always laid out LTR so an RTL page does not
reorder its source name. `mirrored` affects only the visual source and only in
RTL. The component defines no transition or animation, so reduced motion needs
no alternate path. It keeps `currentColor` active and does not disable browser
forced-color adjustment.

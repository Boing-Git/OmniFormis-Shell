# CircularProgress

`CircularProgress` renders a small, fixed-size ring progress indicator.
Pass `value` for determinate progress, or omit it entirely for a
continuously animating indeterminate spinner — the same contract a native
`<progress>` element uses.

```tsx
import { CircularProgress } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<CircularProgress aria-label="Progress" value={0.4} />
<CircularProgress aria-label="Loading" />
```

## Contract

- `value` (a number in `[0, max]`) renders determinate progress with an
  accurate `aria-valuenow`. Omitting `value` renders indeterminate mode: a
  continuously rotating, pulsing arc with no `aria-valuenow` at all,
  signaling a busy/indeterminate state to assistive technology. No track
  element renders in indeterminate mode — the pinned source's own
  indeterminate track color is transparent.
- `max` defaults to `1`. `aria-label`/`aria-labelledby` provide the
  required accessible name — `CircularProgress` has no visible label of
  its own.
- Fixed `40px` intrinsic size, matching a small, fixed-size spinner's real
  web usage; override `--m3e-comp-circular-progress-diameter` to resize.
- Determinate arcs account for the visual width of their round caps when
  reserving the active/track gap; 0% and 100% omit zero-length arcs rather
  than letting SVG render a stray cap dot.
- Indeterminate rotation layers share the fixed center of the SVG view box,
  so the pulsing arc rotates in place as its painted bounds change.
- For the Material 3 Expressive rippling-ring treatment, see
  `WavyProgress`.

## Tokens and boundaries

Colors, geometry, and motion timing come entirely from `--m3e-comp-
circular-progress-*` CSS custom properties, scoped by `Material3Provider`.
`CircularProgress` injects no runtime styles, uses no
`requestAnimationFrame` loop (indeterminate motion composes three CSS
`@keyframes` animations, matching the source's three composed animation
values), and imports no Next.js, Vite, router, animation
library, or private application code.

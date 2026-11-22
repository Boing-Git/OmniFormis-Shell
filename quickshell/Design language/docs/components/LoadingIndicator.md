# LoadingIndicator

`LoadingIndicator` renders the Material 3 Expressive shape-morphing
loading indicator. Pass `value` for determinate progress (morphing between
a circle and a soft-burst shape), or omit it entirely for a continuously
animating indeterminate loop through seven shapes — the same
determinate/indeterminate contract a native `<progress>` element uses.

```tsx
import { LoadingIndicator } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<LoadingIndicator aria-label="Loading" value={0.4} />
<LoadingIndicator aria-label="Loading" />
```

## Contract

- `value` (a number in `[0, max]`) renders determinate progress with an
  accurate `aria-valuenow`, morphing between a circle and a soft-burst
  shape as it advances. Omitting `value` renders indeterminate mode: a
  continuously morphing, rotating loop through seven shapes, with no
  `aria-valuenow` at all, signaling a busy/indeterminate state to
  assistive technology.
- `max` defaults to `1`. `aria-label`/`aria-labelledby` provide the
  required accessible name — `LoadingIndicator` has no visible label of
  its own.
- Fixed `48px` intrinsic size; override
  `--m3e-comp-loading-indicator-container-width`/`-container-height` to
  resize.
- Only the uncontained treatment is covered — there is no colored-container
  variant.

## Tokens and boundaries

Color and layout come entirely from `--m3e-comp-loading-indicator-*` CSS
custom properties, scoped by `Material3Provider`. `LoadingIndicator`
injects no runtime styles and uses no `requestAnimationFrame` loop —
determinate motion is a plain function of the `value` prop (the same
polygon-morph interpolation the source performs every frame, computed
synchronously at render time), and indeterminate motion is pure CSS
`@keyframes`, using a spring-shaped `linear()` easing function to
reproduce the source's own morph spring exactly. The shape geometry itself
is precomputed offline from a faithful port of the source's
`RoundedPolygon`/`Morph` shape-matching algorithm — see ADR 0022 for the
full technique.

# LinearProgress

`LinearProgress` renders a straight, horizontal progress bar. Pass `value`
for determinate progress, or omit it entirely for a continuously animating
indeterminate bar — the same contract a native `<progress>` element uses.

```tsx
import { LinearProgress } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<LinearProgress aria-label="Download progress" value={0.4} />
<LinearProgress aria-label="Loading" />
```

## Contract

- `value` (a number in `[0, max]`) renders determinate progress with an
  accurate `aria-valuenow`. Omitting `value` renders indeterminate mode: a
  continuously animating pair of bars with no `aria-valuenow` at all,
  signaling a busy/indeterminate state to assistive technology.
- `max` defaults to `1`. `aria-label`/`aria-labelledby` provide the
  required accessible name — `LinearProgress` has no visible label of its
  own.
- `inline-size` defaults to `100%` (full-width, like a native `<progress>`
  element); set it via ordinary CSS on the root or a wrapping container.
- For the Material 3 Expressive traveling-wave treatment, see
  `WavyProgress`.

## Tokens and boundaries

Colors, geometry, and motion timing come entirely from `--m3e-comp-linear-
progress-*` CSS custom properties, scoped by `Material3Provider`.
`LinearProgress` injects no runtime styles, uses no `requestAnimationFrame`
loop (indeterminate motion is pure CSS `@keyframes`), and imports no Next.js, Vite, router, animation library, or private application code.

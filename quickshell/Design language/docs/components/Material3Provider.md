# Material3Provider

`Material3Provider` renders one complete, nestable Material theme scope. It owns
theme data and resolved color mode without mutating the document root or
requiring runtime stylesheet injection.

```tsx
import {
  Material3Provider,
  useResolvedColorMode,
} from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

function ModeLabel() {
  const mode = useResolvedColorMode()
  return <output>Resolved mode: {mode}</output>
}

export function App() {
  return (
    <Material3Provider colorMode="system">
      <ModeLabel />
    </Material3Provider>
  )
}
```

## Anatomy, variants, and states

- The provider renders a `.m3e-theme` `div` around `children`. Standard div
  attributes, `className`, `style`, IDs, data attributes, and ARIA attributes
  forward to that root.
- `theme` defaults to the complete immutable `defaultTheme`. Custom themes must
  be created or parsed by the public theme APIs.
- `colorMode` is `light`, `dark`, or `system` (default). The root exposes both
  configured and resolved modes through stable data attributes.
- `systemModeFallback` is the deterministic server/hydration snapshot and
  defaults to `light`.
- `preventColorSchemeFlash` optionally emits a scoped initialization script;
  `nonce` forwards a CSP nonce to that script. Static CSS already chooses the
  visual system scheme without it.
- Nested providers start a complete independent scope before applying their own
  theme differences.

## Accessibility

The provider adds no widget role, focus behavior, or keyboard interaction. Its
wrapper is a passive `div`; consumers remain responsible for semantic landmarks
inside it. Color schemes are validated against the documented role-pair contrast
requirements. Forced-colors and reduced-motion behavior remain component-owned.

Do not add a role merely to hide the provider wrapper. If the wrapper
participates in layout, use ordinary `className` or `style` without changing the
semantics of its children.

## Tokens

The complete stylesheet assigns default `--m3e-ref-*`, `--m3e-sys-*`, and
`--m3e-comp-*` custom properties to `.m3e-theme`. A custom provider writes only
validated differences as inline custom properties. Light/dark aliases let
static media queries resolve system mode before hydration.

Theme creation and token utilities are available through the React-free
`/theme` and `/tokens` entries. See [the theming guide](../THEMING.md) and
[SSR guide](../SSR.md).

## SSR and boundaries

Server markup is deterministic when the same `theme`, `colorMode`, and
`systemModeFallback` reach the first client render. `useResolvedColorMode` and
`useMaterial3Theme` use separate contexts so mode-only consumers do not
subscribe to complete theme changes.

The provider imports no framework adapter. Next.js, Vite,
router, link, image, font, storage, and application state remain consumer-owned.

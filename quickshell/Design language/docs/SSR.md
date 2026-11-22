# SSR and system color mode

The library renders deterministic server markup and supports React hydration
without mutating `document.documentElement`. The provider owns color mode on its own
scope.

## Server-safe data entries

Create themes or inspect tokens from React Server Components and other server
modules through the React-free entries:

```ts
import { createTheme } from '@language-lit/material3-expressive/theme'
import { defaultTokenSet } from '@language-lit/material3-expressive/tokens'

export const theme = createTheme({
  density: defaultTokenSet.system.density,
})
```

Import React components and hooks from the root entry only inside a
client-capable module.

## Deterministic system mode

`colorMode="system"` uses `systemModeFallback` as the server and first hydration
snapshot. It defaults to `light`. Static CSS independently evaluates
`prefers-color-scheme`, so the visual light/dark scheme is correct before React
subscribes to the media query.

```tsx
'use client'

import type { ReactNode } from 'react'
import { Material3Provider } from '@language-lit/material3-expressive'
import type { Material3Theme } from '@language-lit/material3-expressive/theme'

export function Providers({
  children,
  theme,
}: {
  children: ReactNode
  theme: Material3Theme
}) {
  return (
    <Material3Provider
      theme={theme}
      colorMode="system"
      systemModeFallback="light"
    >
      {children}
    </Material3Provider>
  )
}
```

The theme object is serializable and may cross a server-to-client boundary.

## Optional resolved-mode initialization

Most applications need only the static stylesheet. If application code reads
`data-m3e-resolved-color-mode` before hydration, enable the provider's scoped
initialization script:

```tsx
<Material3Provider
  colorMode="system"
  preventColorSchemeFlash
  nonce={contentSecurityPolicyNonce}
>
  {children}
</Material3Provider>
```

The script updates only its provider element. Pass the request's CSP nonce when
the policy requires it. The script is absent by default.

## Next.js App Router

Import `/styles.css` from the root layout and render a small client provider
component beneath it. Create custom theme data in a server module through
`/theme`; do not import the client root barrel into that server module.

No Next.js adapter is part of the public API. The same provider and serialized
theme work in Vite, other SSR frameworks, and direct `renderToString`/
`hydrateRoot` setups.

## Nested scopes and hydration

Nested providers each emit a complete `.m3e-theme` scope. Keep the same theme,
`colorMode`, and `systemModeFallback` values between server rendering and the
first client render. A later prop change is ordinary React state, not a hydration
strategy.

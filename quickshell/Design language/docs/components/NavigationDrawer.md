# NavigationDrawer

`NavigationDrawer` renders a full-height side panel of navigation items in
one of three variants: a temporary modal overlay, a non-modal panel that
collapses in place, or an always-visible permanent panel.

```tsx
import { useState } from 'react'
import { Icon, NavigationDrawer } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

const [open, setOpen] = useState(false)

<NavigationDrawer
  aria-label="Mail folders"
  variant="modal"
  open={open}
  onOpenChange={setOpen}
  items={[
    { value: 'inbox', label: 'Inbox', icon: <Icon source="inbox" /> },
    { value: 'sent', label: 'Sent', icon: <Icon source="send" /> },
  ]}
/>
```

## Contract

- `items`, `value`/`defaultValue`/`onValueChange` reuse `NavigationBar`'s
  own `NavigationItem` shape and link-safe `href` behavior.
- `variant` (default `'modal'`):
  - `'modal'` — a temporary overlay using the same native `<dialog>`
    technique `Dialog` uses (`showModal()`/`close()`, Escape/outside-click
    dismissal), sliding in from the logical start edge. `open`/
    `defaultOpen`/`onOpenChange` control it.
  - `'dismissible'` — a non-modal panel that collapses/expands in place,
    pushing adjacent content rather than overlaying it. Also controlled by
    `open`/`defaultOpen`/`onOpenChange`.
  - `'permanent'` — always visible; `open`/`defaultOpen`/`onOpenChange` are
    accepted but ignored.

## Tokens and boundaries

All color, geometry, and motion values live in one
`--m3e-comp-navigation-drawer-*` registration. Theme overrides remain
scoped to `Material3Provider`; `NavigationDrawer` injects no runtime
styles. It imports no Next.js, Vite, router, animation
library, or private application code.

# Snackbar

`Snackbar` renders a portaled, transient status message fixed to the bottom
of the viewport. It is a single controlled component, not a queue — a
consumer wanting several queued messages manages that in their own state.

```tsx
import { useState } from 'react'
import { Snackbar } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

const [open, setOpen] = useState(false)

<Snackbar
  message="Conversation removed"
  action={{ label: 'Undo', onClick: handleUndo }}
  open={open}
  onOpenChange={setOpen}
/>
```

## Contract

- `open`/`defaultOpen`/`onOpenChange` follow the same controlled/
  uncontrolled shape as every other stateful component. `onOpenChange`
  fires whenever the snackbar closes itself — the auto-dismiss timer, the
  action, or the dismiss button.
- `message` is the required body. `action?: { label, onClick }` renders one
  inline text button; activating it calls `onClick` then closes.
  `dismissible` (default `false`) renders a close icon button;
  `dismissLabel` (default `'Dismiss'`) sets its accessible name.
- `duration` accepts `'short'` (4000ms), `'long'` (10000ms), `'indefinite'`,
  or an exact millisecond count. It defaults to `'short'` with no `action`
  and `'indefinite'` with one — matching the pinned Material source's own
  default logic.

## Behavior

The auto-dismiss countdown pauses while the snackbar is hovered or
focused and resumes the remaining time on leave, so a user reading a
longer message or reaching for the action never has it disappear from
under them. `role="status"` announces the message politely without
stealing focus.

## Tokens and boundaries

All color, geometry, and motion values live in one `--m3e-comp-snackbar-*`
registration. Theme overrides remain scoped to `Material3Provider`;
`Snackbar` injects no runtime styles. It imports no Next.js,
Vite, router, animation library, or private application code.

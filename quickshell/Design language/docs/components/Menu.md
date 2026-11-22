# Menu

`Menu` renders a data-driven, portaled action menu anchored to a trigger you
already render. It is the first component with no native top-layer
primitive to lean on — positioning, outside-click/Escape dismissal, and
focus restoration are all owned by the library.

```tsx
import { useRef, useState } from 'react'
import { Button, Icon, Menu } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

const anchorRef = useRef<HTMLButtonElement>(null)
const [open, setOpen] = useState(false)

<Button ref={anchorRef} aria-haspopup="menu" aria-expanded={open} onClick={() => setOpen(true)}>
  Actions
</Button>
<Menu
  anchorRef={anchorRef}
  open={open}
  onOpenChange={setOpen}
  items={[
    { value: 'copy', label: 'Copy', leadingIcon: <Icon source="content_copy" />, onSelect: handleCopy },
    { value: 'paste', label: 'Paste', onSelect: handlePaste },
  ]}
/>
```

## Contract

- `open`/`defaultOpen`/`onOpenChange` follow the same controlled/
  uncontrolled shape as every other stateful component.
- `anchorRef` points at a trigger you render and own completely — `Menu`
  renders no trigger of its own. Your trigger is responsible for its own
  `aria-haspopup="menu"`/`aria-expanded`/click wiring, the same
  trigger-agnostic contract `Dialog` already uses for its own open state.
- `items: readonly MenuItem[]` describes the menu's content:
  `{ value, label, onSelect?, leadingIcon?, trailingIcon?, disabled?, checked?, onCheckedChange? }`.
  Omitting `checked` renders a plain `role="menuitem"` that closes the menu
  on activation. Defining `checked` (even `false`) renders
  `role="menuitemcheckbox"` with `aria-checked` and keeps the menu open on
  activation, so a consumer can toggle several settings in one visit.

## Keyboard

| Key | Behavior |
| --- | --- |
| Opening | Moves real focus to the first enabled item |
| ArrowDown / ArrowUp | Move focus across enabled items, wrapping |
| Home / End | Jump to the first/last enabled item |
| Typing | Typeahead — jumps to the next item whose (string) label starts with that character |
| Enter / Space | Activates the focused item |
| Escape | Closes and restores focus to the anchor |
| Tab | Closes without trapping focus — the browser's own tab order continues |

Disabled items are skipped by keyboard navigation and inert to click. There
is no focus trap and no inert background, matching the APG menu-button
pattern rather than Dialog's modal pattern.

## Positioning

The popup tries to align its start edge with the anchor's, then its end
edge, then clamps inside the viewport — the same for the vertical axis,
preferring below the anchor, then above, then clamped. Width stays within
112–280px regardless of anchor width. It repositions on scroll and window
resize while open.

## Tokens and boundaries

All color, geometry, and motion values live in one `--m3e-comp-menu-*`
registration, reused unchanged by `Select`'s own popup listbox. Theme
overrides remain scoped to `Material3Provider`; `Menu` injects no runtime
styles. It imports no Next.js, Vite, router, animation
library, or private application code.

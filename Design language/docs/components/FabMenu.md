# FabMenu

`FabMenu` renders a trigger FAB that morphs shape, color, and icon size
when toggled, revealing a staggered column of `FabMenuItem`s above it.

```tsx
import { FabMenu, FabMenuItem } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<FabMenu
  triggerLabel="Create"
  icon={<AddIcon />}
  closeIcon={<CloseIcon />}
  expanded={open}
  onExpandedChange={setOpen}
>
  <FabMenuItem icon={<EditIcon />} onClick={edit}>
    Edit
  </FabMenuItem>
  <FabMenuItem icon={<ShareIcon />} onClick={share}>
    Share
  </FabMenuItem>
</FabMenu>
```

## Contract

- `triggerLabel` (the trigger's accessible name), `icon` (shown
  collapsed), and `closeIcon` (shown expanded) are required.
  `expanded`/`defaultExpanded`/`onExpandedChange` follow the same
  controlled/uncontrolled toggle contract as `IconButton`'s own
  `selected`/`onSelectedChange`.
- `children` are `FabMenuItem`s (`icon`, `children` as the label,
  `onClick`, `disabled`). Collapsed items are `inert` — removed from both
  the accessibility tree and tab order, but kept in the DOM for the
  reveal transition.
- The trigger exposes `aria-expanded`/`aria-haspopup="true"`/
  `aria-controls`. `ArrowDown` (or `Tab`) from a focused, expanded
  trigger moves focus to the first item.
- Wiring the menu to real navigation/actions is entirely up to
  `onClick` on each `FabMenuItem` — `FabMenu` does not own routing or any
  overlay/menu semantics beyond the disclosure pattern above.

## Tokens and boundaries

Colors, geometry, and motion timing come entirely from
`--m3e-comp-fab-menu-*` CSS custom properties, scoped by
`Material3Provider`. `FabMenu` injects no runtime styles and uses no
`requestAnimationFrame` loop — the trigger's collapsed/expanded morph and
each item's staggered reveal are both plain CSS transitions.

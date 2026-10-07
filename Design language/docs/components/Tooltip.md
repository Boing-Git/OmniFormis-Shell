# Tooltip

`Tooltip` renders a portaled, non-interactive description anchored to a
trigger you already render. Unlike `Menu`, it wires its own show/hide
interaction — hover, focus, and `Escape` — directly on your anchor, so there
is nothing else to wire up.

```tsx
import { useRef } from 'react'
import { Icon, IconButton, Tooltip } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

const anchorRef = useRef<HTMLButtonElement>(null)

<IconButton ref={anchorRef} aria-label="Favorite">
  <Icon source="star" />
</IconButton>
<Tooltip anchorRef={anchorRef} content="Add to favorites" />
```

## Contract

- `anchorRef` points at a trigger you render and own completely, the same
  trigger-agnostic contract `Menu`/`Dialog` already use. Unlike `Menu`,
  your trigger needs no click/`aria-expanded` wiring of its own — `Tooltip`
  attaches hover/focus listeners to the anchor directly and manages
  `aria-describedby` on it imperatively while shown.
- `content` is the required body. `variant` (default `'plain'`) or
  `'rich'` adds an optional `subhead` above `content` and uses a larger
  container. Both variants stay non-interactive: `role="tooltip"`
  disallows focusable content, so there is no action-button variant.
- `placement` (default `'top'`) accepts `'top'`, `'bottom'`, `'start'`, or
  `'end'`; it flips to the opposite side when the preferred one would
  collide with the viewport edge.
- `open`/`defaultOpen`/`onOpenChange` exist as a controlled escape hatch for
  advanced cases, following the same shape as every other stateful component.

## Behavior

Shown immediately on hover or keyboard focus of the anchor; hidden
immediately on hover-out or blur, unless the pointer has moved onto the
tooltip's own popover, which keeps it open. `Escape` always dismisses it.
Positioning centers on the cross axis, flips to the opposite side on
collision, and clamps flush to the viewport edge — it repositions on scroll
and window resize while open.

## Tokens and boundaries

All color, geometry, and motion values live in one `--m3e-comp-tooltip-*`
registration, split into `plain-*` and `rich-*` groups for the two
variants. Theme overrides remain scoped to `Material3Provider`; `Tooltip`
injects no runtime styles. It imports no Next.js, Vite,
router, animation library, or private application code.

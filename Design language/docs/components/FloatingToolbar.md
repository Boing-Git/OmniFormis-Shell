# FloatingToolbar

`FloatingToolbar` renders a floating pill container around toolbar
items — typically `IconButton`s — with roving-tabindex keyboard
navigation matching the WAI-ARIA APG toolbar pattern.

```tsx
import { FloatingToolbar, IconButton } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<FloatingToolbar aria-label="Formatting">
  <IconButton aria-label="Bold"><BoldIcon /></IconButton>
  <IconButton aria-label="Italic"><ItalicIcon /></IconButton>
  <IconButton aria-label="Underline"><UnderlineIcon /></IconButton>
</FloatingToolbar>
```

## Contract

- `children` are rendered directly — typically `IconButton`s. Arrow keys
  (`ArrowLeft`/`ArrowRight` for `orientation="horizontal"`, the default;
  `ArrowUp`/`ArrowDown` for `"vertical"`) move focus among them with
  wraparound; `Home`/`End` jump to the first/last. Only the current item
  is in the page's tab sequence (`tabindex="0"`); every other item is
  `tabindex="-1"`.
- `variant` (`'standard' | 'vibrant'`, default `'standard'`) selects the
  container/content color pairing.
- `expanded`/`defaultExpanded`/`onExpandedChange` control a visible
  collapse of the whole container — wire this to your own scroll
  listener for scroll-driven show/hide; `FloatingToolbar` does not manage
  scrolling itself.
- `role="toolbar"` with `aria-orientation`; `aria-label`/
  `aria-labelledby` provide the required accessible name.
- This component does not position itself against the viewport (no
  `position: fixed`/`sticky` of its own) — apply that via `className`/
  `style` for your layout.

## Tokens and boundaries

Colors, geometry, and motion timing come entirely from
`--m3e-comp-floating-toolbar-*` CSS custom properties, scoped by
`Material3Provider`. `FloatingToolbar` injects no runtime styles and uses
no `requestAnimationFrame` loop.

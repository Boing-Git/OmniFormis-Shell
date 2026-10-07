# ButtonGroup

`ButtonGroup` arranges `Button`/`IconButton` (or other interactive)
children in a horizontal row. Pressing one child visibly grows it and
compresses its immediate siblings — the Material 3 Expressive
"press-triggered neighbor compression" interaction.

```tsx
import { Button, ButtonGroup } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<ButtonGroup aria-label="Text formatting">
  <Button variant="tonal">Bold</Button>
  <Button variant="tonal">Italic</Button>
  <Button variant="tonal">Underline</Button>
</ButtonGroup>
```

## Contract

- `children` are rendered directly in a flex row with the sourced
  `BetweenSpace` gap — there is no data-driven item API; use whatever
  interactive elements you'd otherwise render (typically `Button`/
  `IconButton`).
- `role="group"` by default (override with an explicit `role`, e.g.
  `"toolbar"`); `aria-label`/`aria-labelledby` name the group as a whole.
  Every child keeps native tab order and its own accessible name.
- Only the standard row treatment is covered. For a connected,
  single/multi-select row of buttons, use `SegmentedButtonGroup` instead.
- No automatic overflow into a dropdown menu — use `flex-wrap` or your
  own responsive logic if children may not all fit.

## Tokens and boundaries

Spacing and the press-compression scale come entirely from
`--m3e-comp-button-group-*` CSS custom properties, scoped by
`Material3Provider`. `ButtonGroup` injects no runtime styles and uses no
`requestAnimationFrame` loop — the compression interaction is a CSS
`transform: scale()` pair reading each child's own native `:active` state
via `:has()`, not a JavaScript layout measurement.

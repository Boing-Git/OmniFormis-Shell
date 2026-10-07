# NavigationSuite

`NavigationSuite` picks the right navigation layout for the current
viewport width automatically: `NavigationBar` below 600px,
`NavigationRail` from 600–839px, and a permanent `NavigationDrawer` at
840px and up — the pinned Material breakpoint tiers.

```tsx
import { Icon, NavigationSuite } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<NavigationSuite
  aria-label="Primary sections"
  items={[
    { value: 'home', label: 'Home', icon: <Icon source="home" /> },
    { value: 'favorites', label: 'Favorites', icon: <Icon source="favorite" /> },
  ]}
/>
```

## Contract

- `items`, `value`/`defaultValue`/`onValueChange` reuse `NavigationBar`'s
  own `NavigationItem` shape. `header` passes through to `NavigationRail`
  only (ignored at the other two tiers).
- Registers no component tokens of its own — whichever of `NavigationBar`/
  `NavigationRail`/`NavigationDrawer` is currently rendered supplies every
  color, geometry, and motion value.
- Server-rendered and pre-hydration markup always reflects the compact
  tier (`NavigationBar`), since there is no real viewport to measure yet;
  a client effect measures the actual width immediately after mount and
  corrects it.

## Anatomy, variants, states, and accessibility

Exactly one public navigation component is rendered at a time: a bar in the
compact tier, a rail in the medium tier, or a permanent drawer in the expanded
tier. Selection, disabled items, optional links, icon geometry, and controlled/
uncontrolled value state are delegated to that component's public contract.

Pass an accessible name such as `aria-label` to identify the navigation region.
The rendered bar, rail, or drawer uses native navigation links/buttons and
`aria-current`; it does not adopt tablist arrow-key behavior. Server markup is
fully operable as a compact bar before the viewport-specific enhancement runs.

## Tokens and boundaries

Theme overrides remain scoped to `Material3Provider`; `NavigationSuite`
injects no runtime styles. It imports no Next.js, Vite,
router, animation library, or private application code.

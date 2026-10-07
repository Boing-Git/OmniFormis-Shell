# NavigationRail

`NavigationRail` is `NavigationBar`'s vertical sibling: the same item
language (fixed-size icon, width-expanding pill, label) laid out in a fixed-width side
column, with an optional `header` region above the items.

```tsx
import { FloatingActionButton, Icon, NavigationRail } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<NavigationRail
  aria-label="Primary sections"
  header={<FloatingActionButton aria-label="Compose" icon={<Icon source="add" />} size="medium" />}
  items={[
    { value: 'home', label: 'Home', icon: <Icon source="home" /> },
    { value: 'favorites', label: 'Favorites', icon: <Icon source="favorite" /> },
  ]}
/>
```

## Contract

- `items`, `value`/`defaultValue`/`onValueChange` are identical to
  `NavigationBar`'s own contract — see its documentation for the full
  `NavigationItem` shape and link-safe `href` behavior.
- `header` is a consumer-owned region rendered above the items, typically
  a `FloatingActionButton` or menu button, matching the pinned source's
  own `header` slot.
- Selection keeps the icon in its 24×24px box and expands only the centered
  indicator background from zero width to 56×32px, matching `NavigationBar`.

## Tokens and boundaries

All color, geometry, and motion values live in one
`--m3e-comp-navigation-rail-*` registration. Theme overrides remain scoped
to `Material3Provider`; `NavigationRail` injects no runtime styles. It
imports no Next.js, Vite, router, animation library, or
private application code.

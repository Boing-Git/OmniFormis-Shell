# NavigationBar

`NavigationBar` renders a bottom navigation bar with a width-expanding pill
highlight behind the selected item's icon. It uses web-native `<nav>`/
`aria-current` navigation semantics rather than the pinned Material
source's ported tab role — it is a persistent app-navigation region, not
an in-page tab switcher (see `Tabs` for that).

```tsx
import { Icon, NavigationBar } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<NavigationBar
  aria-label="Primary sections"
  items={[
    { value: 'home', label: 'Home', icon: <Icon source="home" /> },
    { value: 'favorites', label: 'Favorites', icon: <Icon source="favorite" /> },
  ]}
/>
```

## Contract

- `items: readonly NavigationItem[]` describes the bar's content:
  `{ value, label, icon, selectedIcon?, disabled?, href? }`. This is the
  same `NavigationItem` type `NavigationRail`, `NavigationDrawer`, and
  `NavigationSuite` all reuse.
- `value`/`defaultValue`/`onValueChange` follow the same controlled/
  uncontrolled shape as every other stateful component.
  `defaultValue` falls back to the first item's value when omitted.
- An item with `href` renders a real `<a href>` instead of `<button>`, the
  same link-safe pattern `Tabs` already uses — useful for router-driven
  navigation. A disabled `href` item omits `href` (anchors have no native
  disabled state) but keeps `role="link"` so it stays identifiable to
  assistive technology.
- `selectedIcon`, when supplied, replaces `icon` while that item is
  selected (a common outlined-to-filled icon swap); omit it to reuse
  `icon` for both states. Both artworks stay inside the same 24×24px box:
  selection animates only the centered indicator background from zero width
  to its 56×32px pill, never the icon or item footprint.

## Tokens and boundaries

All color, geometry, and motion values live in one
`--m3e-comp-navigation-bar-*` registration. Theme overrides remain scoped
to `Material3Provider`; `NavigationBar` injects no runtime styles. It
imports no Next.js, Vite, router, animation library, or
private application code.

# Tabs

`Tabs` renders a roving-focus `role="tablist"` with a sliding selection
indicator. It is fully data-driven: content, panels, and even link-based
navigation tabs are all declared through `items`.

```tsx
import { Icon, Tabs } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<Tabs
  aria-label="Library sections"
  items={[
    { value: 'photos', label: 'Photos', icon: <Icon source="photo" />, panel: <PhotoGrid /> },
    { value: 'shared', label: 'Shared', icon: <Icon source="folder_shared" />, panel: <SharedList /> },
  ]}
/>
```

## Contract

- `items: readonly TabItem[]` describes the tab list's content:
  `{ value, label?, icon?, disabled?, href?, panel? }`.
- `aria-label` or `aria-labelledby` is required to name the `role="tablist"`
  region, the same required-naming contract every other group-role
  component already has.
- `value`/`defaultValue`/`onValueChange` follow the same controlled/
  uncontrolled shape as every other stateful component.
  `defaultValue` falls back to the first item's value when omitted.
- `variant` (default `'primary'`): a short, rounded indicator that hugs the
  selected tab's own content width, tinted `primary`. `'secondary'`: a
  full-width underline, tinted plain `onSurface` — deliberately more
  subdued, not brand-colored.
- `scrollable` (default `false`) switches from an evenly distributed fixed
  row to a horizontally scrolling one that keeps the selected tab in view.

## Link-safe navigation tabs

An item with `href` renders a real `<a role="tab" href>` instead of
`<button role="tab">`. Arrow-key movement still updates the local
selected/indicator state, but actual navigation is left entirely to the
browser's native anchor behavior — `Tabs` never synthesizes a navigation
from a keypress. This lets you drive `Tabs` from a router's current route:

```tsx
<Tabs
  aria-label="Settings"
  value={router.pathname}
  items={[
    { value: '/settings/profile', label: 'Profile', href: '/settings/profile' },
    { value: '/settings/billing', label: 'Billing', href: '/settings/billing' },
  ]}
/>
```

## Panels

An item with `panel` gets one `role="tabpanel"` region for the selected
item only, correctly associated via `id`/`aria-controls`/
`aria-labelledby`. If no item defines `panel` — a pure link-tabs usage —
`Tabs` renders no tabpanel region at all.

## Keyboard

| Key | Behavior |
| --- | --- |
| ArrowLeft / ArrowRight | Move focus and select, wrapping, skipping disabled tabs |
| Home / End | Jump to and select the first/last enabled tab |

## Tokens and boundaries

All color, geometry, and motion values live in one `--m3e-comp-tabs-*`
registration. Theme overrides remain scoped to `Material3Provider`; `Tabs`
injects no runtime styles. It imports no Next.js, Vite,
router, animation library, or private application code.

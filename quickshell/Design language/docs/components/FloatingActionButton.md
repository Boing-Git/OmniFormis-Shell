# FloatingActionButton

`FloatingActionButton` is the native promoted-action control for Material 3
Expressive. It supports current standard, medium, large, extended, toggle, and
elevation behavior without a router, framework, icon package, or positioning
dependency.

```tsx
import {
  FloatingActionButton,
  Icon,
} from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<FloatingActionButton
  aria-label="Create"
  icon={<Icon source="add" />}
/>
```

## Contract

- The root is always a native `<button>` with an `HTMLButtonElement` ref. It
  defaults to `type="button"`; submit/reset, form owner, name, value, disabled,
  and native handlers continue to work.
- `size` is `standard` (default), `medium`, or `large`.
- `elevation` is `default`, `lowered`, or `none` for ordinary and extended FABs.
- `icon` is required decorative artwork, normally `Icon` or an SVG.
- Adding `label` creates the matching size-aware extended FAB. `expanded`
  defaults to true and may visually collapse the label without changing the
  accessible name.
- `toggle={true}` creates an icon-only toggle FAB and statically excludes
  `label`, `expanded`, and custom elevation.

Use a FAB for the most important action on a screen. Placement, safe areas,
scroll visibility, tooltips, and future `FabMenu` composition remain owned by
the consumer or their dedicated components.

## Extended FABs

```tsx
<FloatingActionButton
  icon={<Icon source="edit" />}
  label="Compose"
  size="medium"
  expanded={isExpanded}
  elevation="lowered"
/>
```

The visible label supplies the native accessible name. When collapsed, it stays
in the accessibility tree while its visual width and opacity transition to
zero. Avoid placing interactive content in `label`.

| Size | Height | Icon | Corner | Type | Leading / trailing | Icon-label |
| --- | ---: | ---: | ---: | --- | ---: | ---: |
| `standard` | 56px | 24px | 16px | title medium | 16 / 16px | 8px |
| `medium` | 80px | 28px | 20px | title large | 26 / 26px | 12px |
| `large` | 96px | 36px | 28px | headline small | 28 / 28px | 16px |

The 12px and 16px medium/large label gaps follow the current AndroidX source
corrections while its generated token files still carry pending values.

## Toggle FABs

Toggle mode implements the current Expressive close-button transition used by
FAB menus, while remaining independently useful before `FabMenu` ships:

```tsx
const [open, setOpen] = useState(false)

<FloatingActionButton
  aria-label="Creation actions"
  icon={<Icon source="add" />}
  selectedIcon={<Icon source="close" />}
  size="large"
  toggle
  selected={open}
  onSelectedChange={setOpen}
/>
```

Use `selected` plus `onSelectedChange` for controlled state or
`defaultSelected` for uncontrolled state. Momentary FABs omit `aria-pressed`;
toggle FABs expose a boolean value. Consumer `onClick` runs first and
`preventDefault()` cancels internal state change.

Selection transitions primary-container/on-primary-container to
primary/on-primary and moves every size to a 56px fully round container with a
20px icon. Medium and large keep their original 80px or 96px footprint while
the selected visual aligns to logical top-end. This preserves layout and flips
the horizontal edge automatically in RTL.

## Elevation and state

| Mode | Rest | Hover | Focus | Pressed |
| --- | ---: | ---: | ---: | ---: |
| `default` | Level 3 | Level 4 | Level 3 | Level 3 |
| `lowered` | Level 1 | Level 2 | Level 1 | Level 1 |
| `none` | Level 0 | Level 0 | Level 0 | Level 0 |
| toggle | Level 3 | Level 3 | Level 3 | Level 3 |

Hover, focus, and pressed state layers consume system opacity tokens. Native
disabled behavior prevents activation, removes the shadow, and applies sourced
on-surface opacity roles.

## Accessibility

Icon-only FABs require localized `aria-label` or `aria-labelledby`; development
builds warn when neither exists. Extended label content supplies the name.
Every icon slot is hidden from assistive technology, so nested meaningful Icons
cannot create duplicate names.

The browser owns pointer, Enter, Space, disabled, focus, and form behavior.
Focus uses a token-backed `:focus-visible` ring. Forced-colors mode uses
ButtonFace/ButtonText, Highlight/HighlightText for selected, GrayText for
disabled, and an explicit outline. Reduced motion removes the transitions but
preserves every state change.

## Tokens and motion

Component variables use these literal groups:

- `--m3e-comp-floating-action-button-{size}-container-{size|shape}`
- `--m3e-comp-floating-action-button-{size}-icon-size`
- `--m3e-comp-floating-action-button-{size}-extended-{leading-space|trailing-space|icon-label-space}`
- ordinary, selected-toggle, and disabled color variables
- default/lowered state shadow variables and the Level 0 shadow
- toggle-selected container size/shape and icon size
- minimum-target and focus-ring variables

Extended size uses Expressive fast-spatial motion while label opacity uses
fast-effects. Toggle size, corner, and icon use fast-spatial; color uses
fast-effects. Elevation uses the default-effects projection. Theme overrides
stay scoped to `Material3Provider`; rendering injects no CSS.

## SSR and boundaries

Server markup, initial expanded state, and uncontrolled initial selection are
deterministic. `FloatingActionButton` imports only React and public and internal primitives. It does not import Next.js, Vite, private application
code, an animation runtime, or a positioning library.

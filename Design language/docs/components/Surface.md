# Surface

`Surface` is the passive Material container foundation. It applies a semantic
container/content color pair, shape clipping, tonal elevation, and shadow
elevation without creating interaction behavior.

```tsx
import { Surface } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<Surface
  as="section"
  aria-labelledby="account-heading"
  color="surface-container-low"
  shape="extra-large"
  shadowElevation={1}
>
  <h2 id="account-heading">Account</h2>
  <p>Profile and security settings.</p>
</Surface>
```

## Contract

- `as` defaults to `div` and accepts only `div`, `section`, `article`, `aside`,
  `main`, `header`, `footer`, or `nav`. The selected element controls semantics;
  Surface never adds a role.
- `color` defaults to `surface`. Surface-container roles use `onSurface`;
  accent, error, fixed, and inverse roles select their corresponding Material
  content role.
- `shape` defaults to `none` and exposes all current system corner roles. Start
  and end shapes swap under RTL.
- `tonalElevation` and `shadowElevation` independently accept levels `0` through
  `5`. Tonal elevation affects only the base `surface` role. Shadow elevation is
  visual and never changes CSS stacking order. Development builds warn when a
  nonzero tonal level is paired with a color role it cannot affect.
- Native attributes, ARIA/data attributes, styles, classes, handlers, children,
  and a correctly narrowed ref are forwarded to the selected element.

Surface is deliberately non-interactive. Use the later purpose-built `Button`,
`Card`, or selection components for click, keyboard, disabled, selected, or
checked behavior. Attaching a click handler to a passive container does not make
it keyboard accessible.

## Color roles

Supported roles are the surface family (`surface`, `surface-dim`,
`surface-bright`, and the five `surface-container-*` emphases), primary,
secondary, and tertiary base/container/fixed roles, `error`, `error-container`,
and `inverse-surface`. Fixed-dim roles use the corresponding high-emphasis
`on*Fixed` content color; lower-emphasis content can choose its own color in a
descendant.

## Tokens

The default component variables are:

- `--m3e-comp-surface-container-color`
- `--m3e-comp-surface-content-color`
- `--m3e-comp-surface-container-shape`
- `--m3e-comp-surface-container-shadow`
- `--m3e-comp-surface-tonal-overlay-opacity`

Explicit variants resolve through `--m3e-sys-color-*`,
`--m3e-sys-shape-corner-*`, and `--m3e-sys-elevation-*`. Override the system
theme for a coordinated design system; override the registered Surface component
tokens only when changing the unconfigured Surface defaults.

## Accessibility and adaptation

Surface introduces no focus stop, keyboard behavior, accessible state, or
interactive role. Landmark naming and document-outline correctness remain with
the consumer because they depend on page context. It has no motion, and it does
not opt out of browser forced-color adjustment.

On the web, authored CSS clips children and projects shadows. Unlike Android
Compose, discrete tonal levels are not accumulated through nested runtime
composition locals; nested surfaces should select an explicit surface-container
role or tonal level. This keeps styling static, SSR-safe, and responsive to
scoped CSS theme overrides.

# IconButton

`IconButton` is a native icon-only action with the current Material 3
Expressive sizes, widths, shapes, and toggle behavior. It has no framework,
router, tooltip, or icon-package dependency.

```tsx
import {
  Icon,
  IconButton,
} from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<IconButton aria-label="Search">
  <Icon source="search" />
</IconButton>
```

## Contract

- The root is always a native `<button>` and its ref is an
  `HTMLButtonElement`. It defaults to `type="button"`; explicit submit/reset,
  form ownership, name, and value retain native behavior.
- `variant` is `standard` (default), `filled`, `tonal`, or `outlined`.
- `size` is `extra-small`, `small` (default), `medium`, `large`, or
  `extra-large`.
- `width` is `narrow`, `uniform` (default), or `wide`. These are sourced visual
  container widths, not page-layout or full-width modes.
- `shape` is `round` (default) or `square`. Pressed and selected states morph
  to the current size tier's sourced shapes.
- `children` is the decorative default visual. Pass `Icon`, SVG, or equivalent
  non-interactive artwork. A toggle may pass `selectedIcon` for an alternate
  selected visual.

`IconButton` does not render a link or tooltip. Use a link for navigation and
associate any tooltip as a separate accessible description.

## Toggle buttons

Toggle mode is explicit and uses native ARIA toggle-button semantics:

```tsx
const [favorite, setFavorite] = useState(false)

<IconButton
  aria-label="Favorite"
  variant="filled"
  toggle
  selected={favorite}
  onSelectedChange={setFavorite}
  selectedIcon={<Icon source="favorite" fill={1} />}
>
  <Icon source="favorite" />
</IconButton>
```

Use `selected` with `onSelectedChange` for controlled state, or
`defaultSelected` for uncontrolled state. The button emits boolean
`aria-pressed`; momentary buttons omit it. `onClick` runs before internal state
behavior, and `event.preventDefault()` cancels the toggle. Enter, Space, pointer
activation, disabled behavior, and focus remain browser-owned.

Keep the accessible name stable, such as “Favorite.” The pressed state says
whether that action is active; changing the name between “Favorite” and
“Unfavorite” would make the meaning of `aria-pressed` ambiguous. An alternate
selected icon is recommended whenever the visual state would otherwise depend
only on color.

## Expressive dimensions

| Size | Height | Icon | Narrow | Uniform | Wide | Outline |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `extra-small` | 32px | 20px | 28px | 32px | 40px | 1px |
| `small` | 40px | 24px | 32px | 40px | 52px | 1px |
| `medium` | 56px | 24px | 48px | 56px | 72px | 1px |
| `large` | 96px | 32px | 64px | 96px | 128px | 2px |
| `extra-large` | 136px | 40px | 104px | 136px | 184px | 3px |

The semantic root remains at least 48 by 48 CSS pixels even when the visual
container is smaller or narrower. Large tiers are prominent actions, not
density substitutes.

## Shape and color

Round resting shapes use exact half-height radii. Square resting roles progress
from medium to large and extra-large. Pressing morphs to small, medium, or large
corners by tier. Toggle selection intentionally makes a round button more
square and a square button fully round, following the current Expressive token
pairs.

| Variant | Momentary/default | Toggle selected |
| --- | --- | --- |
| `standard` | transparent / on-surface-variant | transparent / primary |
| `filled` | primary / on-primary | primary / on-primary |
| `tonal` | secondary-container / on-secondary-container | secondary / on-secondary |
| `outlined` | transparent / on-surface-variant with outline-variant | inverse-surface / inverse-on-surface, no outline |

Filled toggles use surface-container/on-surface-variant while unselected, then
the selected filled pair. Disabled roles and opacities follow the pinned
AndroidX defaults.

## Accessibility

Every icon-only button requires a localized `aria-label` or
`aria-labelledby`; development builds warn when both are empty. The visual
container is `aria-hidden`, so even a mistakenly meaningful nested `Icon`
cannot create a duplicate name. Do not place text or another interactive
element inside the visual slot.

Keyboard focus uses a token-backed `:focus-visible` ring. Forced-colors mode
uses ButtonFace/ButtonText, Highlight/HighlightText for selected, GrayText for
disabled, and a visible border for every variant. Reduced motion removes shape,
color, and state-layer transitions while preserving immediate state changes.

## Tokens

IconButton component variables follow literal groups:

- `--m3e-comp-icon-button-{size}-container-height`
- `--m3e-comp-icon-button-{size}-container-width-{narrow|uniform|wide}`
- `--m3e-comp-icon-button-{size}-icon-size`
- `--m3e-comp-icon-button-{size}-container-shape-{round|square}`
- `--m3e-comp-icon-button-{size}-pressed-container-shape`
- `--m3e-comp-icon-button-{size}-selected-container-shape-{round|square}`
- `--m3e-comp-icon-button-{size}-outline-width`
- variant container/content/selected/disabled color variables
- shared disabled opacity and focus-ring variables

The component consumes the Expressive default-effects spring already projected
by the token serializer. Theme overrides remain scoped to `Material3Provider`;
rendering injects no stylesheet.

## Bidirectionality and SSR

All dimensions use logical inline/block properties. Icon artwork opts into RTL
mirroring through `Icon`; IconButton does not guess whether an image is
directional. Markup and uncontrolled initial selection are deterministic under
React server rendering and hydration.

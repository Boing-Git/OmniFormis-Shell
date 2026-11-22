# Checkbox

`Checkbox` is a native `input type="checkbox"` with current Material container,
outline, checkmark, state-layer, and motion behavior. It owns no label, so it
composes with ordinary HTML labelling.

```tsx
import { Checkbox } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<label>
  <Checkbox name="preferences" value="marketing" defaultChecked />
  Send me product updates
</label>
```

## Contract

- The rendered control is one native checkbox input. Its ref, `name`, `value`,
  `form`, `required`, `id`, ARIA and data attributes, and native handlers are
  forwarded to that input.
- `className` and `style` describe the checkbox root, which owns the 48px
  interaction target around the sourced 18px box.
- `checked` with `onCheckedChange` is controlled; `defaultChecked` is
  uncontrolled and leaves checkedness to the DOM, including native form reset.
- `onChange` runs before the library updates state, and `preventDefault()`
  cancels that update.
- `onCheckedChange` reports the value the browser resolved, so it never needs a
  separate toggle calculation.

## Mixed state

`indeterminate` renders the sourced dash, sets the native `indeterminate`
property, and exposes `aria-checked="mixed"`. It is a controlled visual state:
activation resolves the control to a real checked value, and the consumer clears
the prop from its handler.

```tsx
const allChecked = items.every((item) => item.selected)
const someChecked = items.some((item) => item.selected)

<Checkbox
  aria-label="Select all"
  checked={allChecked}
  indeterminate={!allChecked && someChecked}
  onCheckedChange={selectAll}
/>
```

The property cannot be serialized, so server markup carries `aria-checked` and
the state attribute, and the property is applied after hydration. It is also
reapplied after every commit because browsers clear it on activation.

## States and motion

| State | Container | Outline | Checkmark |
| --- | --- | --- | --- |
| unchecked | transparent | on-surface-variant | none |
| checked | primary | primary | on-primary |
| indeterminate | primary | primary | on-primary dash |
| disabled unchecked | transparent | on-surface at 0.38 | none |
| disabled checked | on-surface at 0.38 | on-surface at 0.38 | surface |
| disabled indeterminate | on-surface at 0.38 | on-surface at 0.38 | surface |

Hover, focus, and pressed use the 40px circular state layer. The checkmark is
revealed along its own path with Expressive default-spatial motion, and leaving
the drawn states snaps after the sourced 100ms delay instead of undrawing.
Moving between checked and indeterminate interpolates the same three-point
polyline the first-party implementation gravitates toward its centre line.
Reduced motion makes every one of those changes immediate.

Current AndroidX Checkbox has no size, variant, or error parameter, and no shape
morph. This implementation therefore ships one form and does not invent
Expressive geometry that the pinned source does not define.

## Accessibility

The native control supplies role, checked state, required state, and keyboard
behavior; Space activates and Enter does not. Naming comes from a wrapping
`label`, `label for`, `aria-label`, or `aria-labelledby`.

The 18px box sits inside a 48px target. `:focus-visible` draws a token-backed
focus ring on the box. Forced-colors mode keeps the outline, uses Highlight for
the checked container and focus ring, and GrayText for disabled treatment.
Layout is logical, so the control behaves correctly in RTL.

## Tokens and boundaries

Checkbox registers searchable `--m3e-comp-checkbox-*` variables for:

- minimum target, container size and shape, outline width, state-layer size,
  checkmark stroke width, checkmark path length, and snap delay;
- checked and disabled checkmark colors;
- checked and disabled container colors with their separate opacities;
- checked, unchecked, and the three disabled outline colors;
- checked and unchecked state-layer colors, and the focus ring.

Theme overrides remain scoped to `Material3Provider`; Checkbox injects no
runtime styles. It imports no Next.js, Vite, router, animation
library, or private application code.

# Radio

`Radio` is a native `input type="radio"` with current Material icon,
state-layer, and motion behavior. It owns no label, so it composes with
ordinary HTML labelling, and no group wrapper, so it composes with ordinary
native grouping.

```tsx
import { Radio } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<label>
  <Radio name="plan" value="pro" defaultChecked />
  Pro plan
</label>
<label>
  <Radio name="plan" value="team" />
  Team plan
</label>
```

## Contract

- The rendered control is one native radio input. Its ref, `value`, `form`,
  `required`, `id`, ARIA and data attributes, and native handlers are
  forwarded to that input.
- `name` is required. Two or more `Radio`s that share a `name` form one
  native group: the browser enforces mutual exclusivity and moves both focus
  and selection with arrow keys, without any orchestration from this library.
- `className` and `style` describe the radio root, which owns the 48px
  interaction target around the sourced 20px circle.
- `checked` with `onCheckedChange` is controlled; `defaultChecked` is
  uncontrolled and leaves checkedness to the DOM, including native form reset
  and native deselection by a sibling in the same group.
- `onChange` runs before the library updates state, and `preventDefault()`
  cancels that update.
- `onCheckedChange` reports the value the browser resolved, so it never needs
  a separate toggle calculation.

## States and motion

| State | Ring and dot |
| --- | --- |
| unselected | on-surface-variant |
| selected | primary |
| disabled unselected | on-surface at 0.38 |
| disabled selected | on-surface at 0.38 |

Hover, focus, and pressed use the 40px circular state layer. The dot scales
in and out with Expressive fast-spatial motion regardless of disabled state;
the shared ring/dot color transitions with Expressive default-effects motion
while enabled and snaps immediately while disabled, matching the source's own
enabled-only color animation guard. Reduced motion makes every one of those
changes immediate.

Current AndroidX RadioButton has no size, variant, or error parameter, so this
implementation ships one form and does not invent Expressive geometry that the
pinned source does not define.

## Accessibility

The native control supplies role, checked state, required state, and keyboard
behavior: Space activates a focused, unchecked radio, arrow keys move focus
and selection within the shared `name` group, and Enter does not activate.
Naming comes from a wrapping `label`, `label for`, `aria-label`, or
`aria-labelledby`.

The 20px circle sits inside a 48px target. `:focus-visible` draws a
token-backed focus ring on the circle. Forced-colors mode keeps the ring
outline, uses Highlight for the selected ring/dot and focus ring, and GrayText
for disabled treatment. Layout is logical, so the control behaves correctly in
RTL.

## Tokens and boundaries

Radio registers searchable `--m3e-comp-radio-*` variables for:

- minimum target, container size, outline width, dot size, and state-layer
  size;
- selected and unselected icon color, shared by the ring and the dot;
- disabled-selected and disabled-unselected icon color with their separate
  opacities;
- selected and unselected state-layer color, and the focus ring.

Theme overrides remain scoped to `Material3Provider`; Radio injects no runtime
styles. It imports no Next.js, Vite, router, animation library,
or private application code.

# Switch

`Switch` is `input type="checkbox" role="switch"` with current Material
track, thumb, state-layer, and pressed-shape motion behavior. It owns no
label, so it composes with ordinary HTML labelling.

```tsx
import { Switch } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<label>
  <Switch name="notifications" defaultChecked />
  Notifications
</label>
```

## Contract

- The rendered control is one native checkbox input exposed as a switch. Its
  ref, `name`, `value`, `form`, `required`, `id`, ARIA and data attributes,
  and native handlers are forwarded to that input. `role` and `type` are
  fixed and cannot be overridden.
- `className` and `style` describe the switch root, which owns the 48px
  interaction target around the sourced 52×32px track.
- `checked` with `onCheckedChange` is controlled; `defaultChecked` is
  uncontrolled and leaves checkedness to the DOM, including native form
  reset.
- `onChange` runs before the library updates state, and `preventDefault()`
  cancels that update.
- `onCheckedChange` reports the value the browser resolved, so it never
  needs a separate toggle calculation.

## Thumb icon

`thumbIcon` reproduces the pinned `thumbContent` slot: decorative content
drawn inside the thumb. The slot centers artwork in the sourced 16×16px box;
a direct `Icon`, SVG, or image is constrained to that size automatically.
Other custom content should likewise fit the 16px box. Its presence keeps the
thumb at the selected handle size even while unchecked, matching the source's
own `hasContent || checked` sizing rule.

```tsx
<Switch
  aria-label="Wi-Fi"
  checked={wifiOn}
  onCheckedChange={setWifiOn}
  thumbIcon={<Icon source={wifiOn ? 'check' : 'close'} />}
/>
```

## States and motion

| State | Track | Thumb | Thumb size |
| --- | --- | --- | --- |
| unselected | surface-container-highest, outline border | outline | 16px |
| selected | primary, no border | on-primary | 24px |
| disabled unselected | surface-container-highest / on-surface at 0.12 | on-surface at 0.38 | 16px |
| disabled selected | on-surface at 0.12, no border | surface | 24px |

Hover, focus, and pressed use a 40px circular state layer centered on the
thumb's own position, so it slides with the thumb rather than staying fixed
at the track's center. Pressing grows the thumb to 28px instantly; releasing
animates it back to its resting size with Expressive fast-spatial motion —
the same asymmetry the source's own snap-while-pressed animation spec
defines. Track and thumb color transition with Expressive default-effects
motion. Reduced motion makes every one of those changes immediate.

The resting thumb's outer-box start is 8px without an icon, 4px with an icon,
and 24px when checked; pressed starts are 2px and 22px. These logical offsets
mirror in RTL.

Current AndroidX Switch has no size, variant, or error parameter, so this
implementation ships one form and does not invent Expressive geometry that
the pinned source does not define.

## Accessibility

`role="switch"` on a native checkbox input needs no explicit `aria-checked`:
the browser derives the accessible checked state from the native `checked`
property the same way it does for the implicit checkbox role. Space
activates and Enter does not. Naming comes from a wrapping `label`,
`label for`, `aria-label`, or `aria-labelledby`.

The 32px-tall track sits inside a 48px target. `:focus-visible` draws a
token-backed focus ring on the track. Forced-colors mode keeps the track
outline, uses Highlight for the selected track/thumb and focus ring, and
GrayText for disabled treatment. Layout is logical, so the control behaves
correctly in RTL.

## Tokens and boundaries

Switch registers searchable `--m3e-comp-switch-*` variables for:

- minimum target, track width/height, track outline width, unselected/
  selected/pressed handle size, icon size, and state-layer size;
- selected and unselected track/thumb/icon color;
- disabled-selected and disabled-unselected thumb/icon color with their own
  opacities, and a single shared disabled-track opacity reused by the
  disabled track and disabled unselected border roles;
- the focus ring.

Theme overrides remain scoped to `Material3Provider`; Switch injects no
runtime styles. It imports no Next.js, Vite, router, animation
library, or private application code.

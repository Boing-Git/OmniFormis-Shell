# TextField

`TextField` is a native `input` with a Material label, indicator/outline,
icon slots, and supporting/error text, in the `filled` and `outlined`
variants. It shares its label/border/icon/supporting-text decoration with
`TextArea` — the pinned source itself reuses one decoration layer for both
single- and multi-line fields.

```tsx
import { TextField } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<TextField
  label="Email"
  variant="outlined"
  type="email"
  value={email}
  onChange={(event) => setEmail(event.currentTarget.value)}
/>
```

## Contract

- The rendered control is one native `input`, associated with a native
  `label` through `htmlFor`/`id` (generated with `useId()` when the caller
  supplies none). Its ref, `name`, `value`/`defaultValue`, `form`,
  `required`, ARIA and data attributes, and native handlers are forwarded to
  that input.
- `className` and `style` describe the field root.
- Value state is left entirely to native controlled/uncontrolled `input`
  behavior — this component owns no derived value state, so React's own
  development warnings for conflicting `value`/`defaultValue` already apply.
- `type` accepts text-like values (`text`, `email`, `password`, `search`,
  `tel`, `url`, `number`); types with incompatible browser-owned chrome are
  excluded at the type level.
- `error` sets `aria-invalid` (unless the caller already set their own) and
  recolors the label, indicator/outline, and supporting text. It does not
  alter `supportingText` content — the caller owns the message.

## Floating label

The label floats between a large resting position/type size and a small
top-aligned position/type size, driven by the input's own native
`:focus`/`:placeholder-shown` pseudo classes rather than React-rendered
state. That means the label repositions correctly even when the value
changes outside a normal input event — browser autofill, a form reset, an
imperative ref write — the same native-truth precedent established for
Radio's checked state.

A caller-supplied `placeholder` is shown only once the label has floated
clear of the input's resting position, matching the pinned source's own
placeholder slot. When no `placeholder` is supplied, the native attribute
still resolves to a single space internally — purely so
`:placeholder-shown` keeps working — and nothing is visibly shown.

## Variants

| Variant | Container | Border affordance |
| --- | --- | --- |
| `filled` (default) | surface-container-highest, top-only rounded | 1px bottom indicator, 2px focused |
| `outlined` | transparent, fully rounded | 1px border with a label-sized notch, 2px focused |

The outlined notch uses three CSS flex panels. A hidden body-small label
clone gives the middle panel its intrinsic width, and that panel's top stroke
scales away when the visible label floats. This produces a label-sized gap
without JS measurement while keeping the outline and label in the same
border-box coordinate system.

## Icons and supporting text

```tsx
<TextField
  variant="outlined"
  label="Search"
  leadingIcon={<Icon source="search" />}
  supportingText="Press enter to search"
/>
```

`leadingIcon`/`trailingIcon` render inside a 48px touch target at the
field's edges. The field owns separate logical start, native-input, and end
regions: an ordinary edge reserves 16px, while an icon edge reserves the 48px
target plus a 4px content gap. The input occupies only the middle region, so
its caret, placeholder, text, and browser-owned affordances cannot move under
an icon when downstream CSS resets native input padding. A transparent native
label keeps the complete field surface clickable without expanding the input
back beneath those regions. `supportingText` renders below the field and is
associated through `aria-describedby`, composed with any caller-supplied
`aria-describedby` rather than replacing it.

The field also owns explicit top, input-content, and bottom rows instead of
using native-control block padding for vertical placement. Filled resolves to
24/24/8px: the first 24px contains the 8px top inset and minimized 16px label,
the input line occupies the next 24px, and 8px remains below. Outlined resolves
to 16/24/16px. Consequently, unlayered native-control padding resets cannot
move a populated value or caret into its label.

## Tokens and boundaries

`TextField` and `TextArea` share one `--m3e-comp-text-field-*` registration.
Every content color role (input, placeholder, label, icons, supporting text)
is identical between the pinned source's filled and outlined token files, so
this port keeps one unprefixed copy of each rather than a duplicated pair;
only the container fill/shape and the indicator/outline border are
registered per variant.

Theme overrides remain scoped to `Material3Provider`; `TextField` injects no
runtime styles. It imports no Next.js, Vite, router, animation
library, or private application code.

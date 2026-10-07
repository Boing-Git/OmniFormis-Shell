# SplitButton

`SplitButton` pairs a primary action button with an icon-only toggle
button (typically a chevron opening an attached menu), visually joined as
one pill with a small shared inner-corner radius. The trailing button
morphs to a full circle while `selected`.

```tsx
import { SplitButton } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<SplitButton
  onClick={save}
  trailingIcon={<ChevronDownIcon />}
  trailingLabel="More save options"
  selected={menuOpen}
  onSelectedChange={setMenuOpen}
>
  Save
</SplitButton>
```

## Contract

- `children` is the leading button's label; `leadingIcon` is optional.
  `onClick` fires only for the leading button.
- `trailingIcon` and `trailingLabel` (the icon-only button's accessible
  name) are required. `selected`/`defaultSelected`/`onSelectedChange`
  follow the same controlled/uncontrolled toggle contract as `IconButton`
  — wire them to an actual menu (e.g. this project's own `Menu`) yourself.
- `variant` (`filled` | `tonal` | `elevated` | `outlined`, default
  `filled`) and `size` (`extra-small` | `small` | `medium` | `large` |
  `extra-large`, default `small`) apply to both buttons together.
- `disabled` disables both buttons together.

## Tokens and boundaries

Colors, geometry, and per-size dimensions come entirely from
`--m3e-comp-split-button-*` CSS custom properties, scoped by
`Material3Provider`. `SplitButton` injects no runtime styles and renders
its own two `<button>` elements directly (it does not nest the public
`Button`/`IconButton` components).

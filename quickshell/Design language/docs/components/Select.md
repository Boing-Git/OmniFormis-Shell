# Select

`Select` is a data-driven combobox: a read-only trigger field built on the
same chrome as `TextField`, plus a popup listbox built on the same chrome as
`Menu`. No native `<select>` element is used — Material's opinionated option
rows cannot be styled inside a native `<select>`'s popup across this
library's browser floor.

```tsx
import { Select } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<Select
  label="Favorite fruit"
  options={[
    { value: 'apple', label: 'Apple' },
    { value: 'banana', label: 'Banana' },
    { value: 'cherry', label: 'Cherry' },
  ]}
  value={value}
  onValueChange={setValue}
/>
```

## Contract

- `value`/`defaultValue`/`onValueChange` (all `string`) follow the same
  controlled/uncontrolled shape as every other stateful component.
- `options: readonly SelectOption[]` is `{ value, label: string, disabled? }`
  — `label` is a plain string, not a node, since it also becomes the
  trigger's own displayed value, the same way a native `<select>`'s
  `<option>` text is inherently plain text too.
- `label`, `variant` (`"filled"` default, or `"outlined"`), `leadingIcon`,
  `supportingText`, `error`, `disabled` all mirror `TextField`'s own prop
  names and defaults exactly.
- `open`/`defaultOpen`/`onOpenChange` control the popup listbox, following
  the same shape, if you need to observe or drive it directly.
- The forwarded ref points at the visible trigger `input` — read-only, not
  editable; typing does not filter the options.
- The read-only trigger inherits `TextFieldChrome`'s distinct logical
  start/content/end regions. Its optional leading icon and required trailing
  chevron therefore reserve their own space outside the input, keeping the
  displayed value and browser-owned input area clear of both decorations even
  when downstream CSS resets input padding.
- The trigger also inherits the shared top/content/bottom grid rows, so its
  filled and outlined label/value placement does not depend on native input
  block padding.

## Keyboard

Closed: Enter, Space, ArrowDown, or ArrowUp opens the listbox with the
active option on the current selection (or the first/last enabled option if
none is selected). Open: ArrowDown/ArrowUp/Home/End move the active option,
typing jumps by prefix, Enter/Space commits and closes, Escape closes
without changing the value, Tab closes.

Unlike `Menu`, focus never leaves the trigger — the currently highlighted
option is tracked with `aria-activedescendant`, following the WAI-ARIA APG
select-only combobox pattern exactly, rather than `Menu`'s own real
per-item focus movement.

## Forms

```tsx
<Select label="Favorite fruit" name="favorite-fruit" options={options} defaultValue="apple" />
```

`name`, when supplied, renders a companion `<input type="hidden">` carrying
the current value, so `Select` participates in native form submission,
`FormData`, and `form.reset()` despite its visible control being a
non-value-carrying, read-only display input.

## Tokens and boundaries

`Select` registers no component tokens of its own: its field chrome reuses
`TextField`'s `--m3e-comp-text-field-*` registration, and its popup listbox
reuses `Menu`'s `--m3e-comp-menu-*` registration, unchanged. Theme overrides
to either domain apply here too, scoped to `Material3Provider`; `Select`
injects no runtime styles. It imports no Next.js, Vite,
router, animation library, or private application code.

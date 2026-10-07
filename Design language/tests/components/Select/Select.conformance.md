# Select conformance

Task: T17
Status: conformant
Reviewed: 2026-07-21

## Primary references

- Material Design menus component guide (exposed dropdown menu section),
  accessed 2026-07-20:
  <https://m3.material.io/components/menus/overview>
- Pinned current AndroidX `ExposedDropdownMenu.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/ExposedDropdownMenu.kt>
- The same `MenuTokens`/`ListTokens`/`StandardMenuTokens` and
  `FilledTextFieldTokens`/`OutlinedTextFieldTokens` this task's `Menu` and
  T14's `TextField` already cite — `Select` registers no tokens of its own.
- WAI-ARIA APG select-only combobox pattern, accessed 2026-07-20:
  <https://www.w3.org/WAI/ARIA/apg/patterns/combobox/examples/combobox-select-only/>
- WCAG 2.2 focus visible, target size, and reduced motion, accessed 2026-07-20:
  <https://www.w3.org/TR/WCAG22/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`. No native `<select>` element is
used — Material's opinionated option rows cannot be styled inside a native
`<select>`'s popup across this library's browser floor — so, following the
pinned source's own `ExposedDropdownMenuBox` (which composes a real
`TextField`/`OutlinedTextField` rather than any native platform picker),
`Select` composes T14's `TextFieldChrome` around a read-only trigger `input`
plus a popup listbox built from this task's own `Menu` container/item
stylesheet, reused unchanged.

## Anatomy and content

- One public, data-driven `Select` component: `options: readonly
  SelectOption[]` (`{ value, label: string, disabled? }`) — `label` is a
  plain string, unlike `MenuItem.label`, since it also becomes the trigger's
  own displayed value, the same way a native `<select>`'s `<option>` text is
  inherently plain text too.
- The visible trigger is a read-only native `input` decorated by
  `TextFieldChrome`: `label`, `variant` (`filled`/`outlined`, default
  `filled`), `leadingIcon`, `supportingText`, `error`, `disabled` all mirror
  `TextField`'s own prop names and defaults exactly. It occupies the shared
  middle content region; the optional leading icon and required trailing
  chevron own separate 52px edge regions rather than overlaying a full-width
  input, so downstream input-padding resets cannot move the displayed value or
  browser-owned control area underneath either decoration.
  The trigger also occupies the shared structural middle block row, preserving
  filled 24/24/8px and outlined 16/24/16px label/value geometry when native
  input block padding is reset.
- A fixed chevron SVG — not a Material Symbols glyph, since baking in a font
  dependency the consumer has not opted into would break "font loading
  remains consumer-owned" — fills `TextFieldChrome`'s existing
  `trailingIcon` slot, inheriting its enabled/disabled/error color handling
  with no new token, and rotates 180° off the trigger's own
  `aria-expanded="true"` attribute via a CSS sibling selector, the same
  native-truth precedent ADR 0016 established for Dialog.
- The popup listbox reuses `Menu`'s own `.m3e-menu`/`.m3e-menu__item`
  classes and `--m3e-comp-menu-*` tokens unchanged, matching how
  `ExposedDropdownMenuDefaults` itself resolves straight through to
  `MenuDefaults.shape`/`containerColor`/`TonalElevation`/`ShadowElevation` —
  the exact same values plain `DropdownMenu` uses, not a distinct
  exposed-dropdown token set.

## Variants, shape, color, and size

- Field chrome: identical to `TextField`'s filled/outlined container, label
  float, outline notch, and icon color roles — `Select` registers no
  component tokens of its own for any of it.
- Listbox: identical to `Menu`'s container/item geometry and color, except
  width is forced to match the trigger's own rendered width
  (`ExposedDropdownMenuBox`'s own `matchAnchorWidth = true` default) rather
  than `Menu`'s intrinsic 112–280px bounds.
- The currently-selected option reuses the same checked-item tertiary-
  container roles `Menu`'s own checkable items already register.
- The keyboard-active (not yet committed) option shows the shared
  `--m3e-sys-state-focus` opacity, since it never receives real DOM focus
  under the `aria-activedescendant` model below.

## States and motion

- Enabled/hovered (real `:hover`)/keyboard-active/selected/disabled options
  are all covered by the reused `Menu` item rules plus one Select-only
  active-option rule.
- Positioning and entrance/exit motion are identical to `Menu`'s — see its
  own conformance doc — with the popup always attempted below the trigger
  first (`ExposedDropdownMenuBox`'s own `MenuAnchorPosition.Below` default),
  flipping above only when there is insufficient space.

## Accessibility

- The trigger is `role="combobox"` with `aria-haspopup="listbox"`,
  `aria-expanded`, `aria-controls`, and `aria-activedescendant` (present
  only while open) — the APG select-only combobox pattern exactly. DOM focus
  never leaves the trigger, a deliberate divergence from `Menu`'s own real
  per-item focus movement, matching each component's own distinct,
  authoritative APG pattern rather than forcing one shared technique.
  `aria-autocomplete="none"` reflects that this is a value-picker, not a
  filterable/editable combobox.
- Keyboard: closed, Enter/Space/ArrowDown/ArrowUp/click open the listbox
  with the active descendant on the selected option (or the first/last
  enabled option if none is selected, for Down/Up respectively); open,
  ArrowDown/ArrowUp/Home/End/typeahead move the active descendant across
  enabled options only; Enter/Space commits and closes; Escape closes
  without changing the value; Tab closes.
- A disabled option is skipped by keyboard navigation and unselectable by
  click; a disabled `Select` opens on neither click nor keyboard.
- The shared transparent associated label keeps the full field surface
  activatable after the trigger input is confined to its middle content
  region; activation still dispatches through the native input's existing
  click handler and `aria-expanded` state.
- `name`, when supplied, renders one native `<input type="hidden">`
  carrying the current value, so `Select` still participates in native form
  submission/`FormData`/`form.reset()` despite its visible control being a
  non-value-carrying, read-only display input — the first hidden-input forms
  shim here, necessary specifically because no native form-associated
  element can render Material's option rows, unlike every prior form
  control's real native element.

## Web-specific deviations

- No native `<select>` element — see Supported Material baseline above.
- `SelectOption.label` is constrained to `string`, narrower than
  `MenuItem.label`'s `ReactNode`, a deliberate scope-narrowing since the
  label serves double duty as both the option row's content and the
  trigger's own displayed input value — a native `<select>`'s `<option>`
  text has the same constraint.
- The hidden-input forms shim (see Accessibility) has no precedent among
  Checkbox/Radio/Switch/TextField/SegmentedButtonGroup, which all use a real
  native form-associated element directly.

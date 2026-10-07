# SegmentedButtonGroup

`SegmentedButtonGroup` renders a row of Material segmented buttons from one
declarative `segments` array — a native radio group for mutually exclusive
selection, or independent native checkboxes for multi-selection. There is no
compound-children API: content, order, and count all come from `segments`.

```tsx
import { SegmentedButtonGroup } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<SegmentedButtonGroup
  segments={[
    { value: 'day', label: 'Day' },
    { value: 'week', label: 'Week' },
    { value: 'month', label: 'Month' },
  ]}
  aria-label="View"
  value={view}
  onValueChange={setView}
/>
```

## Contract

- Each segment renders one native `<input type="radio">` (single-choice,
  the default) or `<input type="checkbox">` (`multiple: true`) wrapped in
  its own native `<label>` — the label's visible text is that control's
  accessible name, with no separate `id` plumbing.
- The group root carries `role="radiogroup"` or `role="group"`; its
  accessible name comes from a caller-supplied `aria-label`/`aria-labelledby`.
- `value`/`defaultValue`/`onValueChange` are `string` in single-choice mode
  and `readonly string[]` in multi-choice mode, discriminated by the
  `multiple` literal so the two shapes cannot be mixed at the type level.
- `name` defaults to a generated id shared by every segment's control;
  supply your own to control the submitted form field name.
- `disabled` at the group level disables every segment; a segment's own
  `disabled` disables only that one.
- `className` and `style` describe the group root; the ref forwards to that
  same root element.

## Selection mode

| `multiple` | Control | Selection |
| --- | --- | --- |
| `false` (default) | `<input type="radio">`, shared `name` | Mutually exclusive; native roving-tabindex keyboard behavior with no custom key handling |
| `true` | `<input type="checkbox">`, shared `name` | Independent; every control reaches sequential focus |

Because selection is entirely native, an uncontrolled single-choice group's
mutual exclusivity is browser-owned even without this component re-rendering
— the same guarantee this library's Radio already relies on. A native form
reset restores every control's own default selection with no library-owned
state involved in that restoration.

```tsx
<SegmentedButtonGroup
  multiple
  segments={travelModes}
  aria-label="Travel modes"
  value={filters}
  onValueChange={setFilters}
/>
```

Single-choice submits one value under its shared `name`; multi-choice's
checked values are all retrievable through `FormData.getAll(name)`.

## Shape

The first segment rounds only its inline-start corners, the last rounds only
its inline-end corners, interior segments stay square, and a lone segment is
fully rounded — mirroring correctly under RTL since the rounding follows
logical corner properties, not physical sides. Adjacent segments overlap by
exactly one border width so shared edges coincide instead of doubling, and a
selected or currently-interacting segment's border stays visually on top of
its neighbors'.

## Icons

```tsx
<SegmentedButtonGroup
  segments={[
    { value: 'left', label: 'Left', icon: <Icon source="format_align_left" /> },
    { value: 'center', label: 'Center', icon: <Icon source="format_align_center" /> },
  ]}
  aria-label="Alignment"
  value={align}
  onValueChange={setAlign}
/>
```

A segment without a supplied `icon` shows only a built-in checkmark, which
fades and scales in on selection and disappears instantly on deselection. A
segment with a supplied `icon` shows that icon while unselected and
crossfades to the checkmark while selected, in both directions.

## Tokens and boundaries

All color, geometry, and motion values live in one
`--m3e-comp-segmented-button-group-*` registration. Theme overrides remain
scoped to `Material3Provider`; `SegmentedButtonGroup` injects no runtime
styles. It imports no Next.js, Vite, router, animation
library, or private application code.

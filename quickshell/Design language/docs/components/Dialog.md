# Dialog

`Dialog` renders a native `<dialog>` element with Material's icon/title/
content/actions layout over it. Openness is controlled like every other
stateful component; the underlying modal (or non-modal) behavior,
backdrop, focus trap, and focus lifecycle all come from the browser.

```tsx
import { Button, Dialog, Icon } from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

<Dialog
  open={open}
  onOpenChange={setOpen}
  role="alertdialog"
  icon={<Icon source="delete" />}
  title="Delete conversation?"
  actions={
    <>
      <Button variant="text" onClick={() => setOpen(false)}>Cancel</Button>
      <Button variant="text" onClick={() => setOpen(false)}>Delete</Button>
    </>
  }
>
  This removes the conversation and its messages. This action cannot be undone.
</Dialog>
```

## Contract

- `open`/`defaultOpen`/`onOpenChange` follow the same controlled/
  uncontrolled shape as every other stateful component. `onOpenChange`
  fires whenever the dialog closes itself — Escape, an outside click, or a
  native `<form method="dialog">` submission — never for a programmatic
  `open` change the caller makes itself.
- `icon`, `title`, `children` (the body/supporting-text region), and
  `actions` are all optional named regions rendered in that order; omitting
  any of them removes its spacing contribution with no leftover gap.
- `role` defaults to `"dialog"` and accepts `"alertdialog"` for
  interruption-style confirmations.
- `className` and `style` describe the root `<dialog>`; the ref forwards to
  that same element.

A controlled dialog's own native dismissal is always reported through
`onOpenChange`, but is not forcibly reverted if the consumer ignores it —
the native close already happened by the time your handler runs. Commit the
new value through `onOpenChange` the same way you would for any other
controlled/uncontrolled component.

## Modal and non-modal

```tsx
<Dialog open={open} onOpenChange={setOpen} modal={false} title="Playback controls">
  …
</Dialog>
```

| `modal` | Native call | Backdrop | Focus trap | Background |
| --- | --- | --- | --- | --- |
| `true` (default) | `showModal()` | Yes | Yes | Inert |
| `false` | `show()` | No | No | Interactive |

`dismissOnEscape` (default `true`) and `dismissOnOutsideClick` (default
`true`) are meaningful only in modal mode: non-modal dialogs render no
backdrop to click, and do not dismiss on Escape by native default.

## Accessible name and description

`title`, when present, sets `aria-labelledby` to a generated id unless you
pass an explicit `aria-label`/`aria-labelledby`. `children`, when present,
sets `aria-describedby` the same way. Supply at least one of `title`,
`aria-label`, or `aria-labelledby` — a dialog with no accessible name warns
in development.

Initial focus placement and, on close, focus restoration to whatever was
focused before the dialog opened are both native `<dialog>` behavior for
either `modal` value — there is no library-owned focus-management code to
configure.

## Forms

```tsx
<Dialog open={open} onOpenChange={setOpen} title="Rename item"
  actions={
    <form method="dialog">
      <Button variant="text" type="submit">Save</Button>
    </form>
  }
>
  <label>
    Name
    <input type="text" defaultValue="Untitled" />
  </label>
</Dialog>
```

A `<form method="dialog">` submission inside the dialog closes it and calls
`onOpenChange(false)` with no extra wiring — it reaches the consumer through
the same native `close` event as Escape or an outside click.

## Sizing

The dialog's own width stays between 280px and 560px, clamped against the
viewport with a margin on each side; very tall content scrolls inside the
dialog rather than overflowing the viewport. There is no separate
full-screen or breakpoint-driven variant — this bounded, content-fit sizing
is the adaptive behavior.

## Tokens and boundaries

All color, geometry, and motion values live in one `--m3e-comp-dialog-*`
registration. Theme overrides remain scoped to `Material3Provider`; `Dialog`
injects no runtime styles. It imports no Next.js, Vite,
router, animation library, or private application code.

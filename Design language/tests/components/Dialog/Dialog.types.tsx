import { createRef } from 'react'
import { Dialog } from '../../../src/components/Dialog'

const dialogRef = createRef<HTMLDialogElement>()

;<Dialog ref={dialogRef} title="Delete item?" defaultOpen onOpenChange={(open) => open} />
;<Dialog
  title="Delete item?"
  open
  onOpenChange={(open) => open}
  modal={false}
  dismissOnEscape={false}
  dismissOnOutsideClick={false}
  role="alertdialog"
  icon={<span />}
  actions={<button type="button">OK</button>}
>
  Body content
</Dialog>
;<Dialog aria-label="Untitled dialog" />

// `title` is ReactNode content, not the native string tooltip attribute.
;<Dialog title={<strong>Delete item?</strong>} />

// @ts-expect-error onOpenChange must accept a boolean, not a string
;<Dialog title="Delete item?" onOpenChange={(open: string) => open} />

// @ts-expect-error role only accepts dialog or alertdialog
;<Dialog title="Delete item?" role="tablist" />

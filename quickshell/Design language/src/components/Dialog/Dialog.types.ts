import type { ComponentPropsWithRef, ReactNode } from 'react'

/** The dialog's implicit ARIA role. `alertdialog` folds the sourced "alert dialog" identity into this component. */
export type DialogRole = 'dialog' | 'alertdialog'

interface DialogOwnProps {
  /** Controlled open state. Omit for uncontrolled `defaultOpen`. */
  readonly open?: boolean
  /** Initial open state when uncontrolled. Defaults to `false`. */
  readonly defaultOpen?: boolean
  /** Called whenever the dialog closes itself: Escape, an outside click, or a native `<form method="dialog">` submission. Never called for programmatic `open` changes the caller makes itself. */
  readonly onOpenChange?: (open: boolean) => void
  /** `true` (default) shows a backdrop, traps focus, and makes background content inert (`showModal()`). `false` shows none of those (`show()`). */
  readonly modal?: boolean
  /** Whether Escape dismisses the dialog. Modal only; non-modal dialogs never dismiss on Escape by native default. Defaults to `true`. */
  readonly dismissOnEscape?: boolean
  /** Whether clicking outside the dialog's own box dismisses it. Modal only, since non-modal dialogs render no backdrop to click. Defaults to `true`. */
  readonly dismissOnOutsideClick?: boolean
  readonly role?: DialogRole
  /** Optional leading icon, centered above the title. */
  readonly icon?: ReactNode
  /** The dialog's headline. Sets `aria-labelledby` unless an explicit `aria-label`/`aria-labelledby` is supplied. */
  readonly title?: ReactNode
  /** The dialog's body content. Sets `aria-describedby` unless an explicit `aria-describedby` is supplied. Inherits supporting-text typography and color for plain text; nested components override by setting their own. */
  readonly children?: ReactNode
  /** A trailing, end-aligned, wrapping row of actions such as confirm/dismiss buttons. */
  readonly actions?: ReactNode
}

export type DialogProps = DialogOwnProps &
  Omit<ComponentPropsWithRef<'dialog'>, keyof DialogOwnProps>

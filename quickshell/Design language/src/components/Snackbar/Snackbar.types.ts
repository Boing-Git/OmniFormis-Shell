import type { ComponentPropsWithRef, ReactNode } from 'react'

export interface SnackbarAction {
  readonly label: string
  readonly onClick: () => void
}

interface SnackbarOwnProps {
  /** Controlled visibility. Omit for uncontrolled `defaultOpen`. */
  readonly open?: boolean
  /** Initial visibility when uncontrolled. Defaults to `false`. */
  readonly defaultOpen?: boolean
  /** Called whenever the snackbar closes itself: the auto-dismiss timer, the action, or the dismiss button. */
  readonly onOpenChange?: (open: boolean) => void
  /** The message body. Required. */
  readonly message: ReactNode
  /** An optional single action button. Activating it closes the snackbar after `onClick` runs. */
  readonly action?: SnackbarAction
  /** Renders a close icon button. Defaults to `false`, matching the pinned source's own `withDismissAction` default. */
  readonly dismissible?: boolean
  /** Accessible label for the dismiss button. Defaults to `'Dismiss'`. */
  readonly dismissLabel?: string
  /**
   * `'short'` (4000ms) or `'long'` (10000ms) auto-dismiss, `'indefinite'`
   * (no auto-dismiss), or an exact millisecond count. Defaults to the
   * pinned source's own logic: `'short'` with no `action`, `'indefinite'`
   * with one. The countdown pauses while the snackbar is hovered or
   * focused and resumes on leave.
   */
  readonly duration?: 'short' | 'long' | 'indefinite' | number
}

export type SnackbarProps = SnackbarOwnProps &
  Omit<ComponentPropsWithRef<'div'>, keyof SnackbarOwnProps | 'children'>

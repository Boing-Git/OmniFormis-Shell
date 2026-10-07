import {
  forwardRef,
  useEffect,
  useId,
  useRef,
  type CSSProperties,
  type DialogHTMLAttributes,
  type ForwardedRef,
  type MouseEventHandler,
  type ReactElement,
  type ReactEventHandler,
  type ReactNode,
} from 'react'
import { composeEventHandlers } from '../../internal/composeEventHandlers'
import { composeRefs } from '../../internal/composeRefs'
import { useControllableState } from '../../internal/useControllableState'
import type { DialogProps, DialogRole } from './Dialog.types'

interface DialogImplementationProps extends Omit<DialogHTMLAttributes<HTMLDialogElement>, 'title'> {
  readonly open?: boolean
  readonly defaultOpen?: boolean
  readonly onOpenChange?: (open: boolean) => void
  readonly modal?: boolean
  readonly dismissOnEscape?: boolean
  readonly dismissOnOutsideClick?: boolean
  readonly role?: DialogRole
  readonly icon?: ReactNode
  readonly title?: ReactNode
  readonly actions?: ReactNode
}

interface DialogComponent {
  (props: DialogProps): ReactElement | null
  displayName?: string
}

function warn(message: string): void {
  if (typeof process !== 'undefined' && process.env.NODE_ENV !== 'production') {
    console.warn(`Dialog: ${message}`)
  }
}

function warnForInvalidProps({
  open,
  defaultOpen,
  onOpenChange,
  hasAccessibleName,
}: {
  readonly open: boolean | undefined
  readonly defaultOpen: boolean | undefined
  readonly onOpenChange: ((open: boolean) => void) | undefined
  readonly hasAccessibleName: boolean
}): void {
  if (open !== undefined && defaultOpen !== undefined) {
    warn('use either open or defaultOpen, not both.')
  }
  if (open !== undefined && onOpenChange === undefined) {
    warn('a controlled open value requires onOpenChange.')
  }
  if (!hasAccessibleName) {
    warn('a dialog requires an accessible name: pass title, aria-label, or aria-labelledby.')
  }
}

function DialogRender(
  {
    open,
    defaultOpen = false,
    onOpenChange,
    modal = true,
    dismissOnEscape = true,
    dismissOnOutsideClick = true,
    role = 'dialog',
    icon,
    title,
    children,
    actions,
    className,
    style,
    id: idProp,
    'aria-label': ariaLabel,
    'aria-labelledby': ariaLabelledByProp,
    'aria-describedby': ariaDescribedByProp,
    onCancel,
    onClose,
    onClick,
    ...dialogProps
  }: DialogImplementationProps,
  forwardedRef: ForwardedRef<HTMLDialogElement>,
) {
  const dialogRef = useRef<HTMLDialogElement | null>(null)
  const generatedId = useId()
  const dialogId = idProp ?? generatedId
  const titleId = title != null ? `${dialogId}-title` : undefined
  const contentId = children != null ? `${dialogId}-content` : undefined

  warnForInvalidProps({
    open,
    defaultOpen,
    onOpenChange,
    hasAccessibleName: title != null || ariaLabel != null || ariaLabelledByProp != null,
  })

  const [resolvedOpen, setOpen] = useControllableState({
    value: open,
    defaultValue: defaultOpen,
    onChange: onOpenChange,
  })

  // A true modal — backdrop, focus trap, inert background — only exists
  // once showModal() runs; setting the `open` attribute in JSX would just
  // produce a plain, non-modal reveal indistinguishable from show(). SSR
  // therefore always paints closed, and this effect performs every open
  // and close imperatively on the client.
  useEffect(() => {
    const dialogEl = dialogRef.current
    if (!dialogEl) return
    if (resolvedOpen && !dialogEl.open) {
      if (modal) dialogEl.showModal()
      else dialogEl.show()
    } else if (!resolvedOpen && dialogEl.open) {
      dialogEl.close()
    }
  }, [resolvedOpen, modal])

  // The native `close` event is the single path back to the controlled
  // `open` value, firing for Escape, an outside click's own `close()`
  // call, and a `<form method="dialog">` submission alike.
  useEffect(() => {
    const dialogEl = dialogRef.current
    if (!dialogEl) return undefined
    const handleNativeClose = () => setOpen(false)
    dialogEl.addEventListener('close', handleNativeClose)
    return () => dialogEl.removeEventListener('close', handleNativeClose)
  }, [setOpen])

  const handleCancel: ReactEventHandler<HTMLDialogElement> = (event) => {
    if (!dismissOnEscape) event.preventDefault()
  }

  // Native `<dialog>` has no automatic outside-click dismissal at this
  // library's browser floor (the `closedby` attribute that adds it
  // postdates that floor), so a click landing on the dialog element
  // itself — never a descendant — with coordinates outside its own
  // rendered box is the standard manual light-dismiss technique.
  const handleClick: MouseEventHandler<HTMLDialogElement> = (event) => {
    if (!modal || !dismissOnOutsideClick) return
    const dialogEl = dialogRef.current
    if (!dialogEl || event.target !== dialogEl) return
    const rect = dialogEl.getBoundingClientRect()
    const clickedInside =
      event.clientX >= rect.left &&
      event.clientX <= rect.right &&
      event.clientY >= rect.top &&
      event.clientY <= rect.bottom
    if (!clickedInside) dialogEl.close()
  }

  const mergedClassName = className ? `m3e-dialog ${className}` : 'm3e-dialog'
  const resolvedAriaLabelledBy = ariaLabel != null ? undefined : (ariaLabelledByProp ?? titleId)
  const resolvedAriaDescribedBy = ariaDescribedByProp ?? contentId

  return (
    <dialog
      {...dialogProps}
      ref={composeRefs(forwardedRef, dialogRef)}
      id={dialogId}
      className={mergedClassName}
      style={style as CSSProperties}
      role={role}
      aria-label={ariaLabel}
      aria-labelledby={resolvedAriaLabelledBy}
      aria-describedby={resolvedAriaDescribedBy}
      data-m3e-has-icon={icon != null}
      onCancel={composeEventHandlers(onCancel, handleCancel)}
      onClose={onClose}
      onClick={composeEventHandlers(onClick, handleClick)}
    >
      {icon != null && (
        <div className="m3e-dialog__icon" aria-hidden="true">
          {icon}
        </div>
      )}
      {title != null && (
        <div className="m3e-dialog__title" id={titleId}>
          {title}
        </div>
      )}
      {children != null && (
        <div className="m3e-dialog__content" id={contentId}>
          {children}
        </div>
      )}
      {actions != null && <div className="m3e-dialog__actions">{actions}</div>}
    </dialog>
  )
}

const ForwardedDialog = forwardRef<HTMLDialogElement, DialogImplementationProps>(DialogRender)
ForwardedDialog.displayName = 'Dialog'

export const Dialog = ForwardedDialog as DialogComponent

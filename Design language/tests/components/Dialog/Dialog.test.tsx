// @vitest-environment jsdom

import { act, cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createRef, useState } from 'react'
import { afterEach, beforeAll, vi } from 'vitest'
import { Dialog } from '../../../src/components/Dialog'
import { installDialogPolyfill } from './dialog-native-polyfill'

beforeAll(installDialogPolyfill)

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

function getDialog(name?: string): HTMLDialogElement {
  return name
    ? (screen.getByRole('dialog', { name }) as HTMLDialogElement)
    : (screen.getByRole('dialog') as HTMLDialogElement)
}

describe('Dialog', () => {
  it('opens uncontrolled through defaultOpen and calls onOpenChange on native close', () => {
    const onOpenChange = vi.fn()
    render(<Dialog defaultOpen title="Delete item?" onOpenChange={onOpenChange} />)
    const dialog = getDialog('Delete item?')

    expect(dialog.open).toBe(true)
    act(() => dialog.close())
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('reports a controlled dialog’s native dismissal through onOpenChange without silently reopening it', () => {
    // Unlike a controlled native form value (which React itself snaps back
    // on the same event), a native close() already ran by the time
    // onOpenChange fires, and nothing forces a further render if the
    // consumer's `open` prop value does not itself change. A controlled
    // consumer is expected to commit the new value through onOpenChange,
    // matching this library's established native-truth precedent of state
    // that can move ahead of an unacknowledged controlled prop.
    const onOpenChange = vi.fn()
    render(<Dialog open title="Confirm" onOpenChange={onOpenChange} />)
    const dialog = getDialog('Confirm')
    expect(dialog.open).toBe(true)

    act(() => dialog.close())
    expect(onOpenChange).toHaveBeenCalledWith(false)
    expect(dialog.open).toBe(false)
  })

  it('calls showModal() by default and show() when modal is false', () => {
    const showModalSpy = vi.spyOn(HTMLDialogElement.prototype, 'showModal')
    const showSpy = vi.spyOn(HTMLDialogElement.prototype, 'show')
    render(<Dialog defaultOpen title="Modal" />)
    expect(showModalSpy).toHaveBeenCalledTimes(1)
    expect(showSpy).not.toHaveBeenCalled()

    render(<Dialog defaultOpen modal={false} title="Non-modal" />)
    expect(showSpy).toHaveBeenCalledTimes(1)
  })

  it('blocks Escape dismissal when dismissOnEscape is false and allows it by default', () => {
    const onOpenChange = vi.fn()
    render(<Dialog defaultOpen dismissOnEscape={false} title="Locked" onOpenChange={onOpenChange} />)
    const dialog = getDialog('Locked')

    const blockedCancel = new Event('cancel', { cancelable: true })
    act(() => {
      dialog.dispatchEvent(blockedCancel)
    })
    expect(blockedCancel.defaultPrevented).toBe(true)
    expect(onOpenChange).not.toHaveBeenCalled()
    expect(dialog.open).toBe(true)
  })

  it('allows Escape dismissal by default, matching the browser default action', () => {
    const onOpenChange = vi.fn()
    render(<Dialog defaultOpen title="Dismissible" onOpenChange={onOpenChange} />)
    const dialog = getDialog('Dismissible')

    const allowedCancel = new Event('cancel', { cancelable: true })
    act(() => {
      dialog.dispatchEvent(allowedCancel)
    })
    expect(allowedCancel.defaultPrevented).toBe(false)
    // The browser's own default action for an unprevented cancel is close().
    act(() => dialog.close())
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('dismisses on an outside click by default and honors dismissOnOutsideClick={false}', () => {
    const onOpenChange = vi.fn()
    render(<Dialog defaultOpen title="Click outside" onOpenChange={onOpenChange} />)
    const dialog = getDialog('Click outside')
    vi.spyOn(dialog, 'getBoundingClientRect').mockReturnValue({
      top: 100,
      bottom: 300,
      left: 100,
      right: 300,
      width: 200,
      height: 200,
      x: 100,
      y: 100,
      toJSON: () => ({}),
    })

    act(() => {
      dialog.dispatchEvent(
        new MouseEvent('click', { bubbles: true, cancelable: true, clientX: 10, clientY: 10 }),
      )
    })
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('ignores an outside click when dismissOnOutsideClick is false', () => {
    const onOpenChange = vi.fn()
    render(
      <Dialog
        defaultOpen
        dismissOnOutsideClick={false}
        title="Stays open"
        onOpenChange={onOpenChange}
      />,
    )
    const dialog = getDialog('Stays open')
    vi.spyOn(dialog, 'getBoundingClientRect').mockReturnValue({
      top: 100,
      bottom: 300,
      left: 100,
      right: 300,
      width: 200,
      height: 200,
      x: 100,
      y: 100,
      toJSON: () => ({}),
    })

    act(() => {
      dialog.dispatchEvent(
        new MouseEvent('click', { bubbles: true, cancelable: true, clientX: 10, clientY: 10 }),
      )
    })
    expect(onOpenChange).not.toHaveBeenCalled()
    expect(dialog.open).toBe(true)
  })

  it('does not treat an outside click as dismissible when non-modal', () => {
    const onOpenChange = vi.fn()
    render(<Dialog defaultOpen modal={false} title="Non-modal" onOpenChange={onOpenChange} />)
    const dialog = getDialog('Non-modal')
    vi.spyOn(dialog, 'getBoundingClientRect').mockReturnValue({
      top: 100,
      bottom: 300,
      left: 100,
      right: 300,
      width: 200,
      height: 200,
      x: 100,
      y: 100,
      toJSON: () => ({}),
    })

    act(() => {
      dialog.dispatchEvent(
        new MouseEvent('click', { bubbles: true, cancelable: true, clientX: 10, clientY: 10 }),
      )
    })
    expect(onOpenChange).not.toHaveBeenCalled()
  })

  it('renders icon, title, content, and actions in sourced order', () => {
    render(
      <Dialog
        defaultOpen
        icon={<span data-testid="icon">*</span>}
        title="Delete conversation?"
        actions={<button type="button">Delete</button>}
      >
        This cannot be undone.
      </Dialog>,
    )
    const dialog = getDialog('Delete conversation?')
    const children = Array.from(dialog.children).map((child) => child.className)

    expect(children).toEqual([
      'm3e-dialog__icon',
      'm3e-dialog__title',
      'm3e-dialog__content',
      'm3e-dialog__actions',
    ])
    expect(dialog.getAttribute('data-m3e-has-icon')).toBe('true')
    expect(screen.getByTestId('icon')).not.toBeNull()
    expect(screen.getByText('This cannot be undone.')).not.toBeNull()
    expect(screen.getByRole('button', { name: 'Delete' })).not.toBeNull()
  })

  it('omits data-m3e-has-icon content when no icon is supplied', () => {
    render(<Dialog defaultOpen title="No icon" />)
    expect(getDialog('No icon').getAttribute('data-m3e-has-icon')).toBe('false')
  })

  it('sends className and style to the root while ref forwards to the dialog element', () => {
    const ref = createRef<HTMLDialogElement>()
    render(
      <Dialog
        ref={ref}
        defaultOpen
        title="Styled"
        className="consumer-class"
        style={{ marginInlineEnd: 8 }}
        data-owner="consumer"
      />,
    )
    const dialog = getDialog('Styled')

    expect(ref.current).toBe(dialog)
    expect(dialog.getAttribute('class')).toBe('m3e-dialog consumer-class')
    expect(dialog.getAttribute('style')).toContain('margin-inline-end: 8px')
    expect(dialog.getAttribute('data-owner')).toBe('consumer')
  })

  it('warns for conflicting and incomplete runtime open props, and for a missing accessible name', () => {
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    render(<Dialog open defaultOpen />)
    expect(warning).toHaveBeenCalledWith('Dialog: use either open or defaultOpen, not both.')
    expect(warning).toHaveBeenCalledWith(
      'Dialog: a controlled open value requires onOpenChange.',
    )
    expect(warning).toHaveBeenCalledWith(
      'Dialog: a dialog requires an accessible name: pass title, aria-label, or aria-labelledby.',
    )
  })

  it('drives a real open/close lifecycle end to end from application state', async () => {
    const user = userEvent.setup()
    function Fixture() {
      const [open, setOpen] = useState(false)
      return (
        <>
          <button type="button" onClick={() => setOpen(true)}>
            Open
          </button>
          <Dialog
            open={open}
            onOpenChange={setOpen}
            title="Confirm"
            actions={
              <button type="button" onClick={() => setOpen(false)}>
                Close
              </button>
            }
          />
        </>
      )
    }
    render(<Fixture />)
    // A closed <dialog> is correctly excluded from the accessibility tree,
    // matching real browser behavior, so the initial check queries the DOM
    // directly rather than through an accessible role.
    const dialog = document.querySelector('dialog') as HTMLDialogElement
    expect(dialog.open).toBe(false)

    await user.click(screen.getByRole('button', { name: 'Open' }))
    expect(getDialog('Confirm')).toBe(dialog)
    expect(dialog.open).toBe(true)

    await user.click(screen.getByRole('button', { name: 'Close' }))
    expect(dialog.open).toBe(false)
  })

  it('exposes a stable component name for React tooling', () => {
    expect(Dialog.displayName).toBe('Dialog')
  })
})

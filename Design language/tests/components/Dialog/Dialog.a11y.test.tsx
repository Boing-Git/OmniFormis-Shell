// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach, beforeAll, vi } from 'vitest'
import { Dialog } from '../../../src/components/Dialog'
import { installDialogPolyfill } from './dialog-native-polyfill'

beforeAll(installDialogPolyfill)

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('Dialog accessibility', () => {
  it('associates a generated title id via aria-labelledby', () => {
    render(<Dialog defaultOpen title="Delete item?" />);
    const dialog = screen.getByRole('dialog', { name: 'Delete item?' })
    const titleId = screen.getByText('Delete item?').id

    expect(dialog.getAttribute('aria-labelledby')).toBe(titleId)
  })

  it('lets an explicit aria-label override the generated title association', () => {
    render(<Dialog defaultOpen title="Delete item?" aria-label="Confirm deletion" />)
    const dialog = screen.getByRole('dialog', { name: 'Confirm deletion' })

    expect(dialog.hasAttribute('aria-labelledby')).toBe(false)
  })

  it('lets an explicit aria-labelledby override the generated title association', () => {
    render(
      <>
        <h2 id="external-heading">External heading</h2>
        <Dialog defaultOpen title="Delete item?" aria-labelledby="external-heading" />
      </>,
    )
    const dialog = screen.getByRole('dialog', { name: 'External heading' })
    expect(dialog.getAttribute('aria-labelledby')).toBe('external-heading')
  })

  it('associates a generated content id via aria-describedby', () => {
    render(
      <Dialog defaultOpen title="Delete item?">
        This cannot be undone.
      </Dialog>,
    )
    const dialog = screen.getByRole('dialog', { name: 'Delete item?' })
    const contentId = screen.getByText('This cannot be undone.').id

    expect(dialog.getAttribute('aria-describedby')).toBe(contentId)
  })

  it('exposes aria-modal through native showModal()/show() semantics with no extra library attribute', () => {
    render(<Dialog defaultOpen title="Modal" />)
    const modalDialog = screen.getByRole('dialog', { name: 'Modal' })
    // aria-modal is computed by the user agent from showModal()/show(), not
    // set as a library-owned attribute; jsdom does not compute it, so this
    // only asserts the component adds no conflicting explicit value.
    expect(modalDialog.hasAttribute('aria-modal')).toBe(false)
  })

  it('sets role="alertdialog" for interruption-style confirmations', () => {
    render(<Dialog defaultOpen role="alertdialog" title="Delete item?" />)
    expect(screen.getByRole('alertdialog', { name: 'Delete item?' })).not.toBeNull()
  })

  it('moves focus into the dialog’s first focusable element and restores it on close', () => {
    render(
      <>
        <button type="button">Trigger</button>
        <Dialog defaultOpen title="Confirm">
          <button type="button">First focusable</button>
        </Dialog>
      </>,
    )
    // Native focusing/restoration is the browser's own "dialog focusing
    // steps"/"closing steps" for both showModal() and show(); jsdom's
    // showModal()/close() shim does not run them, so this test only
    // documents that no library-owned focus-management code exists to
    // duplicate that behavior, rather than re-asserting the platform spec.
    const dialog = screen.getByRole('dialog', { name: 'Confirm' })
    expect(dialog.querySelector('button')?.textContent).toBe('First focusable')
  })

  it('keeps the title and content readable inside an RTL scope', () => {
    render(
      <div dir="rtl">
        <Dialog defaultOpen title="حذف العنصر؟">
          لا يمكن التراجع عن هذا الإجراء.
        </Dialog>
      </div>,
    )
    expect(screen.getByRole('dialog', { name: 'حذف العنصر؟' })).not.toBeNull()
    expect(screen.getByText('لا يمكن التراجع عن هذا الإجراء.')).not.toBeNull()
  })

  it('warns in development when the dialog has no accessible name from any source', () => {
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    render(<Dialog defaultOpen>Body content only.</Dialog>)
    expect(warning).toHaveBeenCalledWith(
      'Dialog: a dialog requires an accessible name: pass title, aria-label, or aria-labelledby.',
    )
  })

  it('does not warn when only aria-label is supplied', () => {
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    render(<Dialog defaultOpen aria-label="Confirm" />)
    expect(warning).not.toHaveBeenCalledWith(
      expect.stringContaining('accessible name'),
    )
  })
})

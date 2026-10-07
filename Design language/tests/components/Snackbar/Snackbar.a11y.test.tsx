// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { Snackbar } from '../../../src/components/Snackbar'

afterEach(cleanup)

describe('Snackbar accessibility', () => {
  it('exposes role="status" so new messages are announced politely', () => {
    render(<Snackbar message="Saved" open onOpenChange={() => undefined} />)
    const snackbar = screen.getByRole('status')
    expect(snackbar.textContent).toBe('Saved')
  })

  it('gives the dismiss button an accessible name distinct from the message', () => {
    render(<Snackbar message="Saved" dismissible open onOpenChange={() => undefined} />)
    expect(screen.getByRole('button', { name: 'Dismiss' })).not.toBeNull()
  })

  it('gives the action button its own accessible label', () => {
    render(
      <Snackbar
        message="Item removed"
        action={{ label: 'Undo', onClick: () => undefined }}
        open
        onOpenChange={() => undefined}
      />,
    )
    expect(screen.getByRole('button', { name: 'Undo' })).not.toBeNull()
  })

  it('keeps the snackbar readable inside an RTL scope', () => {
    render(
      <div dir="rtl">
        <Snackbar message="Saved" open onOpenChange={() => undefined} />
      </div>,
    )
    expect(screen.getByRole('status').textContent).toBe('Saved')
  })
})

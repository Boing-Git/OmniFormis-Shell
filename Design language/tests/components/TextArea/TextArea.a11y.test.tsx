// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach } from 'vitest'
import { TextArea } from '../../../src'

afterEach(cleanup)

describe('TextArea accessibility', () => {
  it('associates its own generated label with the control', () => {
    render(<TextArea label="Feedback" />)
    expect(screen.getByRole('textbox', { name: 'Feedback' })).toBeInstanceOf(HTMLTextAreaElement)
  })

  it('reaches the field through sequential keyboard focus', async () => {
    const user = userEvent.setup()
    render(<TextArea label="Notes" />)

    await user.tab()
    expect(document.activeElement).toBe(screen.getByRole('textbox', { name: 'Notes' }))
  })

  it('removes disabled fields from sequential focus', async () => {
    const user = userEvent.setup()
    render(
      <>
        <TextArea label="Unavailable" disabled />
        <TextArea label="Available" />
      </>,
    )

    await user.tab()
    expect(document.activeElement).toBe(screen.getByRole('textbox', { name: 'Available' }))
  })

  it('exposes an accessible description for supporting text', () => {
    render(<TextArea label="Notes" error supportingText="Required" />)
    const control = screen.getByRole('textbox', { name: 'Notes' })

    expect(control.getAttribute('aria-invalid')).toBe('true')
    expect(
      document.getElementById(control.getAttribute('aria-describedby') ?? '')?.textContent,
    ).toBe('Required')
  })

  it('keeps naming and typing stable inside an RTL scope', async () => {
    const user = userEvent.setup()
    render(
      <div dir="rtl">
        <TextArea label="ملاحظات" />
      </div>,
    )
    const control = screen.getByRole('textbox', { name: 'ملاحظات' }) as HTMLTextAreaElement

    await user.type(control, 'مرحبا')
    expect(control.value).toBe('مرحبا')
  })
})

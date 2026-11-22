// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach } from 'vitest'
import { TextField } from '../../../src'

afterEach(cleanup)

describe('TextField accessibility', () => {
  it('associates its own generated label with the input', () => {
    render(<TextField label="Full name" />)
    expect(screen.getByRole('textbox', { name: 'Full name' })).toBeInstanceOf(HTMLInputElement)
  })

  it('keeps a caller-supplied id and an external description on the same accessible name', () => {
    render(
      <>
        <TextField id="wifi-name" label="Wi-Fi name" aria-describedby="wifi-help" />
        <p id="wifi-help">Visible to nearby devices.</p>
      </>,
    )
    const input = screen.getByRole('textbox', { name: 'Wi-Fi name' })

    expect(input.id).toBe('wifi-name')
    expect(document.querySelector('label')?.getAttribute('for')).toBe('wifi-name')
    expect(input.getAttribute('aria-describedby')).toContain('wifi-help')
  })

  it('reaches the field through sequential keyboard focus', async () => {
    const user = userEvent.setup()
    render(<TextField label="Name" />)

    await user.tab()
    expect(document.activeElement).toBe(screen.getByRole('textbox', { name: 'Name' }))
  })

  it('removes disabled fields from sequential focus', async () => {
    const user = userEvent.setup()
    render(
      <>
        <TextField label="Unavailable" disabled />
        <TextField label="Available" />
      </>,
    )

    await user.tab()
    expect(document.activeElement).toBe(screen.getByRole('textbox', { name: 'Available' }))
  })

  it('exposes an accessible description for supporting text without duplicating it visually', () => {
    render(<TextField label="Promo code" error supportingText="This code has expired" />)
    const input = screen.getByRole('textbox', { name: 'Promo code' })

    expect(input.getAttribute('aria-invalid')).toBe('true')
    expect(
      document.getElementById(input.getAttribute('aria-describedby') ?? '')?.textContent,
    ).toBe('This code has expired')
  })

  it('keeps naming and typing stable inside an RTL scope', async () => {
    const user = userEvent.setup()
    render(
      <div dir="rtl">
        <TextField label="الاسم الكامل" />
      </div>,
    )
    const input = screen.getByRole('textbox', { name: 'الاسم الكامل' }) as HTMLInputElement

    await user.type(input, 'أدا')
    expect(input.value).toBe('أدا')
  })
})

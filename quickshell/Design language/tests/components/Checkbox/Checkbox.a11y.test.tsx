// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, vi } from 'vitest'
import { Checkbox } from '../../../src'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('Checkbox accessibility', () => {
  it('exposes the native checkbox role and a wrapping label name', () => {
    render(
      <label>
        <Checkbox />
        Remember this device
      </label>,
    )

    expect(screen.getByRole('checkbox', { name: 'Remember this device' })).toBeInstanceOf(
      HTMLInputElement,
    )
  })

  it('supports external label association and described relationships', () => {
    render(
      <>
        <label htmlFor="newsletter">Weekly newsletter</label>
        <Checkbox id="newsletter" aria-describedby="newsletter-help" />
        <p id="newsletter-help">One message every Monday.</p>
      </>,
    )
    const checkbox = screen.getByRole('checkbox', { name: 'Weekly newsletter' })

    expect(checkbox.getAttribute('aria-describedby')).toBe('newsletter-help')
  })

  it('uses browser-owned Space activation without synthesized key handling', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(<Checkbox aria-label="Subscribe" onCheckedChange={onCheckedChange} />)
    const checkbox = screen.getByRole('checkbox', { name: 'Subscribe' })

    await user.tab()
    expect(document.activeElement).toBe(checkbox)
    await user.keyboard(' ')
    expect(onCheckedChange).toHaveBeenCalledTimes(1)
    expect(onCheckedChange).toHaveBeenLastCalledWith(true)
    await user.keyboard('{Enter}')
    expect(onCheckedChange).toHaveBeenCalledTimes(1)
  })

  it('reports mixed state to assistive technology and resolves it on activation', async () => {
    const user = userEvent.setup()
    render(<Checkbox aria-label="Select all" indeterminate />)
    const checkbox = screen.getByRole('checkbox', { name: 'Select all' }) as HTMLInputElement

    expect(checkbox.getAttribute('aria-checked')).toBe('mixed')
    await user.tab()
    expect(document.activeElement).toBe(checkbox)
  })

  it('removes disabled checkboxes from sequential focus', async () => {
    const user = userEvent.setup()
    render(
      <>
        <Checkbox aria-label="Unavailable" disabled />
        <Checkbox aria-label="Available" />
      </>,
    )

    await user.tab()
    expect(document.activeElement).toBe(screen.getByRole('checkbox', { name: 'Available' }))
  })

  it('keeps naming and activation stable inside an RTL scope', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(
      <div dir="rtl">
        <label>
          <Checkbox onCheckedChange={onCheckedChange} />
          الاشتراك
        </label>
      </div>,
    )

    await user.click(screen.getByRole('checkbox', { name: 'الاشتراك' }))
    expect(onCheckedChange).toHaveBeenCalledWith(true)
  })
})

// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, vi } from 'vitest'
import { Radio } from '../../../src'

// jsdom has no `window.CSS`, but @testing-library/user-event's native
// radio-group arrow-key walker (its own reimplementation of the browser
// default, the same kind of simulation the Space-activation test below
// already relies on) calls `CSS.escape(name)` to build its group selector.
// This minimal polyfill only needs to cover the plain ASCII `name` values
// used in this file.
if (typeof window !== 'undefined' && !window.CSS) {
  ;(window as unknown as { CSS: { escape: (value: string) => string } }).CSS = {
    escape: (value: string) => value.replace(/([^\w-])/g, '\\$1'),
  }
}

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('Radio accessibility', () => {
  it('exposes the native radio role and a wrapping label name', () => {
    render(
      <label>
        <Radio name="plan" />
        Basic plan
      </label>,
    )

    expect(screen.getByRole('radio', { name: 'Basic plan' })).toBeInstanceOf(HTMLInputElement)
  })

  it('supports external label association and described relationships', () => {
    render(
      <>
        <label htmlFor="plan-pro">Pro plan</label>
        <Radio id="plan-pro" name="plan" aria-describedby="plan-help" />
        <p id="plan-help">Includes priority support.</p>
      </>,
    )
    const radio = screen.getByRole('radio', { name: 'Pro plan' })

    expect(radio.getAttribute('aria-describedby')).toBe('plan-help')
  })

  it('uses browser-owned Space activation without synthesized key handling', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(<Radio name="plan" aria-label="Subscribe" onCheckedChange={onCheckedChange} />)
    const radio = screen.getByRole('radio', { name: 'Subscribe' })

    await user.tab()
    expect(document.activeElement).toBe(radio)
    await user.keyboard(' ')
    expect(onCheckedChange).toHaveBeenCalledTimes(1)
    expect(onCheckedChange).toHaveBeenLastCalledWith(true)
    await user.keyboard('{Enter}')
    expect(onCheckedChange).toHaveBeenCalledTimes(1)
  })

  it('moves focus and selection with arrow keys inside a native named group', async () => {
    const user = userEvent.setup()
    render(
      <>
        <Radio name="plan" aria-label="Basic" defaultChecked />
        <Radio name="plan" aria-label="Pro" />
        <Radio name="plan" aria-label="Team" />
      </>,
    )
    const basic = screen.getByRole('radio', { name: 'Basic' })
    const pro = screen.getByRole('radio', { name: 'Pro' })

    await user.tab()
    expect(document.activeElement).toBe(basic)
    await user.keyboard('{ArrowDown}')
    expect(document.activeElement).toBe(pro)
    expect((pro as HTMLInputElement).checked).toBe(true)
    expect((basic as HTMLInputElement).checked).toBe(false)
  })

  it('leaves an unrelated group unaffected by a different name', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(
      <>
        <Radio name="plan" aria-label="Basic" onCheckedChange={onCheckedChange} />
        <Radio name="frequency" aria-label="Monthly" defaultChecked />
        <Radio name="frequency" aria-label="Yearly" />
      </>,
    )

    await user.click(screen.getByRole('radio', { name: 'Yearly' }))
    expect(onCheckedChange).not.toHaveBeenCalled()
    expect((screen.getByRole('radio', { name: 'Monthly' }) as HTMLInputElement).checked).toBe(
      false,
    )
  })

  it('removes disabled radios from sequential focus', async () => {
    const user = userEvent.setup()
    render(
      <>
        <Radio name="plan" aria-label="Unavailable" disabled />
        <Radio name="plan" aria-label="Available" />
      </>,
    )

    await user.tab()
    expect(document.activeElement).toBe(screen.getByRole('radio', { name: 'Available' }))
  })

  it('keeps naming and activation stable inside an RTL scope', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(
      <div dir="rtl">
        <label>
          <Radio name="plan" onCheckedChange={onCheckedChange} />
          الخطة الأساسية
        </label>
      </div>,
    )

    await user.click(screen.getByRole('radio', { name: 'الخطة الأساسية' }))
    expect(onCheckedChange).toHaveBeenCalledWith(true)
  })
})

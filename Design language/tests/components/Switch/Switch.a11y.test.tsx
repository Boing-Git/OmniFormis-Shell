// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, vi } from 'vitest'
import { Switch } from '../../../src'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('Switch accessibility', () => {
  it('exposes the switch role and a wrapping label name from the native checkbox mapping', () => {
    render(
      <label>
        <Switch />
        Notifications
      </label>,
    )

    expect(screen.getByRole('switch', { name: 'Notifications' })).toBeInstanceOf(HTMLInputElement)
  })

  it('supports external label association and described relationships', () => {
    render(
      <>
        <label htmlFor="wifi">Wi-Fi</label>
        <Switch id="wifi" aria-describedby="wifi-help" />
        <p id="wifi-help">Connects automatically at home.</p>
      </>,
    )
    const toggle = screen.getByRole('switch', { name: 'Wi-Fi' })

    expect(toggle.getAttribute('aria-describedby')).toBe('wifi-help')
  })

  it('exposes on/off state through the native checked property with no explicit aria-checked needed', () => {
    render(<Switch aria-label="Airplane mode" defaultChecked />)
    const toggle = screen.getByRole('switch', { name: 'Airplane mode' }) as HTMLInputElement

    expect(toggle.checked).toBe(true)
    expect(toggle.hasAttribute('aria-checked')).toBe(false)
  })

  it('uses browser-owned Space activation without synthesized key handling', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(<Switch aria-label="Subscribe" onCheckedChange={onCheckedChange} />)
    const toggle = screen.getByRole('switch', { name: 'Subscribe' })

    await user.tab()
    expect(document.activeElement).toBe(toggle)
    await user.keyboard(' ')
    expect(onCheckedChange).toHaveBeenCalledTimes(1)
    expect(onCheckedChange).toHaveBeenLastCalledWith(true)
    await user.keyboard('{Enter}')
    expect(onCheckedChange).toHaveBeenCalledTimes(1)
  })

  it('removes disabled switches from sequential focus', async () => {
    const user = userEvent.setup()
    render(
      <>
        <Switch aria-label="Unavailable" disabled />
        <Switch aria-label="Available" />
      </>,
    )

    await user.tab()
    expect(document.activeElement).toBe(screen.getByRole('switch', { name: 'Available' }))
  })

  it('keeps naming and activation stable inside an RTL scope', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(
      <div dir="rtl">
        <label>
          <Switch onCheckedChange={onCheckedChange} />
          الإشعارات
        </label>
      </div>,
    )

    await user.click(screen.getByRole('switch', { name: 'الإشعارات' }))
    expect(onCheckedChange).toHaveBeenCalledWith(true)
  })
})

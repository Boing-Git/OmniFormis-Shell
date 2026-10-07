// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createElement, createRef, type ComponentType } from 'react'
import { afterEach, vi } from 'vitest'
import { Switch } from '../../../src/components/Switch'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('Switch', () => {
  it('renders one native checkbox input exposed as a switch with unchecked defaults', () => {
    render(<Switch data-testid="notifications" />)
    const input = screen.getByTestId('notifications')
    const root = input.closest('.m3e-switch')

    expect(input).toBeInstanceOf(HTMLInputElement)
    expect(input.getAttribute('type')).toBe('checkbox')
    expect(input.getAttribute('role')).toBe('switch')
    expect((input as HTMLInputElement).checked).toBe(false)
    expect(root?.getAttribute('data-m3e-state')).toBe('unchecked')
    expect(root?.getAttribute('data-m3e-disabled')).toBe('false')
    expect(root?.getAttribute('data-m3e-has-thumb-icon')).toBe('false')
    expect(root?.querySelector('.m3e-switch__thumb')).not.toBeNull()
  })

  it('sends className and style to the root while the ref and native props stay on the input', () => {
    const ref = createRef<HTMLInputElement>()
    render(
      <Switch
        ref={ref}
        className="settings-switch"
        style={{ marginInlineEnd: 8 }}
        id="notifications"
        name="preferences"
        value="notifications"
        required
        data-owner="consumer"
      />,
    )
    const input = document.querySelector('input')
    const root = document.querySelector('.m3e-switch')

    if (!input || !root) throw new Error('Expected a rendered switch')
    expect(ref.current).toBe(input)
    expect(root.getAttribute('class')).toBe('m3e-switch settings-switch')
    expect(root.getAttribute('style')).toContain('margin-inline-end: 8px')
    expect(input.getAttribute('id')).toBe('notifications')
    expect(input.getAttribute('name')).toBe('preferences')
    expect(input.getAttribute('value')).toBe('notifications')
    expect(input.required).toBe(true)
    expect(input.getAttribute('data-owner')).toBe('consumer')
  })

  it('cannot have its role attribute overridden by a caller', () => {
    const UntypedSwitch = Switch as ComponentType<Record<string, unknown>>
    render(createElement(UntypedSwitch, { role: 'checkbox', 'data-testid': 'fixed-role' }))
    expect(screen.getByTestId('fixed-role').getAttribute('role')).toBe('switch')
  })

  it('toggles uncontrolled state through the browser and reports the resolved value', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(<Switch defaultChecked onCheckedChange={onCheckedChange} />)
    const input = screen.getByRole('switch') as HTMLInputElement

    expect(input.closest('.m3e-switch')?.getAttribute('data-m3e-state')).toBe('checked')
    await user.click(input)
    expect(onCheckedChange).toHaveBeenCalledWith(false)
    expect(input.checked).toBe(false)
    expect(input.closest('.m3e-switch')?.getAttribute('data-m3e-state')).toBe('unchecked')
  })

  it('keeps a controlled value authoritative until the consumer commits it', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(<Switch checked={false} onCheckedChange={onCheckedChange} />)
    const input = screen.getByRole('switch') as HTMLInputElement

    await user.click(input)
    expect(onCheckedChange).toHaveBeenCalledWith(true)
    expect(input.checked).toBe(false)
    expect(input.closest('.m3e-switch')?.getAttribute('data-m3e-state')).toBe('unchecked')
  })

  it('runs the consumer change handler first and treats preventDefault as cancellation', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(
      <Switch
        checked={false}
        onCheckedChange={onCheckedChange}
        onChange={(event) => event.preventDefault()}
      />,
    )

    await user.click(screen.getByRole('switch'))
    expect(onCheckedChange).not.toHaveBeenCalled()
  })

  it('exposes a thumb icon slot and reflects its presence on the root', () => {
    render(<Switch aria-label="Wi-Fi" defaultChecked thumbIcon={<span data-testid="glyph" />} />)

    expect(screen.getByTestId('glyph')).not.toBeNull()
    expect(
      screen.getByRole('switch').closest('.m3e-switch')?.getAttribute('data-m3e-has-thumb-icon'),
    ).toBe('true')
  })

  it('uses native disabled behavior and does not mutate state', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(<Switch disabled onCheckedChange={onCheckedChange} />)
    const input = screen.getByRole('switch') as HTMLInputElement

    await user.click(input)
    expect(onCheckedChange).not.toHaveBeenCalled()
    expect(input.disabled).toBe(true)
    expect(input.checked).toBe(false)
    expect(input.closest('.m3e-switch')?.getAttribute('data-m3e-disabled')).toBe('true')
  })

  it('participates in form submission and resynchronizes on native reset', async () => {
    const user = userEvent.setup()
    const submitted: string[] = []
    render(
      <form
        onSubmit={(event) => {
          event.preventDefault()
          submitted.push(...new FormData(event.currentTarget).getAll('preferences').map(String))
        }}
      >
        <Switch name="preferences" value="marketing" defaultChecked />
        <button type="submit">Save</button>
        <button type="reset">Reset</button>
      </form>,
    )
    const input = screen.getByRole('switch') as HTMLInputElement

    await user.click(screen.getByRole('button', { name: 'Save' }))
    expect(submitted).toEqual(['marketing'])

    await user.click(input)
    expect(input.closest('.m3e-switch')?.getAttribute('data-m3e-state')).toBe('unchecked')

    await user.click(screen.getByRole('button', { name: 'Reset' }))
    expect(input.checked).toBe(true)
    expect(input.closest('.m3e-switch')?.getAttribute('data-m3e-state')).toBe('checked')
  })

  it('warns for conflicting and incomplete runtime state props', () => {
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    const UntypedSwitch = Switch as ComponentType<Record<string, unknown>>

    render(createElement(UntypedSwitch, { checked: true, defaultChecked: true }))
    expect(warning).toHaveBeenCalledWith('Switch: use either checked or defaultChecked, not both.')
    expect(warning).toHaveBeenCalledWith(
      'Switch: a controlled checked value requires onCheckedChange or onChange.',
    )
  })

  it('exposes a stable component name for React tooling', () => {
    expect(Switch.displayName).toBe('Switch')
  })
})

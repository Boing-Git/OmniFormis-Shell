// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createElement, createRef, useState, type ComponentType } from 'react'
import { afterEach, vi } from 'vitest'
import { Checkbox } from '../../../src/components/Checkbox'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('Checkbox', () => {
  it('renders one native checkbox input with unchecked defaults', () => {
    render(<Checkbox data-testid="terms" />)
    const input = screen.getByTestId('terms')
    const root = input.closest('.m3e-checkbox')

    expect(input).toBeInstanceOf(HTMLInputElement)
    expect(input.getAttribute('type')).toBe('checkbox')
    expect((input as HTMLInputElement).checked).toBe(false)
    expect((input as HTMLInputElement).indeterminate).toBe(false)
    expect(input.hasAttribute('aria-checked')).toBe(false)
    expect(root?.getAttribute('data-m3e-state')).toBe('unchecked')
    expect(root?.getAttribute('data-m3e-disabled')).toBe('false')
    expect(root?.querySelector('.m3e-checkbox__mark-path')).not.toBeNull()
  })

  it('sends className and style to the root while the ref and native props stay on the input', () => {
    const ref = createRef<HTMLInputElement>()
    render(
      <Checkbox
        ref={ref}
        className="settings-checkbox"
        style={{ marginInlineEnd: 8 }}
        id="marketing"
        name="preferences"
        value="marketing"
        required
        data-owner="consumer"
      />,
    )
    const input = document.querySelector('input')
    const root = document.querySelector('.m3e-checkbox')

    if (!input || !root) throw new Error('Expected a rendered checkbox')
    expect(ref.current).toBe(input)
    expect(root.getAttribute('class')).toBe('m3e-checkbox settings-checkbox')
    expect(root.getAttribute('style')).toContain('margin-inline-end: 8px')
    expect(input.getAttribute('id')).toBe('marketing')
    expect(input.getAttribute('name')).toBe('preferences')
    expect(input.getAttribute('value')).toBe('marketing')
    expect(input.required).toBe(true)
    expect(input.getAttribute('data-owner')).toBe('consumer')
  })

  it('toggles uncontrolled state through the browser and reports the resolved value', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(<Checkbox defaultChecked onCheckedChange={onCheckedChange} />)
    const input = screen.getByRole('checkbox') as HTMLInputElement

    expect(input.closest('.m3e-checkbox')?.getAttribute('data-m3e-state')).toBe('checked')
    await user.click(input)
    expect(onCheckedChange).toHaveBeenCalledWith(false)
    expect(input.checked).toBe(false)
    expect(input.closest('.m3e-checkbox')?.getAttribute('data-m3e-state')).toBe('unchecked')
  })

  it('keeps a controlled value authoritative until the consumer commits it', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(<Checkbox checked={false} onCheckedChange={onCheckedChange} />)
    const input = screen.getByRole('checkbox') as HTMLInputElement

    await user.click(input)
    expect(onCheckedChange).toHaveBeenCalledWith(true)
    expect(input.checked).toBe(false)
    expect(input.closest('.m3e-checkbox')?.getAttribute('data-m3e-state')).toBe('unchecked')
  })

  it('runs the consumer change handler first and treats preventDefault as cancellation', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(
      <Checkbox
        checked={false}
        onCheckedChange={onCheckedChange}
        onChange={(event) => event.preventDefault()}
      />,
    )

    await user.click(screen.getByRole('checkbox'))
    expect(onCheckedChange).not.toHaveBeenCalled()
  })

  it('exposes mixed state and restores the native property the browser clears', async () => {
    const user = userEvent.setup()
    function MixedCheckbox() {
      const [checked, setChecked] = useState(false)
      const [indeterminate, setIndeterminate] = useState(true)
      return (
        <Checkbox
          checked={checked}
          indeterminate={indeterminate}
          onCheckedChange={(next) => {
            setChecked(next)
            setIndeterminate(false)
          }}
        />
      )
    }
    render(<MixedCheckbox />)
    const input = screen.getByRole('checkbox') as HTMLInputElement

    expect(input.indeterminate).toBe(true)
    expect(input.getAttribute('aria-checked')).toBe('mixed')
    expect(input.closest('.m3e-checkbox')?.getAttribute('data-m3e-state')).toBe('indeterminate')

    await user.click(input)
    expect(input.indeterminate).toBe(false)
    expect(input.checked).toBe(true)
    expect(input.hasAttribute('aria-checked')).toBe(false)
    expect(input.closest('.m3e-checkbox')?.getAttribute('data-m3e-state')).toBe('checked')
  })

  it('keeps mixed state applied while the consumer still owns it', async () => {
    const user = userEvent.setup()
    render(<Checkbox indeterminate defaultChecked={false} />)
    const input = screen.getByRole('checkbox') as HTMLInputElement

    await user.click(input)
    expect(input.indeterminate).toBe(true)
    expect(input.closest('.m3e-checkbox')?.getAttribute('data-m3e-state')).toBe('indeterminate')
  })

  it('uses native disabled behavior and does not mutate state', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(<Checkbox disabled onCheckedChange={onCheckedChange} />)
    const input = screen.getByRole('checkbox') as HTMLInputElement

    await user.click(input)
    expect(onCheckedChange).not.toHaveBeenCalled()
    expect(input.disabled).toBe(true)
    expect(input.checked).toBe(false)
    expect(input.closest('.m3e-checkbox')?.getAttribute('data-m3e-disabled')).toBe('true')
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
        <Checkbox name="preferences" value="marketing" defaultChecked />
        <button type="submit">Save</button>
        <button type="reset">Reset</button>
      </form>,
    )
    const input = screen.getByRole('checkbox') as HTMLInputElement

    await user.click(screen.getByRole('button', { name: 'Save' }))
    expect(submitted).toEqual(['marketing'])

    await user.click(input)
    expect(input.closest('.m3e-checkbox')?.getAttribute('data-m3e-state')).toBe('unchecked')

    await user.click(screen.getByRole('button', { name: 'Reset' }))
    expect(input.checked).toBe(true)
    expect(input.closest('.m3e-checkbox')?.getAttribute('data-m3e-state')).toBe('checked')
  })

  it('warns for conflicting and incomplete runtime state props', () => {
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    const UntypedCheckbox = Checkbox as ComponentType<Record<string, unknown>>

    render(createElement(UntypedCheckbox, { checked: true, defaultChecked: true }))
    expect(warning).toHaveBeenCalledWith(
      'Checkbox: use either checked or defaultChecked, not both.',
    )
    expect(warning).toHaveBeenCalledWith(
      'Checkbox: a controlled checked value requires onCheckedChange or onChange.',
    )
  })

  it('exposes a stable component name for React tooling', () => {
    expect(Checkbox.displayName).toBe('Checkbox')
  })
})

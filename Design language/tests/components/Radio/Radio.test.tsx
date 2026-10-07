// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createElement, createRef, type ComponentType } from 'react'
import { afterEach, vi } from 'vitest'
import { Radio } from '../../../src/components/Radio'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('Radio', () => {
  it('renders one native radio input with unchecked defaults', () => {
    render(<Radio name="plan" data-testid="basic" />)
    const input = screen.getByTestId('basic')
    const root = input.closest('.m3e-radio')

    expect(input).toBeInstanceOf(HTMLInputElement)
    expect(input.getAttribute('type')).toBe('radio')
    expect((input as HTMLInputElement).checked).toBe(false)
    expect(root?.getAttribute('data-m3e-state')).toBe('unchecked')
    expect(root?.getAttribute('data-m3e-disabled')).toBe('false')
    expect(root?.querySelector('.m3e-radio__dot')).not.toBeNull()
  })

  it('sends className and style to the root while the ref and native props stay on the input', () => {
    const ref = createRef<HTMLInputElement>()
    render(
      <Radio
        ref={ref}
        className="settings-radio"
        style={{ marginInlineEnd: 8 }}
        id="plan-pro"
        name="plan"
        value="pro"
        required
        data-owner="consumer"
      />,
    )
    const input = document.querySelector('input')
    const root = document.querySelector('.m3e-radio')

    if (!input || !root) throw new Error('Expected a rendered radio')
    expect(ref.current).toBe(input)
    expect(root.getAttribute('class')).toBe('m3e-radio settings-radio')
    expect(root.getAttribute('style')).toContain('margin-inline-end: 8px')
    expect(input.getAttribute('id')).toBe('plan-pro')
    expect(input.getAttribute('name')).toBe('plan')
    expect(input.getAttribute('value')).toBe('pro')
    expect(input.required).toBe(true)
    expect(input.getAttribute('data-owner')).toBe('consumer')
  })

  it('toggles uncontrolled state through the browser and reports the resolved value', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(<Radio name="plan" onCheckedChange={onCheckedChange} />)
    const input = screen.getByRole('radio') as HTMLInputElement

    expect(input.closest('.m3e-radio')?.getAttribute('data-m3e-state')).toBe('unchecked')
    await user.click(input)
    expect(onCheckedChange).toHaveBeenCalledWith(true)
    expect(input.checked).toBe(true)
    expect(input.closest('.m3e-radio')?.getAttribute('data-m3e-state')).toBe('checked')
  })

  it('keeps a controlled value authoritative until the consumer commits it', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(<Radio name="plan" checked={false} onCheckedChange={onCheckedChange} />)
    const input = screen.getByRole('radio') as HTMLInputElement

    await user.click(input)
    expect(onCheckedChange).toHaveBeenCalledWith(true)
    expect(input.checked).toBe(false)
    expect(input.closest('.m3e-radio')?.getAttribute('data-m3e-state')).toBe('unchecked')
  })

  it('runs the consumer change handler first and treats preventDefault as cancellation', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(
      <Radio
        name="plan"
        checked={false}
        onCheckedChange={onCheckedChange}
        onChange={(event) => event.preventDefault()}
      />,
    )

    await user.click(screen.getByRole('radio'))
    expect(onCheckedChange).not.toHaveBeenCalled()
  })

  it('is mutually exclusive with other radios sharing its native group', async () => {
    const user = userEvent.setup()
    render(
      <>
        <Radio name="plan" aria-label="Basic" value="basic" defaultChecked />
        <Radio name="plan" aria-label="Pro" value="pro" />
      </>,
    )
    const basic = screen.getByRole('radio', { name: 'Basic' }) as HTMLInputElement
    const pro = screen.getByRole('radio', { name: 'Pro' }) as HTMLInputElement

    expect(basic.checked).toBe(true)
    await user.click(pro)
    // The browser fires no event on `basic` when the group's grouping logic
    // deselects it as a side effect of selecting `pro`, so only the native
    // `.checked` property (which CSS keys off of) is guaranteed live-accurate
    // here; `pro`'s own `data-m3e-state` is accurate because `pro` received
    // the change event that drove its own re-render.
    expect(pro.checked).toBe(true)
    expect(basic.checked).toBe(false)
    expect(pro.closest('.m3e-radio')?.getAttribute('data-m3e-state')).toBe('checked')
  })

  it('uses native disabled behavior and does not mutate state', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    render(<Radio name="plan" disabled onCheckedChange={onCheckedChange} />)
    const input = screen.getByRole('radio') as HTMLInputElement

    await user.click(input)
    expect(onCheckedChange).not.toHaveBeenCalled()
    expect(input.disabled).toBe(true)
    expect(input.checked).toBe(false)
    expect(input.closest('.m3e-radio')?.getAttribute('data-m3e-disabled')).toBe('true')
  })

  it('participates in form submission and resynchronizes on native reset', async () => {
    const user = userEvent.setup()
    const submitted: string[] = []
    render(
      <form
        onSubmit={(event) => {
          event.preventDefault()
          submitted.push(String(new FormData(event.currentTarget).get('plan')))
        }}
      >
        <Radio name="plan" value="basic" defaultChecked />
        <Radio name="plan" value="pro" />
        <button type="submit">Save</button>
        <button type="reset">Reset</button>
      </form>,
    )
    const [basic, pro] = screen.getAllByRole('radio') as HTMLInputElement[]

    await user.click(screen.getByRole('button', { name: 'Save' }))
    expect(submitted).toEqual(['basic'])

    await user.click(pro)
    expect(pro.closest('.m3e-radio')?.getAttribute('data-m3e-state')).toBe('checked')

    await user.click(screen.getByRole('button', { name: 'Reset' }))
    expect(basic.checked).toBe(true)
    expect(basic.closest('.m3e-radio')?.getAttribute('data-m3e-state')).toBe('checked')
    expect(pro.closest('.m3e-radio')?.getAttribute('data-m3e-state')).toBe('unchecked')
  })

  it('warns for conflicting and incomplete runtime state props', () => {
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    const UntypedRadio = Radio as ComponentType<Record<string, unknown>>

    render(createElement(UntypedRadio, { name: 'plan', checked: true, defaultChecked: true }))
    expect(warning).toHaveBeenCalledWith('Radio: use either checked or defaultChecked, not both.')
    expect(warning).toHaveBeenCalledWith(
      'Radio: a controlled checked value requires onCheckedChange or onChange.',
    )
  })

  it('exposes a stable component name for React tooling', () => {
    expect(Radio.displayName).toBe('Radio')
  })
})

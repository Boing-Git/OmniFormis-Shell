// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeAll } from 'vitest'
import { Select } from '../../../src/components/Select'
import type { SelectOption } from '../../../src/components/Select'
import { installScrollIntoViewPolyfill } from './select-native-polyfill'

beforeAll(installScrollIntoViewPolyfill)

afterEach(cleanup)

const options: SelectOption[] = [
  { value: 'apple', label: 'Apple' },
  { value: 'cherry', label: 'Cherry' },
]

describe('Select accessibility', () => {
  it('associates the label via a native label/htmlFor relationship', () => {
    render(<Select label="Fruit" options={options} />)
    expect(screen.getByLabelText('Fruit')).not.toBeNull()
  })

  it('sets aria-haspopup="listbox", aria-controls, and aria-expanded on the trigger', async () => {
    const user = userEvent.setup()
    render(<Select label="Fruit" options={options} />)
    const trigger = screen.getByRole('combobox', { name: 'Fruit' })
    expect(trigger.getAttribute('aria-haspopup')).toBe('listbox')
    expect(trigger.getAttribute('aria-expanded')).toBe('false')

    await user.click(trigger)
    const listbox = screen.getByRole('listbox')
    expect(trigger.getAttribute('aria-expanded')).toBe('true')
    expect(trigger.getAttribute('aria-controls')).toBe(listbox.id)
  })

  it('sets aria-activedescendant only while the listbox is open', async () => {
    const user = userEvent.setup()
    render(<Select label="Fruit" options={options} />)
    const trigger = screen.getByRole('combobox', { name: 'Fruit' })
    expect(trigger.hasAttribute('aria-activedescendant')).toBe(false)

    await user.click(trigger)
    expect(trigger.hasAttribute('aria-activedescendant')).toBe(true)
  })

  it('marks the selected option with aria-selected', async () => {
    const user = userEvent.setup()
    render(<Select label="Fruit" options={options} defaultValue="cherry" />)
    await user.click(screen.getByRole('combobox', { name: 'Fruit' }))
    const cherry = screen.getByRole('option', { name: 'Cherry' })
    const apple = screen.getByRole('option', { name: 'Apple' })
    expect(cherry.getAttribute('aria-selected')).toBe('true')
    expect(apple.getAttribute('aria-selected')).toBe('false')
  })

  it('never exposes free-text autocomplete semantics', () => {
    render(<Select label="Fruit" options={options} />)
    expect(screen.getByRole('combobox', { name: 'Fruit' }).getAttribute('aria-autocomplete')).toBe(
      'none',
    )
  })

  it('associates supportingText via aria-describedby', () => {
    render(<Select label="Fruit" options={options} supportingText="Choose one" />)
    const trigger = screen.getByRole('combobox', { name: 'Fruit' })
    const describedBy = trigger.getAttribute('aria-describedby')
    expect(describedBy).not.toBeNull()
    expect(document.getElementById(describedBy ?? '')?.textContent).toBe('Choose one')
  })

  it('keeps the field readable inside an RTL scope', () => {
    render(
      <div dir="rtl">
        <Select label="فاكهة" options={options} />
      </div>,
    )
    expect(screen.getByRole('combobox', { name: 'فاكهة' })).not.toBeNull()
  })
})

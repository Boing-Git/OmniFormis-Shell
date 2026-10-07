// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createRef } from 'react'
import { afterEach, beforeAll, vi } from 'vitest'
import { Select } from '../../../src/components/Select'
import type { SelectOption } from '../../../src/components/Select'
import { installScrollIntoViewPolyfill } from './select-native-polyfill'

beforeAll(installScrollIntoViewPolyfill)

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

const fruitOptions: SelectOption[] = [
  { value: 'apple', label: 'Apple' },
  { value: 'banana', label: 'Banana', disabled: true },
  { value: 'cherry', label: 'Cherry' },
]

function getTrigger(name = 'Fruit') {
  return screen.getByRole('combobox', { name }) as HTMLInputElement
}

describe('Select', () => {
  it('inherits the shared segmented outline in the outlined variant', () => {
    render(<Select label="Fruit" options={fruitOptions} variant="outlined" />)
    const outline = getTrigger().closest('.m3e-text-field')?.querySelector(
      '.m3e-text-field__outline',
    )

    expect(outline?.querySelector('.m3e-text-field__outline-start')).not.toBeNull()
    expect(outline?.querySelector('.m3e-text-field__notch')?.textContent).toBe('Fruit')
    expect(outline?.querySelector('.m3e-text-field__outline-end')).not.toBeNull()
  })

  it('renders a combobox trigger with no listbox until opened', () => {
    render(<Select label="Fruit" options={fruitOptions} />)
    const trigger = getTrigger()
    expect(trigger.getAttribute('aria-expanded')).toBe('false')
    expect(trigger.readOnly).toBe(true)
    expect(screen.queryByRole('listbox')).toBeNull()
  })

  it('inherits icon-aware regions and activates from the shared whole-field hit target', async () => {
    const user = userEvent.setup()
    render(<Select label="Fruit" options={fruitOptions} leadingIcon={<span />} />)
    const trigger = getTrigger()
    const field = trigger.closest('.m3e-text-field__field')
    const hitTarget = field?.querySelector('.m3e-text-field__hit-target')

    expect(field?.getAttribute('data-m3e-has-leading-icon')).toBe('true')
    expect(field?.getAttribute('data-m3e-has-trailing-icon')).toBe('true')
    await user.click(hitTarget as HTMLLabelElement)
    expect(trigger.getAttribute('aria-expanded')).toBe('true')
  })

  it('opens the listbox on click and renders each option in display order', async () => {
    const user = userEvent.setup()
    render(<Select label="Fruit" options={fruitOptions} />)
    await user.click(getTrigger())

    const listbox = screen.getByRole('listbox')
    const options = screen.getAllByRole('option')
    expect(listbox).not.toBeNull()
    expect(options.map((option) => option.textContent)).toEqual(['Apple', 'Banana', 'Cherry'])
    expect(options[1].getAttribute('aria-disabled')).toBe('true')
  })

  it('clicking an enabled option commits its value, updates the trigger, and closes', async () => {
    const user = userEvent.setup()
    const onValueChange = vi.fn()
    render(<Select label="Fruit" options={fruitOptions} onValueChange={onValueChange} />)
    await user.click(getTrigger())
    await user.click(screen.getByRole('option', { name: 'Cherry' }))

    expect(onValueChange).toHaveBeenCalledWith('cherry')
    // Closing is requested synchronously (aria-expanded reflects it
    // immediately); the listbox's own removal from the DOM is deferred
    // until its exit transition finishes, so this checks the request
    // itself rather than racing real transition/rAF timing.
    expect(getTrigger().getAttribute('aria-expanded')).toBe('false')
    expect(getTrigger().value).toBe('Cherry')
  })

  it('clicking a disabled option does nothing', async () => {
    const user = userEvent.setup()
    const onValueChange = vi.fn()
    render(<Select label="Fruit" options={fruitOptions} onValueChange={onValueChange} />)
    await user.click(getTrigger())
    await user.click(screen.getByRole('option', { name: 'Banana' }))

    expect(onValueChange).not.toHaveBeenCalled()
    expect(screen.getByRole('listbox')).not.toBeNull()
  })

  it('ArrowDown while closed opens the listbox with the first enabled option active', async () => {
    const user = userEvent.setup()
    render(<Select label="Fruit" options={fruitOptions} />)
    getTrigger().focus()
    await user.keyboard('{ArrowDown}')

    const trigger = getTrigger()
    expect(trigger.getAttribute('aria-expanded')).toBe('true')
    const activeId = trigger.getAttribute('aria-activedescendant')
    expect(document.getElementById(activeId ?? '')?.textContent).toBe('Apple')
  })

  it('ArrowDown/ArrowUp move the active descendant across enabled options only, wrapping', async () => {
    const user = userEvent.setup()
    render(<Select label="Fruit" options={fruitOptions} />)
    getTrigger().focus()
    await user.keyboard('{ArrowDown}')
    await user.keyboard('{ArrowDown}')
    let trigger = getTrigger()
    let activeId = trigger.getAttribute('aria-activedescendant')
    expect(document.getElementById(activeId ?? '')?.textContent).toBe('Cherry')

    await user.keyboard('{ArrowDown}')
    trigger = getTrigger()
    activeId = trigger.getAttribute('aria-activedescendant')
    expect(document.getElementById(activeId ?? '')?.textContent).toBe('Apple')
  })

  it('Enter commits the active option and closes', async () => {
    const user = userEvent.setup()
    const onValueChange = vi.fn()
    render(<Select label="Fruit" options={fruitOptions} onValueChange={onValueChange} />)
    getTrigger().focus()
    await user.keyboard('{ArrowDown}{ArrowDown}{Enter}')

    expect(onValueChange).toHaveBeenCalledWith('cherry')
    expect(getTrigger().getAttribute('aria-expanded')).toBe('false')
  })

  it('Escape closes the listbox without changing the value', async () => {
    const user = userEvent.setup()
    const onValueChange = vi.fn()
    render(<Select label="Fruit" options={fruitOptions} defaultValue="apple" onValueChange={onValueChange} />)
    getTrigger().focus()
    await user.keyboard('{ArrowDown}{ArrowDown}{Escape}')

    expect(onValueChange).not.toHaveBeenCalled()
    expect(getTrigger().getAttribute('aria-expanded')).toBe('false')
    expect(getTrigger().value).toBe('Apple')
  })

  it('typeahead moves the active descendant to the next option starting with the typed letter', async () => {
    const user = userEvent.setup()
    render(<Select label="Fruit" options={fruitOptions} />)
    await user.click(getTrigger())
    await user.keyboard('c')

    const trigger = getTrigger()
    const activeId = trigger.getAttribute('aria-activedescendant')
    expect(document.getElementById(activeId ?? '')?.textContent).toBe('Cherry')
  })

  it('supports uncontrolled defaultValue and controlled value', () => {
    const { rerender } = render(
      <Select label="Fruit" options={fruitOptions} defaultValue="apple" />,
    )
    expect(getTrigger().value).toBe('Apple')

    rerender(<Select label="Fruit" options={fruitOptions} value="cherry" onValueChange={() => undefined} />)
    expect(getTrigger().value).toBe('Cherry')
  })

  it('renders a hidden input tracking the selected value when name is supplied', async () => {
    const user = userEvent.setup()
    const { container } = render(<Select label="Fruit" options={fruitOptions} name="fruit" />)
    const hidden = container.querySelector('input[type="hidden"]') as HTMLInputElement
    expect(hidden.name).toBe('fruit')
    expect(hidden.value).toBe('')

    await user.click(getTrigger())
    await user.click(screen.getByRole('option', { name: 'Apple' }))
    expect(hidden.value).toBe('apple')
  })

  it('renders no hidden input when name is omitted', () => {
    const { container } = render(<Select label="Fruit" options={fruitOptions} />)
    expect(container.querySelector('input[type="hidden"]')).toBeNull()
  })

  it('forwards ref to the visible trigger input', () => {
    const ref = createRef<HTMLInputElement>()
    render(<Select ref={ref} label="Fruit" options={fruitOptions} />)
    expect(ref.current).toBe(getTrigger())
  })

  it('a disabled Select does not open on click or keyboard', async () => {
    const user = userEvent.setup()
    render(<Select label="Fruit" options={fruitOptions} disabled />)
    const trigger = getTrigger()
    expect(trigger.disabled).toBe(true)
    await user.click(trigger)
    expect(screen.queryByRole('listbox')).toBeNull()
  })

  it('exposes a stable component name for React tooling', () => {
    expect(Select.displayName).toBe('Select')
  })
})

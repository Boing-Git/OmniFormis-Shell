// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createRef } from 'react'
import { afterEach, vi } from 'vitest'
import { TextField } from '../../../src/components/TextField'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('TextField', () => {
  it('renders one native text input associated with its label', () => {
    render(<TextField label="Full name" />)
    const input = screen.getByLabelText('Full name')
    const root = input.closest('.m3e-text-field')

    expect(input).toBeInstanceOf(HTMLInputElement)
    expect(input.getAttribute('type')).toBe('text')
    expect(root?.getAttribute('data-m3e-variant')).toBe('filled')
    expect(root?.getAttribute('data-m3e-error')).toBe('false')
    expect(root?.getAttribute('data-m3e-disabled')).toBe('false')
    expect(root?.querySelector('.m3e-text-field__indicator')).not.toBeNull()
    expect(root?.querySelector('.m3e-text-field__outline')).toBeNull()
  })

  it('renders the outlined variant with a notched border and no indicator', () => {
    render(<TextField variant="outlined" label="Email" />)
    const root = screen.getByLabelText('Email').closest('.m3e-text-field')
    const outline = root?.querySelector('.m3e-text-field__outline')

    expect(root?.getAttribute('data-m3e-variant')).toBe('outlined')
    expect(outline?.tagName).toBe('SPAN')
    expect(outline?.getAttribute('aria-hidden')).toBe('true')
    expect(Array.from(outline?.children ?? [], (child) => child.className)).toEqual([
      'm3e-text-field__outline-start',
      'm3e-text-field__notch',
      'm3e-text-field__outline-end',
    ])
    expect(root?.querySelector('.m3e-text-field__notch')?.textContent).toBe('Email')
    expect(root?.querySelector('.m3e-text-field__indicator')).toBeNull()
  })

  it('defaults its native placeholder to a single space so :placeholder-shown stays reliable', () => {
    render(<TextField label="Name" />)
    expect(screen.getByLabelText('Name').getAttribute('placeholder')).toBe(' ')
  })

  it('passes a caller-supplied placeholder through unchanged', () => {
    render(<TextField label="Name" placeholder="Ada Lovelace" />)
    expect(screen.getByLabelText('Name').getAttribute('placeholder')).toBe('Ada Lovelace')
  })

  it('sends className and style to the root while the ref and native props stay on the input', () => {
    const ref = createRef<HTMLInputElement>()
    render(
      <TextField
        ref={ref}
        label="Name"
        className="signup-name"
        style={{ marginInlineEnd: 8 }}
        id="signup-name"
        name="fullName"
        value="Ada"
        onChange={() => undefined}
        required
        data-owner="consumer"
      />,
    )
    const input = document.querySelector('input')
    const root = document.querySelector('.m3e-text-field')

    if (!input || !root) throw new Error('Expected a rendered text field')
    expect(ref.current).toBe(input)
    expect(root.getAttribute('class')).toBe('m3e-text-field signup-name')
    expect(root.getAttribute('style')).toContain('margin-inline-end: 8px')
    expect(input.getAttribute('id')).toBe('signup-name')
    expect(input.getAttribute('name')).toBe('fullName')
    expect(input.value).toBe('Ada')
    expect(input.required).toBe(true)
    expect(input.getAttribute('data-owner')).toBe('consumer')
  })

  it('generates a stable id pairing the label and input when none is supplied', () => {
    render(<TextField label="Name" />)
    const input = screen.getByLabelText('Name')
    const label = document.querySelector('label')

    expect(input.id).not.toBe('')
    expect(label?.getAttribute('for')).toBe(input.id)
  })

  it('accepts a text-like native input type', () => {
    render(<TextField label="Email" type="email" />)
    expect(screen.getByLabelText('Email').getAttribute('type')).toBe('email')
  })

  it('keeps password inputs in the shared leading-icon layout', () => {
    render(
      <TextField label="Password" type="password" leadingIcon={<span data-testid="lock" />} />,
    )
    const input = screen.getByLabelText('Password')
    const field = input.closest('.m3e-text-field__field')

    expect(input.getAttribute('type')).toBe('password')
    expect(field?.getAttribute('data-m3e-has-leading-icon')).toBe('true')
    expect(screen.getByTestId('lock').closest('[data-m3e-position="leading"]')).not.toBeNull()
  })

  it('accepts typed input through the browser like any native text input', async () => {
    const user = userEvent.setup()
    render(<TextField label="Name" />)
    const input = screen.getByLabelText('Name') as HTMLInputElement

    await user.type(input, 'Ada')
    expect(input.value).toBe('Ada')
  })

  it('renders supplied leading and trailing icons and reflects their presence on the field', () => {
    render(
      <TextField
        label="Search"
        leadingIcon={<span data-testid="leading" />}
        trailingIcon={<span data-testid="trailing" />}
      />,
    )
    const field = document.querySelector('.m3e-text-field__field')

    expect(screen.getByTestId('leading').closest('[data-m3e-position="leading"]')).not.toBeNull()
    expect(screen.getByTestId('trailing').closest('[data-m3e-position="trailing"]')).not.toBeNull()
    expect(field?.getAttribute('data-m3e-has-leading-icon')).toBe('true')
    expect(field?.getAttribute('data-m3e-has-trailing-icon')).toBe('true')
  })

  it('keeps the complete field chrome clickable after the input moves into its content region', async () => {
    const user = userEvent.setup()
    render(<TextField label="Search" leadingIcon={<span />} />)
    const input = screen.getByLabelText('Search') as HTMLInputElement
    const hitTarget = input
      .closest('.m3e-text-field__field')
      ?.querySelector('.m3e-text-field__hit-target')

    expect(hitTarget).toBeInstanceOf(HTMLLabelElement)
    expect(hitTarget?.getAttribute('for')).toBe(input.id)
    expect(hitTarget?.getAttribute('aria-hidden')).toBe('true')
    await user.click(hitTarget as HTMLLabelElement)
    expect(document.activeElement).toBe(input)
  })

  it('renders supporting text and associates it through aria-describedby', () => {
    render(<TextField label="Name" supportingText="As it appears on your ticket" />)
    const input = screen.getByLabelText('Name')
    const supporting = screen.getByText('As it appears on your ticket')

    expect(supporting.className).toBe('m3e-text-field__supporting-text')
    expect(input.getAttribute('aria-describedby')).toBe(supporting.id)
  })

  it('composes a caller-supplied aria-describedby with the supporting text id', () => {
    render(
      <>
        <TextField label="Name" supportingText="Required" aria-describedby="extra-help" />
        <p id="extra-help">Extra help</p>
      </>,
    )
    const input = screen.getByLabelText('Name')
    const describedBy = input.getAttribute('aria-describedby')?.split(' ')

    expect(describedBy).toContain('extra-help')
    expect(describedBy).toContain(screen.getByText('Required').id)
  })

  it('flags the error state on the root and the input without altering supporting text content', () => {
    render(<TextField label="Promo code" error supportingText="This code has expired" />)
    const input = screen.getByLabelText('Promo code')

    expect(input.getAttribute('aria-invalid')).toBe('true')
    expect(input.closest('.m3e-text-field')?.getAttribute('data-m3e-error')).toBe('true')
    expect(screen.getByText('This code has expired')).not.toBeNull()
  })

  it('respects a caller-supplied aria-invalid when not flagged as an error', () => {
    render(<TextField label="Name" aria-invalid="true" />)
    expect(screen.getByLabelText('Name').getAttribute('aria-invalid')).toBe('true')
  })

  it('uses native disabled behavior and reflects it on the root', () => {
    render(<TextField label="Locked" disabled defaultValue="Read only" />)
    const input = screen.getByLabelText('Locked') as HTMLInputElement

    expect(input.disabled).toBe(true)
    expect(input.closest('.m3e-text-field')?.getAttribute('data-m3e-disabled')).toBe('true')
  })

  it('participates in form submission and native reset like any native input', async () => {
    const user = userEvent.setup()
    let submitted = ''
    render(
      <form
        onSubmit={(event) => {
          event.preventDefault()
          submitted = String(new FormData(event.currentTarget).get('promo'))
        }}
      >
        <TextField label="Promo code" name="promo" defaultValue="WELCOME10" />
        <button type="submit">Save</button>
        <button type="reset">Reset</button>
      </form>,
    )
    const input = screen.getByLabelText('Promo code') as HTMLInputElement

    await user.clear(input)
    await user.type(input, 'SUMMER5')
    await user.click(screen.getByRole('button', { name: 'Save' }))
    expect(submitted).toBe('SUMMER5')

    await user.click(screen.getByRole('button', { name: 'Reset' }))
    expect(input.value).toBe('WELCOME10')
  })

  it('exposes a stable component name for React tooling', () => {
    expect(TextField.displayName).toBe('TextField')
  })
})

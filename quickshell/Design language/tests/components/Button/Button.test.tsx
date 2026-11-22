// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createRef } from 'react'
import { afterEach, vi } from 'vitest'
import {
  Button,
  type ButtonSize,
  type ButtonVariant,
} from '../../../src/components/Button'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('Button', () => {
  it('renders a safe native button with sourced small filled defaults', () => {
    render(<Button>Save</Button>)
    const button = screen.getByRole('button', { name: 'Save' })
    const label = button.querySelector('.m3e-button__label')

    expect(button).toBeInstanceOf(HTMLButtonElement)
    expect(button.getAttribute('type')).toBe('button')
    expect(button.getAttribute('class')).toBe('m3e-button')
    expect(button.getAttribute('data-m3e-variant')).toBe('filled')
    expect(button.getAttribute('data-m3e-size')).toBe('small')
    expect(button.getAttribute('data-m3e-width')).toBe('fit')
    expect(button.getAttribute('data-m3e-shape')).toBe('round')
    expect(button.getAttribute('data-m3e-disabled')).toBe('false')
    expect(label?.getAttribute('data-m3e-variant')).toBe('labelLarge')
    expect(label?.getAttribute('data-m3e-emphasis')).toBe('baseline')
  })

  it.each([
    ['filled', 'extra-small', 'labelLarge'],
    ['tonal', 'small', 'labelLarge'],
    ['elevated', 'medium', 'titleMedium'],
    ['outlined', 'large', 'headlineSmall'],
    ['text', 'extra-large', 'headlineLarge'],
  ] satisfies ReadonlyArray<readonly [ButtonVariant, ButtonSize, string]>)(
    'maps the %s variant and %s size to stable attributes and typography',
    (variant, size, textVariant) => {
      render(
        <Button variant={variant} size={size}>
          {variant}
        </Button>,
      )
      const button = screen.getByRole('button', { name: variant })
      expect(button.getAttribute('data-m3e-variant')).toBe(variant)
      expect(button.getAttribute('data-m3e-size')).toBe(size)
      expect(
        button.querySelector('.m3e-button__label')?.getAttribute('data-m3e-variant'),
      ).toBe(textVariant)
      cleanup()
    },
  )

  it('renders full-width square layout and decorative icon slots in source order', () => {
    render(
      <Button
        width="full"
        shape="square"
        leadingIcon={<svg data-testid="leading" />}
        trailingIcon={<span data-testid="trailing">→</span>}
      >
        Continue
      </Button>,
    )
    const button = screen.getByRole('button', { name: 'Continue' })
    const container = button.firstElementChild
    const slots = container?.children

    expect(button.getAttribute('data-m3e-width')).toBe('full')
    expect(button.getAttribute('data-m3e-shape')).toBe('square')
    expect(slots).toHaveLength(3)
    expect(slots?.item(0).getAttribute('data-m3e-position')).toBe('leading')
    expect(slots?.item(0).getAttribute('aria-hidden')).toBe('true')
    expect(slots?.item(1).textContent).toBe('Continue')
    expect(slots?.item(2).getAttribute('data-m3e-position')).toBe('trailing')
    expect(slots?.item(2).getAttribute('aria-hidden')).toBe('true')
  })

  it('preserves native props, consumer styling, events, and the button ref', async () => {
    const user = userEvent.setup()
    const ref = createRef<HTMLButtonElement>()
    const onClick = vi.fn()
    render(
      <Button
        ref={ref}
        type="submit"
        name="intent"
        value="publish"
        form="article-form"
        id="publish"
        data-owner="consumer"
        aria-describedby="publish-help"
        className="publish-action"
        style={{ marginInlineStart: 8 }}
        onClick={onClick}
      >
        Publish
      </Button>,
    )
    const button = screen.getByRole('button', { name: 'Publish' })

    await user.click(button)
    expect(onClick).toHaveBeenCalledTimes(1)
    expect(ref.current).toBe(button)
    expect(button.getAttribute('type')).toBe('submit')
    expect(button.getAttribute('name')).toBe('intent')
    expect(button.getAttribute('value')).toBe('publish')
    expect(button.getAttribute('form')).toBe('article-form')
    expect(button.getAttribute('data-owner')).toBe('consumer')
    expect(button.getAttribute('aria-describedby')).toBe('publish-help')
    expect(button.getAttribute('class')).toBe('m3e-button publish-action')
    expect(button.getAttribute('style')).toContain('margin-inline-start: 8px')
  })

  it('keeps form submission opt-in through the native type attribute', async () => {
    const user = userEvent.setup()
    const onSubmit = vi.fn((event: React.FormEvent) => event.preventDefault())
    render(
      <form onSubmit={onSubmit}>
        <Button>Preview</Button>
        <Button type="submit">Save</Button>
      </form>,
    )

    await user.click(screen.getByRole('button', { name: 'Preview' }))
    expect(onSubmit).not.toHaveBeenCalled()
    await user.click(screen.getByRole('button', { name: 'Save' }))
    expect(onSubmit).toHaveBeenCalledTimes(1)
  })

  it('uses native disabled behavior and does not dispatch consumer activation', async () => {
    const user = userEvent.setup()
    const onClick = vi.fn()
    render(<Button disabled onClick={onClick}>Delete</Button>)
    const button = screen.getByRole('button', { name: 'Delete' })

    await user.click(button)
    expect(onClick).not.toHaveBeenCalled()
    expect((button as HTMLButtonElement).disabled).toBe(true)
    expect(button.getAttribute('data-m3e-disabled')).toBe('true')
  })

  it('warns for unnamed empty content without changing the rendered contract', () => {
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    render(<Button>{'   '}</Button>)

    expect(warning).toHaveBeenCalledWith(
      'Button: provide non-empty label content, aria-label, or aria-labelledby so the native button has an accessible name.',
    )
    expect(document.querySelector('button')?.getAttribute('type')).toBe('button')
  })

  it('accepts an explicit accessible name for non-text content', () => {
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    render(<Button aria-label="Create">{null}</Button>)

    expect(screen.getByRole('button', { name: 'Create' })).toBeInstanceOf(HTMLButtonElement)
    expect(warning).not.toHaveBeenCalled()
  })

  it('exposes a stable component name for React tooling', () => {
    expect(Button.displayName).toBe('Button')
  })
})

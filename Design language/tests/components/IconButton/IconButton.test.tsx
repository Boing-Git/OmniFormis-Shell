// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createRef } from 'react'
import { afterEach, vi } from 'vitest'
import {
  Icon,
  IconButton,
  type IconButtonProps,
  type IconButtonSize,
  type IconButtonVariant,
  type IconButtonWidth,
} from '../../../src'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('IconButton', () => {
  it('renders a safe native momentary button with sourced defaults', () => {
    render(
      <IconButton aria-label="More options">
        <Icon source="more_vert" />
      </IconButton>,
    )
    const button = screen.getByRole('button', { name: 'More options' })

    expect(button).toBeInstanceOf(HTMLButtonElement)
    expect(button.getAttribute('type')).toBe('button')
    expect(button.getAttribute('class')).toBe('m3e-icon-button')
    expect(button.getAttribute('data-m3e-variant')).toBe('standard')
    expect(button.getAttribute('data-m3e-size')).toBe('small')
    expect(button.getAttribute('data-m3e-width')).toBe('uniform')
    expect(button.getAttribute('data-m3e-shape')).toBe('round')
    expect(button.getAttribute('data-m3e-toggle')).toBe('false')
    expect(button.hasAttribute('data-m3e-selected')).toBe(false)
    expect(button.hasAttribute('aria-pressed')).toBe(false)
  })

  it.each([
    ['standard', 'extra-small', 'narrow'],
    ['filled', 'small', 'uniform'],
    ['tonal', 'medium', 'wide'],
    ['outlined', 'large', 'narrow'],
    ['filled', 'extra-large', 'wide'],
  ] satisfies ReadonlyArray<readonly [IconButtonVariant, IconButtonSize, IconButtonWidth]>) (
    'maps %s, %s, and %s to stable attributes',
    (variant, size, width) => {
      render(
        <IconButton aria-label={`${variant}-${size}-${width}`} variant={variant} size={size} width={width}>
          <Icon source="check" />
        </IconButton>,
      )
      const button = screen.getByRole('button', { name: `${variant}-${size}-${width}` })
      expect(button.getAttribute('data-m3e-variant')).toBe(variant)
      expect(button.getAttribute('data-m3e-size')).toBe(size)
      expect(button.getAttribute('data-m3e-width')).toBe(width)
      cleanup()
    },
  )

  it('supports uncontrolled selection and alternate selected artwork', async () => {
    const user = userEvent.setup()
    const onSelectedChange = vi.fn()
    render(
      <IconButton
        aria-label="Favorite"
        toggle
        onSelectedChange={onSelectedChange}
        selectedIcon={<Icon source="favorite" fill={1} />}
      >
        <Icon source="favorite" />
      </IconButton>,
    )
    const button = screen.getByRole('button', { name: 'Favorite' })

    expect(button.getAttribute('aria-pressed')).toBe('false')
    expect(button.getAttribute('data-m3e-selected')).toBe('false')
    expect(button.querySelectorAll('.m3e-icon-button__icon')).toHaveLength(2)
    await user.click(button)
    expect(button.getAttribute('aria-pressed')).toBe('true')
    expect(button.getAttribute('data-m3e-selected')).toBe('true')
    expect(onSelectedChange).toHaveBeenCalledWith(true)
    await user.click(button)
    expect(button.getAttribute('aria-pressed')).toBe('false')
    expect(onSelectedChange).toHaveBeenLastCalledWith(false)
    expect(onSelectedChange).toHaveBeenCalledTimes(2)
  })

  it('supports controlled selection without mirroring props into local state', async () => {
    const user = userEvent.setup()
    const onSelectedChange = vi.fn()
    const { rerender } = render(
      <IconButton aria-label="Pin" toggle selected={false} onSelectedChange={onSelectedChange}>
        <Icon source="push_pin" />
      </IconButton>,
    )
    const button = screen.getByRole('button', { name: 'Pin' })

    await user.click(button)
    expect(onSelectedChange).toHaveBeenCalledWith(true)
    expect(button.getAttribute('aria-pressed')).toBe('false')
    rerender(
      <IconButton aria-label="Pin" toggle selected onSelectedChange={onSelectedChange}>
        <Icon source="push_pin" />
      </IconButton>,
    )
    expect(button.getAttribute('aria-pressed')).toBe('true')
  })

  it('runs consumer click behavior first and lets preventDefault cancel toggling', async () => {
    const user = userEvent.setup()
    const order: string[] = []
    const onSelectedChange = vi.fn(() => order.push('selected'))
    const onClick = vi.fn((event: React.MouseEvent<HTMLButtonElement>) => {
      order.push('click')
      event.preventDefault()
    })
    render(
      <IconButton
        aria-label="Lock"
        toggle
        onClick={onClick}
        onSelectedChange={onSelectedChange}
      >
        <Icon source="lock" />
      </IconButton>,
    )
    const button = screen.getByRole('button', { name: 'Lock' })

    await user.click(button)
    expect(order).toEqual(['click'])
    expect(onSelectedChange).not.toHaveBeenCalled()
    expect(button.getAttribute('aria-pressed')).toBe('false')
  })

  it('preserves native props, form behavior, consumer styling, and the ref', async () => {
    const user = userEvent.setup()
    const ref = createRef<HTMLButtonElement>()
    const onSubmit = vi.fn((event: React.FormEvent) => event.preventDefault())
    render(
      <form id="actions" onSubmit={onSubmit}>
        <IconButton
          ref={ref}
          aria-label="Publish"
          type="submit"
          name="intent"
          value="publish"
          form="actions"
          data-owner="consumer"
          aria-describedby="publish-help"
          className="publish-icon"
          style={{ marginInlineStart: 8 }}
        >
          <Icon source="publish" />
        </IconButton>
      </form>,
    )
    const button = screen.getByRole('button', { name: 'Publish' })

    await user.click(button)
    expect(onSubmit).toHaveBeenCalledTimes(1)
    expect(ref.current).toBe(button)
    expect(button.getAttribute('name')).toBe('intent')
    expect(button.getAttribute('value')).toBe('publish')
    expect(button.getAttribute('data-owner')).toBe('consumer')
    expect(button.getAttribute('aria-describedby')).toBe('publish-help')
    expect(button.getAttribute('class')).toBe('m3e-icon-button publish-icon')
    expect(button.getAttribute('style')).toContain('margin-inline-start: 8px')
  })

  it('uses native disabled behavior and never mutates toggle state', async () => {
    const user = userEvent.setup()
    const onClick = vi.fn()
    const onSelectedChange = vi.fn()
    render(
      <IconButton
        aria-label="Favorite"
        toggle
        disabled
        defaultSelected
        onClick={onClick}
        onSelectedChange={onSelectedChange}
      >
        <Icon source="favorite" />
      </IconButton>,
    )
    const button = screen.getByRole('button', { name: 'Favorite' })

    await user.click(button)
    expect(onClick).not.toHaveBeenCalled()
    expect(onSelectedChange).not.toHaveBeenCalled()
    expect(button.getAttribute('aria-pressed')).toBe('true')
    expect((button as HTMLButtonElement).disabled).toBe(true)
  })

  it('warns for a missing accessible name without changing markup', () => {
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    render(
      <IconButton>
        <Icon source="search" />
      </IconButton>,
    )

    expect(warning).toHaveBeenCalledWith(
      'IconButton: provide a non-empty aria-label or aria-labelledby so the icon-only button has an accessible name.',
    )
    expect(document.querySelector('button')?.getAttribute('type')).toBe('button')
  })

  it('warns untyped callers about a controlled toggle without a change callback', () => {
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    const invalidProps = {
      'aria-label': 'Favorite',
      toggle: true,
      selected: true,
      children: <Icon source="favorite" />,
    } as unknown as IconButtonProps

    render(<IconButton {...invalidProps} />)
    expect(warning).toHaveBeenCalledWith(
      'IconButton: a controlled selected value requires onSelectedChange.',
    )
    expect(screen.getByRole('button', { name: 'Favorite' }).getAttribute('aria-pressed')).toBe('true')
  })

  it('exposes a stable component name for React tooling', () => {
    expect(IconButton.displayName).toBe('IconButton')
  })
})

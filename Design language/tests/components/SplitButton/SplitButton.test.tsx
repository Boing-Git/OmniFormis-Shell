// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createRef } from 'react'
import { afterEach, vi } from 'vitest'
import { SplitButton, type SplitButtonSize, type SplitButtonVariant } from '../../../src/components/SplitButton'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('SplitButton', () => {
  it('renders a leading action button and a trailing icon-only toggle button', () => {
    render(
      <SplitButton trailingIcon={<svg data-testid="chevron" />} trailingLabel="More options">
        Save
      </SplitButton>,
    )
    const leading = screen.getByRole('button', { name: 'Save' })
    const trailing = screen.getByRole('button', { name: 'More options' })
    expect(leading).toBeInstanceOf(HTMLButtonElement)
    expect(trailing).toBeInstanceOf(HTMLButtonElement)
    expect(trailing.getAttribute('aria-pressed')).toBe('false')
    expect(screen.getByRole('group')).not.toBeNull()
  })

  it('defaults to filled/small and reflects sourced attributes', () => {
    render(
      <SplitButton trailingIcon={<svg />} trailingLabel="More options">
        Save
      </SplitButton>,
    )
    const root = screen.getByRole('group')
    expect(root.getAttribute('class')).toBe('m3e-split-button')
    expect(root.getAttribute('data-m3e-variant')).toBe('filled')
    expect(root.getAttribute('data-m3e-size')).toBe('small')
  })

  it.each([
    ['filled', 'extra-small'],
    ['tonal', 'small'],
    ['elevated', 'medium'],
    ['outlined', 'large'],
    ['filled', 'extra-large'],
  ] satisfies ReadonlyArray<readonly [SplitButtonVariant, SplitButtonSize]>)(
    'maps the %s variant and %s size to stable attributes',
    (variant, size) => {
      render(
        <SplitButton variant={variant} size={size} trailingIcon={<svg />} trailingLabel="More options">
          Save
        </SplitButton>,
      )
      const root = screen.getByRole('group')
      expect(root.getAttribute('data-m3e-variant')).toBe(variant)
      expect(root.getAttribute('data-m3e-size')).toBe(size)
      cleanup()
    },
  )

  it('renders a leading icon before the label', () => {
    render(
      <SplitButton
        leadingIcon={<svg data-testid="leading" />}
        trailingIcon={<svg />}
        trailingLabel="More options"
      >
        Save
      </SplitButton>,
    )
    const leading = screen.getByRole('button', { name: 'Save' })
    const icon = leading.querySelector('[data-testid="leading"]')
    expect(icon).not.toBeNull()
    expect(icon?.closest('.m3e-split-button__icon')?.getAttribute('aria-hidden')).toBe('true')
  })

  it('fires onClick only for the leading button', async () => {
    const user = userEvent.setup()
    const onClick = vi.fn()
    render(
      <SplitButton onClick={onClick} trailingIcon={<svg />} trailingLabel="More options">
        Save
      </SplitButton>,
    )
    await user.click(screen.getByRole('button', { name: 'Save' }))
    expect(onClick).toHaveBeenCalledTimes(1)
    await user.click(screen.getByRole('button', { name: 'More options' }))
    expect(onClick).toHaveBeenCalledTimes(1)
  })

  it('toggles the trailing button as an uncontrolled selection by default', async () => {
    const user = userEvent.setup()
    const onSelectedChange = vi.fn()
    render(
      <SplitButton
        trailingIcon={<svg />}
        trailingLabel="More options"
        onSelectedChange={onSelectedChange}
      >
        Save
      </SplitButton>,
    )
    const trailing = screen.getByRole('button', { name: 'More options' })
    expect(trailing.getAttribute('aria-pressed')).toBe('false')

    await user.click(trailing)
    expect(trailing.getAttribute('aria-pressed')).toBe('true')
    expect(trailing.getAttribute('data-m3e-selected')).toBe('true')
    expect(onSelectedChange).toHaveBeenCalledWith(true)
  })

  it('supports a controlled selected trailing state', async () => {
    const user = userEvent.setup()
    const onSelectedChange = vi.fn()
    const { rerender } = render(
      <SplitButton
        trailingIcon={<svg />}
        trailingLabel="More options"
        selected={false}
        onSelectedChange={onSelectedChange}
      >
        Save
      </SplitButton>,
    )
    const trailing = screen.getByRole('button', { name: 'More options' })
    await user.click(trailing)
    expect(onSelectedChange).toHaveBeenCalledWith(true)
    // Controlled: stays false until the consumer updates the prop.
    expect(trailing.getAttribute('aria-pressed')).toBe('false')

    rerender(
      <SplitButton
        trailingIcon={<svg />}
        trailingLabel="More options"
        selected={true}
        onSelectedChange={onSelectedChange}
      >
        Save
      </SplitButton>,
    )
    expect(screen.getByRole('button', { name: 'More options' }).getAttribute('aria-pressed')).toBe(
      'true',
    )
  })

  it('disables both buttons', () => {
    render(
      <SplitButton disabled trailingIcon={<svg />} trailingLabel="More options">
        Save
      </SplitButton>,
    )
    expect((screen.getByRole('button', { name: 'Save' }) as HTMLButtonElement).disabled).toBe(true)
    expect(
      (screen.getByRole('button', { name: 'More options' }) as HTMLButtonElement).disabled,
    ).toBe(true)
  })

  it('forwards ref, className, and style to the root', () => {
    const ref = createRef<HTMLDivElement>()
    render(
      <SplitButton
        ref={ref}
        trailingIcon={<svg />}
        trailingLabel="More options"
        className="consumer-class"
        data-owner="consumer"
      >
        Save
      </SplitButton>,
    )
    expect(ref.current?.getAttribute('role')).toBe('group')
    expect(ref.current?.className).toContain('m3e-split-button')
    expect(ref.current?.className).toContain('consumer-class')
    expect(ref.current?.getAttribute('data-owner')).toBe('consumer')
  })

  it('exposes a stable component name for React tooling', () => {
    expect(SplitButton.displayName).toBe('SplitButton')
  })
})

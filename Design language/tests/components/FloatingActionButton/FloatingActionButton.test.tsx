// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createRef } from 'react'
import { afterEach, vi } from 'vitest'
import {
  FloatingActionButton,
  Icon,
  type FloatingActionButtonProps,
  type FloatingActionButtonSize,
} from '../../../src'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('FloatingActionButton', () => {
  it('renders a safe native momentary FAB with sourced defaults', () => {
    render(<FloatingActionButton aria-label="Create" icon={<Icon source="add" />} />)
    const button = screen.getByRole('button', { name: 'Create' })

    expect(button).toBeInstanceOf(HTMLButtonElement)
    expect(button.getAttribute('type')).toBe('button')
    expect(button.getAttribute('class')).toBe('m3e-fab')
    expect(button.getAttribute('data-m3e-size')).toBe('standard')
    expect(button.getAttribute('data-m3e-elevation')).toBe('default')
    expect(button.getAttribute('data-m3e-extended')).toBe('false')
    expect(button.getAttribute('data-m3e-toggle')).toBe('false')
    expect(button.hasAttribute('data-m3e-selected')).toBe(false)
    expect(button.hasAttribute('aria-pressed')).toBe(false)
  })

  it.each(['standard', 'medium', 'large'] satisfies readonly FloatingActionButtonSize[])(
    'maps the %s size to a stable attribute',
    (size) => {
      render(
        <FloatingActionButton
          aria-label={`${size} action`}
          icon={<Icon source="edit" />}
          size={size}
        />,
      )
      expect(screen.getByRole('button', { name: `${size} action` }).getAttribute('data-m3e-size')).toBe(size)
      cleanup()
    },
  )

  it('creates an extended layout from a label and supports visual collapse', () => {
    const { rerender } = render(
      <FloatingActionButton icon={<Icon source="edit" />} label="Compose" size="medium" />,
    )
    const button = screen.getByRole('button', { name: 'Compose' })

    expect(button.getAttribute('data-m3e-extended')).toBe('true')
    expect(button.getAttribute('data-m3e-expanded')).toBe('true')
    expect(button.querySelector('.m3e-fab__label')?.textContent).toBe('Compose')
    rerender(
      <FloatingActionButton
        icon={<Icon source="edit" />}
        label="Compose"
        size="medium"
        expanded={false}
      />,
    )
    expect(button.getAttribute('data-m3e-expanded')).toBe('false')
    expect(screen.getByRole('button', { name: 'Compose' })).toBe(button)
  })

  it('supports uncontrolled toggle selection and alternate artwork', async () => {
    const user = userEvent.setup()
    const onSelectedChange = vi.fn()
    render(
      <FloatingActionButton
        aria-label="Open actions"
        icon={<Icon source="add" />}
        toggle
        onSelectedChange={onSelectedChange}
        selectedIcon={<Icon source="close" />}
      />,
    )
    const button = screen.getByRole('button', { name: 'Open actions' })

    expect(button.getAttribute('aria-pressed')).toBe('false')
    expect(button.querySelectorAll('.m3e-fab__icon')).toHaveLength(2)
    await user.click(button)
    expect(button.getAttribute('aria-pressed')).toBe('true')
    expect(button.getAttribute('data-m3e-selected')).toBe('true')
    expect(onSelectedChange).toHaveBeenCalledWith(true)
    await user.click(button)
    expect(button.getAttribute('aria-pressed')).toBe('false')
    expect(onSelectedChange).toHaveBeenLastCalledWith(false)
    expect(onSelectedChange).toHaveBeenCalledTimes(2)
  })

  it('supports controlled toggle selection without mirroring props locally', async () => {
    const user = userEvent.setup()
    const onSelectedChange = vi.fn()
    const { rerender } = render(
      <FloatingActionButton
        aria-label="Open actions"
        icon={<Icon source="add" />}
        toggle
        selected={false}
        onSelectedChange={onSelectedChange}
      />,
    )
    const button = screen.getByRole('button', { name: 'Open actions' })

    await user.click(button)
    expect(onSelectedChange).toHaveBeenCalledWith(true)
    expect(button.getAttribute('aria-pressed')).toBe('false')
    rerender(
      <FloatingActionButton
        aria-label="Open actions"
        icon={<Icon source="add" />}
        toggle
        selected
        onSelectedChange={onSelectedChange}
      />,
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
      <FloatingActionButton
        aria-label="Open actions"
        icon={<Icon source="add" />}
        toggle
        onClick={onClick}
        onSelectedChange={onSelectedChange}
      />,
    )

    await user.click(screen.getByRole('button', { name: 'Open actions' }))
    expect(order).toEqual(['click'])
    expect(onSelectedChange).not.toHaveBeenCalled()
  })

  it('preserves native props, form behavior, consumer styling, and the ref', async () => {
    const user = userEvent.setup()
    const ref = createRef<HTMLButtonElement>()
    const onSubmit = vi.fn((event: React.FormEvent) => event.preventDefault())
    render(
      <form id="composer" onSubmit={onSubmit}>
        <FloatingActionButton
          ref={ref}
          aria-label="Publish"
          icon={<Icon source="publish" />}
          type="submit"
          name="intent"
          value="publish"
          form="composer"
          data-owner="consumer"
          aria-describedby="publish-help"
          className="publish-fab"
          style={{ marginInlineStart: 8 }}
        />
      </form>,
    )
    const button = screen.getByRole('button', { name: 'Publish' })

    await user.click(button)
    expect(onSubmit).toHaveBeenCalledTimes(1)
    expect(ref.current).toBe(button)
    expect(button.getAttribute('name')).toBe('intent')
    expect(button.getAttribute('value')).toBe('publish')
    expect(button.getAttribute('data-owner')).toBe('consumer')
    expect(button.getAttribute('class')).toBe('m3e-fab publish-fab')
    expect(button.getAttribute('style')).toContain('margin-inline-start: 8px')
  })

  it('uses native disabled behavior and never mutates toggle state', async () => {
    const user = userEvent.setup()
    const onClick = vi.fn()
    const onSelectedChange = vi.fn()
    render(
      <FloatingActionButton
        aria-label="Open actions"
        icon={<Icon source="add" />}
        toggle
        disabled
        defaultSelected
        onClick={onClick}
        onSelectedChange={onSelectedChange}
      />,
    )
    const button = screen.getByRole('button', { name: 'Open actions' })

    await user.click(button)
    expect(onClick).not.toHaveBeenCalled()
    expect(onSelectedChange).not.toHaveBeenCalled()
    expect(button.getAttribute('aria-pressed')).toBe('true')
    expect((button as HTMLButtonElement).disabled).toBe(true)
  })

  it('warns for a missing accessible name without changing markup', () => {
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    render(<FloatingActionButton icon={<Icon source="add" />} />)

    expect(warning).toHaveBeenCalledWith(
      'FloatingActionButton: provide a non-empty label, aria-label, or aria-labelledby so the button has an accessible name.',
    )
    expect(document.querySelector('button')?.getAttribute('type')).toBe('button')
  })

  it('warns untyped callers about invalid extended-toggle and controlled combinations', () => {
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    const invalidProps = {
      'aria-label': 'Open actions',
      icon: <Icon source="add" />,
      label: 'Actions',
      expanded: true,
      elevation: 'lowered',
      toggle: true,
      selected: true,
    } as unknown as FloatingActionButtonProps

    render(<FloatingActionButton {...invalidProps} />)
    expect(warning).toHaveBeenCalledWith(
      'FloatingActionButton: toggle FABs are icon-only; remove label and expanded.',
    )
    expect(warning).toHaveBeenCalledWith(
      'FloatingActionButton: a controlled selected value requires onSelectedChange.',
    )
    expect(warning).toHaveBeenCalledWith(
      'FloatingActionButton: toggle FAB elevation is fixed to Material Level 3; remove elevation.',
    )
  })

  it('exposes a stable component name for React tooling', () => {
    expect(FloatingActionButton.displayName).toBe('FloatingActionButton')
  })
})

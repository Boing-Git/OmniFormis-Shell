// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, vi } from 'vitest'
import { FloatingActionButton, Icon } from '../../../src'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('FloatingActionButton accessibility', () => {
  it('uses its extended label as the native accessible name while hiding icon semantics', () => {
    render(
      <FloatingActionButton
        icon={<Icon source="edit" decorative={false} label="Pencil" />}
        label="Compose"
        expanded={false}
        aria-describedby="compose-help"
      />,
    )
    const button = screen.getByRole('button', { name: 'Compose' })

    expect(screen.getAllByRole('button')).toHaveLength(1)
    expect(screen.queryByRole('img')).toBeNull()
    expect(button.getAttribute('role')).toBeNull()
    expect(button.getAttribute('aria-describedby')).toBe('compose-help')
    expect(button.hasAttribute('aria-pressed')).toBe(false)
  })

  it('uses aria-labelledby and hides both toggle icons from the tree', () => {
    render(
      <>
        <span id="actions-label">Open creation actions</span>
        <FloatingActionButton
          aria-labelledby="actions-label"
          icon={<Icon source="add" decorative={false} label="Add" />}
          toggle
          defaultSelected
          selectedIcon={<Icon source="close" decorative={false} label="Close" />}
        />
      </>,
    )

    expect(
      screen.getByRole('button', { name: 'Open creation actions' }).getAttribute('aria-pressed'),
    ).toBe('true')
    expect(screen.queryByRole('img')).toBeNull()
  })

  it('uses native Enter and Space activation exactly once per key', async () => {
    const user = userEvent.setup()
    const onClick = vi.fn()
    const onSelectedChange = vi.fn()
    render(
      <FloatingActionButton
        aria-label="Open actions"
        icon={<Icon source="add" />}
        toggle
        onClick={onClick}
        onSelectedChange={onSelectedChange}
      />,
    )
    const button = screen.getByRole('button', { name: 'Open actions' })

    await user.tab()
    expect(document.activeElement).toBe(button)
    await user.keyboard('{Enter}')
    expect(onClick).toHaveBeenCalledTimes(1)
    expect(onSelectedChange).toHaveBeenNthCalledWith(1, true)
    await user.keyboard(' ')
    expect(onClick).toHaveBeenCalledTimes(2)
    expect(onSelectedChange).toHaveBeenNthCalledWith(2, false)
  })

  it('removes a disabled FAB from sequential focus', async () => {
    const user = userEvent.setup()
    render(
      <>
        <FloatingActionButton aria-label="Unavailable" icon={<Icon source="block" />} disabled />
        <FloatingActionButton aria-label="Available" icon={<Icon source="add" />} />
      </>,
    )

    await user.tab()
    expect(document.activeElement).toBe(screen.getByRole('button', { name: 'Available' }))
  })

  it('preserves logical source order and toggle state in RTL', () => {
    render(
      <div dir="rtl">
        <FloatingActionButton
          aria-label="Open actions"
          icon={<Icon source="arrow_forward" mirrored />}
          size="large"
          toggle
          defaultSelected
          selectedIcon={<Icon source="close" />}
        />
      </div>,
    )
    const button = screen.getByRole('button', { name: 'Open actions' })

    expect(button.getAttribute('data-m3e-size')).toBe('large')
    expect(button.getAttribute('aria-pressed')).toBe('true')
    expect(button.querySelectorAll('[data-m3e-icon-state]')[0]?.getAttribute('data-m3e-icon-state')).toBe('default')
    expect(button.querySelectorAll('[data-m3e-icon-state]')[1]?.getAttribute('data-m3e-icon-state')).toBe('selected')
  })
})

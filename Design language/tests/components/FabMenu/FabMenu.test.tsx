// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createRef, type ComponentProps } from 'react'
import { afterEach, vi } from 'vitest'
import { FabMenu, FabMenuItem } from '../../../src/components/FabMenu'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

function renderMenu(props: Partial<ComponentProps<typeof FabMenu>> = {}) {
  return render(
    <FabMenu triggerLabel="Create" icon={<svg data-testid="icon-default" />} closeIcon={<svg data-testid="icon-close" />} {...props}>
      <FabMenuItem icon={<svg />} onClick={vi.fn()}>
        Edit
      </FabMenuItem>
      <FabMenuItem icon={<svg />} onClick={vi.fn()}>
        Share
      </FabMenuItem>
    </FabMenu>,
  )
}

describe('FabMenu', () => {
  it('renders a trigger button with the sourced collapsed defaults', () => {
    renderMenu()
    const trigger = screen.getByRole('button', { name: 'Create' })
    expect(trigger.getAttribute('aria-expanded')).toBe('false')
    expect(trigger.getAttribute('aria-haspopup')).toBe('true')
    expect(trigger.getAttribute('aria-controls')).not.toBeNull()
  })

  it('toggles expanded state on trigger click', async () => {
    const user = userEvent.setup()
    renderMenu()
    const trigger = screen.getByRole('button', { name: 'Create' })

    await user.click(trigger)
    expect(trigger.getAttribute('aria-expanded')).toBe('true')

    await user.click(trigger)
    expect(trigger.getAttribute('aria-expanded')).toBe('false')
  })

  it('supports a controlled expanded state', async () => {
    const user = userEvent.setup()
    const onExpandedChange = vi.fn()
    const { rerender } = renderMenu({ expanded: false, onExpandedChange })
    const trigger = screen.getByRole('button', { name: 'Create' })

    await user.click(trigger)
    expect(onExpandedChange).toHaveBeenCalledWith(true)
    expect(trigger.getAttribute('aria-expanded')).toBe('false')

    rerender(
      <FabMenu
        triggerLabel="Create"
        icon={<svg />}
        closeIcon={<svg />}
        expanded={true}
        onExpandedChange={onExpandedChange}
      >
        <FabMenuItem icon={<svg />}>Edit</FabMenuItem>
      </FabMenu>,
    )
    expect(screen.getByRole('button', { name: 'Create' }).getAttribute('aria-expanded')).toBe('true')
  })

  it('removes collapsed items from the accessibility tree and tab order via inert', () => {
    renderMenu()
    const itemsContainer = document.querySelector('.m3e-fab-menu__items') as HTMLElement
    // jsdom does not implement the `inert` IDL property (`.inert`), only
    // reflects the attribute -- assert via getAttribute, not the property.
    expect(itemsContainer.hasAttribute('inert')).toBe(true)
  })

  it('makes items focusable and interactive once expanded', async () => {
    const user = userEvent.setup()
    renderMenu()
    await user.click(screen.getByRole('button', { name: 'Create' }))

    const itemsContainer = document.querySelector('.m3e-fab-menu__items') as HTMLElement
    expect(itemsContainer.hasAttribute('inert')).toBe(false)
    expect(screen.getByRole('button', { name: 'Edit' })).not.toBeNull()
    expect(screen.getByRole('button', { name: 'Share' })).not.toBeNull()
  })

  it('fires each item\'s own onClick', async () => {
    const user = userEvent.setup()
    const onEdit = vi.fn()
    render(
      <FabMenu triggerLabel="Create" icon={<svg />} closeIcon={<svg />} defaultExpanded>
        <FabMenuItem icon={<svg />} onClick={onEdit}>
          Edit
        </FabMenuItem>
      </FabMenu>,
    )
    await user.click(screen.getByRole('button', { name: 'Edit' }))
    expect(onEdit).toHaveBeenCalledTimes(1)
  })

  it('moves focus from the trigger to the first item on ArrowDown while expanded', async () => {
    const user = userEvent.setup()
    renderMenu()
    const trigger = screen.getByRole('button', { name: 'Create' })
    await user.click(trigger)
    trigger.focus()

    await user.keyboard('{ArrowDown}')
    expect(document.activeElement).toBe(screen.getByRole('button', { name: 'Edit' }))
  })

  it('forwards ref, className, and style to the root', () => {
    const ref = createRef<HTMLDivElement>()
    renderMenu({ ref, className: 'consumer-class', 'data-owner': 'consumer' } as never)
    expect(ref.current?.className).toContain('m3e-fab-menu')
    expect(ref.current?.className).toContain('consumer-class')
    expect(ref.current?.getAttribute('data-owner')).toBe('consumer')
  })

  it('exposes stable component names for React tooling', () => {
    expect(FabMenu.displayName).toBe('FabMenu')
    expect(FabMenuItem.displayName).toBe('FabMenuItem')
  })
})

// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach } from 'vitest'
import { FabMenu, FabMenuItem } from '../../../src/components/FabMenu'

afterEach(cleanup)

describe('FabMenu accessibility', () => {
  it('requires a triggerLabel to name the trigger button', () => {
    render(
      <FabMenu triggerLabel="Create" icon={<svg />} closeIcon={<svg />}>
        <FabMenuItem icon={<svg />}>Edit</FabMenuItem>
      </FabMenu>,
    )
    expect(screen.getByRole('button', { name: 'Create' })).not.toBeNull()
  })

  it('exposes aria-expanded/aria-haspopup/aria-controls on the trigger', () => {
    render(
      <FabMenu triggerLabel="Create" icon={<svg />} closeIcon={<svg />}>
        <FabMenuItem icon={<svg />}>Edit</FabMenuItem>
      </FabMenu>,
    )
    const trigger = screen.getByRole('button', { name: 'Create' })
    expect(trigger.getAttribute('aria-expanded')).toBe('false')
    expect(trigger.getAttribute('aria-haspopup')).toBe('true')
    const controlsId = trigger.getAttribute('aria-controls')
    expect(controlsId).not.toBeNull()
    expect(document.getElementById(controlsId!)).not.toBeNull()
  })

  it('hides collapsed item icons from the accessibility tree', async () => {
    const user = userEvent.setup()
    render(
      <FabMenu triggerLabel="Create" icon={<svg />} closeIcon={<svg />}>
        <FabMenuItem icon={<svg data-testid="edit-icon" />}>Edit</FabMenuItem>
      </FabMenu>,
    )
    await user.click(screen.getByRole('button', { name: 'Create' }))
    const icon = screen.getByTestId('edit-icon')
    expect(icon.closest('[aria-hidden="true"]')).not.toBeNull()
  })

  it('keeps the menu readable inside an RTL scope', () => {
    render(
      <div dir="rtl">
        <FabMenu triggerLabel="Create" icon={<svg />} closeIcon={<svg />}>
          <FabMenuItem icon={<svg />}>Edit</FabMenuItem>
        </FabMenu>
      </div>,
    )
    expect(screen.getByRole('button', { name: 'Create' })).not.toBeNull()
  })

  it('disables an item via the native disabled attribute', () => {
    render(
      <FabMenu triggerLabel="Create" icon={<svg />} closeIcon={<svg />} defaultExpanded>
        <FabMenuItem icon={<svg />} disabled>
          Edit
        </FabMenuItem>
      </FabMenu>,
    )
    expect((screen.getByRole('button', { name: 'Edit' }) as HTMLButtonElement).disabled).toBe(true)
  })
})

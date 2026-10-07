// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach } from 'vitest'
import { SplitButton } from '../../../src/components/SplitButton'

afterEach(cleanup)

describe('SplitButton accessibility', () => {
  it('requires a trailingLabel to name the icon-only trailing button', () => {
    render(
      <SplitButton trailingIcon={<svg />} trailingLabel="Show more actions">
        Save
      </SplitButton>,
    )
    expect(screen.getByRole('button', { name: 'Show more actions' })).not.toBeNull()
  })

  it('names the leading button from its own visible label', () => {
    render(
      <SplitButton trailingIcon={<svg />} trailingLabel="More options">
        Publish
      </SplitButton>,
    )
    expect(screen.getByRole('button', { name: 'Publish' })).not.toBeNull()
  })

  it('exposes the trailing toggle state via aria-pressed, not a custom attribute alone', async () => {
    const user = userEvent.setup()
    render(
      <SplitButton trailingIcon={<svg />} trailingLabel="More options">
        Save
      </SplitButton>,
    )
    const trailing = screen.getByRole('button', { name: 'More options' })
    expect(trailing.getAttribute('aria-pressed')).toBe('false')
    await user.click(trailing)
    expect(trailing.getAttribute('aria-pressed')).toBe('true')
  })

  it('keeps both buttons independently focusable via native tab order', async () => {
    const user = userEvent.setup()
    render(
      <SplitButton trailingIcon={<svg />} trailingLabel="More options">
        Save
      </SplitButton>,
    )
    await user.tab()
    expect(document.activeElement).toBe(screen.getByRole('button', { name: 'Save' }))
    await user.tab()
    expect(document.activeElement).toBe(screen.getByRole('button', { name: 'More options' }))
  })

  it('removes both buttons from tab order and marks them disabled together', () => {
    render(
      <SplitButton disabled trailingIcon={<svg />} trailingLabel="More options">
        Save
      </SplitButton>,
    )
    expect(screen.getByRole('button', { name: 'Save' }).hasAttribute('disabled')).toBe(true)
    expect(screen.getByRole('button', { name: 'More options' }).hasAttribute('disabled')).toBe(true)
  })

  it('keeps the group readable inside an RTL scope', () => {
    render(
      <div dir="rtl">
        <SplitButton trailingIcon={<svg />} trailingLabel="More options">
          Save
        </SplitButton>
      </div>,
    )
    expect(screen.getByRole('button', { name: 'Save' })).not.toBeNull()
    expect(screen.getByRole('button', { name: 'More options' })).not.toBeNull()
  })
})

// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach } from 'vitest'
import { Surface } from '../../../src/components/Surface'

afterEach(cleanup)

describe('Surface accessibility', () => {
  it('retains native landmark semantics and its accessible name', () => {
    render(
      <Surface as="nav" aria-label="Lesson sections">
        Navigation
      </Surface>,
    )

    const navigation = screen.getByRole('navigation', { name: 'Lesson sections' })
    expect(navigation.tagName).toBe('NAV')
  })

  it('does not add a keyboard stop or interaction role to a passive surface', async () => {
    const user = userEvent.setup()
    render(
      <>
        <Surface data-testid="surface">Passive content</Surface>
        <button type="button">Next</button>
      </>,
    )

    await user.tab()
    expect(document.activeElement).toBe(screen.getByRole('button', { name: 'Next' }))
    const surface = screen.getByTestId('surface')
    expect(surface.hasAttribute('role')).toBe(false)
    expect(surface.hasAttribute('aria-pressed')).toBe(false)
    expect(surface.hasAttribute('aria-selected')).toBe(false)
  })

  it('preserves consumer-authored region naming relationships', () => {
    render(
      <>
        <h2 id="billing-heading">Billing</h2>
        <Surface as="section" aria-labelledby="billing-heading">
          Billing details
        </Surface>
      </>,
    )

    expect(screen.getByRole('region', { name: 'Billing' })).toHaveProperty(
      'textContent',
      'Billing details',
    )
  })
})

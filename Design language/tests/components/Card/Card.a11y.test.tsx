// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, vi } from 'vitest'
import { Card } from '../../../src'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('Card accessibility', () => {
  it('keeps passive cards out of sequential keyboard focus', async () => {
    const user = userEvent.setup()
    render(
      <>
        <Card>Passive summary</Card>
        <button type="button">Next</button>
      </>,
    )

    await user.tab()
    expect(document.activeElement).toBe(screen.getByRole('button', { name: 'Next' }))
    const card = screen.getByText('Passive summary').closest('article')
    expect(card?.hasAttribute('role')).toBe(false)
    expect(card?.hasAttribute('aria-pressed')).toBe(false)
  })

  it('retains native passive section naming relationships', () => {
    render(
      <>
        <h2 id="billing-title">Billing</h2>
        <Card as="section" aria-labelledby="billing-title">
          Current plan
        </Card>
      </>,
    )

    expect(screen.getByRole('region', { name: 'Billing' })).toHaveProperty(
      'textContent',
      'Current plan',
    )
  })

  it('uses native Enter and Space activation exactly once per key', async () => {
    const user = userEvent.setup()
    const onClick = vi.fn()
    render(<Card interactive onClick={onClick}>Open course</Card>)
    const button = screen.getByRole('button', { name: 'Open course' })

    await user.tab()
    expect(document.activeElement).toBe(button)
    await user.keyboard('{Enter}')
    expect(onClick).toHaveBeenCalledTimes(1)
    await user.keyboard(' ')
    expect(onClick).toHaveBeenCalledTimes(2)
  })

  it('removes disabled interactive cards from sequential focus', async () => {
    const user = userEvent.setup()
    render(
      <>
        <Card interactive disabled>Unavailable lesson</Card>
        <Card interactive>Available lesson</Card>
      </>,
    )

    await user.tab()
    expect(document.activeElement).toBe(
      screen.getByRole('button', { name: 'Available lesson' }),
    )
  })

  it('preserves source order and names inside an RTL scope', () => {
    render(
      <div dir="rtl">
        <Card interactive aria-describedby="lesson-detail">
          <span>Open lesson</span>
          {' '}
          <small id="lesson-detail">Japanese</small>
        </Card>
      </div>,
    )

    const button = screen.getByRole('button', { name: 'Open lesson Japanese' })
    expect(button.getAttribute('aria-describedby')).toBe('lesson-detail')
    expect(button.textContent).toBe('Open lesson Japanese')
  })
})

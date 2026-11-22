// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { CircularProgress } from '../../../src/components/CircularProgress'

afterEach(cleanup)

describe('CircularProgress accessibility', () => {
  it('requires an accessible name via aria-label', () => {
    render(<CircularProgress aria-label="Progress" value={0.5} />)
    expect(screen.getByRole('progressbar', { name: 'Progress' })).not.toBeNull()
  })

  it('supports aria-labelledby as an alternative accessible name', () => {
    render(
      <>
        <h2 id="progress-heading">Progress</h2>
        <CircularProgress aria-labelledby="progress-heading" value={0.5} />
      </>,
    )
    expect(screen.getByRole('progressbar', { name: 'Progress' })).not.toBeNull()
  })

  it('hides the svg geometry from the accessibility tree', () => {
    render(<CircularProgress aria-label="Progress" value={0.5} />)
    const svg = document.querySelector('.m3e-circular-progress__svg')
    expect(svg?.getAttribute('aria-hidden')).toBe('true')
  })

  it('keeps the indicator readable inside an RTL scope', () => {
    render(
      <div dir="rtl">
        <CircularProgress aria-label="Progress" value={0.5} />
      </div>,
    )
    expect(screen.getByRole('progressbar', { name: 'Progress' })).not.toBeNull()
  })

  it('indeterminate mode omits aria-valuenow, signaling a busy/indeterminate state to assistive technology', () => {
    render(<CircularProgress aria-label="Loading" />)
    const bar = screen.getByRole('progressbar', { name: 'Loading' })
    expect(bar.hasAttribute('aria-valuenow')).toBe(false)
  })
})

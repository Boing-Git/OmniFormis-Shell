// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { LoadingIndicator } from '../../../src/components/LoadingIndicator'

afterEach(cleanup)

describe('LoadingIndicator accessibility', () => {
  it('requires an accessible name via aria-label', () => {
    render(<LoadingIndicator aria-label="Loading" value={0.5} />)
    expect(screen.getByRole('progressbar', { name: 'Loading' })).not.toBeNull()
  })

  it('supports aria-labelledby as an alternative accessible name', () => {
    render(
      <>
        <h2 id="loading-heading">Loading</h2>
        <LoadingIndicator aria-labelledby="loading-heading" value={0.5} />
      </>,
    )
    expect(screen.getByRole('progressbar', { name: 'Loading' })).not.toBeNull()
  })

  it('hides the svg geometry from the accessibility tree', () => {
    render(<LoadingIndicator aria-label="Loading" value={0.5} />)
    const svg = document.querySelector('.m3e-loading-indicator__svg')
    expect(svg?.getAttribute('aria-hidden')).toBe('true')
  })

  it('keeps the indicator readable inside an RTL scope', () => {
    render(
      <div dir="rtl">
        <LoadingIndicator aria-label="Loading" value={0.5} />
      </div>,
    )
    expect(screen.getByRole('progressbar', { name: 'Loading' })).not.toBeNull()
  })

  it('indeterminate mode omits aria-valuenow, signaling a busy/indeterminate state to assistive technology', () => {
    render(<LoadingIndicator aria-label="Loading" />)
    const bar = screen.getByRole('progressbar', { name: 'Loading' })
    expect(bar.hasAttribute('aria-valuenow')).toBe(false)
  })

  it('is not focusable and exposes no keyboard model, matching the source', () => {
    render(<LoadingIndicator aria-label="Loading" />)
    const bar = screen.getByRole('progressbar', { name: 'Loading' })
    expect(bar.hasAttribute('tabindex')).toBe(false)
  })
})

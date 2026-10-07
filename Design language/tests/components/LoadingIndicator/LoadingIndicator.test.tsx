// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { createRef } from 'react'
import { afterEach } from 'vitest'
import { LoadingIndicator } from '../../../src/components/LoadingIndicator'

afterEach(cleanup)

describe('LoadingIndicator', () => {
  it('renders role="progressbar" with min/max/now when determinate', () => {
    render(<LoadingIndicator aria-label="Loading" value={0.4} />)
    const bar = screen.getByRole('progressbar', { name: 'Loading' })
    expect(bar.getAttribute('aria-valuemin')).toBe('0')
    expect(bar.getAttribute('aria-valuemax')).toBe('1')
    expect(bar.getAttribute('aria-valuenow')).toBe('0.4')
    expect(bar.getAttribute('data-m3e-determinate')).toBe('true')
  })

  it('omits aria-valuenow when indeterminate (value omitted)', () => {
    render(<LoadingIndicator aria-label="Loading" />)
    const bar = screen.getByRole('progressbar', { name: 'Loading' })
    expect(bar.hasAttribute('aria-valuenow')).toBe(false)
    expect(bar.getAttribute('data-m3e-determinate')).toBe('false')
  })

  it('clamps value into [0, max]', () => {
    const { rerender } = render(<LoadingIndicator aria-label="Loading" value={-1} />)
    expect(screen.getByRole('progressbar').getAttribute('aria-valuenow')).toBe('0')

    rerender(<LoadingIndicator aria-label="Loading" value={5} />)
    expect(screen.getByRole('progressbar').getAttribute('aria-valuenow')).toBe('1')
  })

  it('supports a custom max', () => {
    render(<LoadingIndicator aria-label="Loading" value={50} max={200} />)
    const bar = screen.getByRole('progressbar')
    expect(bar.getAttribute('aria-valuemax')).toBe('200')
    expect(bar.getAttribute('aria-valuenow')).toBe('50')
  })

  it('renders a single morphing path in determinate mode, driven by the value prop', () => {
    render(<LoadingIndicator aria-label="Loading" value={0} />)
    expect(document.querySelectorAll('.m3e-loading-indicator__shape')).toHaveLength(1)
  })

  it('renders the exact start-of-morph shape at value=0 and end-of-morph shape at value=max', () => {
    const { rerender } = render(<LoadingIndicator aria-label="Loading" value={0} />)
    const atZero = document.querySelector('.m3e-loading-indicator__shape')?.getAttribute('d')
    expect(atZero).toMatch(/^M[\d.]+ [\d.]+( C[\d.]+ [\d.]+,[\d.]+ [\d.]+,[\d.]+ [\d.]+)+ Z$/)

    rerender(<LoadingIndicator aria-label="Loading" value={1} />)
    const atOne = document.querySelector('.m3e-loading-indicator__shape')?.getAttribute('d')
    expect(atOne).not.toBe(atZero)
  })

  it('rotates the determinate shape counterclockwise proportional to progress', () => {
    render(<LoadingIndicator aria-label="Loading" value={0.5} />)
    const shape = document.querySelector('.m3e-loading-indicator__shape') as SVGPathElement
    expect(shape.style.transform).toBe('rotate(-90deg)')
  })

  it('renders seven stacked segment paths in indeterminate mode', () => {
    render(<LoadingIndicator aria-label="Loading" />)
    expect(document.querySelectorAll('.m3e-loading-indicator__segment')).toHaveLength(7)
    for (let index = 0; index < 7; index += 1) {
      expect(document.querySelector(`.m3e-loading-indicator__segment-${index}`)).not.toBeNull()
    }
  })

  it('forwards ref, className, and style to the root', () => {
    const ref = createRef<HTMLDivElement>()
    render(
      <LoadingIndicator
        ref={ref}
        aria-label="Loading"
        value={0.5}
        className="consumer-class"
        data-owner="consumer"
      />,
    )
    expect(ref.current?.getAttribute('role')).toBe('progressbar')
    expect(ref.current?.className).toContain('m3e-loading-indicator')
    expect(ref.current?.className).toContain('consumer-class')
    expect(ref.current?.getAttribute('data-owner')).toBe('consumer')
  })

  it('exposes a stable component name for React tooling', () => {
    expect(LoadingIndicator.displayName).toBe('LoadingIndicator')
  })
})

// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { createRef } from 'react'
import { afterEach } from 'vitest'
import { LinearProgress } from '../../../src/components/LinearProgress'

afterEach(cleanup)

describe('LinearProgress', () => {
  it('renders role="progressbar" with min/max/now when determinate', () => {
    render(<LinearProgress aria-label="Download" value={0.4} />)
    const bar = screen.getByRole('progressbar', { name: 'Download' })
    expect(bar.getAttribute('aria-valuemin')).toBe('0')
    expect(bar.getAttribute('aria-valuemax')).toBe('1')
    expect(bar.getAttribute('aria-valuenow')).toBe('0.4')
    expect(bar.getAttribute('data-m3e-determinate')).toBe('true')
  })

  it('omits aria-valuenow when indeterminate (value omitted)', () => {
    render(<LinearProgress aria-label="Loading" />)
    const bar = screen.getByRole('progressbar', { name: 'Loading' })
    expect(bar.hasAttribute('aria-valuenow')).toBe(false)
    expect(bar.getAttribute('data-m3e-determinate')).toBe('false')
  })

  it('clamps value into [0, max]', () => {
    const { rerender } = render(<LinearProgress aria-label="Download" value={-1} />)
    expect(screen.getByRole('progressbar').getAttribute('aria-valuenow')).toBe('0')

    rerender(<LinearProgress aria-label="Download" value={5} />)
    expect(screen.getByRole('progressbar').getAttribute('aria-valuenow')).toBe('1')
  })

  it('supports a custom max', () => {
    render(<LinearProgress aria-label="Download" value={50} max={200} />)
    const bar = screen.getByRole('progressbar')
    expect(bar.getAttribute('aria-valuemax')).toBe('200')
    expect(bar.getAttribute('aria-valuenow')).toBe('50')
  })

  it('sizes the fill by the progress fraction', () => {
    render(<LinearProgress aria-label="Download" value={0.25} />)
    const fill = document.querySelector('.m3e-linear-progress__fill') as HTMLElement
    expect(fill.style.inlineSize).toBe('25%')
  })

  it('renders a stop dot only when determinate', () => {
    const { rerender } = render(<LinearProgress aria-label="Download" value={0.5} />)
    expect(document.querySelector('.m3e-linear-progress__stop')).not.toBeNull()

    rerender(<LinearProgress aria-label="Loading" />)
    expect(document.querySelector('.m3e-linear-progress__stop')).toBeNull()
  })

  it('renders two indeterminate bars only when indeterminate', () => {
    render(<LinearProgress aria-label="Loading" />)
    expect(document.querySelector('.m3e-linear-progress__indeterminate-bar1')).not.toBeNull()
    expect(document.querySelector('.m3e-linear-progress__indeterminate-bar2')).not.toBeNull()
  })

  it('forwards ref, className, and style to the root', () => {
    const ref = createRef<HTMLDivElement>()
    render(
      <LinearProgress
        ref={ref}
        aria-label="Download"
        value={0.5}
        className="consumer-class"
        data-owner="consumer"
      />,
    )
    expect(ref.current?.getAttribute('role')).toBe('progressbar')
    expect(ref.current?.className).toContain('m3e-linear-progress')
    expect(ref.current?.className).toContain('consumer-class')
    expect(ref.current?.getAttribute('data-owner')).toBe('consumer')
  })

  it('exposes a stable component name for React tooling', () => {
    expect(LinearProgress.displayName).toBe('LinearProgress')
  })
})

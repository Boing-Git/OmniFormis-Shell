// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { createRef } from 'react'
import { afterEach } from 'vitest'
import { CircularProgress } from '../../../src/components/CircularProgress'

afterEach(cleanup)

describe('CircularProgress', () => {
  it('renders role="progressbar" with min/max/now when determinate', () => {
    render(<CircularProgress aria-label="Progress" value={0.4} />)
    const bar = screen.getByRole('progressbar', { name: 'Progress' })
    expect(bar.getAttribute('aria-valuemin')).toBe('0')
    expect(bar.getAttribute('aria-valuemax')).toBe('1')
    expect(bar.getAttribute('aria-valuenow')).toBe('0.4')
    expect(bar.getAttribute('data-m3e-determinate')).toBe('true')
  })

  it('omits aria-valuenow when indeterminate (value omitted)', () => {
    render(<CircularProgress aria-label="Loading" />)
    const bar = screen.getByRole('progressbar', { name: 'Loading' })
    expect(bar.hasAttribute('aria-valuenow')).toBe(false)
    expect(bar.getAttribute('data-m3e-determinate')).toBe('false')
  })

  it('clamps value into [0, max]', () => {
    const { rerender } = render(<CircularProgress aria-label="Progress" value={-1} />)
    expect(screen.getByRole('progressbar').getAttribute('aria-valuenow')).toBe('0')

    rerender(<CircularProgress aria-label="Progress" value={5} />)
    expect(screen.getByRole('progressbar').getAttribute('aria-valuenow')).toBe('1')
  })

  it('supports a custom max', () => {
    render(<CircularProgress aria-label="Progress" value={50} max={200} />)
    const bar = screen.getByRole('progressbar')
    expect(bar.getAttribute('aria-valuemax')).toBe('200')
    expect(bar.getAttribute('aria-valuenow')).toBe('50')
  })

  it('renders a fixed 40x40 svg regardless of progress value', () => {
    render(<CircularProgress aria-label="Progress" value={0.75} />)
    const svg = document.querySelector('.m3e-circular-progress__svg')
    expect(svg?.getAttribute('width')).toBe('40')
    expect(svg?.getAttribute('height')).toBe('40')
  })

  it('sizes the indicator sweep by the progress fraction via stroke-dasharray', () => {
    render(<CircularProgress aria-label="Progress" value={0.25} />)
    const indicator = document.querySelector(
      '.m3e-circular-progress__indicator',
    ) as SVGCircleElement
    expect(indicator.style.strokeDasharray).toBe('25 75')
    expect(indicator.getAttribute('transform')).toBe('rotate(-90 20 20)')
  })

  it('uses the source circular phase for indeterminate motion', () => {
    render(<CircularProgress aria-label="Loading" />)
    const indicator = document.querySelector(
      '.m3e-circular-progress__indicator',
    ) as SVGCircleElement
    expect(indicator.hasAttribute('transform')).toBe(false)
  })

  it('does not paint zero-length round-cap artifacts at either determinate endpoint', () => {
    const { rerender } = render(<CircularProgress aria-label="Progress" value={0} />)
    expect(document.querySelector('.m3e-circular-progress__indicator')).toBeNull()
    expect(document.querySelector('.m3e-circular-progress__track')).not.toBeNull()

    rerender(<CircularProgress aria-label="Progress" value={1} />)
    expect(document.querySelector('.m3e-circular-progress__indicator')).not.toBeNull()
    expect(document.querySelector('.m3e-circular-progress__track')).toBeNull()
  })

  it('includes the round caps when calculating the visible active-to-track gap', () => {
    render(<CircularProgress aria-label="Progress" value={0.25} />)
    const track = document.querySelector('.m3e-circular-progress__track') as SVGCircleElement
    const [visibleTrack] = track.style.strokeDasharray.split(' ').map(Number)
    const expectedGapPct = ((4 + 4) / (Math.PI * 40)) * 100

    expect(visibleTrack).toBeCloseTo(100 - 25 - expectedGapPct * 2, 5)
    expect(Number(track.style.strokeDashoffset)).toBeCloseTo(-(25 + expectedGapPct), 5)
  })

  it('renders no track element at all when indeterminate (circularIndeterminateTrackColor is Transparent in the source)', () => {
    const { rerender } = render(<CircularProgress aria-label="Progress" value={0.5} />)
    expect(document.querySelector('.m3e-circular-progress__track')).not.toBeNull()

    rerender(<CircularProgress aria-label="Loading" />)
    expect(document.querySelector('.m3e-circular-progress__track')).toBeNull()
  })

  it('forwards ref, className, and style to the root', () => {
    const ref = createRef<HTMLDivElement>()
    render(
      <CircularProgress
        ref={ref}
        aria-label="Progress"
        value={0.5}
        className="consumer-class"
        data-owner="consumer"
      />,
    )
    expect(ref.current?.getAttribute('role')).toBe('progressbar')
    expect(ref.current?.className).toContain('m3e-circular-progress')
    expect(ref.current?.className).toContain('consumer-class')
    expect(ref.current?.getAttribute('data-owner')).toBe('consumer')
  })

  it('exposes a stable component name for React tooling', () => {
    expect(CircularProgress.displayName).toBe('CircularProgress')
  })
})

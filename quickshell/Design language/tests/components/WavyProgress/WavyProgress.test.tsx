// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { createRef } from 'react'
import { afterEach } from 'vitest'
import { WavyProgress } from '../../../src/components/WavyProgress'

afterEach(cleanup)

describe('WavyProgress', () => {
  it('defaults to shape="linear"', () => {
    render(<WavyProgress aria-label="Upload" value={0.4} />)
    expect(screen.getByRole('progressbar').getAttribute('data-m3e-shape')).toBe('linear')
  })

  it('renders role="progressbar" with min/max/now when determinate, for both shapes', () => {
    const { rerender } = render(<WavyProgress aria-label="Upload" value={0.4} />)
    let bar = screen.getByRole('progressbar', { name: 'Upload' })
    expect(bar.getAttribute('aria-valuemin')).toBe('0')
    expect(bar.getAttribute('aria-valuemax')).toBe('1')
    expect(bar.getAttribute('aria-valuenow')).toBe('0.4')

    rerender(<WavyProgress aria-label="Upload" shape="circular" value={0.4} />)
    bar = screen.getByRole('progressbar', { name: 'Upload' })
    expect(bar.getAttribute('data-m3e-shape')).toBe('circular')
    expect(bar.getAttribute('aria-valuenow')).toBe('0.4')
  })

  it('omits aria-valuenow when indeterminate, for both shapes', () => {
    const { rerender } = render(<WavyProgress aria-label="Syncing" />)
    expect(screen.getByRole('progressbar').hasAttribute('aria-valuenow')).toBe(false)

    rerender(<WavyProgress aria-label="Syncing" shape="circular" />)
    expect(screen.getByRole('progressbar').hasAttribute('aria-valuenow')).toBe(false)
  })

  it('clamps value into [0, max]', () => {
    const { rerender } = render(<WavyProgress aria-label="Upload" value={-1} />)
    expect(screen.getByRole('progressbar').getAttribute('aria-valuenow')).toBe('0')

    rerender(<WavyProgress aria-label="Upload" value={5} />)
    expect(screen.getByRole('progressbar').getAttribute('aria-valuenow')).toBe('1')
  })

  it('linear shape: sizes the wave-clip by the progress fraction', () => {
    render(<WavyProgress aria-label="Upload" value={0.3} />)
    const clip = document.querySelector('.m3e-wavy-progress__wave-clip') as HTMLElement
    expect(clip.style.inlineSize).toBe('30%')
  })

  it('linear shape: renders a stop dot only when determinate', () => {
    const { rerender } = render(<WavyProgress aria-label="Upload" value={0.5} />)
    expect(document.querySelector('.m3e-wavy-progress__stop')).not.toBeNull()

    rerender(<WavyProgress aria-label="Syncing" />)
    expect(document.querySelector('.m3e-wavy-progress__stop')).toBeNull()
  })

  it('linear shape: renders two indeterminate wave bars when indeterminate', () => {
    render(<WavyProgress aria-label="Syncing" />)
    expect(document.querySelector('.m3e-wavy-progress__indeterminate-bar1')).not.toBeNull()
    expect(document.querySelector('.m3e-wavy-progress__indeterminate-bar2')).not.toBeNull()
  })

  it('circular shape: renders a fixed 48x48 svg', () => {
    render(<WavyProgress aria-label="Progress" shape="circular" value={0.5} />)
    const svg = document.querySelector('.m3e-wavy-progress__circular-svg')
    expect(svg?.getAttribute('width')).toBe('48')
    expect(svg?.getAttribute('height')).toBe('48')
  })

  it('circular shape: sizes the sweep by the progress fraction via stroke-dasharray', () => {
    render(<WavyProgress aria-label="Progress" shape="circular" value={0.25} />)
    const sweep = document.querySelector('.m3e-wavy-progress__sweep') as SVGElement
    expect((sweep.style as CSSStyleDeclaration).strokeDasharray).toBe('25 75')
  })

  it('circular shape: does not paint zero-length round-cap artifacts at either endpoint', () => {
    const { rerender } = render(<WavyProgress aria-label="Progress" shape="circular" value={0} />)
    expect(document.querySelector('.m3e-wavy-progress__indicator')).toBeNull()
    expect(document.querySelector('.m3e-wavy-progress__track')).not.toBeNull()

    rerender(<WavyProgress aria-label="Progress" shape="circular" value={1} />)
    expect(document.querySelector('.m3e-wavy-progress__indicator')).not.toBeNull()
    expect(document.querySelector('.m3e-wavy-progress__track')).toBeNull()
  })

  it('circular shape: morphs one matched cubic path between the flat circle and rounded wave', () => {
    const { rerender } = render(
      <WavyProgress aria-label="Progress" shape="circular" value={0.05} />,
    )
    const flatPath = document.querySelector('.m3e-wavy-progress__wave')?.getAttribute('d') ?? ''
    expect(screen.getByRole('progressbar').getAttribute('data-m3e-amplitude')).toBe('flat')

    rerender(<WavyProgress aria-label="Progress" shape="circular" value={0.5} />)
    const wavePath = document.querySelector('.m3e-wavy-progress__wave')?.getAttribute('d') ?? ''
    expect(screen.getByRole('progressbar').getAttribute('data-m3e-amplitude')).toBe('wave')
    expect(wavePath).not.toBe(flatPath)
    expect(wavePath.match(/\bC\b/g)?.length).toBe(flatPath.match(/\bC\b/g)?.length)
    expect(wavePath.match(/\bC\b/g)?.length).toBe(27)
  })

  it('circular shape: keeps the sourced track visible when indeterminate', () => {
    const { rerender } = render(<WavyProgress aria-label="Progress" shape="circular" value={0.5} />)
    expect(document.querySelector('.m3e-wavy-progress__track')).not.toBeNull()

    rerender(<WavyProgress aria-label="Syncing" shape="circular" />)
    const track = document.querySelector('.m3e-wavy-progress__track') as SVGPathElement
    expect(track).not.toBeNull()
    expect(track.classList.contains('m3e-wavy-progress__track-sweep')).toBe(true)
    expect(track.hasAttribute('style')).toBe(false)
  })

  it('ramps amplitude toward zero near the start and end of determinate progress', () => {
    const { rerender } = render(<WavyProgress aria-label="Upload" value={0.02} />)
    let path = document.querySelector('.m3e-wavy-progress__linear-wave-svg path')
    const flatPath = path?.getAttribute('d')
    expect(screen.getByRole('progressbar').getAttribute('data-m3e-amplitude')).toBe('flat')
    expect(flatPath).toContain('Q')

    rerender(<WavyProgress aria-label="Upload" value={0.5} />)
    path = document.querySelector('.m3e-wavy-progress__linear-wave-svg path')
    const wavePath = path?.getAttribute('d')
    expect(screen.getByRole('progressbar').getAttribute('data-m3e-amplitude')).toBe('wave')
    expect(wavePath).not.toBe(flatPath)
    expect(wavePath?.match(/\bQ\b/g)?.length).toBe(flatPath?.match(/\bQ\b/g)?.length)

    rerender(<WavyProgress aria-label="Upload" value={0.99} />)
    path = document.querySelector('.m3e-wavy-progress__linear-wave-svg path')
    expect(screen.getByRole('progressbar').getAttribute('data-m3e-amplitude')).toBe('flat')
    expect(path?.getAttribute('d')).toBe(flatPath)
  })

  it('forwards ref, className, and style to the root', () => {
    const ref = createRef<HTMLDivElement>()
    render(
      <WavyProgress
        ref={ref}
        aria-label="Upload"
        value={0.5}
        className="consumer-class"
        data-owner="consumer"
      />,
    )
    expect(ref.current?.getAttribute('role')).toBe('progressbar')
    expect(ref.current?.className).toContain('m3e-wavy-progress')
    expect(ref.current?.className).toContain('consumer-class')
    expect(ref.current?.getAttribute('data-owner')).toBe('consumer')
  })

  it('exposes a stable component name for React tooling', () => {
    expect(WavyProgress.displayName).toBe('WavyProgress')
  })
})

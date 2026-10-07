// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { WavyProgress } from '../../../src/components/WavyProgress'

afterEach(cleanup)

describe('WavyProgress accessibility', () => {
  it('requires an accessible name via aria-label, for both shapes', () => {
    const { rerender } = render(<WavyProgress aria-label="Upload" value={0.5} />)
    expect(screen.getByRole('progressbar', { name: 'Upload' })).not.toBeNull()

    rerender(<WavyProgress aria-label="Progress" shape="circular" value={0.5} />)
    expect(screen.getByRole('progressbar', { name: 'Progress' })).not.toBeNull()
  })

  it('supports aria-labelledby as an alternative accessible name', () => {
    render(
      <>
        <h2 id="upload-heading">Upload</h2>
        <WavyProgress aria-labelledby="upload-heading" value={0.5} />
      </>,
    )
    expect(screen.getByRole('progressbar', { name: 'Upload' })).not.toBeNull()
  })

  it('hides the wave svg geometry from the accessibility tree', () => {
    const { rerender } = render(<WavyProgress aria-label="Upload" value={0.5} />)
    expect(document.querySelector('.m3e-wavy-progress__linear-wave-svg')?.getAttribute('aria-hidden')).toBe(
      'true',
    )

    rerender(<WavyProgress aria-label="Progress" shape="circular" value={0.5} />)
    expect(document.querySelector('.m3e-wavy-progress__circular-svg')?.getAttribute('aria-hidden')).toBe(
      'true',
    )
  })

  it('keeps the indicator readable inside an RTL scope, for both shapes', () => {
    render(
      <div dir="rtl">
        <WavyProgress aria-label="Upload" value={0.5} />
        <WavyProgress aria-label="Progress" shape="circular" value={0.5} />
      </div>,
    )
    expect(screen.getByRole('progressbar', { name: 'Upload' })).not.toBeNull()
    expect(screen.getByRole('progressbar', { name: 'Progress' })).not.toBeNull()
  })

  it('indeterminate mode omits aria-valuenow, signaling a busy/indeterminate state to assistive technology', () => {
    render(<WavyProgress aria-label="Syncing" />)
    const bar = screen.getByRole('progressbar', { name: 'Syncing' })
    expect(bar.hasAttribute('aria-valuenow')).toBe(false)
  })
})

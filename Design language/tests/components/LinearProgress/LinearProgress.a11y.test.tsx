// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { LinearProgress } from '../../../src/components/LinearProgress'

afterEach(cleanup)

describe('LinearProgress accessibility', () => {
  it('requires an accessible name via aria-label', () => {
    render(<LinearProgress aria-label="Download" value={0.5} />)
    expect(screen.getByRole('progressbar', { name: 'Download' })).not.toBeNull()
  })

  it('supports aria-labelledby as an alternative accessible name', () => {
    render(
      <>
        <h2 id="download-heading">Download</h2>
        <LinearProgress aria-labelledby="download-heading" value={0.5} />
      </>,
    )
    expect(screen.getByRole('progressbar', { name: 'Download' })).not.toBeNull()
  })

  it('hides the track/fill/stop decoration from the accessibility tree via role=progressbar semantics alone', () => {
    render(<LinearProgress aria-label="Download" value={0.5} />)
    const bar = screen.getByRole('progressbar')
    // The decorative children carry no independent accessible content —
    // the progressbar's own name/value pair is the sole accessible surface.
    expect(bar.textContent).toBe('')
  })

  it('keeps the bar readable inside an RTL scope', () => {
    render(
      <div dir="rtl">
        <LinearProgress aria-label="Download" value={0.5} />
      </div>,
    )
    expect(screen.getByRole('progressbar', { name: 'Download' })).not.toBeNull()
  })

  it('indeterminate mode omits aria-valuenow, signaling a busy/indeterminate state to assistive technology', () => {
    render(<LinearProgress aria-label="Loading" />)
    const bar = screen.getByRole('progressbar', { name: 'Loading' })
    expect(bar.hasAttribute('aria-valuenow')).toBe(false)
    expect(bar.getAttribute('aria-valuemin')).toBe('0')
    expect(bar.getAttribute('aria-valuemax')).toBe('1')
  })
})

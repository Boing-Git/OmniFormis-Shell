// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, vi } from 'vitest'
import {
  Icon,
  type IconSourceProps,
} from '../../../src/components/Icon'

function DirectionSource(props: IconSourceProps) {
  return (
    <svg {...props} viewBox="0 0 24 24">
      <path d="m8 4 8 8-8 8Z" />
    </svg>
  )
}

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('Icon accessibility', () => {
  it('keeps a decorative source out of the accessibility tree', () => {
    render(<Icon source={DirectionSource} data-testid="icon" />)

    expect(screen.queryByRole('img')).toBeNull()
    expect(screen.getByTestId('icon').getAttribute('aria-hidden')).toBe('true')
    expect(document.querySelector('svg')?.getAttribute('aria-hidden')).toBe('true')
  })

  it('exposes exactly one named image for a meaningful icon', () => {
    render(<Icon source={DirectionSource} decorative={false} label="Continue" />)

    expect(screen.getAllByRole('img')).toHaveLength(1)
    expect(screen.getByRole('img', { name: 'Continue' }).tagName).toBe('SPAN')
    expect(document.querySelector('svg')?.getAttribute('aria-hidden')).toBe('true')
  })

  it('fails closed when an untyped consumer provides an empty meaningful label', () => {
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    render(<Icon source="warning" decorative={false} label="" data-testid="icon" />)

    expect(screen.queryByRole('img')).toBeNull()
    expect(screen.getByTestId('icon').getAttribute('aria-hidden')).toBe('true')
    expect(warning).toHaveBeenCalledWith(
      'Icon: meaningful icons require a non-empty label when decorative={false}.',
    )
  })

  it('does not duplicate the accessible name of an icon-only control', () => {
    render(
      <button type="button" aria-label="Search">
        <Icon source="search" />
      </button>,
    )

    expect(screen.getByRole('button', { name: 'Search' })).toBeInstanceOf(
      HTMLButtonElement,
    )
    expect(screen.queryByRole('img')).toBeNull()
  })

  it('adds no keyboard stop or interactive ARIA state', async () => {
    const user = userEvent.setup()
    render(
      <>
        <Icon source="info" decorative={false} label="Information" data-testid="icon" />
        <button type="button">Next</button>
      </>,
    )

    await user.tab()
    expect(document.activeElement).toBe(screen.getByRole('button', { name: 'Next' }))
    const icon = screen.getByTestId('icon')
    expect(icon.hasAttribute('tabindex')).toBe(false)
    expect(icon.hasAttribute('aria-pressed')).toBe(false)
    expect(icon.hasAttribute('aria-selected')).toBe(false)
  })

  it('records RTL mirroring only as an explicit visual opt-in', () => {
    const { rerender } = render(
      <div dir="rtl">
        <Icon source={DirectionSource} data-testid="icon" />
      </div>,
    )
    expect(screen.getByTestId('icon').getAttribute('data-m3e-mirrored')).toBe('false')

    rerender(
      <div dir="rtl">
        <Icon source={DirectionSource} mirrored data-testid="icon" />
      </div>,
    )
    expect(screen.getByTestId('icon').getAttribute('data-m3e-mirrored')).toBe('true')
  })
})

// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createRef } from 'react'
import { afterEach, vi } from 'vitest'
import {
  Icon,
  type IconSourceProps,
} from '../../../src/components/Icon'

function SearchSource(props: IconSourceProps) {
  return (
    <svg {...props} viewBox="0 0 24 24">
      <path d="M9 3a6 6 0 1 0 0 12 6 6 0 0 0 0-12Zm0 2a4 4 0 1 1 0 8 4 4 0 0 1 0-8Z" />
      <path d="m13 14 6 6" />
    </svg>
  )
}

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('Icon', () => {
  it('renders a decorative Material Symbols glyph by default', () => {
    render(<Icon source="search" data-testid="icon" />)
    const icon = screen.getByTestId('icon')
    const visual = icon.firstElementChild

    expect(icon.tagName).toBe('SPAN')
    expect(icon.getAttribute('class')).toBe('m3e-icon')
    expect(icon.getAttribute('aria-hidden')).toBe('true')
    expect(icon.hasAttribute('role')).toBe(false)
    expect(icon.hasAttribute('tabindex')).toBe(false)
    expect(icon.getAttribute('data-m3e-source')).toBe('symbol')
    expect(icon.getAttribute('data-m3e-symbol-style')).toBe('outlined')
    expect(visual?.getAttribute('class')).toBe('m3e-icon__symbol')
    expect(visual?.getAttribute('aria-hidden')).toBe('true')
    expect(visual?.textContent).toBe('search')
  })

  it('adapts an SVG source component while the root owns semantics', () => {
    render(
      <Icon
        source={SearchSource}
        decorative={false}
        label="Search results"
        data-testid="icon"
      />,
    )
    const icon = screen.getByRole('img', { name: 'Search results' })
    const svg = icon.querySelector('svg')

    expect(icon).toBe(screen.getByTestId('icon'))
    expect(icon.getAttribute('data-m3e-source')).toBe('svg')
    expect(icon.hasAttribute('data-m3e-symbol-style')).toBe(false)
    expect(svg?.getAttribute('class')).toBe('m3e-icon__svg')
    expect(svg?.getAttribute('aria-hidden')).toBe('true')
    expect(svg?.getAttribute('focusable')).toBe('false')
    expect(svg?.getAttribute('viewBox')).toBe('0 0 24 24')
  })

  it('preserves consumer attributes, presentation, classes, and handlers', async () => {
    const user = userEvent.setup()
    const onPointerEnter = vi.fn()
    render(
      <Icon
        source="favorite"
        data-testid="icon"
        id="favorite-icon"
        data-owner="consumer"
        aria-describedby="favorite-help"
        className="favorite-mark"
        style={{ color: 'rebeccapurple' }}
        onPointerEnter={onPointerEnter}
      />,
    )
    const icon = screen.getByTestId('icon')

    await user.hover(icon)
    expect(onPointerEnter).toHaveBeenCalledTimes(1)
    expect(icon.getAttribute('id')).toBe('favorite-icon')
    expect(icon.getAttribute('data-owner')).toBe('consumer')
    expect(icon.getAttribute('aria-describedby')).toBe('favorite-help')
    expect(icon.getAttribute('class')).toBe('m3e-icon favorite-mark')
    expect(icon.getAttribute('style')).toContain('color: rebeccapurple')
  })

  it('forwards a ref to its passive span root', () => {
    const ref = createRef<HTMLSpanElement>()
    render(<Icon ref={ref} source={SearchSource} />)

    expect(ref.current).toBeInstanceOf(HTMLSpanElement)
    expect(ref.current?.getAttribute('data-m3e-source')).toBe('svg')
  })

  it('serializes size and every current Material Symbols axis deterministically', () => {
    render(
      <Icon
        source="favorite"
        symbolStyle="rounded"
        size={32}
        fill={1}
        weight={575}
        grade={100}
        opticalSize={40}
        roundness={100}
        mirrored
        data-testid="icon"
      />,
    )
    const icon = screen.getByTestId('icon')
    const style = icon.getAttribute('style') ?? ''

    expect(icon.getAttribute('data-m3e-symbol-style')).toBe('rounded')
    expect(icon.getAttribute('data-m3e-mirrored')).toBe('true')
    expect(style).toContain('--m3e-icon-size: 32px')
    expect(style).toContain('--m3e-icon-symbol-fill: 1')
    expect(style).toContain('--m3e-icon-symbol-weight: 575')
    expect(style).toContain('--m3e-icon-symbol-grade: 100')
    expect(style).toContain('--m3e-icon-symbol-optical-size: 40')
    expect(style).toContain('--m3e-icon-symbol-roundness: 100')
  })

  it('tracks visual size with a clamped optical size when not explicitly set', () => {
    const { rerender } = render(<Icon source="add" size={16} data-testid="icon" />)
    expect(screen.getByTestId('icon').getAttribute('style')).toContain(
      '--m3e-icon-symbol-optical-size: 20',
    )

    rerender(<Icon source="add" size={64} data-testid="icon" />)
    expect(screen.getByTestId('icon').getAttribute('style')).toContain(
      '--m3e-icon-symbol-optical-size: 48',
    )
  })

  it('warns about empty meaningful labels and out-of-range symbol values', () => {
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    render(
      <Icon
        source=""
        decorative={false}
        label=""
        size={0}
        fill={2}
        weight={50}
        grade={250}
        opticalSize={12}
        roundness={101}
      />,
    )

    expect(warning).toHaveBeenCalledWith('Icon: a Material Symbols source must not be empty.')
    expect(warning).toHaveBeenCalledWith(
      'Icon: meaningful icons require a non-empty label when decorative={false}.',
    )
    expect(warning).toHaveBeenCalledWith(
      'Icon: size must be a positive finite CSS-pixel value; received 0.',
    )
    expect(warning).toHaveBeenCalledTimes(8)
  })

  it('exposes a stable component name for React tooling', () => {
    expect(Icon.displayName).toBe('Icon')
  })
})

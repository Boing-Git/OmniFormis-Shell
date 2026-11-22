// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createRef } from 'react'
import { afterEach, vi } from 'vitest'
import { FloatingToolbar } from '../../../src/components/FloatingToolbar'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('FloatingToolbar', () => {
  it('renders role="toolbar" with the sourced defaults', () => {
    render(
      <FloatingToolbar aria-label="Formatting">
        <button type="button">Bold</button>
        <button type="button">Italic</button>
      </FloatingToolbar>,
    )
    const toolbar = screen.getByRole('toolbar', { name: 'Formatting' })
    expect(toolbar.getAttribute('class')).toBe('m3e-floating-toolbar')
    expect(toolbar.getAttribute('aria-orientation')).toBe('horizontal')
    expect(toolbar.getAttribute('data-m3e-orientation')).toBe('horizontal')
    expect(toolbar.getAttribute('data-m3e-variant')).toBe('standard')
    expect(toolbar.getAttribute('data-m3e-expanded')).toBe('true')
  })

  it('reflects orientation and variant attributes', () => {
    render(
      <FloatingToolbar aria-label="Actions" orientation="vertical" variant="vibrant">
        <button type="button">One</button>
      </FloatingToolbar>,
    )
    const toolbar = screen.getByRole('toolbar')
    expect(toolbar.getAttribute('aria-orientation')).toBe('vertical')
    expect(toolbar.getAttribute('data-m3e-orientation')).toBe('vertical')
    expect(toolbar.getAttribute('data-m3e-variant')).toBe('vibrant')
  })

  it('only the first item is in the tab sequence initially, the rest are roving-tabindex -1', () => {
    render(
      <FloatingToolbar aria-label="Actions">
        <button type="button">One</button>
        <button type="button">Two</button>
        <button type="button">Three</button>
      </FloatingToolbar>,
    )
    const buttons = screen.getAllByRole('button')
    expect(buttons.map((b) => b.tabIndex)).toEqual([0, -1, -1])
  })

  it('moves focus and the roving tabindex with ArrowRight/ArrowLeft when horizontal', async () => {
    const user = userEvent.setup()
    render(
      <FloatingToolbar aria-label="Actions">
        <button type="button">One</button>
        <button type="button">Two</button>
        <button type="button">Three</button>
      </FloatingToolbar>,
    )
    const [one, two, three] = screen.getAllByRole('button')
    one.focus()

    await user.keyboard('{ArrowRight}')
    expect(document.activeElement).toBe(two)
    expect(two.tabIndex).toBe(0)
    expect(one.tabIndex).toBe(-1)

    await user.keyboard('{ArrowRight}')
    expect(document.activeElement).toBe(three)

    // wraps around
    await user.keyboard('{ArrowRight}')
    expect(document.activeElement).toBe(one)

    await user.keyboard('{ArrowLeft}')
    expect(document.activeElement).toBe(three)
  })

  it('moves focus with ArrowUp/ArrowDown when vertical, not ArrowRight/ArrowLeft', async () => {
    const user = userEvent.setup()
    render(
      <FloatingToolbar aria-label="Actions" orientation="vertical">
        <button type="button">One</button>
        <button type="button">Two</button>
      </FloatingToolbar>,
    )
    const [one, two] = screen.getAllByRole('button')
    one.focus()

    await user.keyboard('{ArrowRight}')
    expect(document.activeElement).toBe(one)

    await user.keyboard('{ArrowDown}')
    expect(document.activeElement).toBe(two)
  })

  it('Home/End jump to the first/last item', async () => {
    const user = userEvent.setup()
    render(
      <FloatingToolbar aria-label="Actions">
        <button type="button">One</button>
        <button type="button">Two</button>
        <button type="button">Three</button>
      </FloatingToolbar>,
    )
    const [one, , three] = screen.getAllByRole('button')
    one.focus()

    await user.keyboard('{End}')
    expect(document.activeElement).toBe(three)

    await user.keyboard('{Home}')
    expect(document.activeElement).toBe(one)
  })

  it('supports controlled and uncontrolled expanded state', () => {
    const { rerender } = render(
      <FloatingToolbar aria-label="Actions" expanded={false}>
        <button type="button">One</button>
      </FloatingToolbar>,
    )
    expect(screen.getByRole('toolbar').getAttribute('data-m3e-expanded')).toBe('false')

    rerender(
      <FloatingToolbar aria-label="Actions" expanded={true}>
        <button type="button">One</button>
      </FloatingToolbar>,
    )
    expect(screen.getByRole('toolbar').getAttribute('data-m3e-expanded')).toBe('true')
  })

  it('forwards ref, className, and style to the root', () => {
    const ref = createRef<HTMLDivElement>()
    render(
      <FloatingToolbar ref={ref} aria-label="Actions" className="consumer-class" data-owner="consumer">
        <button type="button">One</button>
      </FloatingToolbar>,
    )
    expect(ref.current?.getAttribute('role')).toBe('toolbar')
    expect(ref.current?.className).toContain('m3e-floating-toolbar')
    expect(ref.current?.className).toContain('consumer-class')
    expect(ref.current?.getAttribute('data-owner')).toBe('consumer')
  })

  it('exposes a stable component name for React tooling', () => {
    expect(FloatingToolbar.displayName).toBe('FloatingToolbar')
  })
})

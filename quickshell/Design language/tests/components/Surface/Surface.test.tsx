// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createRef } from 'react'
import { afterEach, vi } from 'vitest'
import { Surface } from '../../../src/components/Surface'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('Surface', () => {
  it('renders a passive rectangular surface by default', () => {
    render(<Surface data-testid="surface">Content</Surface>)
    const surface = screen.getByTestId('surface')

    expect(surface.tagName).toBe('DIV')
    expect(surface).toHaveProperty('textContent', 'Content')
    expect(surface.getAttribute('class')).toBe('m3e-surface')
    expect(surface.getAttribute('data-m3e-color')).toBe('surface')
    expect(surface.getAttribute('data-m3e-tonal-elevation')).toBe('0')
    expect(surface.getAttribute('data-m3e-shadow-elevation')).toBe('0')
    expect(surface.getAttribute('data-m3e-shape')).toBe('none')
    expect(surface.hasAttribute('role')).toBe(false)
    expect(surface.hasAttribute('tabindex')).toBe(false)
  })

  it('preserves native attributes, consumer styles, classes, and pointer handlers', async () => {
    const user = userEvent.setup()
    const onPointerEnter = vi.fn()
    render(
      <Surface
        id="account-summary"
        data-testid="surface"
        data-owner="consumer"
        aria-describedby="surface-description"
        className="account-surface"
        style={{ padding: 12 }}
        onPointerEnter={onPointerEnter}
      >
        Summary
      </Surface>,
    )
    const surface = screen.getByTestId('surface')

    await user.hover(surface)
    expect(onPointerEnter).toHaveBeenCalledTimes(1)
    expect(surface.getAttribute('id')).toBe('account-summary')
    expect(surface.getAttribute('data-owner')).toBe('consumer')
    expect(surface.getAttribute('aria-describedby')).toBe('surface-description')
    expect(surface.getAttribute('class')).toBe('m3e-surface account-surface')
    expect(surface.getAttribute('style')).toContain('padding: 12px')
  })

  it('forwards the ref to the selected semantic element', () => {
    const ref = createRef<HTMLElement>()
    render(
      <Surface as="article" ref={ref} aria-label="Release note">
        Details
      </Surface>,
    )

    expect(ref.current).toBeInstanceOf(HTMLElement)
    expect(ref.current?.tagName).toBe('ARTICLE')
    expect(ref.current?.getAttribute('aria-label')).toBe('Release note')
  })

  it('renders each supported passive semantic element without inferred behavior', () => {
    const elements = ['section', 'article', 'aside', 'main', 'header', 'footer', 'nav'] as const

    for (const element of elements) {
      const { container, unmount } = render(<Surface as={element}>{element}</Surface>)
      expect(container.firstElementChild?.tagName.toLowerCase()).toBe(element)
      expect(container.firstElementChild?.hasAttribute('tabindex')).toBe(false)
      unmount()
    }
  })

  it('serializes explicit color, tonal elevation, shadow elevation, and shape', () => {
    const { container } = render(
      <Surface
        color="surface"
        tonalElevation={2}
        shadowElevation={4}
        shape="extra-large-increased"
      >
        Expressive surface
      </Surface>,
    )

    expect(container.innerHTML).toMatchInlineSnapshot(
      `"<div class=\"m3e-surface\" data-m3e-color=\"surface\" data-m3e-tonal-elevation=\"2\" data-m3e-shadow-elevation=\"4\" data-m3e-shape=\"extra-large-increased\">Expressive surface</div>"`,
    )
  })

  it('warns when tonal elevation cannot affect the selected color role', () => {
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    render(<Surface color="primary-container" tonalElevation={1} />)

    expect(warning).toHaveBeenCalledWith(
      'Surface: tonalElevation only affects color="surface". Received color="primary-container" with tonalElevation={1}; use color="surface" or remove tonalElevation.',
    )
  })
})

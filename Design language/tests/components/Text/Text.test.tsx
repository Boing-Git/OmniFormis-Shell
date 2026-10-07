// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createRef } from 'react'
import { afterEach, vi } from 'vitest'
import { Text } from '../../../src/components/Text'
import { TYPOGRAPHY_EMPHASES, TYPOGRAPHY_ROLE_NAMES } from '../../../src/tokens'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('Text', () => {
  it('renders neutral inline body text by default', () => {
    render(<Text data-testid="text">Content</Text>)
    const text = screen.getByTestId('text')

    expect(text.tagName).toBe('SPAN')
    expect(text).toHaveProperty('textContent', 'Content')
    expect(text.getAttribute('class')).toBe('m3e-text')
    expect(text.getAttribute('data-m3e-variant')).toBe('bodyLarge')
    expect(text.getAttribute('data-m3e-emphasis')).toBe('baseline')
    expect(text.hasAttribute('role')).toBe(false)
    expect(text.hasAttribute('tabindex')).toBe(false)
  })

  it('preserves native attributes, consumer presentation, and handlers', async () => {
    const user = userEvent.setup()
    const onPointerEnter = vi.fn()
    render(
      <Text
        as="label"
        htmlFor="display-name"
        id="display-name-label"
        data-testid="text"
        data-owner="consumer"
        aria-describedby="display-name-help"
        className="account-label"
        style={{ fontSize: 19 }}
        onPointerEnter={onPointerEnter}
      >
        Display name
      </Text>,
    )
    const text = screen.getByTestId('text')

    await user.hover(text)
    expect(onPointerEnter).toHaveBeenCalledTimes(1)
    expect(text.getAttribute('for')).toBe('display-name')
    expect(text.getAttribute('id')).toBe('display-name-label')
    expect(text.getAttribute('data-owner')).toBe('consumer')
    expect(text.getAttribute('aria-describedby')).toBe('display-name-help')
    expect(text.getAttribute('class')).toBe('m3e-text account-label')
    expect(text.getAttribute('style')).toContain('font-size: 19px')
  })

  it('forwards the ref to the explicitly selected semantic element', () => {
    const ref = createRef<HTMLHeadingElement>()
    render(
      <Text as="h2" ref={ref} variant="labelSmall">
        Release notes
      </Text>,
    )

    expect(ref.current).toBeInstanceOf(HTMLHeadingElement)
    expect(ref.current?.tagName).toBe('H2')
    expect(ref.current?.getAttribute('data-m3e-variant')).toBe('labelSmall')
  })

  it('renders every supported semantic element without inferred behavior', () => {
    const elements = [
      'p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'label', 'legend',
      'strong', 'em', 'small', 'blockquote', 'figcaption',
    ] as const

    for (const element of elements) {
      const { container, unmount } = render(<Text as={element}>{element}</Text>)
      expect(container.firstElementChild?.tagName.toLowerCase()).toBe(element)
      expect(container.firstElementChild?.hasAttribute('tabindex')).toBe(false)
      unmount()
    }
  })

  it('serializes every baseline and Expressive emphasized type style', () => {
    for (const emphasis of TYPOGRAPHY_EMPHASES) {
      for (const variant of TYPOGRAPHY_ROLE_NAMES) {
        const { container, unmount } = render(
          <Text as="p" variant={variant} emphasis={emphasis}>
            {variant}
          </Text>,
        )
        const text = container.firstElementChild
        expect(text?.tagName).toBe('P')
        expect(text?.getAttribute('data-m3e-variant')).toBe(variant)
        expect(text?.getAttribute('data-m3e-emphasis')).toBe(emphasis)
        unmount()
      }
    }
  })

  it('exposes a stable component name for React tooling', () => {
    expect(Text.displayName).toBe('Text')
  })
})

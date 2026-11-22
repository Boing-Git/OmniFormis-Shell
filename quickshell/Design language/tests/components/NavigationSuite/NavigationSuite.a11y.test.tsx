// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { NavigationSuite } from '../../../src/components/NavigationSuite'
import type { NavigationItem } from '../../../src/components/NavigationSuite'
import { installWidthMatchMedia } from './navigation-suite-native-polyfill'

afterEach(cleanup)

const items: NavigationItem[] = [
  { value: 'home', label: 'Home', icon: <span /> },
  { value: 'search', label: 'Search', icon: <span />, disabled: true },
]

describe('NavigationSuite accessibility', () => {
  it('exposes the active layout as a real nav landmark at every tier', () => {
    for (const width of [320, 700, 900]) {
      installWidthMatchMedia(width)
      const { unmount } = render(<NavigationSuite items={items} />)
      expect(screen.getByRole('navigation')).not.toBeNull()
      unmount()
    }
  })

  it('marks a disabled item with aria-disabled regardless of active layout', () => {
    installWidthMatchMedia(320)
    render(<NavigationSuite items={items} />)
    expect(screen.getByRole('button', { name: 'Search' }).getAttribute('aria-disabled')).toBe('true')
  })

  it('keeps items readable inside an RTL scope', () => {
    installWidthMatchMedia(320)
    render(
      <div dir="rtl">
        <NavigationSuite items={items} />
      </div>,
    )
    expect(screen.getByRole('button', { name: 'Home' })).not.toBeNull()
  })
})

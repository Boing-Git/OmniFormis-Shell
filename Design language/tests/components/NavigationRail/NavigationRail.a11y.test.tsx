// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { NavigationRail } from '../../../src/components/NavigationRail'
import type { NavigationItem } from '../../../src/components/NavigationRail'

afterEach(cleanup)

const items: NavigationItem[] = [
  { value: 'home', label: 'Home', icon: <span /> },
  { value: 'search', label: 'Search', icon: <span />, disabled: true },
]

describe('NavigationRail accessibility', () => {
  it('renders a nav landmark containing the items', () => {
    render(<NavigationRail items={items} />)
    expect(screen.getByRole('navigation').querySelectorAll('button')).toHaveLength(2)
  })

  it('marks the selected item with aria-current="page"', () => {
    render(<NavigationRail items={items} />)
    expect(screen.getByRole('button', { name: 'Home' }).getAttribute('aria-current')).toBe('page')
  })

  it('marks a disabled item with aria-disabled', () => {
    render(<NavigationRail items={items} />)
    expect(screen.getByRole('button', { name: 'Search' }).getAttribute('aria-disabled')).toBe('true')
  })

  it('keeps items readable inside an RTL scope', () => {
    render(
      <div dir="rtl">
        <NavigationRail items={items} />
      </div>,
    )
    expect(screen.getByRole('button', { name: 'Home' })).not.toBeNull()
  })
})

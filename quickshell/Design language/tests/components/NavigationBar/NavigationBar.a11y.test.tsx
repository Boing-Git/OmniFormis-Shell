// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { NavigationBar } from '../../../src/components/NavigationBar'
import type { NavigationItem } from '../../../src/components/NavigationBar'

afterEach(cleanup)

const items: NavigationItem[] = [
  { value: 'home', label: 'Home', icon: <span /> },
  { value: 'search', label: 'Search', icon: <span />, disabled: true },
]

describe('NavigationBar accessibility', () => {
  it('renders a nav landmark containing the items', () => {
    render(<NavigationBar items={items} />)
    const nav = screen.getByRole('navigation')
    expect(nav.querySelectorAll('button')).toHaveLength(2)
  })

  it('marks the selected item with aria-current="page", not aria-selected', () => {
    render(<NavigationBar items={items} />)
    const home = screen.getByRole('button', { name: 'Home' })
    expect(home.getAttribute('aria-current')).toBe('page')
    expect(home.hasAttribute('aria-selected')).toBe(false)
  })

  it('marks a disabled item with aria-disabled', () => {
    render(<NavigationBar items={items} />)
    expect(screen.getByRole('button', { name: 'Search' }).getAttribute('aria-disabled')).toBe('true')
  })

  it('hides the icon from assistive technology, relying on the visible label for the accessible name', () => {
    render(<NavigationBar items={items} />)
    const icon = document.querySelector('.m3e-navigation-bar__icon')
    expect(icon?.getAttribute('aria-hidden')).toBe('true')
  })

  it('keeps items readable inside an RTL scope', () => {
    render(
      <div dir="rtl">
        <NavigationBar items={items} />
      </div>,
    )
    expect(screen.getByRole('button', { name: 'Home' })).not.toBeNull()
  })
})

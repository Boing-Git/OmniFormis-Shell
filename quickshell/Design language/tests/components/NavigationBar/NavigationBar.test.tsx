// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createRef } from 'react'
import { afterEach, vi } from 'vitest'
import { NavigationBar } from '../../../src/components/NavigationBar'
import type { NavigationItem } from '../../../src/components/NavigationBar'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

const items: NavigationItem[] = [
  { value: 'home', label: 'Home', icon: <span /> },
  { value: 'search', label: 'Search', icon: <span /> },
  { value: 'settings', label: 'Settings', icon: <span />, disabled: true },
]

describe('NavigationBar', () => {
  it('renders each item as a labeled navigation control, selecting the first by default', () => {
    render(<NavigationBar items={items} />)
    const home = screen.getByRole('button', { name: 'Home' })
    expect(home.getAttribute('aria-current')).toBe('page')
    expect(screen.getByRole('button', { name: 'Search' }).getAttribute('aria-current')).toBeNull()
  })

  it('clicking an item selects it (uncontrolled)', async () => {
    const user = userEvent.setup()
    render(<NavigationBar items={items} />)
    await user.click(screen.getByRole('button', { name: 'Search' }))
    expect(screen.getByRole('button', { name: 'Search' }).getAttribute('aria-current')).toBe('page')
    expect(screen.getByRole('button', { name: 'Home' }).getAttribute('aria-current')).toBeNull()
  })

  it('a disabled item is a native disabled button, inert to click', async () => {
    const user = userEvent.setup()
    render(<NavigationBar items={items} />)
    const settings = screen.getByRole('button', { name: 'Settings' }) as HTMLButtonElement
    expect(settings.disabled).toBe(true)
    await user.click(settings)
    expect(screen.getByRole('button', { name: 'Home' }).getAttribute('aria-current')).toBe('page')
  })

  it('renders an item with href as a real link and omits href when disabled', () => {
    const linkItems: NavigationItem[] = [
      { value: 'home', label: 'Home', icon: <span />, href: '/home' },
      { value: 'archive', label: 'Archive', icon: <span />, href: '/archive', disabled: true },
    ]
    render(<NavigationBar items={linkItems} />)
    const home = screen.getByRole('link', { name: 'Home' })
    expect(home.getAttribute('href')).toBe('/home')
    const archive = screen.getByRole('link', { name: 'Archive' })
    expect(archive.hasAttribute('href')).toBe(false)
    expect(archive.getAttribute('aria-disabled')).toBe('true')
  })

  it('swaps to selectedIcon while an item is selected', async () => {
    const user = userEvent.setup()
    const withSelectedIcon: NavigationItem[] = [
      { value: 'home', label: 'Home', icon: <span data-testid="home-icon" /> },
      {
        value: 'favorites',
        label: 'Favorites',
        icon: <span data-testid="fav-icon-outline" />,
        selectedIcon: <span data-testid="fav-icon-filled" />,
      },
    ]
    render(<NavigationBar items={withSelectedIcon} />)
    expect(screen.queryByTestId('fav-icon-filled')).toBeNull()
    await user.click(screen.getByRole('button', { name: 'Favorites' }))
    expect(screen.getByTestId('fav-icon-filled')).not.toBeNull()
    expect(screen.queryByTestId('fav-icon-outline')).toBeNull()
  })

  it('supports a controlled value/onValueChange pair', async () => {
    const user = userEvent.setup()
    const onValueChange = vi.fn()
    render(<NavigationBar items={items} value="home" onValueChange={onValueChange} />)
    await user.click(screen.getByRole('button', { name: 'Search' }))
    expect(onValueChange).toHaveBeenCalledWith('search')
    expect(screen.getByRole('button', { name: 'Home' }).getAttribute('aria-current')).toBe('page')
  })

  it('supports uncontrolled defaultValue', () => {
    render(<NavigationBar items={items} defaultValue="search" />)
    expect(screen.getByRole('button', { name: 'Search' }).getAttribute('aria-current')).toBe('page')
  })

  it('forwards ref, className, and style to the root nav', () => {
    const ref = createRef<HTMLElement>()
    render(<NavigationBar ref={ref} items={items} className="consumer-class" data-owner="consumer" />)
    expect(ref.current?.tagName).toBe('NAV')
    expect(ref.current?.className).toContain('m3e-navigation-bar')
    expect(ref.current?.className).toContain('consumer-class')
    expect(ref.current?.getAttribute('data-owner')).toBe('consumer')
  })

  it('exposes a stable component name for React tooling', () => {
    expect(NavigationBar.displayName).toBe('NavigationBar')
  })
})

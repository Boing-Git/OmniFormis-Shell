// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createRef } from 'react'
import { afterEach, vi } from 'vitest'
import { NavigationRail } from '../../../src/components/NavigationRail'
import type { NavigationItem } from '../../../src/components/NavigationRail'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

const items: NavigationItem[] = [
  { value: 'home', label: 'Home', icon: <span /> },
  { value: 'search', label: 'Search', icon: <span /> },
  { value: 'settings', label: 'Settings', icon: <span />, disabled: true },
]

describe('NavigationRail', () => {
  it('renders each item, selecting the first by default', () => {
    render(<NavigationRail items={items} />)
    expect(screen.getByRole('button', { name: 'Home' }).getAttribute('aria-current')).toBe('page')
  })

  it('clicking an item selects it (uncontrolled)', async () => {
    const user = userEvent.setup()
    render(<NavigationRail items={items} />)
    await user.click(screen.getByRole('button', { name: 'Search' }))
    expect(screen.getByRole('button', { name: 'Search' }).getAttribute('aria-current')).toBe('page')
  })

  it('a disabled item is a native disabled button, inert to click', async () => {
    const user = userEvent.setup()
    render(<NavigationRail items={items} />)
    const settings = screen.getByRole('button', { name: 'Settings' }) as HTMLButtonElement
    expect(settings.disabled).toBe(true)
    await user.click(settings)
    expect(screen.getByRole('button', { name: 'Home' }).getAttribute('aria-current')).toBe('page')
  })

  it('renders an optional header above the items', () => {
    render(<NavigationRail items={items} header={<button type="button">Compose</button>} />)
    const header = document.querySelector('.m3e-navigation-rail__header')
    expect(header?.textContent).toBe('Compose')
  })

  it('renders no header region when omitted', () => {
    render(<NavigationRail items={items} />)
    expect(document.querySelector('.m3e-navigation-rail__header')).toBeNull()
  })

  it('renders an item with href as a real link', () => {
    const linkItems: NavigationItem[] = [{ value: 'home', label: 'Home', icon: <span />, href: '/home' }]
    render(<NavigationRail items={linkItems} />)
    expect(screen.getByRole('link', { name: 'Home' }).getAttribute('href')).toBe('/home')
  })

  it('supports a controlled value/onValueChange pair', async () => {
    const user = userEvent.setup()
    const onValueChange = vi.fn()
    render(<NavigationRail items={items} value="home" onValueChange={onValueChange} />)
    await user.click(screen.getByRole('button', { name: 'Search' }))
    expect(onValueChange).toHaveBeenCalledWith('search')
  })

  it('supports uncontrolled defaultValue', () => {
    render(<NavigationRail items={items} defaultValue="search" />)
    expect(screen.getByRole('button', { name: 'Search' }).getAttribute('aria-current')).toBe('page')
  })

  it('forwards ref, className, and style to the root nav', () => {
    const ref = createRef<HTMLElement>()
    render(<NavigationRail ref={ref} items={items} className="consumer-class" data-owner="consumer" />)
    expect(ref.current?.tagName).toBe('NAV')
    expect(ref.current?.className).toContain('m3e-navigation-rail')
    expect(ref.current?.className).toContain('consumer-class')
    expect(ref.current?.getAttribute('data-owner')).toBe('consumer')
  })

  it('exposes a stable component name for React tooling', () => {
    expect(NavigationRail.displayName).toBe('NavigationRail')
  })
})

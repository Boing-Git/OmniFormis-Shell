// @vitest-environment jsdom

import { act, cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createRef } from 'react'
import { afterEach, vi } from 'vitest'
import { NavigationSuite } from '../../../src/components/NavigationSuite'
import type { NavigationItem } from '../../../src/components/NavigationSuite'
import { installWidthMatchMedia } from './navigation-suite-native-polyfill'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

const items: NavigationItem[] = [
  { value: 'home', label: 'Home', icon: <span /> },
  { value: 'search', label: 'Search', icon: <span /> },
]

describe('NavigationSuite', () => {
  it('renders NavigationBar below the medium breakpoint (compact)', () => {
    installWidthMatchMedia(320)
    render(<NavigationSuite items={items} />)
    expect(document.querySelector('.m3e-navigation-bar')).not.toBeNull()
    expect(document.querySelector('.m3e-navigation-rail')).toBeNull()
    expect(document.querySelector('.m3e-navigation-drawer')).toBeNull()
  })

  it('renders NavigationRail between the medium and expanded breakpoints', () => {
    installWidthMatchMedia(700)
    render(<NavigationSuite items={items} />)
    expect(document.querySelector('.m3e-navigation-rail')).not.toBeNull()
    expect(document.querySelector('.m3e-navigation-bar')).toBeNull()
  })

  it('renders a permanent NavigationDrawer at and above the expanded breakpoint', () => {
    installWidthMatchMedia(900)
    render(<NavigationSuite items={items} />)
    const drawer = document.querySelector('.m3e-navigation-drawer')
    expect(drawer).not.toBeNull()
    expect(drawer?.getAttribute('data-m3e-variant')).toBe('permanent')
  })

  it('switches layout live when the simulated viewport width changes', () => {
    const controller = installWidthMatchMedia(320)
    render(<NavigationSuite items={items} />)
    expect(document.querySelector('.m3e-navigation-bar')).not.toBeNull()

    act(() => controller.setWidth(900))
    expect(document.querySelector('.m3e-navigation-bar')).toBeNull()
    expect(document.querySelector('.m3e-navigation-drawer')).not.toBeNull()
  })

  it('shares selection state across a layout switch', () => {
    const controller = installWidthMatchMedia(320)
    render(<NavigationSuite items={items} defaultValue="search" />)
    expect(screen.getByRole('button', { name: 'Search' }).getAttribute('aria-current')).toBe('page')

    act(() => controller.setWidth(700))
    expect(screen.getByRole('button', { name: 'Search' }).getAttribute('aria-current')).toBe('page')
  })

  it('passes header through to NavigationRail only', () => {
    installWidthMatchMedia(700)
    render(<NavigationSuite items={items} header={<button type="button">Compose</button>} />)
    expect(document.querySelector('.m3e-navigation-rail__header')?.textContent).toBe('Compose')
  })

  it('supports a controlled value/onValueChange pair', async () => {
    installWidthMatchMedia(320)
    const onValueChange = vi.fn()
    render(<NavigationSuite items={items} value="home" onValueChange={onValueChange} />)
    const user = userEvent.setup()
    await user.click(screen.getByRole('button', { name: 'Search' }))
    expect(onValueChange).toHaveBeenCalledWith('search')
  })

  it('forwards ref, className, and style to the wrapper', () => {
    installWidthMatchMedia(320)
    const ref = createRef<HTMLDivElement>()
    render(<NavigationSuite ref={ref} items={items} className="consumer-class" data-owner="consumer" />)
    expect(ref.current?.className).toContain('m3e-navigation-suite')
    expect(ref.current?.className).toContain('consumer-class')
    expect(ref.current?.getAttribute('data-owner')).toBe('consumer')
  })

  it('exposes a stable component name for React tooling', () => {
    expect(NavigationSuite.displayName).toBe('NavigationSuite')
  })
})

// @vitest-environment jsdom

import { act, cleanup, render, screen } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { afterEach, beforeEach } from 'vitest'
import {
  Material3Provider,
  createTheme,
  defaultTheme,
  useMaterial3Theme,
  useResolvedColorMode,
} from '../../src'

interface MatchMediaController {
  readonly setDark: (matches: boolean) => void
}

function installMatchMedia(initialDark = false): MatchMediaController {
  let dark = initialDark
  const listeners = new Set<(event: MediaQueryListEvent) => void>()
  const mediaQuery = {
    media: '(prefers-color-scheme: dark)',
    get matches() {
      return dark
    },
    onchange: null,
    addEventListener: (_type: string, listener: (event: MediaQueryListEvent) => void) => {
      listeners.add(listener)
    },
    removeEventListener: (_type: string, listener: (event: MediaQueryListEvent) => void) => {
      listeners.delete(listener)
    },
    addListener: () => {},
    removeListener: () => {},
    dispatchEvent: () => true,
  } as MediaQueryList
  Object.defineProperty(window, 'matchMedia', {
    configurable: true,
    value: () => mediaQuery,
  })
  return {
    setDark(matches) {
      dark = matches
      const event = { matches, media: mediaQuery.media } as MediaQueryListEvent
      listeners.forEach((listener) => listener(event))
    },
  }
}

afterEach(cleanup)
beforeEach(() => installMatchMedia(false))

describe('Material3Provider', () => {
  it('renders a complete default scoped theme without touching the document root', () => {
    const rootBefore = [...document.documentElement.attributes].map(({ name, value }) => [name, value])
    render(<Material3Provider data-testid="provider">content</Material3Provider>)
    const provider = screen.getByTestId('provider')

    expect(provider.classList.contains('m3e-theme')).toBe(true)
    expect(provider.getAttribute('data-m3e-color-mode')).toBe('system')
    expect(provider.getAttribute('data-m3e-resolved-color-mode')).toBe('light')
    expect(provider.hasAttribute('style')).toBe(false)
    expect([...document.documentElement.attributes].map(({ name, value }) => [name, value])).toEqual(
      rootBefore,
    )
  })

  it('scopes custom theme differences and preserves explicit style overrides', () => {
    const theme = createTheme({ density: { scale: -2 } })
    render(
      <Material3Provider
        data-testid="provider"
        theme={theme}
        colorMode="light"
        style={{ '--m3e-sys-density-scale': -3 } as React.CSSProperties}
      />,
    )
    const provider = screen.getByTestId('provider')
    expect(provider.style.getPropertyValue('--m3e-sys-density-scale')).toBe('-3')
    expect(document.documentElement.style.getPropertyValue('--m3e-sys-density-scale')).toBe('')
  })

  it('isolates nested theme scopes', () => {
    render(
      <Material3Provider data-testid="outer" theme={createTheme({ density: { scale: -1 } })}>
        <Material3Provider data-testid="inner" theme={createTheme({ density: { scale: -2 } })}>
          nested
        </Material3Provider>
      </Material3Provider>,
    )
    expect(screen.getByTestId('outer').style.getPropertyValue('--m3e-sys-density-scale')).toBe('-1')
    expect(screen.getByTestId('inner').style.getPropertyValue('--m3e-sys-density-scale')).toBe('-2')
  })

  it('uses scheme aliases for custom system themes and fixed variables for fixed modes', () => {
    const theme = createTheme({
      colorSchemes: { light: { primary: { $ref: 'ref.palette.primary-30' } } },
    })
    const { rerender } = render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="system" />,
    )
    const provider = screen.getByTestId('provider')
    expect(provider.style.getPropertyValue('--m3e-theme-color-light-primary')).toBe(
      'var(--m3e-ref-palette-primary-30)',
    )
    expect(provider.style.getPropertyValue('--m3e-sys-color-primary')).toBe('')

    rerender(<Material3Provider data-testid="provider" theme={theme} colorMode="light" />)
    expect(provider.style.getPropertyValue('--m3e-theme-color-light-primary')).toBe('')
    expect(provider.style.getPropertyValue('--m3e-sys-color-primary')).toBe(
      'var(--m3e-ref-palette-primary-30)',
    )
  })

  it('updates only resolved-mode consumers when the system preference changes', () => {
    const media = installMatchMedia(false)
    let themeRenders = 0
    let modeRenders = 0
    function ThemeReader() {
      themeRenders += 1
      return <span>{useMaterial3Theme() === defaultTheme ? 'default' : 'custom'}</span>
    }
    function ModeReader() {
      modeRenders += 1
      return <output>{useResolvedColorMode()}</output>
    }

    render(
      <Material3Provider>
        <ThemeReader />
        <ModeReader />
      </Material3Provider>,
    )
    expect(screen.getByText('light')).toBeTruthy()
    expect(themeRenders).toBe(1)
    expect(modeRenders).toBe(1)

    act(() => media.setDark(true))
    expect(screen.getByText('dark')).toBeTruthy()
    expect(themeRenders).toBe(1)
    expect(modeRenders).toBe(2)
  })

  it('hydrates from the server fallback before synchronizing the browser preference', async () => {
    installMatchMedia(true)
    const tree = (
      <Material3Provider systemModeFallback="light">
        <span>hydrated child</span>
      </Material3Provider>
    )
    const serverHtml = renderToString(tree)
    expect(serverHtml).toContain('data-m3e-resolved-color-mode="light"')

    const container = document.createElement('div')
    container.innerHTML = serverHtml
    document.body.append(container)
    const recoverableErrors: unknown[] = []
    const root = hydrateRoot(container, tree, {
      onRecoverableError: (error) => recoverableErrors.push(error),
    })
    await act(async () => {})

    expect(
      container.firstElementChild?.getAttribute('data-m3e-resolved-color-mode'),
    ).toBe('dark')
    expect(recoverableErrors).toEqual([])
    await act(async () => root.unmount())
    container.remove()
  })
})

// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { Material3Provider, NavigationBar, createTheme, defaultTheme } from '../../../src'
import type { NavigationItem } from '../../../src/components/NavigationBar'

afterEach(cleanup)

const items: NavigationItem[] = [{ value: 'home', label: 'Home', icon: <span /> }]

function withNavigationBarToken(name: string, value: number | string | { $ref: string }) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'navigation-bar'
      ? {
          ...registration,
          tokens: {
            ...registration.tokens,
            [name]: {
              ...registration.tokens[name],
              value,
            },
          },
        }
      : registration,
  )
}

describe('NavigationBar theme integration', () => {
  it('ships the sourced geometry and color defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'navigation-bar',
    )?.tokens

    expect(tokens?.['container-color'].value).toEqual({ $ref: 'sys.color.surfaceContainer' })
    expect(tokens?.['container-height'].value).toBe('64px')
    expect(tokens?.['item-active-indicator-color'].value).toEqual({
      $ref: 'sys.color.secondaryContainer',
    })
    expect(tokens?.['item-active-label-color'].value).toEqual({ $ref: 'sys.color.secondary' })
  })

  it('supports scoped NavigationBar token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withNavigationBarToken('container-height', '72px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <NavigationBar items={items} />
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-navigation-bar-container-height'),
    ).toBe('72px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested NavigationBar overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withNavigationBarToken('container-color', { $ref: 'sys.color.tertiary' }),
    })
    const innerTheme = createTheme({
      componentTokens: withNavigationBarToken('container-color', { $ref: 'sys.color.secondary' }),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <NavigationBar items={items} />
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <NavigationBar items={items} />
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-navigation-bar-container-color'),
    ).toBe('var(--m3e-sys-color-tertiary)')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-navigation-bar-container-color'),
    ).toBe('var(--m3e-sys-color-secondary)')
  })
})

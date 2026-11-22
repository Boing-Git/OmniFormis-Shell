// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { Material3Provider, NavigationRail, createTheme, defaultTheme } from '../../../src'
import type { NavigationItem } from '../../../src/components/NavigationRail'

afterEach(cleanup)

const items: NavigationItem[] = [{ value: 'home', label: 'Home', icon: <span /> }]

function withNavigationRailToken(name: string, value: number | string | { $ref: string }) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'navigation-rail'
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

describe('NavigationRail theme integration', () => {
  it('ships the sourced geometry and color defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'navigation-rail',
    )?.tokens

    expect(tokens?.['container-color'].value).toEqual({ $ref: 'sys.color.surface' })
    expect(tokens?.['container-width'].value).toBe('96px')
    expect(tokens?.['item-active-indicator-color'].value).toEqual({
      $ref: 'sys.color.secondaryContainer',
    })
  })

  it('supports scoped NavigationRail token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withNavigationRailToken('container-width', '120px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <NavigationRail items={items} />
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-navigation-rail-container-width'),
    ).toBe('120px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested NavigationRail overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withNavigationRailToken('container-color', { $ref: 'sys.color.tertiary' }),
    })
    const innerTheme = createTheme({
      componentTokens: withNavigationRailToken('container-color', { $ref: 'sys.color.secondary' }),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <NavigationRail items={items} />
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <NavigationRail items={items} />
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-navigation-rail-container-color'),
    ).toBe('var(--m3e-sys-color-tertiary)')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-navigation-rail-container-color'),
    ).toBe('var(--m3e-sys-color-secondary)')
  })
})

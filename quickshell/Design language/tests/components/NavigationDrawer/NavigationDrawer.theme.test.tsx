// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { Material3Provider, NavigationDrawer, createTheme, defaultTheme } from '../../../src'
import type { NavigationItem } from '../../../src/components/NavigationDrawer'

afterEach(cleanup)

const items: NavigationItem[] = [{ value: 'inbox', label: 'Inbox', icon: <span /> }]

function withNavigationDrawerToken(name: string, value: number | string | { $ref: string }) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'navigation-drawer'
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

describe('NavigationDrawer theme integration', () => {
  it('ships the sourced geometry and color defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'navigation-drawer',
    )?.tokens

    expect(tokens?.['container-width'].value).toBe('360px')
    expect(tokens?.['modal-container-color'].value).toEqual({
      $ref: 'sys.color.surfaceContainerLow',
    })
    expect(tokens?.['standard-container-color'].value).toEqual({ $ref: 'sys.color.surface' })
    expect(tokens?.['item-active-indicator-height'].value).toBe('56px')
    expect(tokens?.['scrim-opacity'].value).toBe(0.32)
  })

  it('supports scoped NavigationDrawer token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withNavigationDrawerToken('container-width', '320px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <NavigationDrawer items={items} variant="permanent" />
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-navigation-drawer-container-width'),
    ).toBe('320px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested NavigationDrawer overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withNavigationDrawerToken('standard-container-color', {
        $ref: 'sys.color.tertiary',
      }),
    })
    const innerTheme = createTheme({
      componentTokens: withNavigationDrawerToken('standard-container-color', {
        $ref: 'sys.color.secondary',
      }),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <NavigationDrawer items={items} variant="permanent" />
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <NavigationDrawer items={items} variant="permanent" />
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen
        .getByTestId('outer')
        .style.getPropertyValue('--m3e-comp-navigation-drawer-standard-container-color'),
    ).toBe('var(--m3e-sys-color-tertiary)')
    expect(
      screen
        .getByTestId('inner')
        .style.getPropertyValue('--m3e-comp-navigation-drawer-standard-container-color'),
    ).toBe('var(--m3e-sys-color-secondary)')
  })
})

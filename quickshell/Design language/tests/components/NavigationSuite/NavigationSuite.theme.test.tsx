// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { Material3Provider, NavigationSuite, createTheme, defaultTheme } from '../../../src'
import type { NavigationItem } from '../../../src/components/NavigationSuite'
import { installWidthMatchMedia } from './navigation-suite-native-polyfill'

afterEach(cleanup)

const items: NavigationItem[] = [{ value: 'home', label: 'Home', icon: <span /> }]

function withNavigationBarToken(name: string, value: number | string) {
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

describe('NavigationSuite theme integration', () => {
  it('registers no component tokens of its own — it reuses NavigationBar/NavigationRail/NavigationDrawer', () => {
    const own = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'navigation-suite',
    )
    expect(own).toBeUndefined()
  })

  it('reflects a scoped NavigationBar token override in the compact tier it renders', () => {
    installWidthMatchMedia(320)
    const theme = createTheme({
      componentTokens: withNavigationBarToken('container-height', '72px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="light">
        <NavigationSuite items={items} />
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-navigation-bar-container-height'),
    ).toBe('72px')
    expect(document.querySelector('style')).toBeNull()
  })
})

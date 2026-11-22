// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach, beforeAll } from 'vitest'
import { Material3Provider, Tabs, createTheme, defaultTheme } from '../../../src'
import type { TabItem } from '../../../src/components/Tabs'
import { installTabsNativePolyfills } from './tabs-native-polyfill'

beforeAll(installTabsNativePolyfills)
afterEach(cleanup)

const items: TabItem[] = [
  { value: 'photos', label: 'Photos' },
  { value: 'files', label: 'Files' },
]

function withTabsToken(name: string, value: number | string | { $ref: string }) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'tabs'
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

describe('Tabs theme integration', () => {
  it('ships the sourced geometry and color defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'tabs',
    )?.tokens

    expect(tokens?.['indicator-color'].value).toEqual({ $ref: 'sys.color.primary' })
    expect(tokens?.['indicator-height'].value).toBe('3px')
    expect(tokens?.['container-height'].value).toBe('48px')
    expect(tokens?.['primary-active-label-color'].value).toEqual({ $ref: 'sys.color.primary' })
    expect(tokens?.['secondary-active-label-color'].value).toEqual({ $ref: 'sys.color.onSurface' })
  })

  it('supports scoped Tabs token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withTabsToken('container-height', '56px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <Tabs aria-label="Library" items={items} />
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-tabs-container-height'),
    ).toBe('56px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested Tabs overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withTabsToken('indicator-color', { $ref: 'sys.color.tertiary' }),
    })
    const innerTheme = createTheme({
      componentTokens: withTabsToken('indicator-color', { $ref: 'sys.color.secondary' }),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <Tabs aria-label="Library" items={items} />
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <Tabs aria-label="Library" items={items} />
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-tabs-indicator-color'),
    ).toBe('var(--m3e-sys-color-tertiary)')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-tabs-indicator-color'),
    ).toBe('var(--m3e-sys-color-secondary)')
  })
})

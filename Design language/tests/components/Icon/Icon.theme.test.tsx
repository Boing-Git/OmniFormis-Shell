// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import {
  Icon,
  Material3Provider,
  createTheme,
  defaultTheme,
} from '../../../src'

afterEach(cleanup)

function withIconToken(name: string, value: number | string) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'icon'
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

describe('Icon theme integration', () => {
  it('ships sourced default component tokens for size and every symbol axis', () => {
    const iconTokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'icon',
    )

    expect(iconTokens?.tokens.size.value).toBe('24px')
    expect(iconTokens?.tokens['symbol-fill'].value).toBe(0)
    expect(iconTokens?.tokens['symbol-weight'].value).toBe(400)
    expect(iconTokens?.tokens['symbol-grade'].value).toBe(0)
    expect(iconTokens?.tokens['symbol-optical-size'].value).toBe(24)
    expect(iconTokens?.tokens['symbol-roundness'].value).toBe(50)
  })

  it('supports scoped component-token overrides without runtime style injection', () => {
    const componentTokens = withIconToken('symbol-family-rounded', '"Custom Symbols"')
    const theme = createTheme({ componentTokens })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <Icon source="favorite" symbolStyle="rounded" />
      </Material3Provider>,
    )

    expect(
      screen
        .getByTestId('provider')
        .style.getPropertyValue('--m3e-comp-icon-symbol-family-rounded'),
    ).toBe('"Custom Symbols"')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested Icon token overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withIconToken('symbol-weight', 500),
    })
    const innerTheme = createTheme({
      componentTokens: withIconToken('symbol-weight', 650),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <Icon source="home" />
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <Icon source="settings" />
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-icon-symbol-weight'),
    ).toBe('500')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-icon-symbol-weight'),
    ).toBe('650')
  })
})

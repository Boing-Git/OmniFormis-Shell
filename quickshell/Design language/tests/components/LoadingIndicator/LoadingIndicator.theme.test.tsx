// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { LoadingIndicator } from '../../../src/components/LoadingIndicator'
import { Material3Provider, createTheme, defaultTheme } from '../../../src'

afterEach(cleanup)

function withLoadingIndicatorToken(name: string, value: number | string | { $ref: string }) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'loading-indicator'
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

describe('LoadingIndicator theme integration', () => {
  it('ships the sourced color and layout defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'loading-indicator',
    )?.tokens

    expect(tokens?.['active-indicator-color'].value).toEqual({ $ref: 'sys.color.primary' })
    expect(tokens?.['container-width'].value).toBe('48px')
    expect(tokens?.['container-height'].value).toBe('48px')
    expect(tokens?.['indeterminate-cycle-duration'].value).toBe('4550ms')
    expect(tokens?.['global-rotation-duration'].value).toBe('4666ms')
  })

  it('supports scoped LoadingIndicator token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withLoadingIndicatorToken('container-width', '64px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <LoadingIndicator aria-label="Loading" value={0.5} />
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-loading-indicator-container-width'),
    ).toBe('64px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested LoadingIndicator overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withLoadingIndicatorToken('active-indicator-color', { $ref: 'sys.color.tertiary' }),
    })
    const innerTheme = createTheme({
      componentTokens: withLoadingIndicatorToken('active-indicator-color', { $ref: 'sys.color.secondary' }),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <LoadingIndicator aria-label="Loading" value={0.5} />
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <LoadingIndicator aria-label="Loading" value={0.5} />
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen
        .getByTestId('outer')
        .style.getPropertyValue('--m3e-comp-loading-indicator-active-indicator-color'),
    ).toBe('var(--m3e-sys-color-tertiary)')
    expect(
      screen
        .getByTestId('inner')
        .style.getPropertyValue('--m3e-comp-loading-indicator-active-indicator-color'),
    ).toBe('var(--m3e-sys-color-secondary)')
  })
})

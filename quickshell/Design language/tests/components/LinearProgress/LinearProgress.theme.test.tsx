// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { LinearProgress } from '../../../src/components/LinearProgress'
import { Material3Provider, createTheme, defaultTheme } from '../../../src'

afterEach(cleanup)

function withLinearProgressToken(name: string, value: number | string | { $ref: string }) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'linear-progress'
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

describe('LinearProgress theme integration', () => {
  it('ships the sourced geometry and color defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'linear-progress',
    )?.tokens

    expect(tokens?.['active-indicator-color'].value).toEqual({ $ref: 'sys.color.primary' })
    expect(tokens?.['track-color'].value).toEqual({ $ref: 'sys.color.secondaryContainer' })
    expect(tokens?.['container-height'].value).toBe('4px')
    expect(tokens?.['stop-size'].value).toBe('4px')
  })

  it('supports scoped LinearProgress token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withLinearProgressToken('container-height', '8px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <LinearProgress aria-label="Download" value={0.5} />
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-linear-progress-container-height'),
    ).toBe('8px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested LinearProgress overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withLinearProgressToken('active-indicator-color', { $ref: 'sys.color.tertiary' }),
    })
    const innerTheme = createTheme({
      componentTokens: withLinearProgressToken('active-indicator-color', { $ref: 'sys.color.secondary' }),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <LinearProgress aria-label="Download" value={0.5} />
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <LinearProgress aria-label="Download" value={0.5} />
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-linear-progress-active-indicator-color'),
    ).toBe('var(--m3e-sys-color-tertiary)')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-linear-progress-active-indicator-color'),
    ).toBe('var(--m3e-sys-color-secondary)')
  })
})

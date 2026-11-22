// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { CircularProgress } from '../../../src/components/CircularProgress'
import { Material3Provider, createTheme, defaultTheme } from '../../../src'

afterEach(cleanup)

function withCircularProgressToken(name: string, value: number | string | { $ref: string }) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'circular-progress'
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

describe('CircularProgress theme integration', () => {
  it('ships the sourced geometry and color defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'circular-progress',
    )?.tokens

    expect(tokens?.['active-indicator-color'].value).toEqual({ $ref: 'sys.color.primary' })
    expect(tokens?.['track-color'].value).toEqual({ $ref: 'sys.color.secondaryContainer' })
    expect(tokens?.diameter.value).toBe('40px')
    expect(tokens?.['stroke-width'].value).toBe('4px')
  })

  it('supports scoped CircularProgress token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withCircularProgressToken('diameter', '64px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <CircularProgress aria-label="Progress" value={0.5} />
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-circular-progress-diameter'),
    ).toBe('64px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested CircularProgress overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withCircularProgressToken('active-indicator-color', { $ref: 'sys.color.tertiary' }),
    })
    const innerTheme = createTheme({
      componentTokens: withCircularProgressToken('active-indicator-color', { $ref: 'sys.color.secondary' }),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <CircularProgress aria-label="Progress" value={0.5} />
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <CircularProgress aria-label="Progress" value={0.5} />
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-circular-progress-active-indicator-color'),
    ).toBe('var(--m3e-sys-color-tertiary)')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-circular-progress-active-indicator-color'),
    ).toBe('var(--m3e-sys-color-secondary)')
  })
})

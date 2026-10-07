// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { WavyProgress } from '../../../src/components/WavyProgress'
import { Material3Provider, createTheme, defaultTheme } from '../../../src'

afterEach(cleanup)

function withWavyProgressToken(name: string, value: number | string | { $ref: string }) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'wavy-progress'
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

describe('WavyProgress theme integration', () => {
  it('ships the sourced geometry and color defaults for both shapes', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'wavy-progress',
    )?.tokens

    expect(tokens?.['active-indicator-color'].value).toEqual({ $ref: 'sys.color.primary' })
    expect(tokens?.['track-color'].value).toEqual({ $ref: 'sys.color.secondaryContainer' })
    expect(tokens?.['linear-determinate-wavelength'].value).toBe('40px')
    expect(tokens?.['linear-indeterminate-wavelength'].value).toBe('20px')
    expect(tokens?.['circular-diameter'].value).toBe('48px')
    expect(tokens?.['circular-wavelength'].value).toBe('15px')
  })

  it('supports scoped WavyProgress token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withWavyProgressToken('circular-diameter', '64px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <WavyProgress aria-label="Progress" shape="circular" value={0.5} />
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-wavy-progress-circular-diameter'),
    ).toBe('64px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested WavyProgress overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withWavyProgressToken('active-indicator-color', { $ref: 'sys.color.tertiary' }),
    })
    const innerTheme = createTheme({
      componentTokens: withWavyProgressToken('active-indicator-color', { $ref: 'sys.color.secondary' }),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <WavyProgress aria-label="Upload" value={0.5} />
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <WavyProgress aria-label="Upload" value={0.5} />
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-wavy-progress-active-indicator-color'),
    ).toBe('var(--m3e-sys-color-tertiary)')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-wavy-progress-active-indicator-color'),
    ).toBe('var(--m3e-sys-color-secondary)')
  })
})

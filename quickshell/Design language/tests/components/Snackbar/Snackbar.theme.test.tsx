// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { Material3Provider, Snackbar, createTheme, defaultTheme } from '../../../src'

afterEach(cleanup)

function withSnackbarToken(name: string, value: number | string | { $ref: string }) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'snackbar'
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

describe('Snackbar theme integration', () => {
  it('ships the sourced geometry and color defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'snackbar',
    )?.tokens

    expect(tokens?.['container-color'].value).toEqual({ $ref: 'sys.color.inverseSurface' })
    expect(tokens?.['container-shape'].value).toEqual({ $ref: 'sys.shape.corners.cornerExtraSmall' })
    expect(tokens?.['container-min-height'].value).toBe('48px')
    expect(tokens?.['container-max-width'].value).toBe('600px')
    expect(tokens?.['action-label-color'].value).toEqual({ $ref: 'sys.color.inversePrimary' })
  })

  it('supports scoped Snackbar token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withSnackbarToken('container-max-width', '480px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <Snackbar message="Saved" open onOpenChange={() => undefined} />
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-snackbar-container-max-width'),
    ).toBe('480px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested Snackbar overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withSnackbarToken('container-color', { $ref: 'sys.color.tertiary' }),
    })
    const innerTheme = createTheme({
      componentTokens: withSnackbarToken('container-color', { $ref: 'sys.color.secondary' }),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <Snackbar message="Saved" open onOpenChange={() => undefined} />
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <Snackbar message="Saved" open onOpenChange={() => undefined} />
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-snackbar-container-color'),
    ).toBe('var(--m3e-sys-color-tertiary)')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-snackbar-container-color'),
    ).toBe('var(--m3e-sys-color-secondary)')
  })
})

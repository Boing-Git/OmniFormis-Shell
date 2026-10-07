// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach, beforeAll } from 'vitest'
import { Dialog, Material3Provider, createTheme, defaultTheme } from '../../../src'
import { installDialogPolyfill } from './dialog-native-polyfill'

beforeAll(installDialogPolyfill)

afterEach(cleanup)

function withDialogToken(name: string, value: number | string) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'dialog'
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

describe('Dialog theme integration', () => {
  it('ships the sourced geometry, color, and scrim defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'dialog',
    )?.tokens

    expect(tokens?.['container-color'].value).toEqual({ $ref: 'sys.color.surfaceContainerHigh' })
    expect(tokens?.['container-shape'].value).toEqual({ $ref: 'sys.shape.corners.cornerExtraLarge' })
    expect(tokens?.['container-min-width'].value).toBe('280px')
    expect(tokens?.['container-max-width'].value).toBe('560px')
    expect(tokens?.['icon-color'].value).toEqual({ $ref: 'sys.color.secondary' })
    expect(tokens?.['headline-color'].value).toEqual({ $ref: 'sys.color.onSurface' })
    expect(tokens?.['scrim-opacity'].value).toBe(0.32)
  })

  it('supports scoped Dialog token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withDialogToken('container-max-width', '640px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <Dialog defaultOpen title="Themed" />
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-dialog-container-max-width'),
    ).toBe('640px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested Dialog overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withDialogToken('container-color', { $ref: 'sys.color.tertiaryContainer' }),
    })
    const innerTheme = createTheme({
      componentTokens: withDialogToken('container-color', { $ref: 'sys.color.secondaryContainer' }),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <Dialog defaultOpen title="Outer" />
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <Dialog defaultOpen title="Inner" />
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-dialog-container-color'),
    ).toBe('var(--m3e-sys-color-tertiary-container)')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-dialog-container-color'),
    ).toBe('var(--m3e-sys-color-secondary-container)')
  })
})

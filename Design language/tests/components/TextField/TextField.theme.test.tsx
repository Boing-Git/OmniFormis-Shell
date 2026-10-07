// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import {
  TextField,
  Material3Provider,
  createTheme,
  defaultTheme,
} from '../../../src'

afterEach(cleanup)

function withTextFieldToken(name: string, value: number | string) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'text-field'
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

describe('TextField theme integration', () => {
  it('ships the sourced geometry, color, and disabled defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'text-field',
    )?.tokens

    expect(tokens?.['min-container-block-size'].value).toBe('56px')
    expect(tokens?.['min-container-inline-size'].value).toBe('280px')
    expect(tokens?.['label-color'].value).toEqual({ $ref: 'sys.color.onSurfaceVariant' })
    expect(tokens?.['focus-label-color'].value).toEqual({ $ref: 'sys.color.primary' })
    expect(tokens?.['error-label-color'].value).toEqual({ $ref: 'sys.color.error' })
    expect(tokens?.['disabled-label-opacity'].value).toBe(0.38)
    expect(tokens?.['filled-container-color'].value).toEqual({
      $ref: 'sys.color.surfaceContainerHighest',
    })
    expect(tokens?.['filled-indicator-height'].value).toBe('1px')
    expect(tokens?.['filled-focus-indicator-height'].value).toBe('2px')
    expect(tokens?.['outlined-outline-color'].value).toEqual({ $ref: 'sys.color.outline' })
    expect(tokens?.['outlined-disabled-outline-opacity'].value).toBe(0.12)
  })

  it('supports scoped TextField token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withTextFieldToken('min-container-inline-size', '320px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <TextField label="Custom" />
      </Material3Provider>,
    )

    expect(
      screen
        .getByTestId('provider')
        .style.getPropertyValue('--m3e-comp-text-field-min-container-inline-size'),
    ).toBe('320px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested TextField overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withTextFieldToken('label-color', { $ref: 'sys.color.tertiary' }),
    })
    const innerTheme = createTheme({
      componentTokens: withTextFieldToken('label-color', { $ref: 'sys.color.secondary' }),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <TextField label="Outer" />
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <TextField label="Inner" />
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-text-field-label-color'),
    ).toBe('var(--m3e-sys-color-tertiary)')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-text-field-label-color'),
    ).toBe('var(--m3e-sys-color-secondary)')
  })
})

// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import {
  Radio,
  Material3Provider,
  createTheme,
  defaultTheme,
} from '../../../src'

afterEach(cleanup)

function withRadioToken(name: string, value: number | string) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'radio'
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

describe('Radio theme integration', () => {
  it('ships the sourced geometry, color, and disabled defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'radio',
    )?.tokens

    expect(tokens?.['container-size'].value).toBe('20px')
    expect(tokens?.['outline-width'].value).toBe('2px')
    expect(tokens?.['dot-size'].value).toBe('10px')
    expect(tokens?.['state-layer-size'].value).toBe('40px')
    expect(tokens?.['selected-icon-color'].value).toEqual({ $ref: 'sys.color.primary' })
    expect(tokens?.['unselected-icon-color'].value).toEqual({
      $ref: 'sys.color.onSurfaceVariant',
    })
    expect(tokens?.['disabled-selected-icon-color'].value).toEqual({
      $ref: 'sys.color.onSurface',
    })
    expect(tokens?.['disabled-selected-icon-opacity'].value).toBe(0.38)
    expect(tokens?.['disabled-unselected-icon-opacity'].value).toBe(0.38)
    expect(tokens?.['focus-ring-color'].value).toEqual({ $ref: 'sys.color.secondary' })
  })

  it('supports scoped Radio token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withRadioToken('container-size', '22px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <Radio name="plan" aria-label="Custom" />
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-radio-container-size'),
    ).toBe('22px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested Radio overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withRadioToken('focus-ring-width', '3px'),
    })
    const innerTheme = createTheme({
      componentTokens: withRadioToken('focus-ring-width', '4px'),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <Radio name="outer" aria-label="Outer" />
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <Radio name="inner" aria-label="Inner" />
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-radio-focus-ring-width'),
    ).toBe('3px')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-radio-focus-ring-width'),
    ).toBe('4px')
  })
})

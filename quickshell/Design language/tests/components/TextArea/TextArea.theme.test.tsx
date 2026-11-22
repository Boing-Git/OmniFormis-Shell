// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import {
  TextArea,
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

describe('TextArea theme integration', () => {
  it('consumes the shared text-field token registration, not a duplicate one', () => {
    const componentNames = defaultTheme.componentTokens.map((registration) => registration.component)
    expect(componentNames.filter((name) => name === 'text-field')).toHaveLength(1)
  })

  it('supports scoped token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withTextFieldToken('min-container-inline-size', '320px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <TextArea label="Custom" />
      </Material3Provider>,
    )

    expect(
      screen
        .getByTestId('provider')
        .style.getPropertyValue('--m3e-comp-text-field-min-container-inline-size'),
    ).toBe('320px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested TextArea overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withTextFieldToken('label-color', { $ref: 'sys.color.tertiary' }),
    })
    const innerTheme = createTheme({
      componentTokens: withTextFieldToken('label-color', { $ref: 'sys.color.secondary' }),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <TextArea label="Outer" />
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <TextArea label="Inner" />
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

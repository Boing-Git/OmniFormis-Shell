// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { ButtonGroup } from '../../../src/components/ButtonGroup'
import { Material3Provider, createTheme, defaultTheme } from '../../../src'

afterEach(cleanup)

function withButtonGroupToken(name: string, value: number | string | { $ref: string }) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'button-group'
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

describe('ButtonGroup theme integration', () => {
  it('ships the sourced spacing default and this project\'s own compression-scale defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'button-group',
    )?.tokens

    expect(tokens?.['between-space'].value).toBe('12px')
    expect(tokens?.['pressed-scale'].value).toBe('1.08')
    expect(tokens?.['neighbor-scale'].value).toBe('0.94')
  })

  it('supports scoped ButtonGroup token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withButtonGroupToken('between-space', '24px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <ButtonGroup aria-label="Actions">
          <button type="button">One</button>
        </ButtonGroup>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-button-group-between-space'),
    ).toBe('24px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested ButtonGroup overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withButtonGroupToken('pressed-scale', '1.2'),
    })
    const innerTheme = createTheme({
      componentTokens: withButtonGroupToken('pressed-scale', '1.02'),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <ButtonGroup aria-label="Outer">
          <button type="button">One</button>
        </ButtonGroup>
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <ButtonGroup aria-label="Inner">
            <button type="button">Two</button>
          </ButtonGroup>
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-button-group-pressed-scale'),
    ).toBe('1.2')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-button-group-pressed-scale'),
    ).toBe('1.02')
  })
})

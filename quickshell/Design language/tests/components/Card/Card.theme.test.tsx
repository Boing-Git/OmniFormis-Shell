// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import {
  Card,
  Material3Provider,
  createTheme,
  defaultTheme,
} from '../../../src'

afterEach(cleanup)

function withCardToken(name: string, value: number | string) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'card'
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

describe('Card theme integration', () => {
  it('ships the current sourced shape, color, outline, disabled, and elevation defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'card',
    )?.tokens

    expect(tokens?.['container-shape'].value).toEqual({
      $ref: 'sys.shape.corners.cornerMedium',
    })
    expect(tokens?.['filled-container-color'].value).toEqual({
      $ref: 'sys.color.surfaceContainerHighest',
    })
    expect(tokens?.['elevated-container-shadow'].value).toEqual({
      $ref: 'sys.elevation.level1.shadow',
    })
    expect(tokens?.['elevated-hover-container-shadow'].value).toEqual({
      $ref: 'sys.elevation.level2.shadow',
    })
    expect(tokens?.['outlined-outline-color'].value).toEqual({
      $ref: 'sys.color.outlineVariant',
    })
    expect(tokens?.['outlined-disabled-outline-opacity'].value).toBe(0.12)
    expect(tokens?.['disabled-content-opacity'].value).toBe(0.38)
  })

  it('supports scoped Card token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withCardToken('container-shape', '20px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <Card>Custom</Card>
      </Material3Provider>,
    )

    expect(
      screen
        .getByTestId('provider')
        .style.getPropertyValue('--m3e-comp-card-container-shape'),
    ).toBe('20px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested Card overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withCardToken('focus-ring-width', '3px'),
    })
    const innerTheme = createTheme({
      componentTokens: withCardToken('focus-ring-width', '4px'),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <Card interactive>Outer</Card>
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <Card interactive>Inner</Card>
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-card-focus-ring-width'),
    ).toBe('3px')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-card-focus-ring-width'),
    ).toBe('4px')
  })
})

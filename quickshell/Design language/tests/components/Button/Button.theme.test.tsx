// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import {
  Button,
  Material3Provider,
  createTheme,
  defaultTheme,
} from '../../../src'

afterEach(cleanup)

function withButtonToken(name: string, value: number | string) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'button'
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

describe('Button theme integration', () => {
  it('ships sourced defaults for every Expressive size tier and key variant roles', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'button',
    )?.tokens

    expect(tokens?.['extra-small-container-height'].value).toBe('32px')
    expect(tokens?.['small-container-height'].value).toBe('40px')
    expect(tokens?.['medium-container-height'].value).toBe('56px')
    expect(tokens?.['large-container-height'].value).toBe('96px')
    expect(tokens?.['extra-large-container-height'].value).toBe('136px')
    expect(tokens?.['large-icon-size'].value).toBe('32px')
    expect(tokens?.['extra-large-outline-width'].value).toBe('3px')
    expect(tokens?.['filled-container-color'].value).toEqual({ $ref: 'sys.color.primary' })
    expect(tokens?.['tonal-container-color'].value).toEqual({
      $ref: 'sys.color.secondaryContainer',
    })
  })

  it('supports scoped Button token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withButtonToken('medium-container-height', '60px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <Button size="medium">Custom</Button>
      </Material3Provider>,
    )

    expect(
      screen
        .getByTestId('provider')
        .style.getPropertyValue('--m3e-comp-button-medium-container-height'),
    ).toBe('60px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested Button overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withButtonToken('focus-ring-width', '3px'),
    })
    const innerTheme = createTheme({
      componentTokens: withButtonToken('focus-ring-width', '4px'),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <Button>Outer</Button>
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <Button>Inner</Button>
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-button-focus-ring-width'),
    ).toBe('3px')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-button-focus-ring-width'),
    ).toBe('4px')
  })

  it('recomputes scoped CSS motion when a theme overrides the source spring', () => {
    const theme = createTheme({
      motion: {
        expressive: {
          default: {
            effects: {
              kind: 'spring',
              dampingRatio: 0.8,
              stiffness: 400,
            },
          },
        },
      },
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="light">
        <Button>Slower motion</Button>
      </Material3Provider>,
    )

    const style = screen.getByTestId('provider').style
    expect(
      style.getPropertyValue('--m3e-sys-motion-expressive-default-effects-stiffness'),
    ).toBe('400')
    expect(
      style.getPropertyValue('--m3e-sys-motion-expressive-default-effects-duration'),
    ).toBe('464ms')
    expect(
      style.getPropertyValue('--m3e-sys-motion-expressive-default-effects-easing'),
    ).toContain('linear(')
  })
})

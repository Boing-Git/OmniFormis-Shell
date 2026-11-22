// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import {
  Icon,
  IconButton,
  Material3Provider,
  createTheme,
  defaultTheme,
} from '../../../src'

afterEach(cleanup)

function withIconButtonToken(name: string, value: number | string) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'icon-button'
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

describe('IconButton theme integration', () => {
  it('ships sourced size, width, shape, outline, and state defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'icon-button',
    )?.tokens

    expect(tokens?.['extra-small-container-height'].value).toBe('32px')
    expect(tokens?.['small-container-width-wide'].value).toBe('52px')
    expect(tokens?.['medium-container-width-narrow'].value).toBe('48px')
    expect(tokens?.['large-container-width-wide'].value).toBe('128px')
    expect(tokens?.['extra-large-container-width-wide'].value).toBe('184px')
    expect(tokens?.['extra-large-outline-width'].value).toBe('3px')
    expect(tokens?.['filled-unselected-container-color'].value).toEqual({
      $ref: 'sys.color.surfaceContainer',
    })
    expect(tokens?.['outlined-selected-container-color'].value).toEqual({
      $ref: 'sys.color.inverseSurface',
    })
  })

  it('supports scoped IconButton token overrides without style injection', () => {
    const theme = createTheme({
      componentTokens: withIconButtonToken('medium-container-width-wide', '80px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <IconButton aria-label="Custom" size="medium" width="wide">
          <Icon source="tune" />
        </IconButton>
      </Material3Provider>,
    )

    expect(
      screen
        .getByTestId('provider')
        .style.getPropertyValue('--m3e-comp-icon-button-medium-container-width-wide'),
    ).toBe('80px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested IconButton overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withIconButtonToken('focus-ring-width', '3px'),
    })
    const innerTheme = createTheme({
      componentTokens: withIconButtonToken('focus-ring-width', '4px'),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <IconButton aria-label="Outer"><Icon source="add" /></IconButton>
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <IconButton aria-label="Inner"><Icon source="add" /></IconButton>
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-icon-button-focus-ring-width'),
    ).toBe('3px')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-icon-button-focus-ring-width'),
    ).toBe('4px')
  })
})

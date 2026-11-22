// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import {
  FloatingActionButton,
  Icon,
  Material3Provider,
  createTheme,
  defaultTheme,
} from '../../../src'

afterEach(cleanup)

function withFloatingActionButtonToken(name: string, value: number | string) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'floating-action-button'
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

describe('FloatingActionButton theme integration', () => {
  it('ships sourced size, extended, toggle, color, and elevation defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'floating-action-button',
    )?.tokens

    expect(tokens?.['standard-container-size'].value).toBe('56px')
    expect(tokens?.['medium-container-size'].value).toBe('80px')
    expect(tokens?.['large-container-size'].value).toBe('96px')
    expect(tokens?.['large-icon-size'].value).toBe('36px')
    expect(tokens?.['medium-extended-icon-label-space'].value).toBe('12px')
    expect(tokens?.['toggle-selected-container-size'].value).toBe('56px')
    expect(tokens?.['toggle-selected-icon-size'].value).toBe('20px')
    expect(tokens?.['container-color'].value).toEqual({
      $ref: 'sys.color.primaryContainer',
    })
    expect(tokens?.['default-hover-container-shadow'].value).toEqual({
      $ref: 'sys.elevation.level4.shadow',
    })
  })

  it('supports scoped FAB token overrides without style injection', () => {
    const theme = createTheme({
      componentTokens: withFloatingActionButtonToken('medium-container-size', '84px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <FloatingActionButton aria-label="Custom" icon={<Icon source="tune" />} size="medium" />
      </Material3Provider>,
    )

    expect(
      screen
        .getByTestId('provider')
        .style.getPropertyValue('--m3e-comp-floating-action-button-medium-container-size'),
    ).toBe('84px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested FAB overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withFloatingActionButtonToken('focus-ring-width', '3px'),
    })
    const innerTheme = createTheme({
      componentTokens: withFloatingActionButtonToken('focus-ring-width', '4px'),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <FloatingActionButton aria-label="Outer" icon={<Icon source="add" />} />
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <FloatingActionButton aria-label="Inner" icon={<Icon source="add" />} />
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-floating-action-button-focus-ring-width'),
    ).toBe('3px')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-floating-action-button-focus-ring-width'),
    ).toBe('4px')
  })
})

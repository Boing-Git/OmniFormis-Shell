// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import {
  Switch,
  Material3Provider,
  createTheme,
  defaultTheme,
} from '../../../src'

afterEach(cleanup)

function withSwitchToken(name: string, value: number | string) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'switch'
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

describe('Switch theme integration', () => {
  it('ships the sourced geometry, color, and disabled defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'switch',
    )?.tokens

    expect(tokens?.['track-width'].value).toBe('52px')
    expect(tokens?.['track-height'].value).toBe('32px')
    expect(tokens?.['unselected-handle-size'].value).toBe('16px')
    expect(tokens?.['selected-handle-size'].value).toBe('24px')
    expect(tokens?.['pressed-handle-size'].value).toBe('28px')
    expect(tokens?.['selected-track-color'].value).toEqual({ $ref: 'sys.color.primary' })
    expect(tokens?.['unselected-track-color'].value).toEqual({
      $ref: 'sys.color.surfaceContainerHighest',
    })
    expect(tokens?.['selected-icon-color'].value).toEqual({
      $ref: 'sys.color.onPrimaryContainer',
    })
    expect(tokens?.['disabled-track-opacity'].value).toBe(0.12)
    expect(tokens?.['disabled-selected-icon-opacity'].value).toBe(0.38)
    expect(tokens?.['disabled-unselected-thumb-opacity'].value).toBe(0.38)
    expect(tokens?.['focus-ring-color'].value).toEqual({ $ref: 'sys.color.secondary' })
  })

  it('supports scoped Switch token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withSwitchToken('track-width', '56px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <Switch aria-label="Custom" />
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-switch-track-width'),
    ).toBe('56px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested Switch overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withSwitchToken('focus-ring-width', '3px'),
    })
    const innerTheme = createTheme({
      componentTokens: withSwitchToken('focus-ring-width', '4px'),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <Switch aria-label="Outer" />
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <Switch aria-label="Inner" />
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-switch-focus-ring-width'),
    ).toBe('3px')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-switch-focus-ring-width'),
    ).toBe('4px')
  })
})

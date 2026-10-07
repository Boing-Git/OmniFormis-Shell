// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import {
  Checkbox,
  Material3Provider,
  createTheme,
  defaultTheme,
} from '../../../src'

afterEach(cleanup)

function withCheckboxToken(name: string, value: number | string) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'checkbox'
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

describe('Checkbox theme integration', () => {
  it('ships the sourced geometry, color, and disabled defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'checkbox',
    )?.tokens

    expect(tokens?.['container-size'].value).toBe('18px')
    expect(tokens?.['container-shape'].value).toBe('2px')
    expect(tokens?.['outline-width'].value).toBe('2px')
    expect(tokens?.['state-layer-size'].value).toBe('40px')
    expect(tokens?.['checked-container-color'].value).toEqual({ $ref: 'sys.color.primary' })
    expect(tokens?.['checked-checkmark-color'].value).toEqual({ $ref: 'sys.color.onPrimary' })
    expect(tokens?.['unchecked-outline-color'].value).toEqual({
      $ref: 'sys.color.onSurfaceVariant',
    })
    // The pinned source applies no alpha to the disabled checkmark role.
    expect(tokens?.['disabled-checkmark-color'].value).toEqual({ $ref: 'sys.color.surface' })
    expect(tokens?.['disabled-checked-container-opacity'].value).toBe(0.38)
    expect(tokens?.['disabled-unchecked-outline-opacity'].value).toBe(0.38)
    expect(tokens?.['disabled-indeterminate-outline-opacity'].value).toBe(0.38)
    expect(tokens?.['focus-ring-color'].value).toEqual({ $ref: 'sys.color.secondary' })
  })

  it('supports scoped Checkbox token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withCheckboxToken('container-size', '20px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <Checkbox aria-label="Custom" />
      </Material3Provider>,
    )

    expect(
      screen
        .getByTestId('provider')
        .style.getPropertyValue('--m3e-comp-checkbox-container-size'),
    ).toBe('20px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested Checkbox overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withCheckboxToken('focus-ring-width', '3px'),
    })
    const innerTheme = createTheme({
      componentTokens: withCheckboxToken('focus-ring-width', '4px'),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <Checkbox aria-label="Outer" />
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <Checkbox aria-label="Inner" />
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-checkbox-focus-ring-width'),
    ).toBe('3px')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-checkbox-focus-ring-width'),
    ).toBe('4px')
  })
})

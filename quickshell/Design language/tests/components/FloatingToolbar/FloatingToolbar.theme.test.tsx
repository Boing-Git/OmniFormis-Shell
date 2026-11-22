// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { FloatingToolbar } from '../../../src/components/FloatingToolbar'
import { Material3Provider, createTheme, defaultTheme } from '../../../src'

afterEach(cleanup)

function withFloatingToolbarToken(name: string, value: number | string | { $ref: string }) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'floating-toolbar'
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

describe('FloatingToolbar theme integration', () => {
  it('ships the sourced geometry and color defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'floating-toolbar',
    )?.tokens

    expect(tokens?.['container-height'].value).toBe('64px')
    expect(tokens?.['content-padding'].value).toBe('8px')
    expect(tokens?.['standard-container-color'].value).toEqual({ $ref: 'sys.color.surfaceContainer' })
    expect(tokens?.['vibrant-container-color'].value).toEqual({ $ref: 'sys.color.primaryContainer' })
  })

  it('supports scoped FloatingToolbar token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withFloatingToolbarToken('container-height', '72px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <FloatingToolbar aria-label="Actions">
          <button type="button">One</button>
        </FloatingToolbar>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-floating-toolbar-container-height'),
    ).toBe('72px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested FloatingToolbar overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withFloatingToolbarToken('standard-container-color', { $ref: 'sys.color.tertiary' }),
    })
    const innerTheme = createTheme({
      componentTokens: withFloatingToolbarToken('standard-container-color', { $ref: 'sys.color.secondary' }),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <FloatingToolbar aria-label="Outer">
          <button type="button">One</button>
        </FloatingToolbar>
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <FloatingToolbar aria-label="Inner">
            <button type="button">Two</button>
          </FloatingToolbar>
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen
        .getByTestId('outer')
        .style.getPropertyValue('--m3e-comp-floating-toolbar-standard-container-color'),
    ).toBe('var(--m3e-sys-color-tertiary)')
    expect(
      screen
        .getByTestId('inner')
        .style.getPropertyValue('--m3e-comp-floating-toolbar-standard-container-color'),
    ).toBe('var(--m3e-sys-color-secondary)')
  })
})

// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import {
  Material3Provider,
  Surface,
  createTheme,
  defaultTheme,
} from '../../../src'

afterEach(cleanup)

describe('Surface theme integration', () => {
  it('inherits a custom system color from its scoped provider', () => {
    const theme = createTheme({
      colorSchemes: { light: { surface: { $ref: 'ref.palette.primary-95' } } },
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="light">
        <Surface data-testid="surface">Custom</Surface>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-sys-color-surface'),
    ).toBe('var(--m3e-ref-palette-primary-95)')
    expect(screen.getByTestId('surface').getAttribute('data-m3e-color')).toBe('surface')
  })

  it('supports a scoped component-token override without runtime style injection', () => {
    const surfaceTokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'surface',
    )!
    const theme = createTheme({
      componentTokens: [
        {
          ...surfaceTokens,
          tokens: {
            ...surfaceTokens.tokens,
            'container-color': { kind: 'color', value: '#123456' },
          },
        },
      ],
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <Surface>Component override</Surface>
      </Material3Provider>,
    )

    expect(
      screen
        .getByTestId('provider')
        .style.getPropertyValue('--m3e-comp-surface-container-color'),
    ).toBe('#123456')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested theme overrides on their own provider scopes', () => {
    const outerTheme = createTheme({ density: { scale: -1 } })
    const innerTheme = createTheme({
      colorSchemes: { dark: { surfaceContainer: { $ref: 'ref.palette.neutral-20' } } },
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="dark">
        <Surface>
          <Material3Provider data-testid="inner" theme={innerTheme} colorMode="dark">
            <Surface color="surface-container">Nested</Surface>
          </Material3Provider>
        </Surface>
      </Material3Provider>,
    )

    expect(screen.getByTestId('outer').style.getPropertyValue('--m3e-sys-density-scale')).toBe('-1')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-sys-color-surface-container'),
    ).toBe('var(--m3e-ref-palette-neutral-20)')
    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-sys-color-surface-container'),
    ).toBe('')
  })
})

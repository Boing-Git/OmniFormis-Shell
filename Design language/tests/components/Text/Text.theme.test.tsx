// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { Material3Provider, Text, createTheme } from '../../../src'

afterEach(cleanup)

describe('Text theme integration', () => {
  it('selects custom baseline typography from its scoped provider', () => {
    const theme = createTheme({
      typography: {
        baseline: {
          bodyLarge: {
            fontSize: '1.125rem',
            lineHeight: '1.75rem',
            letterSpacing: '0rem',
            axes: { ROND: 75, wdth: 96 },
          },
        },
      },
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="light">
        <Text data-testid="text">Custom baseline</Text>
      </Material3Provider>,
    )

    const provider = screen.getByTestId('provider')
    expect(
      provider.style.getPropertyValue('--m3e-sys-typescale-baseline-body-large-font-size'),
    ).toBe('1.125rem')
    expect(
      provider.style.getPropertyValue('--m3e-sys-typescale-baseline-body-large-axes-rond'),
    ).toBe('75')
    expect(screen.getByTestId('text').getAttribute('data-m3e-variant')).toBe('bodyLarge')
  })

  it('selects the independently themeable Expressive emphasized scale', () => {
    const theme = createTheme({
      reference: { typeface: { brand: ['Recursive', 'sans-serif'] } },
      typography: {
        emphasized: {
          displayLarge: {
            fontFamily: { $ref: 'ref.typeface.brand' },
            fontWeight: { $ref: 'ref.typeface.weight.bold' },
            axes: { GRAD: 120, ROND: 100, wght: 700 },
          },
        },
      },
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <Text variant="displayLarge" emphasis="emphasized">Expressive</Text>
      </Material3Provider>,
    )

    const provider = screen.getByTestId('provider')
    expect(provider.style.getPropertyValue('--m3e-ref-typeface-brand')).toBe(
      '"Recursive", sans-serif',
    )
    expect(
      provider.style.getPropertyValue(
        '--m3e-sys-typescale-emphasized-display-large-font-weight',
      ),
    ).toBe('var(--m3e-ref-typeface-weight-bold)')
    expect(
      provider.style.getPropertyValue('--m3e-sys-typescale-emphasized-display-large-axes-grad'),
    ).toBe('120')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested typography overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      typography: { baseline: { bodySmall: { fontSize: '0.8125rem' } } },
    })
    const innerTheme = createTheme({
      typography: { emphasized: { bodySmall: { fontSize: '0.9375rem' } } },
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <Text variant="bodySmall">Outer</Text>
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <Text variant="bodySmall" emphasis="emphasized">Inner</Text>
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue(
        '--m3e-sys-typescale-baseline-body-small-font-size',
      ),
    ).toBe('0.8125rem')
    expect(
      screen.getByTestId('outer').style.getPropertyValue(
        '--m3e-sys-typescale-emphasized-body-small-font-size',
      ),
    ).toBe('')
    expect(
      screen.getByTestId('inner').style.getPropertyValue(
        '--m3e-sys-typescale-emphasized-body-small-font-size',
      ),
    ).toBe('0.9375rem')
  })
})

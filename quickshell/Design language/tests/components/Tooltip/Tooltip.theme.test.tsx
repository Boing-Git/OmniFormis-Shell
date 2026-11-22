// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { useRef } from 'react'
import { afterEach } from 'vitest'
import { Material3Provider, Tooltip, createTheme, defaultTheme } from '../../../src'

afterEach(cleanup)

function withTooltipToken(name: string, value: number | string | { $ref: string }) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'tooltip'
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

function Anchored() {
  const anchorRef = useRef<HTMLButtonElement>(null)
  return (
    <>
      <button type="button" ref={anchorRef}>
        Save
      </button>
      <Tooltip anchorRef={anchorRef} content="Save the document" open onOpenChange={() => undefined} />
    </>
  )
}

describe('Tooltip theme integration', () => {
  it('ships the sourced plain/rich geometry and color defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'tooltip',
    )?.tokens

    expect(tokens?.['plain-container-color'].value).toEqual({ $ref: 'sys.color.inverseSurface' })
    expect(tokens?.['plain-container-shape'].value).toEqual({
      $ref: 'sys.shape.corners.cornerExtraSmall',
    })
    expect(tokens?.['rich-container-color'].value).toEqual({ $ref: 'sys.color.surfaceContainer' })
    expect(tokens?.['rich-container-shape'].value).toEqual({ $ref: 'sys.shape.corners.cornerMedium' })
    expect(tokens?.['plain-max-width'].value).toBe('200px')
    expect(tokens?.['rich-max-width'].value).toBe('320px')
  })

  it('supports scoped Tooltip token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withTooltipToken('plain-max-width', '240px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <Anchored />
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-tooltip-plain-max-width'),
    ).toBe('240px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested Tooltip overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withTooltipToken('plain-container-color', { $ref: 'sys.color.tertiary' }),
    })
    const innerTheme = createTheme({
      componentTokens: withTooltipToken('plain-container-color', { $ref: 'sys.color.secondary' }),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <Anchored />
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <Anchored />
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-tooltip-plain-container-color'),
    ).toBe('var(--m3e-sys-color-tertiary)')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-tooltip-plain-container-color'),
    ).toBe('var(--m3e-sys-color-secondary)')
  })
})

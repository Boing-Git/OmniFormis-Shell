// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { useRef } from 'react'
import { afterEach } from 'vitest'
import { Material3Provider, Menu, createTheme, defaultTheme } from '../../../src'
import type { MenuItem } from '../../../src/components/Menu'

afterEach(cleanup)

const items: MenuItem[] = [{ value: 'copy', label: 'Copy' }]

function withMenuToken(name: string, value: number | string | { $ref: string }) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'menu'
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
        Actions
      </button>
      <Menu anchorRef={anchorRef} items={items} open onOpenChange={() => undefined} />
    </>
  )
}

describe('Menu theme integration', () => {
  it('ships the sourced geometry and color defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'menu',
    )?.tokens

    expect(tokens?.['container-color'].value).toEqual({ $ref: 'sys.color.surfaceContainer' })
    expect(tokens?.['container-shape'].value).toEqual({ $ref: 'sys.shape.corners.cornerExtraSmall' })
    expect(tokens?.['container-min-width'].value).toBe('112px')
    expect(tokens?.['container-max-width'].value).toBe('280px')
    expect(tokens?.['item-min-height'].value).toBe('48px')
    expect(tokens?.['item-checked-container-color'].value).toEqual({
      $ref: 'sys.color.tertiaryContainer',
    })
  })

  it('supports scoped Menu token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withMenuToken('container-max-width', '320px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <Anchored />
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-menu-container-max-width'),
    ).toBe('320px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested Menu overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withMenuToken('container-color', { $ref: 'sys.color.tertiaryContainer' }),
    })
    const innerTheme = createTheme({
      componentTokens: withMenuToken('container-color', { $ref: 'sys.color.secondaryContainer' }),
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
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-menu-container-color'),
    ).toBe('var(--m3e-sys-color-tertiary-container)')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-menu-container-color'),
    ).toBe('var(--m3e-sys-color-secondary-container)')
  })
})

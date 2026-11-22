// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { SplitButton } from '../../../src/components/SplitButton'
import { Material3Provider, createTheme, defaultTheme } from '../../../src'

afterEach(cleanup)

function withSplitButtonToken(name: string, value: number | string | { $ref: string }) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'split-button'
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

describe('SplitButton theme integration', () => {
  it('ships the sourced per-size and variant defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'split-button',
    )?.tokens

    expect(tokens?.['between-space'].value).toBe('2px')
    expect(tokens?.['small-container-height'].value).toBe('40px')
    expect(tokens?.['extra-large-container-height'].value).toBe('136px')
    expect(tokens?.['filled-container-color'].value).toEqual({ $ref: 'sys.color.primary' })
    expect(tokens?.['outlined-outline-color'].value).toEqual({ $ref: 'sys.color.outlineVariant' })
  })

  it('supports scoped SplitButton token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withSplitButtonToken('small-container-height', '48px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <SplitButton trailingIcon={<svg />} trailingLabel="More options">
          Save
        </SplitButton>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-split-button-small-container-height'),
    ).toBe('48px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested SplitButton overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withSplitButtonToken('filled-container-color', { $ref: 'sys.color.tertiary' }),
    })
    const innerTheme = createTheme({
      componentTokens: withSplitButtonToken('filled-container-color', { $ref: 'sys.color.secondary' }),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <SplitButton trailingIcon={<svg />} trailingLabel="Outer options">
          Outer
        </SplitButton>
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <SplitButton trailingIcon={<svg />} trailingLabel="Inner options">
            Inner
          </SplitButton>
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('outer').style.getPropertyValue('--m3e-comp-split-button-filled-container-color'),
    ).toBe('var(--m3e-sys-color-tertiary)')
    expect(
      screen.getByTestId('inner').style.getPropertyValue('--m3e-comp-split-button-filled-container-color'),
    ).toBe('var(--m3e-sys-color-secondary)')
  })
})

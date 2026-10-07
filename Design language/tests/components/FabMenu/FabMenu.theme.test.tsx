// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { FabMenu, FabMenuItem } from '../../../src/components/FabMenu'
import { Material3Provider, createTheme, defaultTheme } from '../../../src'

afterEach(cleanup)

function withFabMenuToken(name: string, value: number | string | { $ref: string }) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'fab-menu'
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

describe('FabMenu theme integration', () => {
  it('ships the sourced geometry and color defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'fab-menu',
    )?.tokens

    expect(tokens?.['trigger-size'].value).toBe('56px')
    expect(tokens?.['trigger-container-color-collapsed'].value).toEqual({
      $ref: 'sys.color.primaryContainer',
    })
    expect(tokens?.['trigger-container-color-expanded'].value).toEqual({ $ref: 'sys.color.primary' })
    expect(tokens?.['item-height'].value).toBe('56px')
  })

  it('supports scoped FabMenu token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withFabMenuToken('trigger-size', '64px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <FabMenu triggerLabel="Create" icon={<svg />} closeIcon={<svg />}>
          <FabMenuItem icon={<svg />}>Edit</FabMenuItem>
        </FabMenu>
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-fab-menu-trigger-size'),
    ).toBe('64px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested FabMenu overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withFabMenuToken('trigger-container-color-collapsed', { $ref: 'sys.color.tertiary' }),
    })
    const innerTheme = createTheme({
      componentTokens: withFabMenuToken('trigger-container-color-collapsed', { $ref: 'sys.color.secondary' }),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <FabMenu triggerLabel="Outer" icon={<svg />} closeIcon={<svg />}>
          <FabMenuItem icon={<svg />}>Edit</FabMenuItem>
        </FabMenu>
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <FabMenu triggerLabel="Inner" icon={<svg />} closeIcon={<svg />}>
            <FabMenuItem icon={<svg />}>Edit</FabMenuItem>
          </FabMenu>
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen
        .getByTestId('outer')
        .style.getPropertyValue('--m3e-comp-fab-menu-trigger-container-color-collapsed'),
    ).toBe('var(--m3e-sys-color-tertiary)')
    expect(
      screen
        .getByTestId('inner')
        .style.getPropertyValue('--m3e-comp-fab-menu-trigger-container-color-collapsed'),
    ).toBe('var(--m3e-sys-color-secondary)')
  })
})

// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import {
  SegmentedButtonGroup,
  Material3Provider,
  createTheme,
  defaultTheme,
} from '../../../src'

const viewSegments = [
  { value: 'day', label: 'Day' },
  { value: 'week', label: 'Week' },
] as const

afterEach(cleanup)

function withSegmentedButtonGroupToken(name: string, value: number | string) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'segmented-button-group'
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

describe('SegmentedButtonGroup theme integration', () => {
  it('ships the sourced geometry, color, and disabled defaults', () => {
    const tokens = defaultTheme.componentTokens.find(
      (registration) => registration.component === 'segmented-button-group',
    )?.tokens

    expect(tokens?.['container-height'].value).toBe('40px')
    expect(tokens?.['minimum-width'].value).toBe('58px')
    expect(tokens?.['border-width'].value).toBe('1px')
    expect(tokens?.['icon-size'].value).toBe('18px')
    expect(tokens?.['active-container-color'].value).toEqual({
      $ref: 'sys.color.secondaryContainer',
    })
    expect(tokens?.['active-content-color'].value).toEqual({
      $ref: 'sys.color.onSecondaryContainer',
    })
    expect(tokens?.['border-color'].value).toEqual({ $ref: 'sys.color.outline' })
    expect(tokens?.['disabled-content-opacity'].value).toBe(0.38)
    expect(tokens?.['disabled-border-opacity'].value).toBe(0.12)
  })

  it('supports scoped SegmentedButtonGroup token overrides without runtime style injection', () => {
    const theme = createTheme({
      componentTokens: withSegmentedButtonGroupToken('minimum-width', '72px'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="dark">
        <SegmentedButtonGroup segments={viewSegments} aria-label="View" />
      </Material3Provider>,
    )

    expect(
      screen
        .getByTestId('provider')
        .style.getPropertyValue('--m3e-comp-segmented-button-group-minimum-width'),
    ).toBe('72px')
    expect(document.querySelector('style')).toBeNull()
  })

  it('keeps nested SegmentedButtonGroup overrides on their own provider scopes', () => {
    const outerTheme = createTheme({
      componentTokens: withSegmentedButtonGroupToken('active-content-color', {
        $ref: 'sys.color.tertiary',
      }),
    })
    const innerTheme = createTheme({
      componentTokens: withSegmentedButtonGroupToken('active-content-color', {
        $ref: 'sys.color.secondary',
      }),
    })
    render(
      <Material3Provider data-testid="outer" theme={outerTheme} colorMode="light">
        <SegmentedButtonGroup segments={viewSegments} aria-label="Outer" />
        <Material3Provider data-testid="inner" theme={innerTheme} colorMode="light">
          <SegmentedButtonGroup segments={viewSegments} aria-label="Inner" />
        </Material3Provider>
      </Material3Provider>,
    )

    expect(
      screen
        .getByTestId('outer')
        .style.getPropertyValue('--m3e-comp-segmented-button-group-active-content-color'),
    ).toBe('var(--m3e-sys-color-tertiary)')
    expect(
      screen
        .getByTestId('inner')
        .style.getPropertyValue('--m3e-comp-segmented-button-group-active-content-color'),
    ).toBe('var(--m3e-sys-color-secondary)')
  })
})

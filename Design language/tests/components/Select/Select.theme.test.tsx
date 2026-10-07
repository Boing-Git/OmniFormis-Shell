// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach, beforeAll } from 'vitest'
import { Material3Provider, Select, createTheme, defaultTheme } from '../../../src'
import type { SelectOption } from '../../../src/components/Select'
import { installScrollIntoViewPolyfill } from './select-native-polyfill'

beforeAll(installScrollIntoViewPolyfill)

afterEach(cleanup)

const options: SelectOption[] = [{ value: 'apple', label: 'Apple' }]

function withTextFieldToken(name: string, value: number | string) {
  return defaultTheme.componentTokens.map((registration) =>
    registration.component === 'text-field'
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

describe('Select theme integration', () => {
  it('registers no component tokens of its own — it reuses text-field and menu', () => {
    const own = defaultTheme.componentTokens.find((registration) => registration.component === 'select')
    expect(own).toBeUndefined()
  })

  it('reflects a scoped text-field token override in its own field chrome', () => {
    const theme = createTheme({
      componentTokens: withTextFieldToken('filled-container-color', '#123456'),
    })
    render(
      <Material3Provider data-testid="provider" theme={theme} colorMode="light">
        <Select label="Fruit" options={options} />
      </Material3Provider>,
    )

    expect(
      screen.getByTestId('provider').style.getPropertyValue('--m3e-comp-text-field-filled-container-color'),
    ).toBe('#123456')
    expect(document.querySelector('style')).toBeNull()
  })
})

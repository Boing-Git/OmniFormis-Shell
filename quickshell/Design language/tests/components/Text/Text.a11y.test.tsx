// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach } from 'vitest'
import { Text } from '../../../src/components/Text'

afterEach(cleanup)

describe('Text accessibility', () => {
  it('does not turn a display role into an HTML heading', () => {
    render(<Text variant="displayLarge">Visual display text</Text>)

    expect(screen.queryByRole('heading')).toBeNull()
    expect(screen.getByText('Visual display text').tagName).toBe('SPAN')
  })

  it('keeps the selected heading level independent from a small visual role', () => {
    render(
      <Text as="h3" variant="bodySmall">
        Semantic section title
      </Text>,
    )

    const heading = screen.getByRole('heading', { level: 3, name: 'Semantic section title' })
    expect(heading.getAttribute('data-m3e-variant')).toBe('bodySmall')
  })

  it('preserves native label activation', async () => {
    const user = userEvent.setup()
    render(
      <>
        <Text as="label" htmlFor="email" variant="labelLarge">
          Email
        </Text>
        <input id="email" type="email" />
      </>,
    )

    await user.click(screen.getByText('Email'))
    expect(document.activeElement).toBe(screen.getByRole('textbox', { name: 'Email' }))
  })

  it('preserves legend naming for a native fieldset', () => {
    render(
      <fieldset>
        <Text as="legend" variant="titleSmall" emphasis="emphasized">
          Preferences
        </Text>
        <label><input type="checkbox" /> Weekly summary</label>
      </fieldset>,
    )

    expect(screen.getByRole('group', { name: 'Preferences' })).toBeInstanceOf(
      HTMLFieldSetElement,
    )
  })

  it('does not add a keyboard stop or interactive state', async () => {
    const user = userEvent.setup()
    render(
      <>
        <Text data-testid="text" emphasis="emphasized">Passive text</Text>
        <button type="button">Next</button>
      </>,
    )

    await user.tab()
    expect(document.activeElement).toBe(screen.getByRole('button', { name: 'Next' }))
    const text = screen.getByTestId('text')
    expect(text.hasAttribute('role')).toBe(false)
    expect(text.hasAttribute('aria-pressed')).toBe(false)
    expect(text.hasAttribute('aria-selected')).toBe(false)
  })
})

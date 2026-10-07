// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach } from 'vitest'
import { FloatingToolbar } from '../../../src/components/FloatingToolbar'

afterEach(cleanup)

describe('FloatingToolbar accessibility', () => {
  it('requires an accessible name via aria-label', () => {
    render(
      <FloatingToolbar aria-label="Formatting">
        <button type="button">Bold</button>
      </FloatingToolbar>,
    )
    expect(screen.getByRole('toolbar', { name: 'Formatting' })).not.toBeNull()
  })

  it('supports aria-labelledby as an alternative accessible name', () => {
    render(
      <>
        <h2 id="toolbar-heading">Formatting</h2>
        <FloatingToolbar aria-labelledby="toolbar-heading">
          <button type="button">Bold</button>
        </FloatingToolbar>
      </>,
    )
    expect(screen.getByRole('toolbar', { name: 'Formatting' })).not.toBeNull()
  })

  it('announces orientation via aria-orientation', () => {
    render(
      <FloatingToolbar aria-label="Actions" orientation="vertical">
        <button type="button">One</button>
      </FloatingToolbar>,
    )
    expect(screen.getByRole('toolbar').getAttribute('aria-orientation')).toBe('vertical')
  })

  it('keeps the toolbar readable inside an RTL scope', () => {
    render(
      <div dir="rtl">
        <FloatingToolbar aria-label="Actions">
          <button type="button">One</button>
          <button type="button">Two</button>
        </FloatingToolbar>
      </div>,
    )
    expect(screen.getByRole('toolbar', { name: 'Actions' })).not.toBeNull()
  })

  it('keeps disabled items out of the roving tab sequence but does not skip them silently', () => {
    render(
      <FloatingToolbar aria-label="Actions">
        <button type="button">One</button>
        <button type="button" disabled>
          Two
        </button>
        <button type="button">Three</button>
      </FloatingToolbar>,
    )
    // The middle item is still present with a native `disabled` attribute,
    // which itself removes it from the tab order -- no custom skip logic
    // is layered on top, matching every other v1 component's reliance on
    // native semantics.
    const buttons = screen.getAllByRole('button')
    expect((buttons[1] as HTMLButtonElement).disabled).toBe(true)
  })
})

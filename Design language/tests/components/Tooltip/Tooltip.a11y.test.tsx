// @vitest-environment jsdom

import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { useRef } from 'react'
import { afterEach } from 'vitest'
import { Tooltip } from '../../../src/components/Tooltip'

afterEach(cleanup)

function Anchored() {
  const anchorRef = useRef<HTMLButtonElement>(null)
  return (
    <>
      <button type="button" ref={anchorRef}>
        Save
      </button>
      <Tooltip anchorRef={anchorRef} content="Save the document" />
    </>
  )
}

describe('Tooltip accessibility', () => {
  it('exposes role="tooltip" with no focusable descendant', () => {
    render(<Anchored />)
    fireEvent.mouseEnter(screen.getByRole('button', { name: 'Save' }))
    const tooltip = screen.getByRole('tooltip')
    expect(tooltip.querySelector('button, a, input, select, textarea, [tabindex]')).toBeNull()
  })

  it('links the anchor to the tooltip via aria-describedby while shown', () => {
    render(<Anchored />)
    const anchor = screen.getByRole('button', { name: 'Save' })
    fireEvent.mouseEnter(anchor)
    const tooltip = screen.getByRole('tooltip')
    expect(anchor.getAttribute('aria-describedby')).toBe(tooltip.id)
  })

  it('removes aria-describedby once the anchor no longer has a shown tooltip', () => {
    render(<Anchored />)
    const anchor = screen.getByRole('button', { name: 'Save' })
    fireEvent.focus(anchor)
    expect(anchor.hasAttribute('aria-describedby')).toBe(true)
    fireEvent.blur(anchor)
    expect(anchor.hasAttribute('aria-describedby')).toBe(false)
  })

  it('keeps the tooltip readable inside an RTL scope', () => {
    render(
      <div dir="rtl">
        <Anchored />
      </div>,
    )
    fireEvent.mouseEnter(screen.getByRole('button', { name: 'Save' }))
    expect(screen.getByRole('tooltip').textContent).toBe('Save the document')
  })
})

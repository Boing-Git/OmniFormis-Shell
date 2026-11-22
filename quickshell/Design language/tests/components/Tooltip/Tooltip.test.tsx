// @vitest-environment jsdom

import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { createRef, useRef } from 'react'
import { afterEach, vi } from 'vitest'
import { Tooltip } from '../../../src/components/Tooltip'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

function Anchored({ onOpenChange }: { readonly onOpenChange?: (open: boolean) => void }) {
  const anchorRef = useRef<HTMLButtonElement>(null)
  return (
    <>
      <button type="button" ref={anchorRef}>
        Save
      </button>
      <Tooltip anchorRef={anchorRef} content="Save the document" onOpenChange={onOpenChange} />
    </>
  )
}

describe('Tooltip', () => {
  it('renders nothing until hovered, then portals role="tooltip" to document.body', () => {
    render(<Anchored />)
    expect(screen.queryByRole('tooltip')).toBeNull()

    fireEvent.mouseEnter(screen.getByRole('button', { name: 'Save' }))
    const tooltip = screen.getByRole('tooltip')
    expect(tooltip.parentElement).toBe(document.body)
    expect(tooltip.textContent).toBe('Save the document')
  })

  it('shows on mouseenter and hides on mouseleave of the anchor', () => {
    const onOpenChange = vi.fn()
    render(<Anchored onOpenChange={onOpenChange} />)
    const anchor = screen.getByRole('button', { name: 'Save' })

    fireEvent.mouseEnter(anchor)
    expect(onOpenChange).toHaveBeenCalledWith(true)
    expect(screen.getByRole('tooltip')).not.toBeNull()

    fireEvent.mouseLeave(anchor)
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('shows on focus and hides on blur of the anchor', () => {
    const onOpenChange = vi.fn()
    render(<Anchored onOpenChange={onOpenChange} />)
    const anchor = screen.getByRole('button', { name: 'Save' })

    fireEvent.focus(anchor)
    expect(onOpenChange).toHaveBeenCalledWith(true)

    fireEvent.blur(anchor)
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('stays open when the pointer moves from the anchor onto the popover itself', () => {
    const onOpenChange = vi.fn()
    render(<Anchored onOpenChange={onOpenChange} />)
    const anchor = screen.getByRole('button', { name: 'Save' })

    fireEvent.mouseEnter(anchor)
    onOpenChange.mockClear()
    fireEvent.mouseEnter(screen.getByRole('tooltip'))
    fireEvent.mouseLeave(anchor)
    expect(onOpenChange).not.toHaveBeenCalledWith(false)

    fireEvent.mouseLeave(screen.getByRole('tooltip'))
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('Escape closes the tooltip', () => {
    const onOpenChange = vi.fn()
    render(<Anchored onOpenChange={onOpenChange} />)
    fireEvent.mouseEnter(screen.getByRole('button', { name: 'Save' }))
    fireEvent.keyDown(document, { key: 'Escape' })
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('sets aria-describedby on the anchor only while mounted, merging with an existing value', () => {
    function AnchoredWithDescribedBy() {
      const anchorRef = useRef<HTMLButtonElement>(null)
      return (
        <>
          <button type="button" ref={anchorRef} aria-describedby="existing-hint">
            Save
          </button>
          <span id="existing-hint">Existing hint</span>
          <Tooltip anchorRef={anchorRef} content="Save the document" />
        </>
      )
    }
    render(<AnchoredWithDescribedBy />)
    const anchor = screen.getByRole('button', { name: 'Save' })
    expect(anchor.getAttribute('aria-describedby')).toBe('existing-hint')

    fireEvent.mouseEnter(anchor)
    const tooltip = screen.getByRole('tooltip')
    expect(anchor.getAttribute('aria-describedby')).toBe(`existing-hint ${tooltip.id}`)

    fireEvent.mouseLeave(anchor)
  })

  it('renders a rich tooltip with a subhead above the content, both non-interactive', () => {
    const anchorRef = createRef<HTMLButtonElement>()
    render(
      <>
        <button type="button" ref={anchorRef}>
          Info
        </button>
        <Tooltip
          anchorRef={anchorRef}
          variant="rich"
          subhead="Storage"
          content="12 of 15 GB used"
          open
          onOpenChange={() => undefined}
        />
      </>,
    )
    const tooltip = screen.getByRole('tooltip')
    expect(tooltip.className).toContain('m3e-tooltip--rich')
    expect(tooltip.textContent).toBe('Storage12 of 15 GB used')
    expect(tooltip.querySelector('button, a, input, [tabindex]')).toBeNull()
  })

  it('supports uncontrolled defaultOpen', () => {
    const anchorRef = createRef<HTMLButtonElement>()
    render(
      <>
        <button type="button" ref={anchorRef}>
          Save
        </button>
        <Tooltip anchorRef={anchorRef} content="Save the document" defaultOpen />
      </>,
    )
    expect(screen.getByRole('tooltip')).not.toBeNull()
  })

  it('forwards ref, className, and style to the popover root', () => {
    const ref = createRef<HTMLDivElement>()
    const anchorRef = createRef<HTMLButtonElement>()
    render(
      <>
        <button type="button" ref={anchorRef}>
          Save
        </button>
        <Tooltip
          ref={ref}
          anchorRef={anchorRef}
          content="Save the document"
          open
          onOpenChange={() => undefined}
          className="consumer-class"
          data-owner="consumer"
        />
      </>,
    )
    const tooltip = screen.getByRole('tooltip')
    expect(ref.current).toBe(tooltip)
    expect(tooltip.className).toContain('m3e-tooltip')
    expect(tooltip.className).toContain('consumer-class')
    expect(tooltip.getAttribute('data-owner')).toBe('consumer')
  })

  it('exposes a stable component name for React tooling', () => {
    expect(Tooltip.displayName).toBe('Tooltip')
  })
})

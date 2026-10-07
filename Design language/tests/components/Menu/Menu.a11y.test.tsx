// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { createRef, useRef } from 'react'
import { afterEach } from 'vitest'
import { Menu } from '../../../src/components/Menu'
import type { MenuItem } from '../../../src/components/Menu'

afterEach(cleanup)

const items: MenuItem[] = [
  { value: 'copy', label: 'Copy' },
  { value: 'paste', label: 'Paste' },
]

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

describe('Menu accessibility', () => {
  it('exposes role="menu" with role="menuitem" children in display order', () => {
    render(<Anchored />)
    const menu = screen.getByRole('menu')
    const children = screen.getAllByRole('menuitem')
    expect(children.map((child) => child.textContent)).toEqual(['Copy', 'Paste'])
    expect(menu.contains(children[0])).toBe(true)
  })

  it('renders a checkable item as role="menuitemcheckbox" with aria-checked', () => {
    const anchorRef = createRef<HTMLButtonElement>()
    render(
      <>
        <button type="button" ref={anchorRef}>
          Actions
        </button>
        <Menu
          anchorRef={anchorRef}
          items={[{ value: 'wrap', label: 'Word wrap', checked: true }]}
          open
          onOpenChange={() => undefined}
        />
      </>,
    )
    const item = screen.getByRole('menuitemcheckbox', { name: 'Word wrap' })
    expect(item.getAttribute('aria-checked')).toBe('true')
  })

  it('marks a disabled item with aria-disabled and excludes it from the tab order', () => {
    const anchorRef = createRef<HTMLButtonElement>()
    render(
      <>
        <button type="button" ref={anchorRef}>
          Actions
        </button>
        <Menu
          anchorRef={anchorRef}
          items={[
            { value: 'a', label: 'A' },
            { value: 'b', label: 'B', disabled: true },
          ]}
          open
          onOpenChange={() => undefined}
        />
      </>,
    )
    const disabledItem = screen.getByRole('menuitem', { name: 'B' })
    expect(disabledItem.getAttribute('aria-disabled')).toBe('true')
    expect(disabledItem.getAttribute('tabindex')).toBe('-1')
  })

  it('keeps the menu readable inside an RTL scope', () => {
    render(
      <div dir="rtl">
        <Anchored />
      </div>,
    )
    expect(screen.getByRole('menu')).not.toBeNull()
    expect(screen.getByRole('menuitem', { name: 'Copy' })).not.toBeNull()
  })

  it('renders no accessible name requirement of its own — the consumer trigger owns aria-haspopup/aria-expanded', () => {
    // Menu is trigger-agnostic (see ADR 0017/Dialog precedent): it neither
    // renders nor requires a specific trigger shape, so this only documents
    // that role="menu" needs no separate accessible-name prop from Menu
    // itself for the menu surface to be valid.
    render(<Anchored />)
    expect(screen.getByRole('menu').hasAttribute('aria-label')).toBe(false)
  })
})

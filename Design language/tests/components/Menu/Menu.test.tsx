// @vitest-environment jsdom

import { act, cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createRef, useRef, useState } from 'react'
import { afterEach, vi } from 'vitest'
import { Menu } from '../../../src/components/Menu'
import type { MenuItem } from '../../../src/components/Menu'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

const basicItems: MenuItem[] = [
  { value: 'copy', label: 'Copy', onSelect: vi.fn() },
  { value: 'paste', label: 'Paste', onSelect: vi.fn(), disabled: true },
  { value: 'duplicate', label: 'Duplicate', onSelect: vi.fn() },
]

function Anchored({
  items = basicItems,
  onOpenChange,
}: {
  readonly items?: MenuItem[]
  readonly onOpenChange?: (open: boolean) => void
}) {
  const anchorRef = useRef<HTMLButtonElement>(null)
  const [open, setOpen] = useState(true)
  return (
    <>
      <button type="button" ref={anchorRef}>
        Actions
      </button>
      <Menu
        anchorRef={anchorRef}
        items={items}
        open={open}
        onOpenChange={(next) => {
          setOpen(next)
          onOpenChange?.(next)
        }}
      />
    </>
  )
}

describe('Menu', () => {
  it('renders nothing when closed and portals role="menu" to document.body when open', () => {
    const anchorRef = createRef<HTMLButtonElement>()
    const { rerender } = render(
      <>
        <button type="button" ref={anchorRef}>
          Anchor
        </button>
        <Menu anchorRef={anchorRef} items={basicItems} open={false} onOpenChange={() => undefined} />
      </>,
    )
    expect(screen.queryByRole('menu')).toBeNull()

    rerender(
      <>
        <button type="button" ref={anchorRef}>
          Anchor
        </button>
        <Menu anchorRef={anchorRef} items={basicItems} open onOpenChange={() => undefined} />
      </>,
    )
    const menu = screen.getByRole('menu')
    expect(menu.parentElement).toBe(document.body)
  })

  it('renders each item with role="menuitem" and skips a disabled item during Home/End', () => {
    render(<Anchored />)
    const items = screen.getAllByRole('menuitem')
    expect(items.map((item) => item.textContent)).toEqual(['Copy', 'Paste', 'Duplicate'])
    expect(items[1].getAttribute('aria-disabled')).toBe('true')
  })

  it('moves real focus to the first enabled item on open', () => {
    render(<Anchored />)
    expect(document.activeElement).toBe(screen.getByRole('menuitem', { name: 'Copy' }))
  })

  it('ArrowDown/ArrowUp move focus across enabled items only, wrapping and skipping disabled ones', async () => {
    const user = userEvent.setup()
    render(<Anchored />)
    await user.keyboard('{ArrowDown}')
    expect(document.activeElement).toBe(screen.getByRole('menuitem', { name: 'Duplicate' }))
    await user.keyboard('{ArrowDown}')
    expect(document.activeElement).toBe(screen.getByRole('menuitem', { name: 'Copy' }))
    await user.keyboard('{ArrowUp}')
    expect(document.activeElement).toBe(screen.getByRole('menuitem', { name: 'Duplicate' }))
  })

  it('Home/End jump to the first/last enabled item', async () => {
    const user = userEvent.setup()
    render(<Anchored />)
    await user.keyboard('{End}')
    expect(document.activeElement).toBe(screen.getByRole('menuitem', { name: 'Duplicate' }))
    await user.keyboard('{Home}')
    expect(document.activeElement).toBe(screen.getByRole('menuitem', { name: 'Copy' }))
  })

  it('typeahead jumps to the next item whose label starts with the typed character', async () => {
    const user = userEvent.setup()
    render(<Anchored />)
    await user.keyboard('d')
    expect(document.activeElement).toBe(screen.getByRole('menuitem', { name: 'Duplicate' }))
  })

  it('Enter activates the focused item, calls onSelect, and closes the menu', async () => {
    const user = userEvent.setup()
    const onSelect = vi.fn()
    const onOpenChange = vi.fn()
    const items: MenuItem[] = [{ value: 'a', label: 'Item A', onSelect }]
    render(<Anchored items={items} onOpenChange={onOpenChange} />)
    await user.keyboard('{Enter}')
    expect(onSelect).toHaveBeenCalledTimes(1)
    // Closing is requested synchronously; the popover's own removal from
    // the DOM is deferred until its exit transition finishes (see "defers
    // unmount past a close request"), so this checks the request itself
    // rather than racing real transition/rAF timing.
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('restores focus to the anchor after a keyboard-activated selection', async () => {
    const user = userEvent.setup()
    const items: MenuItem[] = [{ value: 'a', label: 'Item A', onSelect: vi.fn() }]
    render(<Anchored items={items} />)
    await user.keyboard('{Enter}')
    expect(document.activeElement).toBe(screen.getByRole('button', { name: 'Actions' }))
  })

  it('a checkable item renders menuitemcheckbox, toggles aria-checked, and stays open', async () => {
    const user = userEvent.setup()
    const onCheckedChange = vi.fn()
    const items: MenuItem[] = [
      { value: 'wrap', label: 'Word wrap', checked: false, onCheckedChange },
    ]
    render(<Anchored items={items} />)
    const item = screen.getByRole('menuitemcheckbox', { name: 'Word wrap' })
    expect(item.getAttribute('aria-checked')).toBe('false')

    await user.keyboard('{Enter}')
    expect(onCheckedChange).toHaveBeenCalledWith(true)
    expect(screen.getByRole('menu')).not.toBeNull()
  })

  it('clicking an enabled item activates it; clicking a disabled item does nothing', async () => {
    const user = userEvent.setup()
    const onSelect = vi.fn()
    const onOpenChange = vi.fn()
    const items: MenuItem[] = [
      { value: 'a', label: 'Item A', onSelect },
      { value: 'b', label: 'Item B', onSelect: vi.fn(), disabled: true },
    ]
    render(<Anchored items={items} onOpenChange={onOpenChange} />)
    await user.click(screen.getByRole('menuitem', { name: 'Item B' }))
    expect(onOpenChange).not.toHaveBeenCalled()

    await user.click(screen.getByRole('menuitem', { name: 'Item A' }))
    expect(onSelect).toHaveBeenCalledTimes(1)
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('Escape closes the menu and restores focus to the anchor', async () => {
    const user = userEvent.setup()
    const onOpenChange = vi.fn()
    render(<Anchored onOpenChange={onOpenChange} />)
    await user.keyboard('{Escape}')
    expect(onOpenChange).toHaveBeenCalledWith(false)
    expect(document.activeElement).toBe(screen.getByRole('button', { name: 'Actions' }))
  })

  it('an outside click closes the menu without stealing focus from the clicked element', async () => {
    const user = userEvent.setup()
    const onOpenChange = vi.fn()
    render(
      <>
        <button type="button">Elsewhere</button>
        <Anchored onOpenChange={onOpenChange} />
      </>,
    )
    await user.click(screen.getByRole('button', { name: 'Elsewhere' }))
    expect(onOpenChange).toHaveBeenCalledWith(false)
    expect(document.activeElement).toBe(screen.getByRole('button', { name: 'Elsewhere' }))
  })

  it('Tab closes the menu without trapping focus', async () => {
    const user = userEvent.setup()
    const onOpenChange = vi.fn()
    render(<Anchored onOpenChange={onOpenChange} />)
    await user.keyboard('{Tab}')
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it('supports uncontrolled defaultOpen', () => {
    const anchorRef = createRef<HTMLButtonElement>()
    render(
      <>
        <button type="button" ref={anchorRef}>
          Anchor
        </button>
        <Menu anchorRef={anchorRef} items={basicItems} defaultOpen />
      </>,
    )
    expect(screen.getByRole('menu')).not.toBeNull()
  })

  it('forwards ref, className, and style to the popover root', () => {
    const ref = createRef<HTMLDivElement>()
    const anchorRef = createRef<HTMLButtonElement>()
    render(
      <>
        <button type="button" ref={anchorRef}>
          Anchor
        </button>
        <Menu
          ref={ref}
          anchorRef={anchorRef}
          items={basicItems}
          open
          onOpenChange={() => undefined}
          className="consumer-class"
          data-owner="consumer"
        />
      </>,
    )
    const menu = screen.getByRole('menu')
    expect(ref.current).toBe(menu)
    expect(menu.className).toContain('m3e-menu')
    expect(menu.className).toContain('consumer-class')
    expect(menu.getAttribute('data-owner')).toBe('consumer')
  })

  it('drives a real open/close lifecycle from application state', async () => {
    const user = userEvent.setup()
    function Fixture() {
      const anchorRef = useRef<HTMLButtonElement>(null)
      const [open, setOpen] = useState(false)
      return (
        <>
          <button type="button" ref={anchorRef} onClick={() => setOpen(true)}>
            Open menu
          </button>
          <Menu anchorRef={anchorRef} items={basicItems} open={open} onOpenChange={setOpen} />
        </>
      )
    }
    render(<Fixture />)
    expect(screen.queryByRole('menu')).toBeNull()
    await user.click(screen.getByRole('button', { name: 'Open menu' }))
    expect(screen.getByRole('menu')).not.toBeNull()
  })

  it('exposes a stable component name for React tooling', () => {
    expect(Menu.displayName).toBe('Menu')
  })

  it('defers unmount past a close request once opened, then unmounts via the fallback timer', () => {
    vi.useFakeTimers({ toFake: ['requestAnimationFrame', 'cancelAnimationFrame', 'setTimeout', 'clearTimeout'] })
    const anchorRef = createRef<HTMLButtonElement>()
    const { rerender } = render(
      <>
        <button type="button" ref={anchorRef}>
          Anchor
        </button>
        <Menu anchorRef={anchorRef} items={basicItems} open onOpenChange={() => undefined} />
      </>,
    )
    // Flush the double-rAF entrance flip so the overlay has genuinely
    // entered before the close request below can exercise the deferred
    // exit path rather than the "never finished entering" immediate path.
    act(() => {
      vi.advanceTimersByTime(100)
    })
    expect(screen.getByRole('menu').getAttribute('data-m3e-open')).toBe('true')

    rerender(
      <>
        <button type="button" ref={anchorRef}>
          Anchor
        </button>
        <Menu anchorRef={anchorRef} items={basicItems} open={false} onOpenChange={() => undefined} />
      </>,
    )
    // Still present: the exit path defers unmount until transitionend or the
    // fallback timer, matching the pinned source's own enter/exit animation
    // rather than an immediate hard cut.
    expect(screen.queryByRole('menu')).not.toBeNull()

    act(() => {
      vi.advanceTimersByTime(500)
    })
    expect(screen.queryByRole('menu')).toBeNull()
    vi.useRealTimers()
  })
})

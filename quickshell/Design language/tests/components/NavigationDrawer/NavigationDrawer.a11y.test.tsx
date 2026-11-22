// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { afterEach, beforeAll } from 'vitest'
import { NavigationDrawer } from '../../../src/components/NavigationDrawer'
import type { NavigationItem } from '../../../src/components/NavigationDrawer'
import { installDialogPolyfill } from '../Dialog/dialog-native-polyfill'

beforeAll(installDialogPolyfill)
afterEach(cleanup)

const items: NavigationItem[] = [
  { value: 'inbox', label: 'Inbox', icon: <span /> },
  { value: 'trash', label: 'Trash', icon: <span />, disabled: true },
]

describe('NavigationDrawer accessibility', () => {
  it('renders a nav landmark, with an accessible name when supplied', () => {
    render(<NavigationDrawer items={items} variant="permanent" aria-label="Mail folders" />)
    expect(screen.getByRole('navigation', { name: 'Mail folders' })).not.toBeNull()
  })

  it('marks the selected item with aria-current="page"', () => {
    render(<NavigationDrawer items={items} variant="permanent" />)
    expect(screen.getByRole('button', { name: 'Inbox' }).getAttribute('aria-current')).toBe('page')
  })

  it('marks a disabled item with aria-disabled', () => {
    render(<NavigationDrawer items={items} variant="permanent" />)
    expect(screen.getByRole('button', { name: 'Trash' }).getAttribute('aria-disabled')).toBe('true')
  })

  it('gives the modal variant a native dialog element for focus containment', () => {
    render(<NavigationDrawer items={items} variant="modal" open onOpenChange={() => undefined} />)
    expect(document.querySelector('dialog')).not.toBeNull()
  })

  it('keeps items readable inside an RTL scope', () => {
    render(
      <div dir="rtl">
        <NavigationDrawer items={items} variant="permanent" />
      </div>,
    )
    expect(screen.getByRole('button', { name: 'Inbox' })).not.toBeNull()
  })
})

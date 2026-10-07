import { createRef } from 'react'
import { NavigationDrawer } from '../../../src/components/NavigationDrawer'
import type { NavigationItem } from '../../../src/components/NavigationDrawer'

const navRef = createRef<HTMLElement>()

const items: NavigationItem[] = [
  { value: 'inbox', label: 'Inbox', icon: <span /> },
  { value: 'trash', label: 'Trash', icon: <span />, disabled: true },
]

;<NavigationDrawer ref={navRef} items={items} variant="permanent" />
;<NavigationDrawer items={items} variant="dismissible" open onOpenChange={(open) => open} />
;<NavigationDrawer items={items} variant="modal" defaultOpen onOpenChange={(open) => open} />
;<NavigationDrawer items={items} defaultValue="trash" onValueChange={(value) => value} />

// @ts-expect-error items is required
;<NavigationDrawer />

// @ts-expect-error variant must be one of the known values
;<NavigationDrawer items={items} variant="floating" />

// @ts-expect-error onOpenChange must accept a boolean, not a string
;<NavigationDrawer items={items} onOpenChange={(open: string) => open} />

// @ts-expect-error NavigationDrawer renders no children of its own — items own their content
;<NavigationDrawer items={items}>
  <span />
</NavigationDrawer>

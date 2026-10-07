import { createRef } from 'react'
import { NavigationBar } from '../../../src/components/NavigationBar'
import type { NavigationItem } from '../../../src/components/NavigationBar'

const navRef = createRef<HTMLElement>()

const items: NavigationItem[] = [
  { value: 'home', label: 'Home', icon: <span />, selectedIcon: <span /> },
  { value: 'search', label: 'Search', icon: <span />, disabled: true },
  { value: 'link', label: 'External', icon: <span />, href: '/external' },
]

;<NavigationBar ref={navRef} items={items} />
;<NavigationBar items={items} defaultValue="search" onValueChange={(value) => value} />

// @ts-expect-error items is required
;<NavigationBar />

// @ts-expect-error onValueChange must accept a string, not a number
;<NavigationBar items={items} onValueChange={(value: number) => value} />

// @ts-expect-error NavigationBar renders no children of its own — items own their content
;<NavigationBar items={items}>
  <span />
</NavigationBar>

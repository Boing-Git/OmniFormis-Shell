import { createRef } from 'react'
import { NavigationRail } from '../../../src/components/NavigationRail'
import type { NavigationItem } from '../../../src/components/NavigationRail'

const navRef = createRef<HTMLElement>()

const items: NavigationItem[] = [
  { value: 'home', label: 'Home', icon: <span /> },
  { value: 'search', label: 'Search', icon: <span />, disabled: true },
]

;<NavigationRail ref={navRef} items={items} />
;<NavigationRail items={items} header={<span />} defaultValue="search" onValueChange={(value) => value} />

// @ts-expect-error items is required
;<NavigationRail />

// @ts-expect-error onValueChange must accept a string, not a number
;<NavigationRail items={items} onValueChange={(value: number) => value} />

// @ts-expect-error NavigationRail renders no children of its own — items own their content
;<NavigationRail items={items}>
  <span />
</NavigationRail>

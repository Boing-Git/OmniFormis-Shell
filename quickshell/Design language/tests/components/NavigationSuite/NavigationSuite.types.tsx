import { createRef } from 'react'
import { NavigationSuite } from '../../../src/components/NavigationSuite'
import type { NavigationItem } from '../../../src/components/NavigationSuite'

const suiteRef = createRef<HTMLDivElement>()

const items: NavigationItem[] = [
  { value: 'home', label: 'Home', icon: <span /> },
  { value: 'search', label: 'Search', icon: <span />, disabled: true },
]

;<NavigationSuite ref={suiteRef} items={items} />
;<NavigationSuite items={items} header={<span />} defaultValue="search" onValueChange={(value) => value} />

// @ts-expect-error items is required
;<NavigationSuite />

// @ts-expect-error onValueChange must accept a string, not a number
;<NavigationSuite items={items} onValueChange={(value: number) => value} />

// @ts-expect-error NavigationSuite renders no children of its own — items own their content
;<NavigationSuite items={items}>
  <span />
</NavigationSuite>

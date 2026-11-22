import { createRef } from 'react'
import { Tabs } from '../../../src/components/Tabs'
import type { TabItem } from '../../../src/components/Tabs'

const tabsRef = createRef<HTMLDivElement>()

const items: TabItem[] = [
  { value: 'photos', label: 'Photos', icon: <span />, panel: <div /> },
  { value: 'shared', label: 'Shared', disabled: true },
  { value: 'link', label: 'External', href: '/external' },
]

;<Tabs ref={tabsRef} aria-label="Library" items={items} />
;<Tabs aria-label="Library" items={items} variant="secondary" scrollable />
;<Tabs
  aria-label="Library"
  items={items}
  defaultValue="shared"
  onValueChange={(value) => value}
/>

// @ts-expect-error items is required
;<Tabs aria-label="Library" />

// @ts-expect-error onValueChange must accept a string, not a number
;<Tabs aria-label="Library" items={items} onValueChange={(value: number) => value} />

// @ts-expect-error variant must be one of the known values
;<Tabs aria-label="Library" items={items} variant="tertiary" />

// @ts-expect-error Tabs renders no children of its own — items own their content
;<Tabs aria-label="Library" items={items}>
  <span />
</Tabs>

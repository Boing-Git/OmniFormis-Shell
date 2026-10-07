import { createRef } from 'react'
import { Menu } from '../../../src/components/Menu'
import type { MenuItem } from '../../../src/components/Menu'

const menuRef = createRef<HTMLDivElement>()
const anchorRef = createRef<HTMLButtonElement>()

const items: MenuItem[] = [
  { value: 'copy', label: 'Copy', onSelect: () => undefined },
  {
    value: 'wrap',
    label: 'Word wrap',
    checked: true,
    onCheckedChange: (checked) => checked,
    leadingIcon: <span />,
    trailingIcon: <span />,
    disabled: false,
  },
]

;<Menu
  ref={menuRef}
  anchorRef={anchorRef}
  items={items}
  defaultOpen
  onOpenChange={(open) => open}
/>
;<Menu anchorRef={anchorRef} items={items} open onOpenChange={(open) => open} />

// @ts-expect-error anchorRef is required
;<Menu items={items} />

// @ts-expect-error items is required
;<Menu anchorRef={anchorRef} />

// @ts-expect-error onOpenChange must accept a boolean, not a string
;<Menu anchorRef={anchorRef} items={items} onOpenChange={(open: string) => open} />

// @ts-expect-error Menu renders no children of its own — items own their content
;<Menu anchorRef={anchorRef} items={items}>
  <span />
</Menu>

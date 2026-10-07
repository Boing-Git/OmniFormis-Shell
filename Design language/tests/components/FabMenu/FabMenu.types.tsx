import { createRef } from 'react'
import { FabMenu, FabMenuItem } from '../../../src/components/FabMenu'

const menuRef = createRef<HTMLDivElement>()
const itemRef = createRef<HTMLButtonElement>()

;<FabMenu ref={menuRef} triggerLabel="Create" icon={<svg />} closeIcon={<svg />}>
  <FabMenuItem ref={itemRef} icon={<svg />} onClick={() => {}}>
    Edit
  </FabMenuItem>
</FabMenu>

;<FabMenu
  triggerLabel="Create"
  icon={<svg />}
  closeIcon={<svg />}
  expanded={false}
  onExpandedChange={(expanded) => expanded}
>
  <FabMenuItem disabled>No icon</FabMenuItem>
</FabMenu>

// @ts-expect-error triggerLabel is required
;<FabMenu icon={<svg />} closeIcon={<svg />}>
  <FabMenuItem>Edit</FabMenuItem>
</FabMenu>

// @ts-expect-error closeIcon is required
;<FabMenu triggerLabel="Create" icon={<svg />}>
  <FabMenuItem>Edit</FabMenuItem>
</FabMenu>

// @ts-expect-error FabMenuItem requires children (its label)
;<FabMenuItem icon={<svg />} />

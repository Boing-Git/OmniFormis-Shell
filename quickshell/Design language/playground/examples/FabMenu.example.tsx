import { useState } from 'react'
import { FabMenu, FabMenuItem, Icon, Surface, Text } from '@language-lit/material3-expressive'

export function FabMenuExample() {
  const [open, setOpen] = useState(false)

  return (
    <Surface
      as="section"
      aria-labelledby="fab-menu-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="fab-menu-example"
    >
      <Text as="h2" id="fab-menu-example-title" variant="titleLarge" emphasis="emphasized">
        FAB menu
      </Text>
      <Text as="p" variant="bodyMedium">
        Click the trigger to morph it into a close button and reveal a
        staggered column of items, closest-to-trigger first.
      </Text>

      <div className="fab-menu-example__row">
        <FabMenu
          triggerLabel="Create"
          icon={<Icon source="add" />}
          closeIcon={<Icon source="close" />}
          expanded={open}
          onExpandedChange={setOpen}
        >
          <FabMenuItem icon={<Icon source="edit" />} onClick={() => setOpen(false)}>
            Edit
          </FabMenuItem>
          <FabMenuItem icon={<Icon source="share" />} onClick={() => setOpen(false)}>
            Share
          </FabMenuItem>
          <FabMenuItem icon={<Icon source="delete" />} onClick={() => setOpen(false)}>
            Delete
          </FabMenuItem>
          <FabMenuItem onClick={() => setOpen(false)}>Archive</FabMenuItem>
          <FabMenuItem icon={<Icon source="lock" />} disabled>
            Restricted
          </FabMenuItem>
        </FabMenu>
      </div>
    </Surface>
  )
}

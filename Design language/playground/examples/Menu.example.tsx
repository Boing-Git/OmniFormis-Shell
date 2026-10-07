import { useRef, useState } from 'react'
import { Button, Icon, Menu, Surface, Text } from '@language-lit/material3-expressive'

export function MenuExample() {
  const anchorRef = useRef<HTMLButtonElement>(null)
  const [open, setOpen] = useState(false)
  const [wordWrap, setWordWrap] = useState(true)
  const [autoSave, setAutoSave] = useState(true)
  const [lastSelected, setLastSelected] = useState<string | null>(null)

  return (
    <Surface
      as="section"
      aria-labelledby="menu-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="menu-example"
    >
      <Text as="h2" id="menu-example-title" variant="titleLarge" emphasis="emphasized">
        Menu
      </Text>
      <Text as="p" variant="bodyMedium">
        A portaled, keyboard-navigable action menu anchored to a trigger the
        consumer owns, with a checkable item that keeps the menu open.
      </Text>

      <div className="menu-example__row">
        <Button
          ref={anchorRef}
          variant="outlined"
          aria-haspopup="menu"
          aria-expanded={open}
          onClick={() => setOpen(true)}
        >
          Open menu
        </Button>
        {lastSelected != null && (
          <Text as="p" variant="bodySmall">
            Last selected: {lastSelected}
          </Text>
        )}
      </div>

      <Menu
        anchorRef={anchorRef}
        open={open}
        onOpenChange={setOpen}
        items={[
          {
            value: 'copy',
            label: 'Copy',
            leadingIcon: <Icon source="content_copy" />,
            onSelect: () => setLastSelected('Copy'),
          },
          {
            value: 'paste',
            label: 'Paste',
            leadingIcon: <Icon source="content_paste" />,
            onSelect: () => setLastSelected('Paste'),
          },
          {
            value: 'share',
            label: 'Share',
            leadingIcon: <Icon source="share" />,
            trailingIcon: <Icon source="chevron_right" />,
            onSelect: () => setLastSelected('Share'),
          },
          {
            value: 'delete',
            label: 'Delete',
            leadingIcon: <Icon source="delete" />,
            disabled: true,
            onSelect: () => setLastSelected('Delete'),
          },
          {
            value: 'word-wrap',
            label: 'Word wrap',
            checked: wordWrap,
            onCheckedChange: setWordWrap,
          },
          {
            value: 'auto-save',
            label: 'Auto save',
            checked: autoSave,
            disabled: true,
            onCheckedChange: setAutoSave,
          },
        ]}
      />
    </Surface>
  )
}

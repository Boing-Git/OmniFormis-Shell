import { useState } from 'react'
import { Button, Dialog, Icon, Surface, Text } from '@language-lit/material3-expressive'

export function DialogExample() {
  const [confirmOpen, setConfirmOpen] = useState(false)
  const [customOpen, setCustomOpen] = useState(false)
  const [nonModalOpen, setNonModalOpen] = useState(false)
  const [titlelessOpen, setTitlelessOpen] = useState(false)

  return (
    <Surface
      as="section"
      aria-labelledby="dialog-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="dialog-example"
    >
      <Text as="h2" id="dialog-example-title" variant="titleLarge" emphasis="emphasized">
        Dialogs
      </Text>
      <Text as="p" variant="bodyMedium">
        A native &lt;dialog&gt; element with modal and non-modal semantics, icon/
        title/content/actions layout, and adaptive width sizing.
      </Text>

      <div className="dialog-example__row">
        <Button variant="filled" onClick={() => setConfirmOpen(true)}>
          Open confirmation
        </Button>
        <Button variant="outlined" onClick={() => setCustomOpen(true)}>
          Open custom content
        </Button>
        <Button variant="tonal" onClick={() => setNonModalOpen(true)}>
          Open non-modal
        </Button>
        <Button variant="tonal" onClick={() => setTitlelessOpen(true)}>
          Open title-less
        </Button>
      </div>

      <Dialog
        open={confirmOpen}
        onOpenChange={setConfirmOpen}
        role="alertdialog"
        icon={<Icon source="delete" />}
        title="Delete conversation?"
        actions={
          <>
            <Button variant="text" onClick={() => setConfirmOpen(false)}>
              Cancel
            </Button>
            <Button variant="text" onClick={() => setConfirmOpen(false)}>
              Delete
            </Button>
          </>
        }
      >
        This removes the conversation and its messages. This action cannot be
        undone.
      </Dialog>

      <Dialog
        open={customOpen}
        onOpenChange={setCustomOpen}
        title="Rename item"
        actions={
          <form method="dialog">
            <Button variant="text" type="submit">
              Save
            </Button>
          </form>
        }
      >
        <label className="dialog-example__field">
          Name
          <input type="text" defaultValue="Untitled" />
        </label>
      </Dialog>

      <Dialog
        open={nonModalOpen}
        onOpenChange={setNonModalOpen}
        modal={false}
        title="Playback controls"
      >
        <Text as="p" variant="bodyMedium">
          Non-modal: the rest of the page stays interactive while this is open.
        </Text>
        <div className="dialog-example__row">
          <Button variant="text" onClick={() => setNonModalOpen(false)}>
            Close
          </Button>
        </div>
      </Dialog>

      <Dialog
        open={titlelessOpen}
        onOpenChange={setTitlelessOpen}
        icon={<Icon source="check_circle" />}
        aria-label="Changes saved"
        actions={
          <Button variant="text" onClick={() => setTitlelessOpen(false)}>
            Done
          </Button>
        }
      >
        <Text as="p" variant="bodyMedium">
          No title here: the icon and body carry the message on their own.
        </Text>
      </Dialog>
    </Surface>
  )
}

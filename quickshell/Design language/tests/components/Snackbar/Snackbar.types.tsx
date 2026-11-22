import { createRef } from 'react'
import { Snackbar } from '../../../src/components/Snackbar'

const snackbarRef = createRef<HTMLDivElement>()

;<Snackbar ref={snackbarRef} message="Saved" defaultOpen onOpenChange={(open) => open} />
;<Snackbar message="Item removed" action={{ label: 'Undo', onClick: () => undefined }} />
;<Snackbar message="Saved" dismissible dismissLabel="Close" />
;<Snackbar message="Saved" duration="long" />
;<Snackbar message="Saved" duration={2500} />

// @ts-expect-error message is required
;<Snackbar />

// @ts-expect-error onOpenChange must accept a boolean, not a string
;<Snackbar message="Saved" onOpenChange={(open: string) => open} />

// @ts-expect-error duration must be a known string or a number
;<Snackbar message="Saved" duration="forever" />

// @ts-expect-error action requires both label and onClick
;<Snackbar message="Saved" action={{ label: 'Undo' }} />

// @ts-expect-error Snackbar renders no children of its own — message owns it
;<Snackbar message="Saved">
  <span />
</Snackbar>

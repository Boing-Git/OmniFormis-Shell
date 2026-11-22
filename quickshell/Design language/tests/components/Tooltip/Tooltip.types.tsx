import { createRef } from 'react'
import { Tooltip } from '../../../src/components/Tooltip'

const tooltipRef = createRef<HTMLDivElement>()
const anchorRef = createRef<HTMLButtonElement>()

;<Tooltip ref={tooltipRef} anchorRef={anchorRef} content="Save the document" />
;<Tooltip anchorRef={anchorRef} content="Save the document" variant="rich" subhead="Storage" />
;<Tooltip anchorRef={anchorRef} content="Save the document" placement="start" />
;<Tooltip
  anchorRef={anchorRef}
  content="Save the document"
  defaultOpen
  onOpenChange={(open) => open}
/>

// @ts-expect-error anchorRef is required
;<Tooltip content="Save the document" />

// @ts-expect-error content is required
;<Tooltip anchorRef={anchorRef} />

// @ts-expect-error onOpenChange must accept a boolean, not a string
;<Tooltip anchorRef={anchorRef} content="Save the document" onOpenChange={(open: string) => open} />

// @ts-expect-error placement must be one of the known values
;<Tooltip anchorRef={anchorRef} content="Save the document" placement="middle" />

// @ts-expect-error Tooltip renders no children of its own — content owns it
;<Tooltip anchorRef={anchorRef} content="Save the document">
  <span />
</Tooltip>

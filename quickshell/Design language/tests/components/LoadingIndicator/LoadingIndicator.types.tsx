import { createRef } from 'react'
import { LoadingIndicator } from '../../../src/components/LoadingIndicator'

const ref = createRef<HTMLDivElement>()

;<LoadingIndicator ref={ref} aria-label="Loading" value={0.5} />
;<LoadingIndicator aria-label="Loading" />
;<LoadingIndicator aria-label="Loading" value={50} max={200} />

// @ts-expect-error value must be a number
;<LoadingIndicator aria-label="Loading" value="0.5" />

// @ts-expect-error LoadingIndicator renders no children of its own
;<LoadingIndicator aria-label="Loading" value={0.5}>
  <span />
</LoadingIndicator>

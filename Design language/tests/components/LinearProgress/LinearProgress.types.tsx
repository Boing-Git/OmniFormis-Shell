import { createRef } from 'react'
import { LinearProgress } from '../../../src/components/LinearProgress'

const ref = createRef<HTMLDivElement>()

;<LinearProgress ref={ref} aria-label="Download" value={0.5} />
;<LinearProgress aria-label="Loading" />
;<LinearProgress aria-label="Download" value={50} max={200} />

// @ts-expect-error value must be a number
;<LinearProgress aria-label="Download" value="0.5" />

// @ts-expect-error LinearProgress renders no children of its own
;<LinearProgress aria-label="Download" value={0.5}>
  <span />
</LinearProgress>

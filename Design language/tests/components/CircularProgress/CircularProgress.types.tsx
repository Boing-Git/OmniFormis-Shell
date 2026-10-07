import { createRef } from 'react'
import { CircularProgress } from '../../../src/components/CircularProgress'

const ref = createRef<HTMLDivElement>()

;<CircularProgress ref={ref} aria-label="Progress" value={0.5} />
;<CircularProgress aria-label="Loading" />
;<CircularProgress aria-label="Progress" value={50} max={200} />

// @ts-expect-error value must be a number
;<CircularProgress aria-label="Progress" value="0.5" />

// @ts-expect-error CircularProgress renders no children of its own
;<CircularProgress aria-label="Progress" value={0.5}>
  <span />
</CircularProgress>

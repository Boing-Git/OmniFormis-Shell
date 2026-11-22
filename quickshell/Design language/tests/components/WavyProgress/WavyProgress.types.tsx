import { createRef } from 'react'
import { WavyProgress } from '../../../src/components/WavyProgress'

const ref = createRef<HTMLDivElement>()

;<WavyProgress ref={ref} aria-label="Upload" value={0.5} />
;<WavyProgress aria-label="Syncing" />
;<WavyProgress aria-label="Progress" shape="circular" value={0.5} />
;<WavyProgress aria-label="Upload" value={50} max={200} />

// @ts-expect-error shape must be one of the known values
;<WavyProgress aria-label="Progress" shape="square" value={0.5} />

// @ts-expect-error value must be a number
;<WavyProgress aria-label="Upload" value="0.5" />

// @ts-expect-error WavyProgress renders no children of its own
;<WavyProgress aria-label="Upload" value={0.5}>
  <span />
</WavyProgress>

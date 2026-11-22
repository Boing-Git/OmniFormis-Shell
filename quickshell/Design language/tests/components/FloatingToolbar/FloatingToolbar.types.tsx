import { createRef } from 'react'
import { FloatingToolbar } from '../../../src/components/FloatingToolbar'

const ref = createRef<HTMLDivElement>()

;<FloatingToolbar ref={ref} aria-label="Actions">
  <button type="button">One</button>
</FloatingToolbar>

;<FloatingToolbar
  aria-label="Actions"
  orientation="vertical"
  variant="vibrant"
  expanded={false}
  onExpandedChange={(expanded) => expanded}
>
  <button type="button">One</button>
</FloatingToolbar>

// @ts-expect-error children is required
;<FloatingToolbar aria-label="Actions" />

// @ts-expect-error orientation must be 'horizontal' | 'vertical'
;<FloatingToolbar aria-label="Actions" orientation="diagonal">
  <button type="button">One</button>
</FloatingToolbar>

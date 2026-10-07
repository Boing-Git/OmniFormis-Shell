import { createRef } from 'react'
import { SegmentedButtonGroup } from '../../../src/components/SegmentedButtonGroup'

const groupRef = createRef<HTMLDivElement>()
const segments = [
  { value: 'day', label: 'Day' },
  { value: 'week', label: 'Week', icon: <span /> },
] as const

;<SegmentedButtonGroup
  ref={groupRef}
  segments={segments}
  aria-label="View"
  name="view"
  defaultValue="day"
  onValueChange={(value) => value.toUpperCase()}
/>
;<SegmentedButtonGroup
  multiple
  segments={segments}
  aria-label="Filters"
  defaultValue={['day']}
  onValueChange={(value) => value.length}
/>
;<SegmentedButtonGroup segments={segments} aria-label="Disabled" disabled />

// @ts-expect-error segments is required
;<SegmentedButtonGroup aria-label="View" />

// @ts-expect-error single-choice value must be a string, not an array
;<SegmentedButtonGroup segments={segments} aria-label="View" value={['day']} />

// @ts-expect-error multi-choice value must be an array, not a string
;<SegmentedButtonGroup multiple segments={segments} aria-label="Filters" value="day" />

// @ts-expect-error SegmentedButtonGroup computes its own children from segments
;<SegmentedButtonGroup segments={segments} aria-label="View">
  Content
</SegmentedButtonGroup>

// @ts-expect-error role is computed internally, not caller-supplied
;<SegmentedButtonGroup segments={segments} aria-label="View" role="tablist" />

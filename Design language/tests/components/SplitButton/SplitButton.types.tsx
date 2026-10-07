import { createRef } from 'react'
import { SplitButton } from '../../../src/components/SplitButton'

const ref = createRef<HTMLDivElement>()

;<SplitButton ref={ref} trailingIcon={<svg />} trailingLabel="More options">
  Save
</SplitButton>

;<SplitButton
  variant="tonal"
  size="large"
  leadingIcon={<svg />}
  trailingIcon={<svg />}
  trailingLabel="More options"
  selected={false}
  onSelectedChange={(selected) => selected}
  disabled
>
  Save
</SplitButton>

// @ts-expect-error trailingIcon is required
;<SplitButton trailingLabel="More options">Save</SplitButton>

// @ts-expect-error trailingLabel is required
;<SplitButton trailingIcon={<svg />}>Save</SplitButton>

// @ts-expect-error children (the leading label) is required
;<SplitButton trailingIcon={<svg />} trailingLabel="More options" />

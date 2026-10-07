import { createRef } from 'react'
import { Select } from '../../../src/components/Select'
import type { SelectOption } from '../../../src/components/Select'

const selectRef = createRef<HTMLInputElement>()

const options: SelectOption[] = [
  { value: 'apple', label: 'Apple' },
  { value: 'cherry', label: 'Cherry', disabled: true },
]

;<Select ref={selectRef} label="Fruit" options={options} />
;<Select
  label="Fruit"
  options={options}
  value="apple"
  onValueChange={(value) => value}
  variant="outlined"
  leadingIcon={<span />}
  supportingText="Choose one"
  error
  disabled
  required
  name="fruit"
  open
  onOpenChange={(open) => open}
/>

// @ts-expect-error label is required
;<Select options={options} />

// @ts-expect-error options is required
;<Select label="Fruit" />

// @ts-expect-error onValueChange must accept a string, not a number
;<Select label="Fruit" options={options} onValueChange={(value: number) => value} />

// @ts-expect-error variant only accepts filled or outlined
;<Select label="Fruit" options={options} variant="text" />

// @ts-expect-error SelectOption.label must be a plain string, not a node
;<Select label="Fruit" options={[{ value: 'a', label: <span /> }]} />

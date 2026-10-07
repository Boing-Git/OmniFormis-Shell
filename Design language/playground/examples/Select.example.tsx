import { useState } from 'react'
import { Icon, Select, Surface, Text } from '@language-lit/material3-expressive'

const fruitOptions = [
  { value: 'apple', label: 'Apple' },
  { value: 'banana', label: 'Banana' },
  { value: 'cherry', label: 'Cherry' },
  { value: 'durian', label: 'Durian', disabled: true },
]

export function SelectExample() {
  const [filledValue, setFilledValue] = useState('apple')
  const [outlinedValue, setOutlinedValue] = useState('')

  return (
    <Surface
      as="section"
      aria-labelledby="select-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="select-example"
    >
      <Text as="h2" id="select-example-title" variant="titleLarge" emphasis="emphasized">
        Select
      </Text>
      <Text as="p" variant="bodyMedium">
        A combobox trigger built on the same field chrome as TextField, with
        a width-matched listbox popup.
      </Text>

      <div className="select-example__row">
        <Select
          label="Favorite fruit"
          variant="filled"
          leadingIcon={<Icon source="nutrition" />}
          options={fruitOptions}
          value={filledValue}
          onValueChange={setFilledValue}
          supportingText="One disabled option"
          name="favorite-fruit"
        />
        <Select
          label="Outlined select"
          variant="outlined"
          options={fruitOptions}
          value={outlinedValue}
          onValueChange={setOutlinedValue}
        />
        <Select label="Disabled" options={fruitOptions} defaultValue="banana" disabled />
      </div>

      <div className="select-example__row">
        <Select
          label="Outlined with icon"
          variant="outlined"
          leadingIcon={<Icon source="nutrition" />}
          options={fruitOptions}
          defaultValue="cherry"
        />
        <Select
          label="Invalid selection"
          options={fruitOptions}
          defaultValue="banana"
          error
          supportingText="Out of stock, please choose another"
        />
        <Select
          label="Disabled outlined"
          variant="outlined"
          options={fruitOptions}
          defaultValue="banana"
          disabled
        />
      </div>

      <div className="select-example__row">
        <Select
          label="Statically open"
          options={fruitOptions}
          defaultValue="apple"
          defaultOpen
          supportingText="Rendered open to preview the listbox, including the disabled option"
        />
      </div>
    </Surface>
  )
}

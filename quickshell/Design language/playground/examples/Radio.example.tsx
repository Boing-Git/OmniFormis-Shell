import { useState } from 'react'
import {
  Radio,
  Surface,
  Text,
} from '@language-lit/material3-expressive'

const plans = [
  { value: 'basic', label: 'Basic' },
  { value: 'pro', label: 'Pro' },
  { value: 'team', label: 'Team' },
] as const

export function RadioExample() {
  const [plan, setPlan] = useState<(typeof plans)[number]['value']>('basic')

  return (
    <Surface
      as="section"
      aria-labelledby="radio-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="radio-example"
    >
      <Text as="h2" id="radio-example-title" variant="titleLarge" emphasis="emphasized">
        Radios
      </Text>
      <Text as="p" variant="bodyMedium">
        A native, grouped control with selected and disabled state.
      </Text>

      <div className="radio-example__group" role="radiogroup" aria-label="Plan">
        {plans.map((option) => (
          <label key={option.value} className="radio-example__row">
            <Radio
              name="plan"
              value={option.value}
              checked={plan === option.value}
              onCheckedChange={() => setPlan(option.value)}
            />
            <Text as="span" variant="bodyLarge">
              {option.label}
            </Text>
          </label>
        ))}
      </div>

      <div className="radio-example__group">
        <label className="radio-example__row">
          <Radio name="disabled-plan" value="unavailable" disabled />
          <Text as="span" variant="bodyLarge">
            Unavailable
          </Text>
        </label>
        <label className="radio-example__row">
          <Radio name="disabled-plan" value="selected-unavailable" disabled defaultChecked />
          <Text as="span" variant="bodyLarge">
            Unavailable and selected
          </Text>
        </label>
      </div>

      <Text as="span" role="status" variant="bodySmall" aria-live="polite">
        Selected plan: {plan}
      </Text>
    </Surface>
  )
}

import { useState } from 'react'
import { Icon, Surface, Text, TextArea } from '@language-lit/material3-expressive'

export function TextAreaExample() {
  const [feedback, setFeedback] = useState('')

  return (
    <Surface
      as="section"
      aria-labelledby="text-area-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="text-area-example"
    >
      <Text as="h2" id="text-area-example-title" variant="titleLarge" emphasis="emphasized">
        Text areas
      </Text>
      <Text as="p" variant="bodyMedium">
        The same field chrome as TextField around a native multiline control.
      </Text>

      <div className="text-area-example__row">
        <TextArea
          label="Feedback"
          rows={4}
          value={feedback}
          onChange={(event) => setFeedback(event.currentTarget.value)}
          supportingText="Tell us what worked and what didn't"
        />
        <TextArea variant="outlined" label="Notes" rows={4} error supportingText="Required" />
      </div>

      <div className="text-area-example__row">
        <TextArea
          label="Message"
          rows={4}
          leadingIcon={<Icon source="edit_note" />}
          trailingIcon={<Icon source="mic" />}
          defaultValue="Great course, thanks!"
        />
        <TextArea
          label="Comments"
          rows={4}
          error
          supportingText="This field is required"
        />
        <TextArea label="Unavailable" rows={4} disabled defaultValue="Locked" />
      </div>
    </Surface>
  )
}

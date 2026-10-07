import { useState } from 'react'
import {
  Checkbox,
  Surface,
  Text,
} from '@language-lit/material3-expressive'

const lessons = ['Hiragana', 'Katakana', 'Kanji'] as const

export function CheckboxExample() {
  const [completed, setCompleted] = useState<readonly string[]>([lessons[0]])

  const allCompleted = completed.length === lessons.length
  const someCompleted = completed.length > 0 && !allCompleted

  return (
    <Surface
      as="section"
      aria-labelledby="checkbox-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="checkbox-example"
    >
      <Text as="h2" id="checkbox-example-title" variant="titleLarge" emphasis="emphasized">
        Checkboxes
      </Text>
      <Text as="p" variant="bodyMedium">
        A native control with checked, mixed, and disabled state.
      </Text>

      <label className="checkbox-example__row">
        <Checkbox
          checked={allCompleted}
          indeterminate={someCompleted}
          onCheckedChange={(checked) => setCompleted(checked ? lessons : [])}
        />
        <Text as="span" variant="bodyLarge">
          All lessons complete
        </Text>
      </label>

      <div className="checkbox-example__group">
        {lessons.map((lesson) => (
          <label key={lesson} className="checkbox-example__row">
            <Checkbox
              name="lessons"
              value={lesson}
              checked={completed.includes(lesson)}
              onCheckedChange={(checked) =>
                setCompleted((current) =>
                  checked
                    ? [...current, lesson]
                    : current.filter((entry) => entry !== lesson),
                )
              }
            />
            <Text as="span" variant="bodyLarge">
              {lesson}
            </Text>
          </label>
        ))}
      </div>

      <div className="checkbox-example__group">
        <label className="checkbox-example__row">
          <Checkbox disabled />
          <Text as="span" variant="bodyLarge">
            Unavailable
          </Text>
        </label>
        <label className="checkbox-example__row">
          <Checkbox disabled defaultChecked />
          <Text as="span" variant="bodyLarge">
            Unavailable and complete
          </Text>
        </label>
        <label className="checkbox-example__row">
          <Checkbox disabled indeterminate />
          <Text as="span" variant="bodyLarge">
            Unavailable and partial
          </Text>
        </label>
      </div>

      <Text as="span" role="status" variant="bodySmall" aria-live="polite">
        Complete: {completed.length} of {lessons.length}
      </Text>
    </Surface>
  )
}

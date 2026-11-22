import { Button, ButtonGroup, Icon, IconButton, Surface, Text } from '@language-lit/material3-expressive'

export function ButtonGroupExample() {
  return (
    <Surface
      as="section"
      aria-labelledby="button-group-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="button-group-example"
    >
      <Text as="h2" id="button-group-example-title" variant="titleLarge" emphasis="emphasized">
        Button groups
      </Text>
      <Text as="p" variant="bodyMedium">
        Arbitrary children arranged in a row. Press one to see it grow and
        its neighbors compress, reading each child's own native :active
        state via CSS :has() -- no JavaScript layout measurement.
      </Text>

      <div className="button-group-example__row">
        <ButtonGroup aria-label="Text formatting">
          <IconButton aria-label="Bold" variant="tonal">
            <Icon source="format_bold" />
          </IconButton>
          <IconButton aria-label="Italic" variant="tonal">
            <Icon source="format_italic" />
          </IconButton>
          <IconButton aria-label="Underline" variant="tonal">
            <Icon source="format_underlined" />
          </IconButton>
        </ButtonGroup>
      </div>

      <div className="button-group-example__row">
        <ButtonGroup aria-label="Actions">
          <Button variant="outlined">One</Button>
          <Button variant="outlined">Two</Button>
          <Button variant="outlined">Three</Button>
          <Button variant="outlined">Four</Button>
        </ButtonGroup>
      </div>
    </Surface>
  )
}

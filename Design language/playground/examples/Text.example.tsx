import { Surface, Text } from '@language-lit/material3-expressive'

export function TextExample() {
  return (
    <Surface
      as="section"
      aria-labelledby="text-example-title"
      color="surface-container"
      shape="extra-large"
      className="text-example"
    >
      <Text
        as="h2"
        id="text-example-title"
        variant="displaySmall"
        emphasis="emphasized"
      >
        Expressive typography
      </Text>
      <Text as="p" variant="bodyLarge">
        Semantic elements and visual roles stay independent.
      </Text>
      <Surface color="inverse-surface" shape="medium" className="text-example__inverse">
        <Text variant="labelLarge" emphasis="emphasized">
          Content color is inherited
        </Text>
      </Surface>
      <Text as="h3" variant="titleMedium" emphasis="emphasized">
        Type scale
      </Text>
      <Text as="div" variant="displayLarge">
        Display large
      </Text>
      <Text as="strong" variant="displayMedium">
        Display medium
      </Text>
      <Text as="h1" variant="headlineLarge">
        Headline large
      </Text>
      <Text as="div" variant="headlineMedium">
        Headline medium
      </Text>
      <Text as="blockquote" variant="headlineSmall">
        Headline small
      </Text>
      <Text as="div" variant="titleLarge">
        Title large
      </Text>
      <Text as="div" variant="titleSmall">
        Title small
      </Text>
      <Text as="div" variant="bodyMedium" emphasis="baseline">
        Body medium (explicit baseline)
      </Text>
      <Text as="div" variant="bodySmall">
        Body small
      </Text>
      <Text as="label" variant="labelMedium">
        Label medium
      </Text>
      <Text as="div" variant="labelSmall">
        Label small
      </Text>
    </Surface>
  )
}

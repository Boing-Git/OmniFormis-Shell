import { LinearProgress, Surface, Text } from '@language-lit/material3-expressive'

export function LinearProgressExample() {
  return (
    <Surface
      as="section"
      aria-labelledby="linear-progress-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="linear-progress-example"
    >
      <Text as="h2" id="linear-progress-example-title" variant="titleLarge" emphasis="emphasized">
        Linear progress
      </Text>
      <Text as="p" variant="bodyMedium">
        Determinate at a few fractions and self-animating indeterminate. See
        WavyProgress for the Material 3 Expressive traveling-wave treatment.
      </Text>

      <Text as="p" variant="labelLarge">Determinate</Text>
      <LinearProgress aria-label="Download progress, empty" value={0} />
      <LinearProgress aria-label="Download progress, low" value={0.05} />
      <LinearProgress aria-label="Download progress, mid" value={0.45} />
      <LinearProgress aria-label="Download progress, high" value={0.98} />
      <LinearProgress aria-label="Download progress, complete" value={1} />

      <Text as="p" variant="labelLarge">Custom max</Text>
      <LinearProgress aria-label="Download progress, custom max" value={150} max={200} />

      <Text as="p" variant="labelLarge">Indeterminate</Text>
      <LinearProgress aria-label="Loading" />
    </Surface>
  )
}

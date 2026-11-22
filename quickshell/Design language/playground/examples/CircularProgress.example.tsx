import { CircularProgress, Surface, Text } from '@language-lit/material3-expressive'

export function CircularProgressExample() {
  return (
    <Surface
      as="section"
      aria-labelledby="circular-progress-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="circular-progress-example"
    >
      <Text as="h2" id="circular-progress-example-title" variant="titleLarge" emphasis="emphasized">
        Circular progress
      </Text>
      <Text as="p" variant="bodyMedium">
        Determinate at a few fractions and self-animating indeterminate
        (global + additional rotation and a pulsing sweep, composed the same
        way the pinned source composes three independent animations). See
        WavyProgress for the Material 3 Expressive rippling-ring treatment.
      </Text>

      <div className="circular-progress-example__row">
        <CircularProgress aria-label="Progress, empty" value={0} />
        <CircularProgress aria-label="Progress, low" value={0.05} />
        <CircularProgress aria-label="Progress, mid" value={0.45} />
        <CircularProgress aria-label="Progress, high" value={0.98} />
        <CircularProgress aria-label="Progress, complete" value={1} />
        <CircularProgress aria-label="Progress, custom max" value={150} max={200} />
        <CircularProgress aria-label="Loading" />
      </div>
    </Surface>
  )
}

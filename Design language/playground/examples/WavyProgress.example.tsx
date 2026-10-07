import { Surface, Text, WavyProgress } from '@language-lit/material3-expressive'

export function WavyProgressExample() {
  return (
    <Surface
      as="section"
      aria-labelledby="wavy-progress-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="wavy-progress-example"
    >
      <Text as="h2" id="wavy-progress-example-title" variant="titleLarge" emphasis="emphasized">
        Wavy progress
      </Text>
      <Text as="p" variant="bodyMedium">
        The Material 3 Expressive traveling-wave/rippling-ring treatment,
        determinate at a few fractions (watch the amplitude ramp down near
        0% and 100%) and self-animating indeterminate.
      </Text>

      <Text as="p" variant="labelLarge">Linear — determinate</Text>
      <WavyProgress aria-label="Upload progress, empty" value={0} />
      <WavyProgress aria-label="Upload progress, low" value={0.05} />
      <WavyProgress aria-label="Upload progress, mid" value={0.45} />
      <WavyProgress aria-label="Upload progress, high" value={0.98} />
      <WavyProgress aria-label="Upload progress, complete" value={1} />

      <Text as="p" variant="labelLarge">Linear — custom max</Text>
      <WavyProgress aria-label="Upload progress, custom max" value={150} max={200} />

      <Text as="p" variant="labelLarge">Linear — indeterminate</Text>
      <WavyProgress aria-label="Syncing" />

      <Text as="p" variant="labelLarge">Circular</Text>
      <div className="wavy-progress-example__row">
        <WavyProgress aria-label="Progress, empty" shape="circular" value={0} />
        <WavyProgress aria-label="Progress, low" shape="circular" value={0.05} />
        <WavyProgress aria-label="Progress, mid" shape="circular" value={0.45} />
        <WavyProgress aria-label="Progress, high" shape="circular" value={0.98} />
        <WavyProgress aria-label="Progress, complete" shape="circular" value={1} />
        <WavyProgress aria-label="Progress, custom max" shape="circular" value={150} max={200} />
        <WavyProgress aria-label="Syncing" shape="circular" />
      </div>
    </Surface>
  )
}

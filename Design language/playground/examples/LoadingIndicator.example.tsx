import { LoadingIndicator, Surface, Text } from '@language-lit/material3-expressive'

export function LoadingIndicatorExample() {
  return (
    <Surface
      as="section"
      aria-labelledby="loading-indicator-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="loading-indicator-example"
    >
      <Text as="h2" id="loading-indicator-example-title" variant="titleLarge" emphasis="emphasized">
        Loading indicator
      </Text>
      <Text as="p" variant="bodyMedium">
        Determinate morphs between a circle and a soft-burst shape as
        progress advances; indeterminate loops continuously through seven
        Material 3 Expressive shapes with a real polygon-morph animation,
        precomputed offline from the pinned source's own shape-matching
        algorithm.
      </Text>

      <div className="loading-indicator-example__row">
        <LoadingIndicator aria-label="Loading, empty" value={0} />
        <LoadingIndicator aria-label="Loading, low" value={0.05} />
        <LoadingIndicator aria-label="Loading, mid" value={0.45} />
        <LoadingIndicator aria-label="Loading, high" value={0.98} />
        <LoadingIndicator aria-label="Loading, complete" value={1} />
        <LoadingIndicator aria-label="Loading, custom max" value={150} max={200} />
        <LoadingIndicator aria-label="Loading" />
      </div>
    </Surface>
  )
}

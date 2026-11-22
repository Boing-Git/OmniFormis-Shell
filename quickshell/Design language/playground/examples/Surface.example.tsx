import type { CSSProperties } from 'react'
import { Surface } from '@language-lit/material3-expressive'

const surfaceColors = [
  'surface',
  'surface-dim',
  'surface-bright',
  'surface-container-lowest',
  'surface-container',
  'surface-container-high',
  'surface-container-highest',
  'primary',
  'primary-fixed',
  'primary-fixed-dim',
  'secondary',
  'secondary-container',
  'secondary-fixed',
  'secondary-fixed-dim',
  'tertiary',
  'tertiary-container',
  'tertiary-fixed',
  'tertiary-fixed-dim',
  'error',
  'error-container',
  'inverse-surface',
] as const

const surfaceShapes = [
  'none',
  'extra-small',
  'extra-small-top',
  'small',
  'medium',
  'large-start',
  'large-end',
  'large-top',
  'large-increased',
  'extra-large-top',
  'extra-large-increased',
  'extra-extra-large',
  'full',
] as const

const shadowElevations = [0, 1, 2, 3, 4, 5] as const
const tonalElevations = [1, 2, 3, 4, 5] as const
const surfaceElements = ['article', 'aside', 'header', 'footer', 'nav', 'main'] as const

const swatchGridStyle: CSSProperties = {
  display: 'grid',
  gap: '0.75rem',
  gridTemplateColumns: 'repeat(auto-fill, minmax(9rem, 1fr))',
}

const swatchStyle: CSSProperties = {
  display: 'grid',
  gap: '0.25rem',
  fontSize: '0.75rem',
  padding: '0.75rem',
}

export function SurfaceExample() {
  return (
    <Surface
      as="section"
      aria-labelledby="surface-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="surface-example"
    >
      <h2 id="surface-example-title">Surface</h2>
      <p>Color, content color, shape, and elevation stay theme-backed.</p>
      <Surface
        color="primary-container"
        shape="large"
        shadowElevation={1}
        className="surface-example__nested"
      >
        Nested semantic content
      </Surface>

      <h3>Tonal elevation (color=&quot;surface&quot;)</h3>
      <div style={swatchGridStyle}>
        <Surface color="surface" shape="small" style={swatchStyle}>
          Tonal 0 (default)
        </Surface>
        {tonalElevations.map((level) => (
          <Surface key={level} color="surface" tonalElevation={level} shape="small" style={swatchStyle}>
            Tonal {level}
          </Surface>
        ))}
      </div>

      <h3>Color roles</h3>
      <div style={swatchGridStyle}>
        {surfaceColors.map((color) => (
          <Surface key={color} color={color} shape="small" style={swatchStyle}>
            {color}
          </Surface>
        ))}
      </div>

      <h3>Shapes</h3>
      <div style={swatchGridStyle}>
        {surfaceShapes.map((shape) => (
          <Surface key={shape} color="surface-container" shape={shape} style={swatchStyle}>
            {shape}
          </Surface>
        ))}
      </div>

      <h3>Shadow elevation</h3>
      <div style={swatchGridStyle}>
        {shadowElevations.map((level) => (
          <Surface
            key={level}
            color="surface-container-low"
            shadowElevation={level}
            shape="small"
            style={swatchStyle}
          >
            Shadow {level}
          </Surface>
        ))}
      </div>

      <h3>Landmark elements (as)</h3>
      <div style={swatchGridStyle}>
        {surfaceElements.map((element) => (
          <Surface key={element} as={element} color="surface-container" shape="small" style={swatchStyle}>
            {`<${element}>`}
          </Surface>
        ))}
      </div>
    </Surface>
  )
}

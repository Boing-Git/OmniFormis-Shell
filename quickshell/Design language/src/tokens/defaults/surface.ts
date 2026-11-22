import type { ComponentTokenRegistration } from '../schema'

/**
 * Default tokens for the passive Material Surface contract. Variant props map
 * to system roles in component CSS; these tokens define the unconfigured
 * surface described by the first-party API.
 */
export const defaultSurfaceTokens = {
  component: 'surface',
  task: 'T04',
  source: {
    id: 'androidx-material3-surface',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/0be207d91046b7376beeef5544d331a02d6fa87c/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/Surface.kt',
    revision: '0be207d91046b7376beeef5544d331a02d6fa87c',
    accessed: '2026-07-19',
  },
  tokens: {
    'container-color': { kind: 'color', value: { $ref: 'sys.color.surface' } },
    'content-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'container-shape': { kind: 'shape', value: { $ref: 'sys.shape.corners.cornerNone' } },
    'container-shadow': { kind: 'shadow', value: { $ref: 'sys.elevation.level0.shadow' } },
    'tonal-overlay-opacity': {
      kind: 'opacity',
      value: { $ref: 'sys.elevation.level0.tonalOverlayOpacity' },
    },
  },
} as const satisfies ComponentTokenRegistration

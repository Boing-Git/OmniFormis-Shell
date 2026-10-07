import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX Material 3 Expressive IconButton values adapted from dp to
 * CSS pixels. State colors and shapes remain connected to system roles.
 */
export const defaultIconButtonTokens = {
  component: 'icon-button',
  task: 'T08',
  source: {
    id: 'androidx-material3-icon-button',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/f0793303999c933a40c10d79212e0580d21bdc68/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/IconButtonDefaults.kt',
    revision: 'f0793303999c933a40c10d79212e0580d21bdc68',
    accessed: '2026-07-19',
  },
  tokens: {
    'minimum-interactive-target': {
      kind: 'dimension',
      value: { $ref: 'sys.density.minimumInteractiveTarget' },
    },
    'focus-ring-width': { kind: 'dimension', value: '2px' },
    'focus-ring-offset': { kind: 'dimension', value: '2px' },
    'focus-ring-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },

    'extra-small-container-height': { kind: 'dimension', value: '32px' },
    'extra-small-container-width-narrow': { kind: 'dimension', value: '28px' },
    'extra-small-container-width-uniform': { kind: 'dimension', value: '32px' },
    'extra-small-container-width-wide': { kind: 'dimension', value: '40px' },
    'extra-small-icon-size': { kind: 'dimension', value: '20px' },
    'extra-small-container-shape-round': { kind: 'shape', value: '16px' },
    'extra-small-container-shape-square': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerMedium' },
    },
    'extra-small-pressed-container-shape': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerSmall' },
    },
    'extra-small-selected-container-shape-round': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerMedium' },
    },
    'extra-small-selected-container-shape-square': { kind: 'shape', value: '16px' },
    'extra-small-outline-width': { kind: 'dimension', value: '1px' },

    'small-container-height': { kind: 'dimension', value: '40px' },
    'small-container-width-narrow': { kind: 'dimension', value: '32px' },
    'small-container-width-uniform': { kind: 'dimension', value: '40px' },
    'small-container-width-wide': { kind: 'dimension', value: '52px' },
    'small-icon-size': { kind: 'dimension', value: '24px' },
    'small-container-shape-round': { kind: 'shape', value: '20px' },
    'small-container-shape-square': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerMedium' },
    },
    'small-pressed-container-shape': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerSmall' },
    },
    'small-selected-container-shape-round': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerMedium' },
    },
    'small-selected-container-shape-square': { kind: 'shape', value: '20px' },
    'small-outline-width': { kind: 'dimension', value: '1px' },

    'medium-container-height': { kind: 'dimension', value: '56px' },
    'medium-container-width-narrow': { kind: 'dimension', value: '48px' },
    'medium-container-width-uniform': { kind: 'dimension', value: '56px' },
    'medium-container-width-wide': { kind: 'dimension', value: '72px' },
    'medium-icon-size': { kind: 'dimension', value: '24px' },
    'medium-container-shape-round': { kind: 'shape', value: '28px' },
    'medium-container-shape-square': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerLarge' },
    },
    'medium-pressed-container-shape': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerMedium' },
    },
    'medium-selected-container-shape-round': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerLarge' },
    },
    'medium-selected-container-shape-square': { kind: 'shape', value: '28px' },
    'medium-outline-width': { kind: 'dimension', value: '1px' },

    'large-container-height': { kind: 'dimension', value: '96px' },
    'large-container-width-narrow': { kind: 'dimension', value: '64px' },
    'large-container-width-uniform': { kind: 'dimension', value: '96px' },
    'large-container-width-wide': { kind: 'dimension', value: '128px' },
    'large-icon-size': { kind: 'dimension', value: '32px' },
    'large-container-shape-round': { kind: 'shape', value: '48px' },
    'large-container-shape-square': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerExtraLarge' },
    },
    'large-pressed-container-shape': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerLarge' },
    },
    'large-selected-container-shape-round': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerExtraLarge' },
    },
    'large-selected-container-shape-square': { kind: 'shape', value: '48px' },
    'large-outline-width': { kind: 'dimension', value: '2px' },

    'extra-large-container-height': { kind: 'dimension', value: '136px' },
    'extra-large-container-width-narrow': { kind: 'dimension', value: '104px' },
    'extra-large-container-width-uniform': { kind: 'dimension', value: '136px' },
    'extra-large-container-width-wide': { kind: 'dimension', value: '184px' },
    'extra-large-icon-size': { kind: 'dimension', value: '40px' },
    'extra-large-container-shape-round': { kind: 'shape', value: '68px' },
    'extra-large-container-shape-square': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerExtraLarge' },
    },
    'extra-large-pressed-container-shape': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerLarge' },
    },
    'extra-large-selected-container-shape-round': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerExtraLarge' },
    },
    'extra-large-selected-container-shape-square': { kind: 'shape', value: '68px' },
    'extra-large-outline-width': { kind: 'dimension', value: '3px' },

    'standard-content-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' },
    },
    'standard-selected-content-color': {
      kind: 'color', value: { $ref: 'sys.color.primary' },
    },
    'standard-disabled-content-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },

    'filled-container-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'filled-content-color': { kind: 'color', value: { $ref: 'sys.color.onPrimary' } },
    'filled-unselected-container-color': {
      kind: 'color', value: { $ref: 'sys.color.surfaceContainer' },
    },
    'filled-unselected-content-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' },
    },
    'filled-selected-container-color': {
      kind: 'color', value: { $ref: 'sys.color.primary' },
    },
    'filled-selected-content-color': {
      kind: 'color', value: { $ref: 'sys.color.onPrimary' },
    },
    'filled-disabled-container-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'filled-disabled-content-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },

    'tonal-container-color': {
      kind: 'color', value: { $ref: 'sys.color.secondaryContainer' },
    },
    'tonal-content-color': {
      kind: 'color', value: { $ref: 'sys.color.onSecondaryContainer' },
    },
    'tonal-selected-container-color': {
      kind: 'color', value: { $ref: 'sys.color.secondary' },
    },
    'tonal-selected-content-color': {
      kind: 'color', value: { $ref: 'sys.color.onSecondary' },
    },
    'tonal-disabled-container-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'tonal-disabled-content-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },

    'outlined-content-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' },
    },
    'outlined-outline-color': {
      kind: 'color', value: { $ref: 'sys.color.outlineVariant' },
    },
    'outlined-selected-container-color': {
      kind: 'color', value: { $ref: 'sys.color.inverseSurface' },
    },
    'outlined-selected-content-color': {
      kind: 'color', value: { $ref: 'sys.color.inverseOnSurface' },
    },
    'outlined-disabled-content-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'outlined-disabled-outline-color': {
      kind: 'color', value: { $ref: 'sys.color.outlineVariant' },
    },

    'disabled-container-opacity': { kind: 'opacity', value: 0.1 },
    'disabled-content-opacity': { kind: 'opacity', value: 0.38 },
    'disabled-outline-opacity': { kind: 'opacity', value: 0.38 },
  },
} as const satisfies ComponentTokenRegistration

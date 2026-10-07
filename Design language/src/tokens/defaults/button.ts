import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX Material 3 Button values adapted from dp to CSS pixels.
 * Variant state colors and elevation stay connected to theme system roles.
 */
export const defaultButtonTokens = {
  component: 'button',
  task: 'T07',
  source: {
    id: 'androidx-material3-button',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/dd849e200f5046c2f2ca904e821fc9d42cbd0256/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/Button.kt',
    revision: 'dd849e200f5046c2f2ca904e821fc9d42cbd0256',
    accessed: '2026-07-19',
  },
  tokens: {
    'minimum-interactive-target': {
      kind: 'dimension',
      value: { $ref: 'sys.density.minimumInteractiveTarget' },
    },
    'minimum-width': { kind: 'dimension', value: '58px' },
    'focus-ring-width': { kind: 'dimension', value: '2px' },
    'focus-ring-offset': { kind: 'dimension', value: '2px' },
    'focus-ring-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },

    'extra-small-container-height': { kind: 'dimension', value: '32px' },
    'extra-small-padding-block': { kind: 'dimension', value: '6px' },
    'extra-small-padding-inline': { kind: 'dimension', value: '12px' },
    'extra-small-icon-size': { kind: 'dimension', value: '20px' },
    'extra-small-icon-spacing': { kind: 'dimension', value: '4px' },
    'extra-small-container-shape-round': { kind: 'shape', value: '16px' },
    'extra-small-container-shape-square': {
      kind: 'shape',
      value: { $ref: 'sys.shape.corners.cornerMedium' },
    },
    'extra-small-pressed-container-shape': {
      kind: 'shape',
      value: { $ref: 'sys.shape.corners.cornerSmall' },
    },
    'extra-small-outline-width': { kind: 'dimension', value: '1px' },

    'small-container-height': { kind: 'dimension', value: '40px' },
    'small-padding-block': { kind: 'dimension', value: '10px' },
    'small-padding-inline': { kind: 'dimension', value: '16px' },
    'small-icon-size': { kind: 'dimension', value: '20px' },
    'small-icon-spacing': { kind: 'dimension', value: '8px' },
    'small-container-shape-round': { kind: 'shape', value: '20px' },
    'small-container-shape-square': {
      kind: 'shape',
      value: { $ref: 'sys.shape.corners.cornerMedium' },
    },
    'small-pressed-container-shape': {
      kind: 'shape',
      value: { $ref: 'sys.shape.corners.cornerSmall' },
    },
    'small-outline-width': { kind: 'dimension', value: '1px' },

    'medium-container-height': { kind: 'dimension', value: '56px' },
    'medium-padding-block': { kind: 'dimension', value: '16px' },
    'medium-padding-inline': { kind: 'dimension', value: '24px' },
    'medium-icon-size': { kind: 'dimension', value: '24px' },
    'medium-icon-spacing': { kind: 'dimension', value: '8px' },
    'medium-container-shape-round': { kind: 'shape', value: '28px' },
    'medium-container-shape-square': {
      kind: 'shape',
      value: { $ref: 'sys.shape.corners.cornerLarge' },
    },
    'medium-pressed-container-shape': {
      kind: 'shape',
      value: { $ref: 'sys.shape.corners.cornerMedium' },
    },
    'medium-outline-width': { kind: 'dimension', value: '1px' },

    'large-container-height': { kind: 'dimension', value: '96px' },
    'large-padding-block': { kind: 'dimension', value: '32px' },
    'large-padding-inline': { kind: 'dimension', value: '48px' },
    'large-icon-size': { kind: 'dimension', value: '32px' },
    'large-icon-spacing': { kind: 'dimension', value: '12px' },
    'large-container-shape-round': { kind: 'shape', value: '48px' },
    'large-container-shape-square': {
      kind: 'shape',
      value: { $ref: 'sys.shape.corners.cornerExtraLarge' },
    },
    'large-pressed-container-shape': {
      kind: 'shape',
      value: { $ref: 'sys.shape.corners.cornerLarge' },
    },
    'large-outline-width': { kind: 'dimension', value: '2px' },

    'extra-large-container-height': { kind: 'dimension', value: '136px' },
    'extra-large-padding-block': { kind: 'dimension', value: '48px' },
    'extra-large-padding-inline': { kind: 'dimension', value: '64px' },
    'extra-large-icon-size': { kind: 'dimension', value: '40px' },
    'extra-large-icon-spacing': { kind: 'dimension', value: '16px' },
    'extra-large-container-shape-round': { kind: 'shape', value: '68px' },
    'extra-large-container-shape-square': {
      kind: 'shape',
      value: { $ref: 'sys.shape.corners.cornerExtraLarge' },
    },
    'extra-large-pressed-container-shape': {
      kind: 'shape',
      value: { $ref: 'sys.shape.corners.cornerLarge' },
    },
    'extra-large-outline-width': { kind: 'dimension', value: '3px' },

    'filled-container-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'filled-content-color': { kind: 'color', value: { $ref: 'sys.color.onPrimary' } },
    'filled-disabled-container-color': {
      kind: 'color',
      value: { $ref: 'sys.color.onSurface' },
    },
    'filled-disabled-content-color': {
      kind: 'color',
      value: { $ref: 'sys.color.onSurfaceVariant' },
    },
    'filled-disabled-container-opacity': { kind: 'opacity', value: 0.1 },
    'filled-disabled-content-opacity': { kind: 'opacity', value: 0.38 },
    'filled-container-shadow': {
      kind: 'shadow',
      value: { $ref: 'sys.elevation.level0.shadow' },
    },
    'filled-hover-container-shadow': {
      kind: 'shadow',
      value: { $ref: 'sys.elevation.level1.shadow' },
    },

    'tonal-container-color': {
      kind: 'color',
      value: { $ref: 'sys.color.secondaryContainer' },
    },
    'tonal-content-color': {
      kind: 'color',
      value: { $ref: 'sys.color.onSecondaryContainer' },
    },
    'tonal-disabled-container-color': {
      kind: 'color',
      value: { $ref: 'sys.color.onSurface' },
    },
    'tonal-disabled-content-color': {
      kind: 'color',
      value: { $ref: 'sys.color.onSurface' },
    },
    'tonal-disabled-container-opacity': { kind: 'opacity', value: 0.12 },
    'tonal-disabled-content-opacity': { kind: 'opacity', value: 0.38 },
    'tonal-container-shadow': {
      kind: 'shadow',
      value: { $ref: 'sys.elevation.level0.shadow' },
    },
    'tonal-hover-container-shadow': {
      kind: 'shadow',
      value: { $ref: 'sys.elevation.level1.shadow' },
    },

    'elevated-container-color': {
      kind: 'color',
      value: { $ref: 'sys.color.surfaceContainerLow' },
    },
    'elevated-content-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'elevated-disabled-container-color': {
      kind: 'color',
      value: { $ref: 'sys.color.onSurface' },
    },
    'elevated-disabled-content-color': {
      kind: 'color',
      value: { $ref: 'sys.color.onSurfaceVariant' },
    },
    'elevated-disabled-container-opacity': { kind: 'opacity', value: 0.1 },
    'elevated-disabled-content-opacity': { kind: 'opacity', value: 0.38 },
    'elevated-container-shadow': {
      kind: 'shadow',
      value: { $ref: 'sys.elevation.level1.shadow' },
    },
    'elevated-hover-container-shadow': {
      kind: 'shadow',
      value: { $ref: 'sys.elevation.level2.shadow' },
    },

    'outlined-content-color': {
      kind: 'color',
      value: { $ref: 'sys.color.onSurfaceVariant' },
    },
    'outlined-outline-color': {
      kind: 'color',
      value: { $ref: 'sys.color.outlineVariant' },
    },
    'outlined-disabled-content-color': {
      kind: 'color',
      value: { $ref: 'sys.color.onSurfaceVariant' },
    },
    'outlined-disabled-outline-color': {
      kind: 'color',
      value: { $ref: 'sys.color.outlineVariant' },
    },
    'outlined-disabled-content-opacity': { kind: 'opacity', value: 0.38 },
    'outlined-disabled-outline-opacity': { kind: 'opacity', value: 0.1 },

    'text-content-color': {
      kind: 'color',
      value: { $ref: 'sys.color.onSurfaceVariant' },
    },
    'text-disabled-content-color': {
      kind: 'color',
      value: { $ref: 'sys.color.onSurfaceVariant' },
    },
    'text-disabled-content-opacity': { kind: 'opacity', value: 0.38 },
  },
} as const satisfies ComponentTokenRegistration

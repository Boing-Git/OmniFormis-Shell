import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX Material 3 Card values adapted from dp to CSS pixels.
 * Container, outline, disabled, and per-state elevation values remain linked
 * to the theme's system roles.
 */
export const defaultCardTokens = {
  component: 'card',
  task: 'T10',
  source: {
    id: 'androidx-material3-card',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/0be207d91046b7376beeef5544d331a02d6fa87c/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/Card.kt',
    revision: '0be207d91046b7376beeef5544d331a02d6fa87c',
    accessed: '2026-07-19',
  },
  tokens: {
    'minimum-interactive-target': {
      kind: 'dimension',
      value: { $ref: 'sys.density.minimumInteractiveTarget' },
    },
    'container-shape': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerMedium' },
    },
    'focus-ring-width': { kind: 'dimension', value: '2px' },
    'focus-ring-offset': { kind: 'dimension', value: '2px' },
    'focus-ring-color': { kind: 'color', value: { $ref: 'sys.color.secondary' } },
    'disabled-content-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'disabled-content-opacity': { kind: 'opacity', value: 0.38 },

    'filled-container-color': {
      kind: 'color', value: { $ref: 'sys.color.surfaceContainerHighest' },
    },
    'filled-content-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'filled-disabled-container-color': {
      kind: 'color', value: { $ref: 'sys.color.surfaceVariant' },
    },
    'filled-disabled-container-base-color': {
      kind: 'color', value: { $ref: 'sys.color.surfaceContainerHighest' },
    },
    'filled-disabled-container-opacity': { kind: 'opacity', value: 0.38 },
    'filled-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level0.shadow' },
    },
    'filled-hover-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level1.shadow' },
    },
    'filled-focus-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level0.shadow' },
    },
    'filled-pressed-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level0.shadow' },
    },
    'filled-disabled-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level0.shadow' },
    },

    'elevated-container-color': {
      kind: 'color', value: { $ref: 'sys.color.surfaceContainerLow' },
    },
    'elevated-content-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'elevated-disabled-container-color': {
      kind: 'color', value: { $ref: 'sys.color.surface' },
    },
    'elevated-disabled-container-base-color': {
      kind: 'color', value: { $ref: 'sys.color.surface' },
    },
    'elevated-disabled-container-opacity': { kind: 'opacity', value: 0.38 },
    'elevated-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level1.shadow' },
    },
    'elevated-hover-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level2.shadow' },
    },
    'elevated-focus-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level1.shadow' },
    },
    'elevated-pressed-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level1.shadow' },
    },
    'elevated-disabled-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level1.shadow' },
    },

    'outlined-container-color': {
      kind: 'color', value: { $ref: 'sys.color.surface' },
    },
    'outlined-content-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'outlined-outline-color': {
      kind: 'color', value: { $ref: 'sys.color.outlineVariant' },
    },
    'outlined-hover-outline-color': {
      kind: 'color', value: { $ref: 'sys.color.outlineVariant' },
    },
    'outlined-focus-outline-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'outlined-pressed-outline-color': {
      kind: 'color', value: { $ref: 'sys.color.outlineVariant' },
    },
    'outlined-outline-width': { kind: 'dimension', value: '1px' },
    'outlined-disabled-container-color': {
      kind: 'color', value: { $ref: 'sys.color.surface' },
    },
    'outlined-disabled-container-base-color': {
      kind: 'color', value: { $ref: 'sys.color.surface' },
    },
    'outlined-disabled-container-opacity': { kind: 'opacity', value: 1 },
    'outlined-disabled-outline-color': {
      kind: 'color', value: { $ref: 'sys.color.outline' },
    },
    'outlined-disabled-outline-base-color': {
      kind: 'color', value: { $ref: 'sys.color.surfaceContainerLow' },
    },
    'outlined-disabled-outline-opacity': { kind: 'opacity', value: 0.12 },
    'outlined-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level0.shadow' },
    },
    'outlined-hover-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level1.shadow' },
    },
    'outlined-focus-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level0.shadow' },
    },
    'outlined-pressed-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level0.shadow' },
    },
    'outlined-disabled-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level0.shadow' },
    },
  },
} as const satisfies ComponentTokenRegistration

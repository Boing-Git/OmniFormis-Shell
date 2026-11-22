import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX Material 3 FAB and Expressive toggle-FAB values adapted
 * from dp to CSS pixels. Colors, elevation, state, and shapes stay connected
 * to theme system roles.
 */
export const defaultFloatingActionButtonTokens = {
  component: 'floating-action-button',
  task: 'T09',
  source: {
    id: 'androidx-material3-floating-action-button',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/b0ef6d36c141931a051272e39ad3f4783dcb28e0/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/FloatingActionButton.kt',
    revision: 'b0ef6d36c141931a051272e39ad3f4783dcb28e0',
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

    'container-color': {
      kind: 'color', value: { $ref: 'sys.color.primaryContainer' },
    },
    'content-color': {
      kind: 'color', value: { $ref: 'sys.color.onPrimaryContainer' },
    },
    'toggle-selected-container-color': {
      kind: 'color', value: { $ref: 'sys.color.primary' },
    },
    'toggle-selected-content-color': {
      kind: 'color', value: { $ref: 'sys.color.onPrimary' },
    },
    'disabled-container-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'disabled-content-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'disabled-container-opacity': { kind: 'opacity', value: 0.12 },
    'disabled-content-opacity': { kind: 'opacity', value: 0.38 },

    'standard-container-size': { kind: 'dimension', value: '56px' },
    'standard-container-shape': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerLarge' },
    },
    'standard-icon-size': { kind: 'dimension', value: '24px' },
    'standard-extended-leading-space': { kind: 'dimension', value: '16px' },
    'standard-extended-trailing-space': { kind: 'dimension', value: '16px' },
    'standard-extended-icon-label-space': { kind: 'dimension', value: '8px' },

    'medium-container-size': { kind: 'dimension', value: '80px' },
    'medium-container-shape': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerLargeIncreased' },
    },
    'medium-icon-size': { kind: 'dimension', value: '28px' },
    'medium-extended-leading-space': { kind: 'dimension', value: '26px' },
    'medium-extended-trailing-space': { kind: 'dimension', value: '26px' },
    'medium-extended-icon-label-space': { kind: 'dimension', value: '12px' },

    'large-container-size': { kind: 'dimension', value: '96px' },
    'large-container-shape': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerExtraLarge' },
    },
    'large-icon-size': { kind: 'dimension', value: '36px' },
    'large-extended-leading-space': { kind: 'dimension', value: '28px' },
    'large-extended-trailing-space': { kind: 'dimension', value: '28px' },
    'large-extended-icon-label-space': { kind: 'dimension', value: '16px' },

    'toggle-selected-container-size': { kind: 'dimension', value: '56px' },
    'toggle-selected-container-shape': { kind: 'shape', value: '28px' },
    'toggle-selected-icon-size': { kind: 'dimension', value: '20px' },

    'default-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level3.shadow' },
    },
    'default-hover-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level4.shadow' },
    },
    'default-focus-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level3.shadow' },
    },
    'default-pressed-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level3.shadow' },
    },
    'lowered-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level1.shadow' },
    },
    'lowered-hover-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level2.shadow' },
    },
    'lowered-focus-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level1.shadow' },
    },
    'lowered-pressed-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level1.shadow' },
    },
    'zero-container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level0.shadow' },
    },
  },
} as const satisfies ComponentTokenRegistration

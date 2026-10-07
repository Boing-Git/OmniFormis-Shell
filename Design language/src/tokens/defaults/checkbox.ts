import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX Material 3 Checkbox values adapted from dp to CSS pixels.
 *
 * Geometry follows the token-backed `CheckboxTokens` path that the pinned
 * implementation selects when `isCheckboxStylingFixEnabled` is enabled. The
 * three unchecked color roles are `Color.Transparent` literals in the pinned
 * source rather than tokens, so the stylesheet expresses them directly instead
 * of registering an unthemed variable.
 */
export const defaultCheckboxTokens = {
  component: 'checkbox',
  task: 'T11',
  source: {
    id: 'androidx-material3-checkbox',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/Checkbox.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-19',
  },
  tokens: {
    'minimum-interactive-target': {
      kind: 'dimension',
      value: { $ref: 'sys.density.minimumInteractiveTarget' },
    },
    'container-size': { kind: 'dimension', value: '18px' },
    'container-shape': { kind: 'shape', value: '2px' },
    'outline-width': { kind: 'dimension', value: '2px' },
    'state-layer-size': { kind: 'dimension', value: '40px' },
    'checkmark-stroke-width': { kind: 'dimension', value: '2px' },
    // Arc length of the sourced three-point checkmark polyline on the 18px
    // container, rounded up so one dash covers either resolved geometry.
    'checkmark-path-length': { kind: 'number', value: 13 },
    'checkmark-snap-delay': { kind: 'string', value: '100ms' },

    'focus-ring-width': { kind: 'dimension', value: '2px' },
    'focus-ring-offset': { kind: 'dimension', value: '2px' },
    'focus-ring-color': { kind: 'color', value: { $ref: 'sys.color.secondary' } },

    'checked-checkmark-color': {
      kind: 'color', value: { $ref: 'sys.color.onPrimary' },
    },
    'disabled-checkmark-color': {
      kind: 'color', value: { $ref: 'sys.color.surface' },
    },

    'checked-container-color': {
      kind: 'color', value: { $ref: 'sys.color.primary' },
    },
    'disabled-checked-container-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'disabled-checked-container-opacity': { kind: 'opacity', value: 0.38 },
    'disabled-indeterminate-container-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'disabled-indeterminate-container-opacity': { kind: 'opacity', value: 0.38 },

    'checked-outline-color': {
      kind: 'color', value: { $ref: 'sys.color.primary' },
    },
    'unchecked-outline-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' },
    },
    'disabled-checked-outline-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'disabled-checked-outline-opacity': { kind: 'opacity', value: 0.38 },
    'disabled-unchecked-outline-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'disabled-unchecked-outline-opacity': { kind: 'opacity', value: 0.38 },
    'disabled-indeterminate-outline-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'disabled-indeterminate-outline-opacity': { kind: 'opacity', value: 0.38 },

    // `indicatorColor` returns the checked box color for On and Indeterminate.
    // Its unchecked result is the transparent unchecked box color, which cannot
    // express hover, focus, or pressed feedback on the web, so the unchecked
    // state layer uses the sourced unselected outline role instead.
    'checked-state-layer-color': {
      kind: 'color', value: { $ref: 'sys.color.primary' },
    },
    'unchecked-state-layer-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' },
    },
  },
} as const satisfies ComponentTokenRegistration

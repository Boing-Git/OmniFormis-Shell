import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX Material 3 `DialogTokens`/`AlertDialogDefaults` values.
 * `AlertDialogDefaults.dialogPadding`/`textPadding` use the non-"precision
 * pointer" branch (24px/24px), matching every other provisional-Expressive
 * exclusion already applied across this library. `DialogMinWidth`/
 * `DialogMaxWidth` (280dp/560dp) are cross-validated against material-web's
 * dialog CSS (`min(560px, calc(100% - 48px))`), which also supplies the
 * 24px-per-side viewport margin and the 32% scrim opacity: the pinned
 * Compose source dims its window via an Android platform default, not a
 * cross-platform Material3 design token, so it has no value of its own to
 * pin for either concern.
 */
export const defaultDialogTokens = {
  component: 'dialog',
  task: 'T16',
  source: {
    id: 'androidx-material3-dialog',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/DialogTokens.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-20',
  },
  tokens: {
    'container-color': {
      kind: 'color', value: { $ref: 'sys.color.surfaceContainerHigh' },
    },
    'container-shape': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerExtraLarge' },
    },
    'container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level3.shadow' },
    },
    'container-padding': { kind: 'dimension', value: '24px' },
    'container-min-width': { kind: 'dimension', value: '280px' },
    'container-max-width': { kind: 'dimension', value: '560px' },
    'container-viewport-margin': { kind: 'dimension', value: '24px' },
    'icon-color': { kind: 'color', value: { $ref: 'sys.color.secondary' } },
    'icon-size': { kind: 'dimension', value: '24px' },
    'icon-spacing': { kind: 'dimension', value: '16px' },
    'headline-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'headline-spacing': { kind: 'dimension', value: '16px' },
    'supporting-text-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' },
    },
    'supporting-text-spacing': { kind: 'dimension', value: '24px' },
    'action-content-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'action-spacing': { kind: 'dimension', value: '8px' },
    'scrim-color': { kind: 'color', value: { $ref: 'sys.color.scrim' } },
    'scrim-opacity': { kind: 'opacity', value: 0.32 },
  },
} as const satisfies ComponentTokenRegistration

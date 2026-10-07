import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX Material 3 `NavigationDrawerTokens` values.
 * `ModalContainerColor`/`ModalContainerElevation` (surfaceContainerLow,
 * level1) apply to the `'modal'` variant only; `StandardContainerColor`/
 * `StandardContainerElevation` (plain surface, level0) apply to both
 * `'dismissible'` and `'permanent'` — the source uses the same "standard"
 * pair for both non-modal variants, so this registration does too rather
 * than inventing a second identical value under a different name.
 * `FocusIndicatorColor` (secondary) is registered for a visible keyboard-
 * focus ring, the same accessibility-driven registration Menu's own
 * `item-focus-ring-color` already made for an upstream-unread-by-default
 * role. `disabled-*` has no source at all (`NavigationDrawerItem`'s
 * `selected`-only color model has no disabled axis), the same universal
 * web-added dimming `NavigationBar`/`NavigationRail`/`Tabs` already use.
 * `scrim-color`/`scrim-opacity` (0.32) reuse Dialog's own cross-validated
 * scrim value (ADR 0016) for the `'modal'` variant's backdrop — the
 * pinned source's modal scrim is an Android platform default, not a
 * component token, the same situation Dialog's own registration already
 * resolved.
 */
export const defaultNavigationDrawerTokens = {
  component: 'navigation-drawer',
  task: 'T20',
  source: {
    id: 'androidx-material3-navigation-drawer',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/NavigationDrawerTokens.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-20',
  },
  tokens: {
    'modal-container-color': {
      kind: 'color', value: { $ref: 'sys.color.surfaceContainerLow' },
    },
    'modal-container-shadow': { kind: 'shadow', value: { $ref: 'sys.elevation.level1.shadow' } },
    'standard-container-color': { kind: 'color', value: { $ref: 'sys.color.surface' } },
    'standard-container-shadow': { kind: 'shadow', value: { $ref: 'sys.elevation.level0.shadow' } },
    'container-width': { kind: 'dimension', value: '360px' },
    'container-shape': { kind: 'shape', value: { $ref: 'sys.shape.corners.cornerLargeEnd' } },
    'scrim-color': { kind: 'color', value: { $ref: 'sys.color.scrim' } },
    'scrim-opacity': { kind: 'opacity', value: 0.32 },
    'item-list-padding-inline': { kind: 'dimension', value: '12px' },
    'item-active-icon-color': {
      kind: 'color', value: { $ref: 'sys.color.onSecondaryContainer' },
    },
    'item-active-label-color': {
      kind: 'color', value: { $ref: 'sys.color.onSecondaryContainer' },
    },
    'item-active-indicator-color': {
      kind: 'color', value: { $ref: 'sys.color.secondaryContainer' },
    },
    'item-active-indicator-height': { kind: 'dimension', value: '56px' },
    'item-active-indicator-shape': { kind: 'shape', value: { $ref: 'sys.shape.corners.cornerFull' } },
    'item-inactive-icon-color': { kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' } },
    'item-inactive-label-color': { kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' } },
    'item-icon-size': { kind: 'dimension', value: '24px' },
    'item-padding-inline-start': { kind: 'dimension', value: '16px' },
    'item-padding-inline-end': { kind: 'dimension', value: '24px' },
    'item-icon-label-gap': { kind: 'dimension', value: '12px' },
    'item-focus-ring-color': { kind: 'color', value: { $ref: 'sys.color.secondary' } },
    'item-disabled-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'item-disabled-opacity': { kind: 'opacity', value: 0.38 },
  },
} as const satisfies ComponentTokenRegistration

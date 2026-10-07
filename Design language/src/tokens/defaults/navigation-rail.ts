import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX Material 3 `NavigationRailColorTokens`/
 * `NavigationRailVerticalItemTokens`/`NavigationRailCollapsedTokens`
 * values, plus `NavigationRail.kt`'s own `NavigationRailHeaderPadding`
 * (8dp, a private layout constant, not a token-file value — the same
 * plain-layout-constant status `Tabs`'/`Tooltip`'s own sizing constants
 * have). The same active label/icon color split `NavigationBar` has
 * (`secondary` label, `onSecondaryContainer` icon) carries over unchanged.
 * `disabled-*` is the same universal web-added dimming `NavigationBar`'s
 * own registration already uses, for the identical reason (no disabled
 * color axis in the source).
 */
export const defaultNavigationRailTokens = {
  component: 'navigation-rail',
  task: 'T20',
  source: {
    id: 'androidx-material3-navigation-rail',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/NavigationRailColorTokens.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-20',
  },
  tokens: {
    'container-color': { kind: 'color', value: { $ref: 'sys.color.surface' } },
    'container-width': { kind: 'dimension', value: '96px' },
    'container-padding-block': { kind: 'dimension', value: '44px' },
    'container-header-gap': { kind: 'dimension', value: '8px' },
    'item-width': { kind: 'dimension', value: '80px' },
    'item-gap': { kind: 'dimension', value: '4px' },
    'item-active-icon-color': {
      kind: 'color', value: { $ref: 'sys.color.onSecondaryContainer' },
    },
    'item-active-label-color': { kind: 'color', value: { $ref: 'sys.color.secondary' } },
    'item-active-indicator-color': {
      kind: 'color', value: { $ref: 'sys.color.secondaryContainer' },
    },
    'item-active-indicator-width': { kind: 'dimension', value: '56px' },
    'item-active-indicator-height': { kind: 'dimension', value: '32px' },
    'item-active-indicator-shape': { kind: 'shape', value: { $ref: 'sys.shape.corners.cornerFull' } },
    'item-inactive-icon-color': { kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' } },
    'item-inactive-label-color': { kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' } },
    'item-icon-label-gap': { kind: 'dimension', value: '4px' },
    'item-icon-size': { kind: 'dimension', value: '24px' },
    'item-disabled-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'item-disabled-opacity': { kind: 'opacity', value: 0.38 },
  },
} as const satisfies ComponentTokenRegistration

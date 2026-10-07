import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX Material 3 `NavigationBarTokens`/
 * `NavigationBarVerticalItemTokens` values. `ItemActiveLabelTextColor`
 * (`secondary`) and `ItemActiveIconColor` (`onSecondaryContainer`) are a
 * genuine sourced split — the selected label and icon are not the same
 * color — not a simplification. Disabled state has no color axis in the
 * source (`NavigationBarItem`'s `enabled` param removes interactivity
 * only), so `disabled-*` reuses the same universal `onSurface`-at-`0.38`-
 * opacity treatment every other v1 interactive component already applies,
 * the same deliberate web addition `Tabs`' own disabled tokens already
 * made for the identical reason.
 */
export const defaultNavigationBarTokens = {
  component: 'navigation-bar',
  task: 'T20',
  source: {
    id: 'androidx-material3-navigation-bar',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/NavigationBarTokens.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-20',
  },
  tokens: {
    'container-color': { kind: 'color', value: { $ref: 'sys.color.surfaceContainer' } },
    'container-shadow': { kind: 'shadow', value: { $ref: 'sys.elevation.level2.shadow' } },
    'container-height': { kind: 'dimension', value: '64px' },
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

import type { ComponentTokenRegistration } from '../schema'

/**
 * `FabBaselineTokens`/`FabMenuBaselineTokens` values. Covers the source's
 * `FloatingActionButtonMenu`/`ToggleFloatingActionButton`/
 * `FloatingActionButtonMenuItem` composables, unified into one
 * self-contained component (`FabMenu`/`FabMenuItem`) that renders its
 * own trigger FAB directly rather than requiring a separately-composed
 * toggle FAB — see ADR 0024.
 *
 * `trigger-size` is `FabBaselineTokens.ContainerHeight`
 * (`56dp`) — *and* `FabMenuBaselineTokens.CloseButtonContainerHeight`
 * (also `56dp`): reading the actual sourced values (not the generic
 * `containerSize: (Float) -> Dp` interpolation callback shape the source
 * exposes) shows the trigger FAB never actually changes size between
 * collapsed and expanded, only shape/color/icon-size — so this project
 * registers one fixed size, not two interpolated ones.
 * `trigger-shape-collapsed`/`trigger-shape-expanded` are `CornerLarge`
 * (`16dp`, from `FloatingActionButtonMenu.kt`'s own internal
 * `FabInitialCornerRadius` constant, not yet promoted to a generated
 * token in the pinned source) and `CornerFull`. `trigger-icon-size-
 * collapsed`/`-expanded` are `FabBaselineTokens.IconSize` (`24dp`) and
 * `FabMenuBaselineTokens.CloseButtonIconSize` (`20dp`).
 * `trigger-container-color-collapsed`/`-expanded` are
 * `primaryContainer`/`primary` (`ToggleFloatingActionButtonDefaults
 * .containerColor`'s own default parameters); `trigger-content-color-
 * collapsed`/`-expanded` are `onPrimaryContainer`/`onPrimary`
 * (`.iconColor`'s own defaults).
 *
 * `item-height`/`item-shape` are `ListItemContainerHeight`/
 * `ListItemContainerShape` (`56dp`/`CornerFull`). `item-icon-size` is
 * `ListItemIconSize` (`24dp`). `item-leading-space`/`-trailing-space`
 * are `ListItemLeadingSpace`/`-TrailingSpace` (`24dp` each).
 * `item-icon-label-gap` is `ListItemIconLabelSpace` (`8dp`).
 * `item-gap` is `ListItemBetweenSpace` (`4dp`).
 * `button-gap` is `CloseButtonBetweenSpace` (`8dp`, the space between the
 * item list and the trigger FAB below it). `item-container-color`/
 * `item-content-color` are `primaryContainer`/`onPrimaryContainer`
 * (`FloatingActionButtonMenuItem`'s own default parameters).
 */
export const defaultFabMenuTokens = {
  component: 'fab-menu',
  task: 'T24',
  source: {
    id: 'androidx-material3-fab-menu',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/FloatingActionButtonMenu.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-20',
  },
  tokens: {
    'trigger-size': { kind: 'dimension', value: '56px' },
    'trigger-shape-collapsed': { kind: 'dimension', value: { $ref: 'sys.shape.cornerValues.large' } },
    'trigger-shape-expanded': { kind: 'shape', value: { $ref: 'sys.shape.corners.cornerFull' } },
    'trigger-icon-size-collapsed': { kind: 'dimension', value: '24px' },
    'trigger-icon-size-expanded': { kind: 'dimension', value: '20px' },
    'trigger-container-color-collapsed': { kind: 'color', value: { $ref: 'sys.color.primaryContainer' } },
    'trigger-container-color-expanded': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'trigger-content-color-collapsed': { kind: 'color', value: { $ref: 'sys.color.onPrimaryContainer' } },
    'trigger-content-color-expanded': { kind: 'color', value: { $ref: 'sys.color.onPrimary' } },
    'trigger-elevation': { kind: 'shadow', value: { $ref: 'sys.elevation.level3.shadow' } },

    'button-gap': { kind: 'dimension', value: '8px' },

    'item-height': { kind: 'dimension', value: '56px' },
    'item-shape': { kind: 'shape', value: { $ref: 'sys.shape.corners.cornerFull' } },
    'item-icon-size': { kind: 'dimension', value: '24px' },
    'item-leading-space': { kind: 'dimension', value: '24px' },
    'item-trailing-space': { kind: 'dimension', value: '24px' },
    'item-icon-label-gap': { kind: 'dimension', value: '8px' },
    'item-gap': { kind: 'dimension', value: '4px' },
    'item-container-color': { kind: 'color', value: { $ref: 'sys.color.primaryContainer' } },
    'item-content-color': { kind: 'color', value: { $ref: 'sys.color.onPrimaryContainer' } },
    'item-elevation': { kind: 'shadow', value: { $ref: 'sys.elevation.level3.shadow' } },
  },
} as const satisfies ComponentTokenRegistration

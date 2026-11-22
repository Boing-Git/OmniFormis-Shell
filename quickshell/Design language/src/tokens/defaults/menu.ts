import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX Material 3 `MenuTokens`/`ListTokens`/`StandardMenuTokens`
 * values, shared by both `Menu` and `Select`'s popup listbox — the pinned
 * source's `ExposedDropdownMenuDefaults` resolves its own shape/color/
 * elevation straight through to the same `MenuDefaults.shape`/
 * `containerColor`/`TonalElevation`/`ShadowElevation` plain `DropdownMenu`
 * uses, not a distinct exposed-dropdown token set, so `Select` registers no
 * component tokens of its own for its popup (see `text-field.ts` for its
 * field chrome, reused unchanged for the same reason).
 *
 * The plain, non-selectable `DropdownMenuItemContent` the source resolves to
 * has no independent shape or background of its own — a bare `Row` with only
 * ripple indication — so item color roles come from `ListTokens`
 * (`ItemLabelTextColor` onSurface, `ItemLeadingIconColor`/
 * `ItemTrailingIconColor` onSurfaceVariant, disabled-0.38 pair) and item
 * rows carry no corner-radius token, unlike the separate Expressive per-item
 * hover/press shape-morph roles (`ItemHoveredContainerExpressiveShape`,
 * etc.) that belong to a different, out-of-scope "expressive list"/grouped-
 * menu rendering path (`DropdownMenuGroup`/`MenuGroupShapes`/cascading
 * menus/drag-select), which has no clean web equivalent and no accompanying
 * gesture surface here. Checked-item color is `StandardMenuTokens` (`Item
 * SelectedContainerColor` tertiaryContainer, `ItemSelected*Color`
 * onTertiaryContainer, disabled-0.38 pair) — the values
 * `defaultMenuSelectableItemColors` actually reads, not the unread
 * `MenuTokens.ListItemSelectedContainerColor`/secondaryContainer role the
 * token file itself defines but no default color resolver ever reaches.
 * `MenuItemColors`' own resolution takes only `(enabled, selected)` — no
 * hover/focus/pressed axis exists in the source's color model — so hover/
 * pressed feedback reuses the shared `--m3e-sys-state-*` state-layer system
 * every other v1 interactive component already applies, with no separate
 * state-layer color role registered here. `MenuTokens.FocusIndicatorColor`
 * (secondary) is registered for a visible keyboard-focus ring despite being
 * upstream-unread by any color resolver, the same deliberate web addition
 * Checkbox/Radio already made for the same accessibility requirement. Label typography reuses
 * the existing `label-large` typescale variables directly, matching every
 * prior task's unread-typography-role precedent (`LabelTextFont` is unread
 * by name for the same reason as every prior component's typography roles).
 */
export const defaultMenuTokens = {
  component: 'menu',
  task: 'T17',
  source: {
    id: 'androidx-material3-menu',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/MenuTokens.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-20',
  },
  tokens: {
    'container-color': {
      kind: 'color', value: { $ref: 'sys.color.surfaceContainer' },
    },
    'container-shape': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerExtraSmall' },
    },
    'container-shadow': {
      kind: 'shadow', value: { $ref: 'sys.elevation.level2.shadow' },
    },
    'container-padding-block': { kind: 'dimension', value: '8px' },
    'container-min-width': { kind: 'dimension', value: '112px' },
    'container-max-width': { kind: 'dimension', value: '280px' },
    'viewport-margin': { kind: 'dimension', value: '8px' },
    'item-min-height': { kind: 'dimension', value: '48px' },
    'item-padding-inline': { kind: 'dimension', value: '12px' },
    'item-container-shape': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerNone' },
    },
    'item-focus-ring-color': { kind: 'color', value: { $ref: 'sys.color.secondary' } },
    'item-label-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'item-leading-icon-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' },
    },
    'item-trailing-icon-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' },
    },
    'item-icon-size': { kind: 'dimension', value: '24px' },
    'item-disabled-label-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'item-disabled-label-opacity': { kind: 'opacity', value: 0.38 },
    'item-disabled-leading-icon-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'item-disabled-leading-icon-opacity': { kind: 'opacity', value: 0.38 },
    'item-disabled-trailing-icon-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'item-disabled-trailing-icon-opacity': { kind: 'opacity', value: 0.38 },
    'item-checked-container-color': {
      kind: 'color', value: { $ref: 'sys.color.tertiaryContainer' },
    },
    'item-checked-label-color': {
      kind: 'color', value: { $ref: 'sys.color.onTertiaryContainer' },
    },
    'item-checked-leading-icon-color': {
      kind: 'color', value: { $ref: 'sys.color.onTertiaryContainer' },
    },
    'item-checked-trailing-icon-color': {
      kind: 'color', value: { $ref: 'sys.color.onTertiaryContainer' },
    },
    'item-checked-disabled-container-color': {
      kind: 'color', value: { $ref: 'sys.color.tertiaryContainer' },
    },
    'item-checked-disabled-container-opacity': { kind: 'opacity', value: 0.38 },
    'item-checked-disabled-label-color': {
      kind: 'color', value: { $ref: 'sys.color.onTertiaryContainer' },
    },
    'item-checked-disabled-label-opacity': { kind: 'opacity', value: 0.38 },
  },
} as const satisfies ComponentTokenRegistration

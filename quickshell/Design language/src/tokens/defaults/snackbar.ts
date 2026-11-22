import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX Material 3 `SnackbarTokens` values, plus the sourced
 * layout constants `Snackbar.kt` itself defines (`ContainerMaxWidth`,
 * `HorizontalSpacing`, `HorizontalSpacingButtonSide`,
 * `SnackbarVerticalPadding`). `IconColor`/`IconSize` belong to the optional
 * dismiss action only — the pinned source's public `Snackbar` composable has
 * no separate leading status-icon slot. Action label focus/hover/pressed
 * colors all resolve to the same `inversePrimary` role (confirmed against
 * material-web's `_md-comp-snackbar.scss` at the same pinned revision this
 * project's `material-web-tokens` source already uses), so hover/press
 * feedback reuses the shared `--m3e-sys-state-*` state-layer system via
 * `currentColor`, the same `Menu`/`Select` precedent, with no separate
 * state-layer color token. The `actionOnNewLine` two-row legacy layout is
 * excluded — see ADR 0018.
 */
export const defaultSnackbarTokens = {
  component: 'snackbar',
  task: 'T18',
  source: {
    id: 'androidx-material3-snackbar',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/SnackbarTokens.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-20',
  },
  tokens: {
    'container-color': { kind: 'color', value: { $ref: 'sys.color.inverseSurface' } },
    'container-shape': { kind: 'shape', value: { $ref: 'sys.shape.corners.cornerExtraSmall' } },
    'container-shadow': { kind: 'shadow', value: { $ref: 'sys.elevation.level3.shadow' } },
    'container-min-height': { kind: 'dimension', value: '48px' },
    'container-max-width': { kind: 'dimension', value: '600px' },
    'container-padding-inline': { kind: 'dimension', value: '16px' },
    'container-padding-inline-button-side': { kind: 'dimension', value: '8px' },
    'container-padding-block': { kind: 'dimension', value: '14px' },
    'supporting-text-color': { kind: 'color', value: { $ref: 'sys.color.inverseOnSurface' } },
    'action-label-color': { kind: 'color', value: { $ref: 'sys.color.inversePrimary' } },
    'dismiss-icon-color': { kind: 'color', value: { $ref: 'sys.color.inverseOnSurface' } },
    'icon-size': { kind: 'dimension', value: '24px' },
  },
} as const satisfies ComponentTokenRegistration

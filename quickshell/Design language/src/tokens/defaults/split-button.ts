import type { ComponentTokenRegistration } from '../schema'

/**
 * `SplitButtonXSmallTokens` through `SplitButtonXLargeTokens` values, plus
 * `Button`'s own variant color tokens (registered independently here
 * rather than shared, the same duplication-over-premature-extraction
 * precedent `WavyProgress`/`CircularProgress` already used).
 *
 * This component renders its own two `<button>` elements directly rather
 * than nesting the public `Button`/`IconButton` components — the same
 * "composite components own their internal buttons" precedent
 * `SegmentedButtonGroup` (T15) already established. See ADR 0023.
 *
 * `*-inner-corner` is each size's `InnerCornerCornerSize` (the small
 * shared radius between the two buttons at rest); `*-inner-corner-hover`
 * is `InnerHoveredCornerCornerSize`/`InnerPressedCornerCornerSize` (the
 * source uses the *same* value for both hover and press — this project
 * does too, one token covers both states). Note these corners *expand*
 * on hover/press, the opposite of `Button`'s own round-to-square press
 * morph — a deliberate source behavior, not a bug.
 * `outer-corner`/`trailing-checked-shape` (`CornerFull`, shared by every
 * size) are `SplitButtonDefaults.OuterCornerSize`/the `CircleShape`
 * default for the trailing button's checked state — a fully round trailing
 * button already satisfies "circle" for a roughly-square icon-only button,
 * so both reuse the same `cornerFull` token rather than registering a
 * separate one.
 *
 * `leading-icon-size` per size is *not* sourced from `SplitButtonDefaults
 * .LeadingIconSize` (a single fixed `ButtonSmallTokens.IconSize` for every
 * split-button size in the pinned source, seemingly an oversight since
 * every other leading-button dimension here scales per size) — this
 * project instead reuses `Button`'s own already-established per-size icon
 * scale (T07) for consistency, a small, deliberate, documented deviation.
 * `trailing-icon-size` per size *is* the sourced `TrailingIconSize`.
 */
export const defaultSplitButtonTokens = {
  component: 'split-button',
  task: 'T23',
  source: {
    id: 'androidx-material3-split-button',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/SplitButton.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-20',
  },
  tokens: {
    'between-space': { kind: 'dimension', value: '2px' },
    'outer-corner': { kind: 'shape', value: { $ref: 'sys.shape.corners.cornerFull' } },
    'trailing-checked-shape': { kind: 'shape', value: { $ref: 'sys.shape.corners.cornerFull' } },
    'focus-ring-width': { kind: 'dimension', value: '2px' },
    'focus-ring-offset': { kind: 'dimension', value: '2px' },
    'focus-ring-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },

    'extra-small-container-height': { kind: 'dimension', value: '32px' },
    'extra-small-inner-corner': { kind: 'dimension', value: { $ref: 'sys.shape.cornerValues.extraSmall' } },
    'extra-small-inner-corner-hover': { kind: 'dimension', value: { $ref: 'sys.shape.cornerValues.small' } },
    'extra-small-leading-leading-space': { kind: 'dimension', value: '12px' },
    'extra-small-leading-trailing-space': { kind: 'dimension', value: '10px' },
    'extra-small-trailing-leading-space': { kind: 'dimension', value: '13px' },
    'extra-small-trailing-trailing-space': { kind: 'dimension', value: '13px' },
    'extra-small-leading-icon-size': { kind: 'dimension', value: '20px' },
    'extra-small-trailing-icon-size': { kind: 'dimension', value: '22px' },

    'small-container-height': { kind: 'dimension', value: '40px' },
    'small-inner-corner': { kind: 'dimension', value: { $ref: 'sys.shape.cornerValues.extraSmall' } },
    'small-inner-corner-hover': { kind: 'dimension', value: { $ref: 'sys.shape.cornerValues.medium' } },
    'small-leading-leading-space': { kind: 'dimension', value: '16px' },
    'small-leading-trailing-space': { kind: 'dimension', value: '12px' },
    'small-trailing-leading-space': { kind: 'dimension', value: '13px' },
    'small-trailing-trailing-space': { kind: 'dimension', value: '13px' },
    'small-leading-icon-size': { kind: 'dimension', value: '20px' },
    'small-trailing-icon-size': { kind: 'dimension', value: '22px' },

    'medium-container-height': { kind: 'dimension', value: '56px' },
    'medium-inner-corner': { kind: 'dimension', value: { $ref: 'sys.shape.cornerValues.extraSmall' } },
    'medium-inner-corner-hover': { kind: 'dimension', value: { $ref: 'sys.shape.cornerValues.medium' } },
    'medium-leading-leading-space': { kind: 'dimension', value: '24px' },
    'medium-leading-trailing-space': { kind: 'dimension', value: '24px' },
    'medium-trailing-leading-space': { kind: 'dimension', value: '15px' },
    'medium-trailing-trailing-space': { kind: 'dimension', value: '15px' },
    'medium-leading-icon-size': { kind: 'dimension', value: '24px' },
    'medium-trailing-icon-size': { kind: 'dimension', value: '26px' },

    'large-container-height': { kind: 'dimension', value: '96px' },
    'large-inner-corner': { kind: 'dimension', value: { $ref: 'sys.shape.cornerValues.small' } },
    'large-inner-corner-hover': { kind: 'dimension', value: { $ref: 'sys.shape.cornerValues.largeIncreased' } },
    'large-leading-leading-space': { kind: 'dimension', value: '48px' },
    'large-leading-trailing-space': { kind: 'dimension', value: '48px' },
    'large-trailing-leading-space': { kind: 'dimension', value: '29px' },
    'large-trailing-trailing-space': { kind: 'dimension', value: '29px' },
    'large-leading-icon-size': { kind: 'dimension', value: '32px' },
    'large-trailing-icon-size': { kind: 'dimension', value: '38px' },

    'extra-large-container-height': { kind: 'dimension', value: '136px' },
    'extra-large-inner-corner': { kind: 'dimension', value: { $ref: 'sys.shape.cornerValues.medium' } },
    'extra-large-inner-corner-hover': { kind: 'dimension', value: { $ref: 'sys.shape.cornerValues.largeIncreased' } },
    'extra-large-leading-leading-space': { kind: 'dimension', value: '64px' },
    'extra-large-leading-trailing-space': { kind: 'dimension', value: '64px' },
    'extra-large-trailing-leading-space': { kind: 'dimension', value: '43px' },
    'extra-large-trailing-trailing-space': { kind: 'dimension', value: '43px' },
    'extra-large-leading-icon-size': { kind: 'dimension', value: '40px' },
    'extra-large-trailing-icon-size': { kind: 'dimension', value: '50px' },

    'filled-container-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'filled-content-color': { kind: 'color', value: { $ref: 'sys.color.onPrimary' } },
    'filled-disabled-container-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'filled-disabled-content-color': { kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' } },
    'filled-disabled-container-opacity': { kind: 'opacity', value: 0.1 },
    'filled-disabled-content-opacity': { kind: 'opacity', value: 0.38 },

    'tonal-container-color': { kind: 'color', value: { $ref: 'sys.color.secondaryContainer' } },
    'tonal-content-color': { kind: 'color', value: { $ref: 'sys.color.onSecondaryContainer' } },
    'tonal-disabled-container-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'tonal-disabled-content-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'tonal-disabled-container-opacity': { kind: 'opacity', value: 0.12 },
    'tonal-disabled-content-opacity': { kind: 'opacity', value: 0.38 },

    'elevated-container-color': { kind: 'color', value: { $ref: 'sys.color.surfaceContainerLow' } },
    'elevated-content-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'elevated-container-shadow': { kind: 'shadow', value: { $ref: 'sys.elevation.level1.shadow' } },
    'elevated-hover-container-shadow': { kind: 'shadow', value: { $ref: 'sys.elevation.level2.shadow' } },
    'elevated-disabled-container-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'elevated-disabled-content-color': { kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' } },
    'elevated-disabled-container-opacity': { kind: 'opacity', value: 0.1 },
    'elevated-disabled-content-opacity': { kind: 'opacity', value: 0.38 },

    'outlined-content-color': { kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' } },
    'outlined-outline-color': { kind: 'color', value: { $ref: 'sys.color.outlineVariant' } },
    'outlined-outline-width': { kind: 'dimension', value: '1px' },
    'outlined-disabled-content-color': { kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' } },
    'outlined-disabled-outline-color': { kind: 'color', value: { $ref: 'sys.color.outlineVariant' } },
    'outlined-disabled-content-opacity': { kind: 'opacity', value: 0.38 },
    'outlined-disabled-outline-opacity': { kind: 'opacity', value: 0.1 },
  },
} as const satisfies ComponentTokenRegistration

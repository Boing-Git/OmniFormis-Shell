import type { ComponentTokenRegistration } from '../schema'

/**
 * `FloatingToolbarTokens` values. Only the source's plain
 * `HorizontalFloatingToolbar`/`VerticalFloatingToolbar` composables
 * (unified here as one component with an `orientation` prop) are
 * covered — the integrated-FAB overload, `FloatingToolbarScrollBehavior`,
 * and Android's touch-exploration force-expand are out of scope. See
 * ADR 0024.
 *
 * `container-height` is `ContainerHeight` (`64dp`) — used as the
 * cross-axis size for both orientations (the source's own `Row`/`Column`
 * layouts share this one size token regardless of direction).
 * `container-shape` is `ContainerShape` (`CornerFull`). `content-padding`
 * is `ContainerLeadingSpace`/`ContainerTrailingSpace` (both `8dp` — the
 * source only ever pairs them as an equal all-sides padding for this
 * component, unlike components that use distinct leading/trailing
 * values). `item-gap` is `ContainerBetweenSpace` (`4dp`). `screen-offset`
 * is `ContainerExternalPadding` (`16dp`), exposed for consumers
 * positioning the toolbar themselves (this component does not prescribe
 * its own fixed/sticky placement).
 *
 * `standard-container-color`/`vibrant-container-color` are
 * `StandardContainerColor`/`VibrantContainerColor`
 * (`surfaceContainer`/`primaryContainer`). Content colors are not in the
 * generated token file (the source resolves `FloatingToolbarColors` from
 * a `ColorScheme` extension property this project didn't fetch) — this
 * project pairs each container color with Material's own conventional
 * on-container role (`onSurface` for `surfaceContainer`,
 * `onPrimaryContainer` for `primaryContainer`), the same reasoning this
 * project already applies whenever a specific content-color source value
 * isn't available. Elevation is `ElevationTokens.Level0` for both
 * expanded and collapsed states in the plain (non-FAB) treatment — no
 * elevation change is needed since none exists in the source either.
 */
export const defaultFloatingToolbarTokens = {
  component: 'floating-toolbar',
  task: 'T24',
  source: {
    id: 'androidx-material3-floating-toolbar',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/FloatingToolbar.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-20',
  },
  tokens: {
    'container-height': { kind: 'dimension', value: '64px' },
    'container-shape': { kind: 'shape', value: { $ref: 'sys.shape.corners.cornerFull' } },
    'content-padding': { kind: 'dimension', value: '8px' },
    'item-gap': { kind: 'dimension', value: '4px' },
    'screen-offset': { kind: 'dimension', value: '16px' },

    'standard-container-color': { kind: 'color', value: { $ref: 'sys.color.surfaceContainer' } },
    'standard-content-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'vibrant-container-color': { kind: 'color', value: { $ref: 'sys.color.primaryContainer' } },
    'vibrant-content-color': { kind: 'color', value: { $ref: 'sys.color.onPrimaryContainer' } },
  },
} as const satisfies ComponentTokenRegistration

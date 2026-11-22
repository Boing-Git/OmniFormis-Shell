import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX Material 3 Switch values adapted from dp to CSS pixels.
 *
 * `SwitchColors`/`defaultSwitchColors` never read the generated
 * Hover/Focus/Pressed-suffixed handle, track, or icon color roles, so they
 * are not registered here, matching the unread-role precedent from Checkbox
 * and Radio. Unlike those two, the pinned source's disabled colors are
 * pre-composited over a fixed `surface` backdrop
 * (`Color.copy(alpha).compositeOver(colorScheme.surface)`); this registration
 * keeps the Checkbox/Radio `color-mix(..., transparent)` technique instead so
 * disabled Switch controls composite correctly against whatever backdrop
 * they actually sit on, not only a literal surface-colored one.
 */
export const defaultSwitchTokens = {
  component: 'switch',
  task: 'T13',
  source: {
    id: 'androidx-material3-switch',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/Switch.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-20',
  },
  tokens: {
    'minimum-interactive-target': {
      kind: 'dimension',
      value: { $ref: 'sys.density.minimumInteractiveTarget' },
    },
    'track-width': { kind: 'dimension', value: '52px' },
    'track-height': { kind: 'dimension', value: '32px' },
    'track-outline-width': { kind: 'dimension', value: '2px' },
    'unselected-handle-size': { kind: 'dimension', value: '16px' },
    'selected-handle-size': { kind: 'dimension', value: '24px' },
    'pressed-handle-size': { kind: 'dimension', value: '28px' },
    'icon-size': { kind: 'dimension', value: '16px' },
    'state-layer-size': { kind: 'dimension', value: '40px' },

    'focus-ring-width': { kind: 'dimension', value: '2px' },
    'focus-ring-offset': { kind: 'dimension', value: '2px' },
    'focus-ring-color': { kind: 'color', value: { $ref: 'sys.color.secondary' } },

    'selected-track-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'selected-thumb-color': { kind: 'color', value: { $ref: 'sys.color.onPrimary' } },
    'selected-icon-color': {
      kind: 'color', value: { $ref: 'sys.color.onPrimaryContainer' },
    },

    'unselected-track-color': {
      kind: 'color', value: { $ref: 'sys.color.surfaceContainerHighest' },
    },
    // The source resolves the default unchecked border from
    // `UnselectedFocusTrackOutlineColor`, not `UnselectedTrackOutlineColor`;
    // both are the `Outline` role, so the naming has no visible effect.
    'unselected-border-color': { kind: 'color', value: { $ref: 'sys.color.outline' } },
    'unselected-thumb-color': { kind: 'color', value: { $ref: 'sys.color.outline' } },
    'unselected-icon-color': {
      kind: 'color', value: { $ref: 'sys.color.surfaceContainerHighest' },
    },

    // One shared constant (`DisabledTrackOpacity`) covers the disabled
    // checked track, disabled unchecked track, and disabled unchecked border.
    'disabled-track-opacity': { kind: 'opacity', value: 0.12 },
    'disabled-selected-track-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'disabled-unselected-track-color': {
      kind: 'color', value: { $ref: 'sys.color.surfaceContainerHighest' },
    },
    'disabled-unselected-border-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },

    // `DisabledSelectedHandleOpacity` is a real source constant equal to 1.0,
    // a documented no-op alpha kept as a literal opaque color instead of an
    // unused opacity token.
    'disabled-selected-thumb-color': { kind: 'color', value: { $ref: 'sys.color.surface' } },
    'disabled-selected-icon-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'disabled-selected-icon-opacity': { kind: 'opacity', value: 0.38 },
    'disabled-unselected-thumb-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'disabled-unselected-thumb-opacity': { kind: 'opacity', value: 0.38 },
    'disabled-unselected-icon-color': {
      kind: 'color', value: { $ref: 'sys.color.surfaceContainerHighest' },
    },
    'disabled-unselected-icon-opacity': { kind: 'opacity', value: 0.38 },

    // The pinned `ripple()` call passes no explicit per-state color, so its
    // resolved tint is ambient `LocalContentColor`, not a Switch color role.
    // The web state layer uses the same primary/on-surface-variant identity
    // pairing established for Checkbox's and Radio's own unread ripple color,
    // rather than the near-white thumb color, which would be nearly invisible.
    'selected-state-layer-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'unselected-state-layer-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' },
    },
  },
} as const satisfies ComponentTokenRegistration

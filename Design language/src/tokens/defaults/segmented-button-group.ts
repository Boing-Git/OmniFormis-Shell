import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX Material 3 SegmentedButton values adapted from dp to CSS
 * pixels.
 *
 * `defaultSegmentedButtonColors()` reads `OutlinedSegmentedButtonTokens.OutlineColor`
 * for both the active and inactive border, and reads
 * `DisabledLabelTextColor`/`DisabledLabelTextOpacity` for both the disabled
 * active and disabled inactive content color — the same upstream constant
 * both times, not two distinctly-named constants that happen to match — so
 * each is registered once here instead of as an active/inactive pair,
 * matching the T14 content-color consolidation precedent. The disabled
 * active container color reuses the enabled `SelectedContainerColor`
 * undimmed and the disabled inactive container stays the same `Transparent`
 * literal as the enabled inactive container: the token file defines no
 * disabled container role at all, so no disabled container token is
 * registered — a disabled selected segment keeps its full tonal fill.
 *
 * Every `Hover*`/`Focus*`/`Pressed*`-suffixed role, and even the base
 * `SelectedIconColor`/`UnselectedIconColor`/`DisabledIconColor`/
 * `DisabledIconOpacity` roles, are unread: `SegmentedButtonContent` never
 * tints its `Icon` explicitly, so the icon always inherits the same
 * `LocalContentColor` the label text resolves from the label-text tokens
 * above, matching the unread-role precedent from every prior selection
 * control while extending it to roles the source defines but never
 * connects to any color resolution path at all.
 *
 * The pinned source applies no `minimumInteractiveComponentSize`-equivalent
 * modifier to `SegmentedButton`, unlike Checkbox/Radio/Switch, so this
 * registration carries no `minimum-interactive-target` token — the 40px
 * `ContainerHeight` is the real, undilated interactive height.
 */
export const defaultSegmentedButtonGroupTokens = {
  component: 'segmented-button-group',
  task: 'T15',
  source: {
    id: 'androidx-material3-segmented-button',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/SegmentedButton.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-20',
  },
  tokens: {
    'container-height': { kind: 'dimension', value: '40px' },
    'minimum-width': { kind: 'dimension', value: '58px' },
    'container-shape': { kind: 'shape', value: { $ref: 'sys.shape.corners.cornerFull' } },
    'border-width': { kind: 'dimension', value: '1px' },
    'icon-size': { kind: 'dimension', value: '18px' },
    'icon-spacing': { kind: 'dimension', value: '8px' },
    'content-padding-inline': { kind: 'dimension', value: '12px' },
    'content-padding-block': { kind: 'dimension', value: '8px' },

    'focus-ring-width': { kind: 'dimension', value: '2px' },
    'focus-ring-offset': { kind: 'dimension', value: '2px' },
    'focus-ring-color': { kind: 'color', value: { $ref: 'sys.color.secondary' } },

    'active-container-color': {
      kind: 'color',
      value: { $ref: 'sys.color.secondaryContainer' },
    },
    'active-content-color': {
      kind: 'color',
      value: { $ref: 'sys.color.onSecondaryContainer' },
    },
    // The inactive container is a `Color.Transparent` literal in the pinned
    // source, not a themed role, so it is expressed directly in the
    // stylesheet instead of registered here, matching the Button/IconButton/
    // Checkbox precedent for the same literal.
    'inactive-content-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'border-color': { kind: 'color', value: { $ref: 'sys.color.outline' } },

    'disabled-content-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'disabled-content-opacity': { kind: 'opacity', value: 0.38 },
    'disabled-border-opacity': { kind: 'opacity', value: 0.12 },
  },
} as const satisfies ComponentTokenRegistration

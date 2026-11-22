import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX Material 3 RadioButton values adapted from dp to CSS pixels.
 *
 * The pinned source paints the outer ring and the inner dot with the same
 * `radioColor` value, so this registration keeps one icon-color role per state
 * instead of separate ring/dot roles. `RadioButtonTokens` also generates
 * Focus/Hover/Pressed icon-color roles that `RadioButtonColors` never reads;
 * they are not registered here for the same reason Checkbox's unread roles
 * were not.
 */
export const defaultRadioTokens = {
  component: 'radio',
  task: 'T12',
  source: {
    id: 'androidx-material3-radio-button',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/RadioButton.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-20',
  },
  tokens: {
    'minimum-interactive-target': {
      kind: 'dimension',
      value: { $ref: 'sys.density.minimumInteractiveTarget' },
    },
    'container-size': { kind: 'dimension', value: '20px' },
    'outline-width': { kind: 'dimension', value: '2px' },
    // Drawn dot diameter: the source animates a 12dp target radius/2 = 6dp,
    // then fills at `radius - strokeWidth / 2` = 6dp - 1dp = 5dp, an actual
    // 10dp drawn diameter.
    'dot-size': { kind: 'dimension', value: '10px' },
    'state-layer-size': { kind: 'dimension', value: '40px' },

    // The source defines no RadioButton focus-indicator token; the web
    // control still needs a visible focus ring, so this uses the secondary
    // role established by the Checkbox precedent.
    'focus-ring-width': { kind: 'dimension', value: '2px' },
    'focus-ring-offset': { kind: 'dimension', value: '2px' },
    'focus-ring-color': { kind: 'color', value: { $ref: 'sys.color.secondary' } },

    'selected-icon-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'unselected-icon-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' },
    },
    'disabled-selected-icon-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'disabled-selected-icon-opacity': { kind: 'opacity', value: 0.38 },
    'disabled-unselected-icon-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'disabled-unselected-icon-opacity': { kind: 'opacity', value: 0.38 },

    // The pinned `ripple()` call passes no explicit per-state color, so its
    // resolved tint is ambient `LocalContentColor`, not `radioColor`. Web
    // hover/focus/pressed feedback needs a concrete color, so the state layer
    // mirrors the same-state icon color role, consistent with the Checkbox
    // precedent for its unchecked state layer.
    'selected-state-layer-color': {
      kind: 'color', value: { $ref: 'sys.color.primary' },
    },
    'unselected-state-layer-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' },
    },
  },
} as const satisfies ComponentTokenRegistration

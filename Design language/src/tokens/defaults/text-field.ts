import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX Material 3 `FilledTextFieldTokens`/`OutlinedTextFieldTokens`
 * values adapted from dp to CSS pixels, shared by `TextField` and `TextArea`.
 *
 * Every content role — input, placeholder, label (base/focus/error/disabled),
 * leading icon, trailing icon, and supporting text — resolves to the exact
 * same color in both token files; Kotlin has no shared-token-file mechanism,
 * so AndroidX simply repeats each constant under both names. This
 * registration keeps one unprefixed copy of each instead of a
 * `filled-*`/`outlined-*` pair that would only ever hold identical values.
 * Only the container fill/shape and the border affordance itself — a bottom
 * indicator line for filled, a full notched outline for outlined, with
 * genuinely different base and disabled-opacity constants — are registered
 * per variant.
 *
 * Three categories of source token are deliberately left unregistered,
 * matching the unread-role precedent from Checkbox, Radio, and Switch:
 *
 * - Every `Hover*`-suffixed role in both token files. `TextFieldColors`'
 *   accessors take only `(enabled, isError, focused)` — there is no fourth
 *   "hovered" axis anywhere in the resolved color model, so these roles are
 *   dead code, not merely unread by name.
 * - `FilledTextFieldTokens.DisabledContainerColor`/`DisabledContainerOpacity`.
 *   `defaultTextFieldColors()` resolves the filled container to the same
 *   `ContainerColor` in every state including disabled; the dimmed disabled
 *   treatment the token file documents is never applied. This registration
 *   reproduces the pinned source's actual behavior (a disabled filled field
 *   keeps a full-opacity container), not the token file's aspirational,
 *   unapplied value.
 * - `InputFont`/`LabelFont`/`SupportingFont` and `LeadingIconSize`/
 *   `TrailingIconSize`. Typography is pulled live from
 *   `MaterialTheme.typography.bodyLarge`/`.bodySmall`, and icon sizing is
 *   left entirely to the caller's icon composable — neither is a token
 *   lookup in the pinned source. This port references the theme's own
 *   `--m3e-sys-typescale-baseline-body-*` roles directly in component CSS
 *   for the same reason, and lets the icon slot's touch target (not the
 *   icon itself) carry the only enforced dimension.
 *
 * The filled `*-indicator-height` and outlined `*-outline-width` values are
 * registered under this component's own token names even though the pinned
 * source's color-resolution code reads separately hardcoded `Dp` literals of
 * the same value (`UnfocusedIndicatorThickness`, `FocusedIndicatorThickness`,
 * `UnfocusedBorderThickness`, `FocusedBorderThickness`) rather than the
 * token constants themselves — the rendered values match exactly, only the
 * constant each mirrors differs.
 *
 * `content-padding`/`icon-content-gap`/`supporting-text-top-gap` mirror
 * `TextFieldDefaults`' own named `Dp` constants (`TextFieldPadding`, the
 * icon-adjacent gap left after `textFieldHorizontalIconPadding()`, and
 * `SupportingTopPadding`) rather than a per-token-file source. Horizontal
 * insets are projected as external start/content/end layout regions so native
 * control padding resets cannot move text beneath an icon. The input's own
 * vertical padding has no equivalent named constant at all — the pinned source
 * computes it inside a private `MeasurePolicy` — so it is a reasoned CSS
 * layout decision documented at its declaration, not a token.
 *
 * Disabled colors use this library's established `color-mix(..., transparent)`
 * technique. For every prior selection control that was a deliberate
 * deviation from the pinned source's `compositeOver(colorScheme.surface)`
 * baked-backdrop approach; here it is not a deviation at all — the pinned
 * source itself resolves every disabled text-field color as true alpha
 * (`fromToken(...).copy(alpha = ...)`), which `color-mix(..., transparent)`
 * reproduces exactly.
 */
export const defaultTextFieldTokens = {
  component: 'text-field',
  task: 'T14',
  source: {
    id: 'androidx-material3-text-field',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/FilledTextFieldTokens.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-20',
  },
  tokens: {
    'minimum-interactive-target': {
      kind: 'dimension',
      value: { $ref: 'sys.density.minimumInteractiveTarget' },
    },
    'min-container-block-size': { kind: 'dimension', value: '56px' },
    'min-container-inline-size': { kind: 'dimension', value: '280px' },
    'content-padding': { kind: 'dimension', value: '16px' },
    'icon-content-gap': { kind: 'dimension', value: '4px' },
    'supporting-text-top-gap': { kind: 'dimension', value: '4px' },

    // Shared content roles — identical across both token files.
    'input-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'caret-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'error-caret-color': { kind: 'color', value: { $ref: 'sys.color.error' } },
    'disabled-input-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'disabled-input-opacity': { kind: 'opacity', value: 0.38 },
    'placeholder-color': { kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' } },
    'label-color': { kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' } },
    'focus-label-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'error-label-color': { kind: 'color', value: { $ref: 'sys.color.error' } },
    'disabled-label-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'disabled-label-opacity': { kind: 'opacity', value: 0.38 },
    'leading-icon-color': { kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' } },
    'disabled-leading-icon-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'disabled-leading-icon-opacity': { kind: 'opacity', value: 0.38 },
    'trailing-icon-color': { kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' } },
    'error-trailing-icon-color': { kind: 'color', value: { $ref: 'sys.color.error' } },
    'disabled-trailing-icon-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'disabled-trailing-icon-opacity': { kind: 'opacity', value: 0.38 },
    'supporting-color': { kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' } },
    'error-supporting-color': { kind: 'color', value: { $ref: 'sys.color.error' } },
    'disabled-supporting-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'disabled-supporting-opacity': { kind: 'opacity', value: 0.38 },

    // Filled — container fill and bottom indicator line.
    'filled-container-color': {
      kind: 'color', value: { $ref: 'sys.color.surfaceContainerHighest' },
    },
    'filled-container-shape': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerExtraSmallTop' },
    },
    'filled-indicator-color': { kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' } },
    'filled-focus-indicator-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'filled-error-indicator-color': { kind: 'color', value: { $ref: 'sys.color.error' } },
    'filled-disabled-indicator-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    'filled-disabled-indicator-opacity': { kind: 'opacity', value: 0.38 },
    'filled-indicator-height': { kind: 'dimension', value: '1px' },
    'filled-focus-indicator-height': { kind: 'dimension', value: '2px' },

    // Outlined — no container fill token in the pinned source; only the
    // border and content roles above are resolved.
    'outlined-container-shape': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerExtraSmall' },
    },
    'outlined-outline-color': { kind: 'color', value: { $ref: 'sys.color.outline' } },
    'outlined-focus-outline-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'outlined-error-outline-color': { kind: 'color', value: { $ref: 'sys.color.error' } },
    'outlined-disabled-outline-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurface' },
    },
    // Distinct from the shared 0.38 content opacity above —
    // `DisabledOutlineOpacity` is its own, lighter, source constant.
    'outlined-disabled-outline-opacity': { kind: 'opacity', value: 0.12 },
    'outlined-outline-width': { kind: 'dimension', value: '1px' },
    'outlined-focus-outline-width': { kind: 'dimension', value: '2px' },
    'outlined-disabled-outline-width': { kind: 'dimension', value: '1px' },
  },
} as const satisfies ComponentTokenRegistration

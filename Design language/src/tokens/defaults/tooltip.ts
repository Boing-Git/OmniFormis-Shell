import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX Material 3 `PlainTooltipTokens`/`RichTooltipTokens`
 * values, plus the sourced sizing/spacing constants `Tooltip.kt` itself
 * defines (`TooltipMinWidth`/`MinHeight`, `plainTooltipMaxWidth`/
 * `richTooltipMaxWidth`, `PlainTooltipContentPadding`,
 * `RichTooltipHorizontalPadding`, `SpacingBetweenTooltipAndAnchor`) — none
 * of these live in a token file upstream, since Compose treats them as
 * plain layout constants, not `@Composable` color/shape roles, the same
 * status they keep here.
 *
 * `RichTooltipTokens.ActionLabelText*`/`ActionFocusLabelTextColor`/
 * `ActionHoverLabelTextColor`/`ActionPressedLabelTextColor` are **not**
 * registered: the pinned source's rich-tooltip action button is excluded
 * entirely (see ADR 0018) because WAI-ARIA explicitly disallows
 * interactive content inside `role="tooltip"` — a direct conflict with the
 * native web semantic, which wins per `SPEC.md` §3. Both variants stay
 * non-interactive text only.
 *
 * `rich-padding-block`/`rich-subhead-gap` approximate the source's
 * baseline-relative `paddingFromBaseline`/`HeightToSubheadFirstLine`/
 * `HeightFromSubheadToTextFirstLine` constants as ordinary CSS block
 * padding/margin — Compose's baseline-relative box model has no direct CSS
 * equivalent, so this is a deliberate, documented simplification rather
 * than a claim of pixel-exact baseline reproduction.
 */
export const defaultTooltipTokens = {
  component: 'tooltip',
  task: 'T18',
  source: {
    id: 'androidx-material3-tooltip',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/RichTooltipTokens.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-20',
  },
  tokens: {
    'plain-container-color': { kind: 'color', value: { $ref: 'sys.color.inverseSurface' } },
    'plain-container-shape': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerExtraSmall' },
    },
    'plain-supporting-text-color': {
      kind: 'color', value: { $ref: 'sys.color.inverseOnSurface' },
    },
    'plain-padding-inline': { kind: 'dimension', value: '8px' },
    'plain-padding-block': { kind: 'dimension', value: '4px' },
    'plain-max-width': { kind: 'dimension', value: '200px' },
    'rich-container-color': { kind: 'color', value: { $ref: 'sys.color.surfaceContainer' } },
    'rich-container-shape': {
      kind: 'shape', value: { $ref: 'sys.shape.corners.cornerMedium' },
    },
    'rich-container-shadow': { kind: 'shadow', value: { $ref: 'sys.elevation.level2.shadow' } },
    'rich-subhead-color': { kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' } },
    'rich-supporting-text-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' },
    },
    'rich-padding-inline': { kind: 'dimension', value: '16px' },
    'rich-padding-block': { kind: 'dimension', value: '12px' },
    'rich-subhead-gap': { kind: 'dimension', value: '4px' },
    'rich-max-width': { kind: 'dimension', value: '320px' },
    'min-width': { kind: 'dimension', value: '40px' },
    'min-height': { kind: 'dimension', value: '24px' },
    'anchor-gap': { kind: 'dimension', value: '4px' },
  },
} as const satisfies ComponentTokenRegistration

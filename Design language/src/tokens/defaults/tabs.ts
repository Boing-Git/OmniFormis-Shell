import type { ComponentTokenRegistration } from '../schema'

/**
 * Current AndroidX Material 3 `PrimaryNavigationTabTokens`/
 * `SecondaryNavigationTabTokens` values, plus sourced layout constants
 * `Tab.kt`/`TabRow.kt` themselves define outside any token file
 * (`HorizontalTextPadding`, `LargeTabHeight`, `TextDistanceFromLeadingIcon`,
 * `ScrollableTabRowMinTabWidth`, `ScrollableTabRowEdgeStartPadding`, and the
 * indicator's own `24dp` default width parameter).
 *
 * `SecondaryNavigationTabTokens` defines no `ActiveIndicator*` fields of its
 * own — the pinned source's `TabRowDefaults.SecondaryIndicator` reads
 * `PrimaryNavigationTabTokens.ActiveIndicatorColor`/`ActiveIndicatorHeight`
 * directly, so this registration reuses the same `indicator-color`/
 * `indicator-height` pair for both variants rather than duplicating an
 * identical value under two names. `indicator-primary-width` (`24px`) and
 * `indicator-shape` (`3px`, `RoundedCornerShape(3dp)`) belong to the
 * `'primary'` variant's own short, content-width-hugging indicator only —
 * `'secondary'` renders a full-tab-width underline with no independent
 * width/shape of its own.
 *
 * `divider-color`/`divider-height` come from
 * `SecondaryNavigationTabTokens.DividerColor`/`DividerHeight`, even though
 * the pinned source's own default `divider` composable for *both*
 * `PrimaryTabRow`/`SecondaryTabRow` is actually a generic, non-tab-specific
 * `HorizontalDivider()` — this project surfaces the actually-defined,
 * traceable token value instead of an untraceable system-generic one, the
 * same "prefer the specific sourced value over an unread generic one"
 * reasoning used throughout.
 *
 * `disabled-label-color`/`disabled-label-opacity`/`disabled-icon-color`/
 * `disabled-icon-opacity` have no source: `Tab`'s `enabled` param removes
 * interactivity only, with no distinct disabled color axis at all in the
 * pinned source's `TabTransition`. This registers the same universal
 * `onSurface`-at-`0.38`-opacity dimming every other v1 interactive
 * component already uses, a deliberate web addition for visual disabled
 * communication.
 *
 * `icon-label-gap` approximates the source's own baseline-relative stacked
 * layout (`SingleLineTextBaselineWithIcon`/`IconDistanceFromBaseline`,
 * measured from a text baseline rather than a simple gap) as an ordinary
 * flexbox `gap` — the same baseline-to-block-model simplification already
 * applied to Tooltip's rich-variant padding, not a claim of pixel-exact
 * baseline reproduction.
 */
export const defaultTabsTokens = {
  component: 'tabs',
  task: 'T19',
  source: {
    id: 'androidx-material3-tabs',
    url: 'https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/PrimaryNavigationTabTokens.kt',
    revision: '225f50d42bf0adeb2abf4b6109befb5ab6ce4efc',
    accessed: '2026-07-20',
  },
  tokens: {
    'container-color': { kind: 'color', value: { $ref: 'sys.color.surface' } },
    'container-height': { kind: 'dimension', value: '48px' },
    'container-height-with-icon-and-label': { kind: 'dimension', value: '72px' },
    'indicator-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'indicator-height': { kind: 'dimension', value: '3px' },
    'indicator-shape': { kind: 'shape', value: '3px' },
    'indicator-primary-width': { kind: 'dimension', value: '24px' },
    'divider-color': { kind: 'color', value: { $ref: 'sys.color.surfaceVariant' } },
    'divider-height': { kind: 'dimension', value: '1px' },
    'primary-active-label-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'primary-active-icon-color': { kind: 'color', value: { $ref: 'sys.color.primary' } },
    'primary-inactive-label-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' },
    },
    'primary-inactive-icon-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' },
    },
    'secondary-active-label-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'secondary-active-icon-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'secondary-inactive-label-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' },
    },
    'secondary-inactive-icon-color': {
      kind: 'color', value: { $ref: 'sys.color.onSurfaceVariant' },
    },
    'icon-size': { kind: 'dimension', value: '24px' },
    'label-inline-padding': { kind: 'dimension', value: '16px' },
    'icon-label-gap': { kind: 'dimension', value: '4px' },
    'scrollable-min-tab-width': { kind: 'dimension', value: '90px' },
    'scrollable-edge-padding': { kind: 'dimension', value: '52px' },
    'disabled-label-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'disabled-label-opacity': { kind: 'opacity', value: 0.38 },
    'disabled-icon-color': { kind: 'color', value: { $ref: 'sys.color.onSurface' } },
    'disabled-icon-opacity': { kind: 'opacity', value: 0.38 },
  },
} as const satisfies ComponentTokenRegistration

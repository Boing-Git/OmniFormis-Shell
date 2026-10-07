# NavigationSuite conformance

Task: T20
Status: conformant
Reviewed: 2026-07-20

## Primary references

- Material Design adaptive navigation guidance, accessed 2026-07-20:
  <https://m3.material.io/foundations/adaptive-design/overview>
- Pinned current AndroidX `NavigationSuiteScaffold.kt`/
  `WindowSizeClassHelper.kt` (`material3-adaptive-navigation-suite`
  module), accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3-adaptive-navigation-suite/src/commonMain/kotlin/androidx/compose/material3/adaptive/navigationsuite/NavigationSuiteScaffold.kt>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`.

## Anatomy and content

- The first component to render another public component
  internally: `NavigationSuite` composes `NavigationBar`, `NavigationRail`,
  and `NavigationDrawer` (`'permanent'`) directly, switching between them
  by viewport width. Reuses `NavigationBar`'s own `NavigationItem` data
  type and `value`/`defaultValue`/`onValueChange` shape; `header` passes
  through to `NavigationRail` only (ignored at the other two tiers).
- Registers **no component tokens of its own** — every color/geometry/
  motion value comes from whichever of the three components is currently
  rendered, the same "reuses an existing domain entirely" precedent
  `Select` already set for `text-field`/`menu`.

## Breakpoints and adaptive switching

- Uses the pinned source's own real `Compact`/`Medium`/`Expanded` width
  breakpoints (`WindowSizeClassHelper.kt`: `0`/`600`/`840px`,
  `WIDTH_DP_MEDIUM_LOWER_BOUND`/`WIDTH_DP_EXPANDED_LOWER_BOUND`) via a new
  `window.matchMedia`-driven internal hook: compact → `NavigationBar`,
  medium → `NavigationRail`, expanded → `NavigationDrawer` (`'permanent'`).
- **Deliberate deviation from the pinned source's own
  `calculateFromAdaptiveInfo`**, which only 2-tier switches between
  `NavigationBar`/`NavigationRail` and never auto-selects a drawer at all —
  see the T20 ADR for the full reasoning. The sourced breakpoint *values*
  are unchanged; only which component each tier maps to differs from that
  one specific pinned function.
- SSR/pre-hydration has no real viewport to measure, so it renders the
  `'compact'` tier (`NavigationBar`) until a client effect measures the
  real width and corrects it — the same "renders a reasonable default
  before a real measurement is available" category `Tabs`'s indicator and
  `Snackbar`'s auto-dismiss timing both already established in different
  forms.

## Web-specific deviations

- Composes public components directly rather than reimplementing their
  rendering — a new, deliberate pattern specific to this "meta" component,
  which should not be reached for by future components that only share
  styling/tokens rather than genuinely needing to interoperate.

# Snackbar conformance

Task: T18
Status: conformant
Reviewed: 2026-07-20

## Primary references

- Material Design snackbar component guide, accessed 2026-07-20:
  <https://m3.material.io/components/snackbar/overview>
- Pinned current AndroidX `Snackbar.kt`/`SnackbarHost.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/Snackbar.kt>
- Pinned generated AndroidX `SnackbarTokens`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/SnackbarTokens.kt>
- material-web snackbar component tokens (no implementation exists),
  cross-validating action/icon state-layer colors, accessed 2026-07-20:
  <https://github.com/material-components/material-web/blob/b4de401eb665ec63474f39319a4ba8f2145974cc/tokens/versions/latest/sass/_md-comp-snackbar.scss>
- WAI-ARIA APG live region / status role guidance, accessed 2026-07-20:
  <https://www.w3.org/WAI/ARIA/apg/practices/name-and-description/>
- WCAG 2.2 timing adjustable (2.2.1), accessed 2026-07-20:
  <https://www.w3.org/TR/WCAG22/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`, adapted to a single controlled
component instead of the pinned source's separate `SnackbarHostState`/
`SnackbarHost` queue orchestration layer — the component inventory names one
`Snackbar`/`SnackbarProps` export, matching this library's other controlled
primitives (`open`/`defaultOpen`/`onOpenChange`) rather than a headless
queue; a consumer wanting multiple queued snackbars manages that in their
own state, the same "library owns the primitive, not the orchestration"
precedent every other component already follows.

## Anatomy and content

- `message` (required body), optional single `action: { label, onClick }`,
  optional `dismissible` (renders a close icon button; default `false`,
  matching the source's own `withDismissAction` default). No leading status
  icon: the pinned source's public `Snackbar` composable has no such slot —
  `SnackbarTokens.IconColor`/`IconSize` belong to the dismiss action only.
- The `actionOnNewLine` two-row legacy layout (`LegacySnackbarVerticalPadding`)
  is excluded — action stays inline, the modern single-row layout.

## Variants, shape, color, and size

- Container: `SnackbarTokens.ContainerColor` (inverseSurface),
  `ContainerElevation` (level3, as shadow), `ContainerShape`
  (cornerExtraSmall), `48px` min height (`SingleLineContainerHeight`),
  `600px` max width (`ContainerMaxWidth`), `16px`/`8px` inline padding
  (`HorizontalSpacing`/`HorizontalSpacingButtonSide`), `14px` block padding
  (`SnackbarVerticalPadding`).
- Content: `SupportingTextColor` (inverseOnSurface), action label color
  (inversePrimary), dismiss icon color (inverseOnSurface), `24px` icon size.
  Action/dismiss focus/hover/pressed colors are all the same role as
  enabled (confirmed against material-web's token file at the same pinned
  revision this project's `material-web-tokens` source already uses), so
  hover/press feedback reuses the shared `--m3e-sys-state-*` state-layer
  system via `currentColor`, the same `Menu`/`Select` precedent.
- No component-level viewport-offset token: the source's positioning is a
  consuming `Scaffold`'s job, and material-web ships no snackbar
  implementation to cross-validate against either. The bottom offset is a
  plain CSS value, the same "implementation constant, not a Material value"
  status `Menu`'s own `z-index: 1000` already has.
- Typography reuses the theme's own `body-medium` (message) and
  `label-large` (action) typescale roles directly.

## States and motion

- `open`/`defaultOpen`/`onOpenChange` follow the same controlled/
  uncontrolled shape as every other component.
- Auto-dismiss duration: `'short'` (4000ms) or `'long'` (10000ms), an exact
  millisecond count, or `'indefinite'`. Defaults to the source's own logic
  (`if (action == null) Short else Indefinite`).
- **Pausable beyond the source**: the countdown pauses while the snackbar is
  hovered or focused and resumes the remaining time on leave — a deliberate
  WCAG 2.2.1 addition; Android's own accessibility services extend timing a
  different way with no web equivalent.
- Entrance/exit motion is a fade + scale (`0.8` → `1`) using the sourced
  `FastSpatial`/`FastEffects` motion slots, matching `FadeInFadeOutWithScale`
  and reusing the same tokens `Menu`/`Tooltip` already use. Exit motion is
  real: closing defers unmount until the transition finishes (or
  immediately, under reduced motion or before the entrance transition ever
  completed).

## Accessibility

- `role="status"` (implicit polite + atomic live region), matching the
  source's own `liveRegion = Polite` semantics — the direct web analogue,
  since Android's own accessibility-service timing/announcement machinery
  has no web equivalent.
- The action and dismiss buttons are real, independently focusable/labeled
  buttons; activating either fires its own callback and closes.

## Web-specific deviations

- Single controlled component instead of a headless queue/host pair (see
  Anatomy).
- Pausable auto-dismiss timer (see States and motion) — the source has no
  equivalent since Android's accessibility services handle timing extension
  differently.
- No leading status icon slot, matching the pinned source's own public API.

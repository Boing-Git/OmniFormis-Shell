# Dialog conformance

Task: T16
Status: conformant
Reviewed: 2026-07-20

## Primary references

- Material Design dialogs component guide, accessed 2026-07-20:
  <https://m3.material.io/components/dialogs/overview>
- Pinned current AndroidX `AlertDialog.kt`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/AlertDialog.kt>
- Pinned generated AndroidX `DialogTokens`, accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/DialogTokens.kt>
- Pinned `androidx.compose.ui.window.DialogProperties` (`AndroidDialog.android.kt`),
  accessed 2026-07-20:
  <https://android.googlesource.com/platform/frameworks/support/+/225f50d42bf0adeb2abf4b6109befb5ab6ce4efc/compose/ui/ui/src/androidMain/kotlin/androidx/compose/ui/window/AndroidDialog.android.kt>
- material-web dialog implementation, cross-validating adaptive width sizing
  and scrim opacity (the pinned Compose source has no cross-platform value
  for either), accessed 2026-07-20:
  <https://github.com/material-components/material-web/blob/main/dialog/internal/_dialog.scss>
- WHATWG HTML Living Standard, the `dialog` element (focusing steps, closing
  steps, `cancel`/`close` events), accessed 2026-07-20:
  <https://html.spec.whatwg.org/multipage/interactive-elements.html#the-dialog-element>
- MDN `<dialog>`, `@starting-style`, accessed 2026-07-20:
  <https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dialog>,
  <https://developer.mozilla.org/en-US/docs/Web/CSS/@starting-style>
- WAI-ARIA APG dialog (modal) pattern, accessed 2026-07-20:
  <https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/>
- WCAG 2.2 focus visible, target size, and reduced motion, accessed 2026-07-20:
  <https://www.w3.org/TR/WCAG22/>

Supported Material baseline: AndroidX Material 3 branch revision
`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`, adapted to a native `<dialog>`
element instead of the pinned source's own Popup-window composable, since
`<dialog>` provides the equivalent modal semantics (backdrop, focus trap,
inert background, focus lifecycle) as a browser primitive rather than a
ported implementation.

## Anatomy and content

- One root `<dialog>` element carries the resolved role, accessible-name/
  description associations, the consumer class and style, and the forwarded
  ref.
- Up to four optional content regions, in order: `icon` (centered, secondary
  color), `title` (headline, centered under an icon or start-aligned
  otherwise), `children` (the body/supporting-text region, inheritable
  typography/color for plain text), `actions` (an end-aligned, wrapping,
  gap-separated row).
- Collapses the pinned source's layered `BasicAlertDialog` (bare
  positioning/sizing) and `AlertDialog` (opinionated icon/title/text/actions
  layout) into one component, matching the single `Dialog`/`DialogProps`
  export already named in the component inventory.

## Variants, shape, color, and size

- `modal` (default `true`) selects `showModal()` — backdrop, focus trap,
  inert background, implicit `aria-modal="true"` — or `show()` for `false` —
  none of those, implicit `aria-modal="false"`. This is a deliberate
  capability addition beyond the pinned source, which is unconditionally
  modal; see Web-specific deviations.
- `role` defaults to `dialog` and accepts `alertdialog`, folding the source's
  separate "alert dialog" identity into one prop.
- Geometry: intrinsic width bounded to 280–560px (`DialogMinWidth`/
  `DialogMaxWidth`), clamped against the viewport with a 24px margin per
  side (cross-validated against material-web, since the pinned source has no
  height cap of its own, only a viewport-safe `max-height` with internal
  scrolling applies). Container shape `cornerExtraLarge`, elevation level 3,
  24px padding (the non-"precision pointer" branch, matching every other
  provisional-Expressive exclusion already applied across this library).
- Icon 24px/secondary color, headline `onSurface`, supporting text
  `onSurfaceVariant`, action content color `primary` (the source itself notes
  this role is typically unused because `TextButton`s set their own color —
  registered anyway for fidelity, since it is genuinely assigned via
  `CompositionLocalProvider`, unlike a role the source never reads at all).
- A 32%-opacity scrim (cross-validated against material-web; the pinned
  source dims its window via an Android platform default, not a
  cross-platform Material3 design token) styles the native `::backdrop`.

## States and motion

- Enabled, disabled-via-absence (there is no disabled state for a dialog
  itself), open, and closed are the only states; there is no error state in
  this component's contract.
- Entrance and exit (fade + scale on the dialog surface, opacity-only fade on
  the backdrop) use `@starting-style` with `transition-behavior:
  allow-discrete` — a native technique that degrades to an instant, fully
  functional show/hide with zero breakage on any browser without
  `@starting-style` support. See Web-specific deviations for why this one
  case does not follow this library's usual hard floor-support commitment.
- Reduced motion removes every transition; instant show/hide is exactly what
  a browser without `@starting-style` support already produces, so the two
  code paths converge on the same visual outcome.

## Component token mapping

- Container: color, shape, elevation shadow, padding, min/max width,
  viewport margin.
- Content: icon color/size/spacing, headline color/spacing, supporting-text
  color/spacing, action content color/spacing.
- Scrim: color, opacity.

All values live in the T16 `dialog` registration. Production CSS validation
requires every literal `--m3e-comp-dialog-*` reference to resolve.

## DOM, forms, and behavior

- Rendered DOM: `<dialog class="m3e-dialog" data-m3e-has-icon>` directly
  containing up to four content `<div>`s (`m3e-dialog__icon`,
  `__title`, `__content`, `__actions`) — no extra wrapper element.
- `open`/`defaultOpen`/`onOpenChange` follow the same controlled/
  uncontrolled shape as every other stateful component
  (`useControllableState`). The `open` HTML attribute is never set directly
  by JSX; an effect performs every `showModal()`/`show()`/`close()` call
  imperatively from the resolved value, since a true modal only exists once
  `showModal()` runs.
- A single native `close` event listener is the one path back to the
  controlled value, firing identically for Escape, an outside click's own
  `close()` call, and a `<form method="dialog">` submission — so a dialog
  containing such a form closes and reports `onOpenChange(false)` with no
  extra library wiring.
- `dismissOnEscape={false}` calls `preventDefault()` on the native `cancel`
  event. `dismissOnOutsideClick={false}` skips the manual outside-click
  check. Both are meaningful only in modal mode.
- Server markup and hydration are deterministic and inject no styles; SSR
  always paints closed regardless of `open`/`defaultOpen`.

## Accessible name, description, role, state, and keyboard

- `title`, when present, sets `aria-labelledby` to a generated id unless the
  caller passes an explicit `aria-label`/`aria-labelledby`. `children`, when
  present, sets `aria-describedby` to a generated id the same way. A
  development-mode warning fires when the dialog has no accessible name from
  any source.
- Initial focus placement (the first focusable descendant, or an explicit
  `autofocus` element) and, on close, focus restoration to the
  previously-focused element are both native `<dialog>` behavior — the HTML
  living standard's dialog focusing steps and closing steps — for either
  `modal` value, requiring no library-owned focus-management code.
- Escape (modal only, native `cancel`/`close` events) and Tab (native focus
  trap while modal) require no key handler.

## Bidirectional, forced-color, and adaptive behavior

- All sizing and spacing use logical properties, so width bounds, margins,
  and text alignment mirror correctly in RTL.
- Forced colors gives the dialog a visible `CanvasText` boundary (elevation
  shadow is not visible in this mode) and a `Canvas`-colored backdrop.
- Default, custom, and nested themes scope every Dialog variable.

## Web-specific deviations

- `modal` is a deliberate capability addition beyond the pinned source, which
  is unconditionally modal (a Compose `Popup` with `focusable = true`): the
  native `<dialog>` element's `show()` mode provides genuine non-modal
  semantics (no backdrop, no focus trap, background stays interactive,
  implicit `aria-modal="false"`) for free, and the task explicitly names
  "modal/non-modal semantics" as in scope.
- `dismissOnOutsideClick` is implemented with a manual bounding-rect click
  check (the click lands on the dialog element itself, then its coordinates
  are tested against its own rendered box) rather than the native `closedby`
  attribute's automatic light dismiss, because `closedby` postdates this
  library's browser floor. The technique is the standard native-`<dialog>`
  light-dismiss workaround predating that attribute.
- The source's confirm/dismiss dual-slot API with its layout-direction-flip
  trick (DOM order confirm-then-dismiss, visual order reversed in LTR) is
  simplified to one `actions` slot: a wrapping, end-aligned flex row where
  the consumer's own JSX order sets both DOM and visual order directly, with
  no framework-specific reordering plumbing. This is a flattening of
  Compose-specific composition mechanics with no clean CSS equivalent, in
  the same spirit as this library's other spring/measure-policy flattenings.
- `@starting-style`/`allow-discrete` motion is used even though it postdates
  this library's usual browser-support floor (`:has()`, pinned to Firefox
  121), because it is a pure progressive enhancement: an unsupporting
  browser silently keeps the dialog fully functional with an instant,
  correct show/hide, never a broken or non-functional one. No other
  component in this library has made that trade, because no other
  component's motion is this cleanly separable from its function.
- A controlled dialog's own native dismissal (Escape, outside click, or a
  `<form method="dialog">` submission) is reported through `onOpenChange`
  but is not forcibly reverted if the consumer ignores it: unlike a
  controlled native form value, where React's own controlled-input
  machinery snaps the DOM back to the prop value on the same event, nothing
  forces a further render of a `<dialog>` whose `open` prop value has not
  itself changed. This mirrors the native-truth precedent already
  established for Radio/Checkbox/SegmentedButtonGroup: platform state can
  move ahead of an unacknowledged controlled prop.
- Predictive-back gesture handling, edge-to-edge system-bar color
  adaptation, and the `shouldUsePrecisionPointerComponentSizing`-gated 20px
  padding variant are Android-platform-specific or unshipped provisional
  behavior with no web equivalent or no stable source value, the same
  exclusion basis as prior tasks' provisional-feature exclusions.

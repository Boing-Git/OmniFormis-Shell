# ADR 0016: Native `<dialog>` as the Dialog primitive, modal/non-modal semantics, and `@starting-style` motion

Status: accepted
Date: 2026-07-20
Task: T16

## Context

The pinned AndroidX revision (`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`)
implements Material dialogs across two layers. `androidx.compose.ui.window
.Dialog`/`DialogProperties` (`AndroidDialog.android.kt`) is a bare,
platform-level popup window: `dismissOnBackPress`/`dismissOnClickOutside`
(both default `true`) control back-press and outside-click dismissal, and
`usePlatformDefaultWidth` constrains content width. `BasicAlertDialog`
(`AlertDialog.kt`) wraps that primitive with only a `sizeIn(minWidth =
DialogMinWidth = 280dp, maxWidth = DialogMaxWidth = 560dp)` box and pane
semantics — no color, shape, or elevation. The opinionated visual identity —
`DialogTokens`' `ContainerColor` (`SurfaceContainerHigh`), `ContainerShape`
(`CornerExtraLarge`), `ContainerElevation` (level 3), `HeadlineColor`/
`SupportingTextColor`/`IconColor`, and `AlertDialogDefaults.dialogPadding`/
`textPadding`/`IconPadding`/`TitlePadding` (24dp/24dp/16dp/16dp,
non-"precision pointer" branch) — belongs only to `AlertDialogContent`, the
implementation behind the separate `AlertDialog` composable, which lays out
an optional icon (centered, bottom-padded), an optional title (centered
under an icon, else start-aligned), optional text, and a confirm/dismiss
button row via a `FlowRow` that receives the confirm button first as an
argument but visually reorders it after the dismiss button in LTR through a
deliberate `LayoutDirection` flip.

The component inventory names one export for this task: `Dialog`/
`DialogProps`. Compose's own Dialog composable is unconditionally modal — a
`Popup` with `focusable = true` that always blocks background interaction.
The web platform's native `<dialog>` element, by contrast, exposes both
`showModal()` (backdrop, focus trap, inert background, implicit
`aria-modal="true"`) and `show()` (none of those, implicit
`aria-modal="false"`) from one element, and its "dialog focusing steps"
(HTML Living Standard) run identically for both methods, moving focus to
the first focusable descendant or an explicit `autofocus` element; its
"closing steps" restore focus to whatever was focused before the dialog
opened, unconditionally after `showModal()` and conditionally after
`show()`. Neither method sets the `open` content attribute as a plain
reveal would: only `showModal()`/`show()` actually produce backdrop/
focus-trap/inert-background/AOM behavior, so driving `open` requires an
imperative call, not a JSX attribute.

## Decision

1. One public `Dialog` component renders a native `<dialog>` element as its
   root, collapsing the pinned source's layered `BasicAlertDialog`
   (bare positioning/sizing) and `AlertDialog` (opinionated icon/title/
   text/actions layout) into one component — matching the single export the
   component inventory already named for this task.
2. `open`/`defaultOpen`/`onOpenChange` follow this library's universal
   `useControllableState` shape. The `open` HTML attribute is never set
   directly by JSX; an effect performs every `showModal()`/`show()`/
   `close()` call imperatively from the resolved value, since — as the
   Context section establishes — a true modal only exists once
   `showModal()` runs, and SSR therefore always paints closed regardless of
   `open`/`defaultOpen`.
3. `modal` (default `true`) selects `showModal()` vs `show()` — the "Modal/
   non-modal semantics" the task title names, and a deliberate capability
   addition beyond the pinned source, which has no non-modal concept at
   all. Initial focus placement and close-time focus restoration are both
   native for either mode, per the Context section's HTML Living Standard
   citation, so no library-owned focus-management code exists.
4. `dismissOnEscape` (default `true`) maps `dismissOnBackPress`: `false`
   calls `preventDefault()` on the native `cancel` event, which is
   cancelable per the HTML Living Standard specifically so a consumer (here,
   this component) can block the default close action. `dismissOnOutsideClick`
   (default `true`) maps `dismissOnClickOutside`: since native automatic
   light dismiss (the `closedby="any"` attribute) postdates this library's
   pinned Chrome/Edge/Firefox/Safari floor, a manual bounding-rect click
   check reproduces it instead — a click whose `target` is the dialog
   element itself (never a descendant) is tested against the element's own
   `getBoundingClientRect()`; landing outside it calls `close()`. Both
   props are meaningful only in modal mode: `show()` renders no backdrop to
   click, and non-modal dialogs do not dismiss on Escape by native default,
   so both are no-ops there by design, not by omission.
5. A single native `close` event listener is the one path back to the
   controlled value, firing identically for Escape, the outside-click
   handler's own `close()` call, and a `<form method="dialog">`
   submission — so a dialog containing such a form closes and reports
   `onOpenChange(false)` with no extra library wiring, a natural extension
   of this library's native-forms-first posture (already established for
   Checkbox/Radio/Switch/SegmentedButtonGroup) to a component that isn't
   itself a form control.
6. `icon`/`title`/`children`/`actions` reproduce `AlertDialogContent`'s
   layout: centered icon, title centered under an icon or start-aligned
   otherwise, and content that sets inheritable default typography/color
   (`SupportingTextColor`/`body-medium`) for plain text while letting any
   nested component override by being explicit — the same content-boundary
   precedent Card established for not forcing typography on interactive
   descendants. Each region's own bottom margin (`icon-spacing`/
   `headline-spacing`/`supporting-text-spacing`, sourced 16px/16px/24px)
   collapses via `:not(:last-child)` when a later region is absent, instead
   of literally porting the source's per-`PaddingValues` stacking, which
   would otherwise double the trailing gap when text has no following
   button row — a Compose-`Column`-specific artifact with no clean CSS
   equivalent.
7. The source's confirm/dismiss dual-slot API and its `LayoutDirection`-flip
   visual-reordering trick are simplified to one `actions` slot: a wrapping,
   end-aligned flex row (`gap` reproducing both `ButtonsMainAxisSpacing`
   and `ButtonsCrossAxisSpacing`, both 8dp) where the consumer's own JSX
   order sets both DOM and visual order directly. This is a flattening of
   Compose-specific composition mechanics with no clean CSS equivalent, in
   the same spirit as this library's existing spring/measure-policy
   flattenings, and it generalizes to zero, one, or more than two actions
   with no dedicated confirm/dismiss prop shape to outgrow.
8. Every `DialogTokens` role `AlertDialogContent` actually reads is
   registered: container color/shape/elevation/padding, icon color/size/
   spacing, headline color/spacing, supporting-text color/spacing, and
   action content color (registered despite the source's own comment that
   `TextButton`s typically override it, since it is genuinely assigned via
   `CompositionLocalProvider`, unlike a role the source never connects to
   any resolution path at all — the same registration standard T15 applied
   to the icon-color roles it left out). `DialogMinWidth`/`DialogMaxWidth`
   (280px/560px) are cross-validated against material-web's dialog CSS
   (`min(560px, calc(100% - 48px))`), which also supplies the only
   available source for two values the pinned Compose source has none of
   its own for — a 24px-per-side viewport margin and a 32%-opacity scrim —
   since window dimming there is an Android platform default, not a
   cross-platform Material3 design token.
9. Entrance and exit motion (fade + scale on the dialog surface using
   `default-spatial` tokens, an opacity-only fade on the backdrop using
   `default-effects` tokens) use `@starting-style` with
   `transition-behavior: allow-discrete` — a native technique, requiring no
   JS orchestration, for animating an element across the top-layer
   `display`/`overlay` transition that a plain `showModal()`/`close()` call
   otherwise performs as a hard cut. This is the one deliberate exception
   to this library's hard browser-floor commitment elsewhere (`:has()`
   pinned to Firefox 121): `@starting-style` reached Baseline in August
   2024, after that floor. The trade is safe specifically because it is a
   pure progressive enhancement — an unsupporting browser keeps every
   functional guarantee (correct open/closed state, focus, callbacks) with
   an instant, correct show/hide instead of an animated one, never a broken
   or non-functional one. No prior component in this library has made that
   trade, because no prior component's motion was this cleanly separable
   from its function; `:has()`-driven state in Radio/SegmentedButtonGroup,
   by contrast, is load-bearing for the correct visual state itself, not
   just its transition.
10. A controlled dialog's own native dismissal is reported through
    `onOpenChange` but is not forcibly reverted if the consumer ignores it.
    This differs from a controlled native form value (`checked` on
    Checkbox/Radio/Switch), where React's own controlled-input machinery
    snaps the DOM back to the prop value as part of the same event; a
    `<dialog>`'s `open` attribute has no equivalent React-owned
    reconciliation, so nothing forces a further render when the consumer's
    `open` prop value does not itself change. This is treated as an
    accepted extension of the native-truth precedent Radio/Checkbox/
    SegmentedButtonGroup already established — platform state can move
    ahead of an unacknowledged controlled prop — documented rather than
    fought with synthetic re-open logic that no other dialog library in
    this ecosystem attempts either.
11. No bundle-budget ceiling raise is needed: `npm run verify`'s
    bundle-size gate passes against the ceilings ADR 0015 raised, with the
    tightest artifact (full CSS) at 221,993 of 245,000 bytes (~91% used).

## Consequences

- Consumers get an entire Material dialog — icon, title, body, actions,
  adaptive sizing, backdrop, focus trap, focus lifecycle — from one
  component and a controlled/uncontrolled `open` pair, with no separate
  focus-trap library, portal, or manual `aria-modal` bookkeeping.
- Non-modal dialogs are a genuine, fully-native capability this library did
  not have before T16, available to any future component that needs a
  dismissable-but-non-blocking surface without reaching for a second
  overlay primitive.
- `@starting-style` establishes that this library's floor-support
  commitment is about function, not decoration: a future component may
  reach for a postdated CSS feature the same way, provided the fallback is
  provably a full-fidelity, merely-unanimated equivalent, not a degraded
  one.
- A controlled `Dialog` consumer must treat `onOpenChange` as the
  authoritative signal to commit state, not a notification a fully
  synchronous parent can silently outvote — a real, documented departure
  from how this library's controlled form controls behave that any future
  overlay component (Menu, Tooltip, Snackbar in T17/T18) should also
  document explicitly rather than assume away.
- The manual outside-click bounding-rect technique is a stopgap against the
  pinned floor's lack of `closedby`; when this library's floor eventually
  moves past that feature's Baseline date, `dismissOnOutsideClick` could be
  reimplemented as a plain `closedby` attribute toggle with no prop-surface
  change, an internal simplification already anticipated by the current
  prop shape.

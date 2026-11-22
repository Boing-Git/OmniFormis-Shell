# ADR 0018: Tooltip's self-wired hover/focus, excluded rich-tooltip action, and a single pausable-timed Snackbar

Status: accepted
Date: 2026-07-20
Task: T18

## Context

The pinned AndroidX revision (`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`,
still the branch's current HEAD since T17) implements tooltips across
`Tooltip.kt` (`TooltipBox`/`PlainTooltip`/`RichTooltip`, positioned by a
`PopupPositionProvider` variant that centers on the cross axis and flips
once on collision, with **zero** viewport margin — `coerceIn(0, ...)`, not
a margin like `DropdownMenuPositionProvider`'s 8dp) and `BasicTooltip.kt`
(`handleGestures`, showing/dismissing immediately on mouse enter/exit or
keyboard focus/blur, with a separate touch long-press path that has no
desktop-web equivalent). `PlainTooltipTokens`/`RichTooltipTokens` supply
container/text color, shape, and elevation; `RichTooltip` additionally
supports an inline action button
(`RichTooltipTokens.ActionLabelTextColor`, etc.).

Snackbars are implemented across `Snackbar.kt` (`Snackbar` composable,
`SnackbarDefaults`) and `SnackbarHost.kt` (`SnackbarHostState`, a
mutex-guarded suspend-function queue that shows one `SnackbarData` at a
time, `SnackbarDuration.toMillis` resolving `Short`/`Long`/`Indefinite` to
`4000`/`10000`/`Long.MAX_VALUE` milliseconds, `FadeInFadeOutWithScale`
animating entry/exit with the same `FastSpatial`/`FastEffects` fade+scale
technique `Menu` already ports). `SnackbarTokens` supplies container/text/
action/icon color, shape, and elevation.

The component inventory names two tasks' worth of exports: `Tooltip`/
`TooltipProps` (kind `overlay`) and `Snackbar`/`SnackbarProps` (kind
`feedback`), each a single component, not the pinned source's
`TooltipState`/`SnackbarHostState` orchestration types.

## Decision

1. `Tooltip` reuses T17's `useAnchoredOverlay`/`overlayPosition`
   infrastructure but needs a different position algorithm: center-aligned
   cross axis, single flip on collision, zero margin, `4px` gap
   (`SpacingBetweenTooltipAndAnchor`) — a genuinely different shape from
   `Menu`/`Select`'s start/end-then-clamp, 8px-margin algorithm, not a
   parameterization of it. `useAnchoredOverlay` gains an optional
   `computePosition` override used only by `Tooltip`; `Menu`/`Select` omit
   it and keep their existing default path and behavior unchanged (their
   existing test suites pass unmodified). `overlayPosition.ts` gains a
   sibling pure function, `computeTooltipPosition`, alongside the existing
   `computeOverlayPosition`.
2. Unlike `Menu`, `Tooltip` wires its own show/hide interaction directly on
   `anchorRef.current` (`mouseenter`/`mouseleave`/`focus`/`blur`) rather
   than asking the consumer to. `Menu`'s click-to-open is genuinely
   app-specific (a button, an icon, a right-click — the consumer's own
   choice), so leaving it to the consumer was correct there; hover/focus
   tooltip triggering is instead a single, standardized WAI-ARIA APG
   interaction with no such ambiguity, so the library owns it completely.
   `open`/`defaultOpen`/`onOpenChange` still exist as a controlled escape
   hatch. Shown/hidden immediately, matching `handleGestures` exactly — no
   invented warm-up delay, since the pinned source has none for its own
   mouse-hover path (only the separate, desktop-inapplicable touch
   long-press path has a duration, `BasicTooltipDefaults.TooltipDuration`,
   1500ms, which is not ported).
3. `Tooltip` also imperatively sets/removes `aria-describedby` on the
   anchor while mounted, merging with (not clobbering) any value the
   consumer already set declaratively — the first imperative ARIA-attribute
   technique in v1, extending the same "library owns unambiguous wiring"
   reasoning that already justifies Dialog's imperative native calls and
   Menu/Select's imperative focus calls.
4. **Hoverable beyond the source**: the popover itself also participates in
   the show/hide evaluation (`anchorHovered || popoverHovered || focused`),
   so a pointer crossing the gap from anchor to popover does not
   flicker-close it — a deliberate WCAG 1.4.13 addition; the source only
   tracks the anchor. No fabricated timing buffer is needed to bridge the
   physical gap: `useAnchoredOverlay`'s own deferred-unmount fade-out
   window (driven by the sourced `FastEffects`/`FastSpatial` motion
   duration) already keeps the popover present and re-openable for exactly
   as long as its exit transition takes, which is enough real time for the
   pointer to complete a normal transition across a few pixels of gap.
5. Both `Tooltip` variants stay non-interactive throughout. `RichTooltip`'s
   action button (`RichTooltipTokens.ActionLabelText*`) has **no web
   port**: WAI-ARIA explicitly disallows interactive content inside
   `role="tooltip"`, a direct conflict with the native web semantic, which
   wins per `SPEC.md` §3. This is a genuine spec conflict, not merely a
   missing browser API — unlike, say, `Menu`'s excluded cascading submenus,
   which are excluded for lack of a clean web equivalent rather than a
   contradiction. No caret/pointer triangle either: the source draws it via
   `CacheDrawScope`/`LayoutCoordinates` custom geometry with no clean web
   equivalent, the same basis prior tasks already excluded
   Compose-specific-drawing features on.
6. `Snackbar` is one public, data-driven-by-props component
   (`message`/`action?`/`dismissible?`/`duration?`), not the pinned
   source's separate `SnackbarHostState`/`SnackbarHost` queue-orchestration
   pair — matching the component inventory's single `Snackbar`/
   `SnackbarProps` export and this library's other controlled primitives
   (`open`/`defaultOpen`/`onOpenChange`). A consumer wanting several queued
   snackbars manages that queue in their own application state, the same
   "library owns the primitive, not the orchestration" precedent every
   other v1 component already follows (`Menu` does not own a
   application-wide menu stack either). It owns a lightweight, local
   mount/measure-free phase machine (mirroring `useAnchoredOverlay`'s
   `closed`/`entering`/`open`/`closing` states minus anchor measurement,
   since a fixed-position toast needs no anchor) rather than reusing
   `useAnchoredOverlay`, since that hook's positioning/anchor-dismissal
   machinery does not apply to an unanchored, viewport-fixed element.
7. `duration` defaults to the source's own logic
   (`if (action == null) Short else Indefinite`, `4000`/`10000`ms).
   **Pausable beyond the source**: the countdown pauses while the snackbar
   is hovered or focused and resumes the remaining time (tracked via
   `Date.now()` deltas, paired consistently with the real `setTimeout` the
   countdown itself uses) on leave — a deliberate WCAG 2.2.1 (timing
   adjustable) addition; Android's own accessibility services extend
   timing a different way with no web equivalent, so the source has no
   analogous mechanism to port.
8. `Snackbar`'s public API has no leading status-icon slot:
   `SnackbarTokens.IconColor`/`IconSize` belong to the optional dismiss
   action only in the pinned source's public `Snackbar` composable — there
   is no separate icon parameter to port. The `actionOnNewLine` two-row
   layout (the source's own `LegacySnackbarVerticalPadding`-prefixed
   constants) is excluded as a legacy variant; the action stays inline, the
   modern single-row layout the non-prefixed constants describe.
9. No `Snackbar` component-level viewport-offset token is registered: the
   pinned source leaves screen-edge placement to a consuming `Scaffold`,
   not a component constant, and material-web ships no snackbar
   implementation at all (only token files) to cross-validate a number
   against either — unlike Dialog's viewport margin, which had a
   cross-validation source available. The bottom offset is therefore a
   plain CSS value, not a claimed-sourced token, the same "implementation
   constant, not a Material value" status `Menu`'s own `z-index: 1000`
   already has.
10. `Snackbar`'s action/icon focus/hover/pressed colors all resolve to the
    same role as enabled in both the pinned AndroidX source and
    material-web's `_md-comp-snackbar.scss` (checked at the
    `material-web-tokens` source's own already-pinned revision
    `b4de401eb665ec63474f39319a4ba8f2145974cc`) — the first time this
    project's cross-validation source corroborates a component-level color
    role rather than filling in a missing numeric value. Hover/press
    feedback therefore reuses the shared `--m3e-sys-state-*` system via
    `currentColor`, the same `Menu`/`Select` precedent, with no separate
    state-layer color token registered.
11. Measured output stayed within the T17 bundle-budget ceilings (raised
    for Menu/Select); no budget update was needed for this task.

## Consequences

- `useAnchoredOverlay` is now genuinely reused by a third component with a
  different position algorithm, validating ADR 0017's stated expectation
  that future overlay components could build on it rather than reinventing
  portal/positioning/dismissal machinery — the `computePosition` override
  is the concrete mechanism a fourth overlay component (if its algorithm
  differs again) would extend the same way.
- `Tooltip` and `Menu` deliberately use two different trigger-ownership
  models (`Menu`: consumer wires the opener; `Tooltip`: the library wires
  hover/focus itself) — a considered, per-interaction decision based on
  whether the triggering interaction is genuinely app-specific or a single
  standardized pattern, not an inconsistency. A future overlay component
  should make the same judgment call on its own interaction rather than
  copying either wholesale.
- The rich-tooltip action button's exclusion is permanent, not a
  provisional gap: no future browser or ARIA revision resolves a
  role="tooltip"-vs-interactive-content conflict, since the constraint is
  definitional. A consumer needing an interactive hover-revealed panel
  should reach for `Menu` or a bespoke popover, not expect `Tooltip` to
  grow one.
- `Snackbar`'s no-queue design means a consumer application showing several
  sequential snackbars is responsible for sequencing them (e.g., not
  opening a second one before the first's `onOpenChange(false)` fires); this
  is a documented, deliberate scope boundary, not an oversight.

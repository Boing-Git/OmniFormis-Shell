# ADR 0020: Web-native navigation semantics, a shared NavigationItem type, an independently-duplicated modal drawer, and a deliberately 3-tier adaptive suite

Status: accepted
Date: 2026-07-20
Task: T20

## Context

The pinned AndroidX revision (`225f50d42bf0adeb2abf4b6109befb5ab6ce4efc`,
still the branch's current HEAD since T17–T19) implements navigation
across `NavigationBar.kt`, `NavigationRail.kt`, and `NavigationDrawer.kt`
(`ModalNavigationDrawer`/`DismissibleNavigationDrawer`/
`PermanentNavigationDrawer`, each with matching `*DrawerSheet` composables
and a shared `DrawerState`/`DrawerValue` pair, plus a swipe-to-dismiss
`anchoredDraggable` gesture on the modal variant). `NavigationBarItem`/
`NavigationRailItem`/`NavigationDrawerItem` all reuse `Modifier.selectable(
role = Role.Tab)`. `NavigationBarTokens`/`NavigationBarVerticalItemTokens`,
`NavigationRailColorTokens`/`NavigationRailVerticalItemTokens`/
`NavigationRailCollapsedTokens`, and `NavigationDrawerTokens` supply each
component's own color/geometry. The separate `material3-adaptive-
navigation-suite` module's `NavigationSuiteScaffold.kt`/
`WindowSizeClassHelper.kt` supply an adaptive layout switcher with real,
sourced `Compact`/`Medium`/`Expanded`/`Large`/`ExtraLarge` width
breakpoints (`0`/`600`/`840`/`1200`/`1600dp`), though its own
`calculateFromAdaptiveInfo` function only switches between
`NavigationBar`/`NavigationRail` — it never auto-selects a drawer.

The component inventory names four tasks' worth of exports:
`NavigationBar`/`NavigationBarProps`, `NavigationRail`/
`NavigationRailProps`, `NavigationDrawer`/`NavigationDrawerProps`, and
`NavigationSuite`/`NavigationSuiteProps` — four components explicitly
grouped as one "navigation suite," unlike any prior task's independent
components.

## Decision

1. **Web-native `<nav>`/`aria-current` navigation semantics, not the
   pinned source's ported `role="tab"`**: `Tabs` (T19) already owns
   `role="tablist"`/`role="tab"`/`role="tabpanel"` for in-page panel
   switching. A navigation bar/rail/drawer is a fundamentally different
   case — persistent site/app navigation — so all three render a
   `<nav aria-label>` (or `aria-labelledby`) containing plain focusable
   items: `<a href>` when navigating, `<button>` otherwise, with
   `aria-current="page"` on the active one. No roving `tabindex` and no
   arrow-key model: items sit in normal tab order like any navigation
   link list, since APG has no composite-widget requirement for a
   navigation menu the way it does for tabs. This is SPEC §3's "web
   semantic wins over ported platform guidance" clause applied for the
   first time to a *pattern* choice, not just a color/shape value. A
   disabled `href` item omits `href` (anchors have no native disabled
   state) but keeps an explicit `role="link"` — discovered via a failing
   test during implementation: omitting `href` alone silently strips the
   anchor's implicit link role entirely, which `Tabs`' own disabled-link
   handling never hit because `Tabs` already sets an explicit `role="tab"`
   regardless of `href` presence.
2. `NavigationBar`, `NavigationRail`, and `NavigationDrawer` share one
   `NavigationItem` data type (`{ value, label, icon, selectedIcon?,
   disabled?, href? }`), canonically defined in `NavigationBar.types.ts`
   and re-exported by the other two through their own public barrels —
   the first cross-component-folder type reuse in v1. Every prior pair of
   components that shared visual styling (`Select`/`Menu`, `Select`/
   `TextField`) never needed to share a *type*, since neither rendered the
   other; these three (and `NavigationSuite`, which renders all three) are
   explicitly designed to interoperate, so sharing the canonical type
   through the public barrel (not a deep import into another component's
   internals, which the architecture check correctly rejects) is the
   right call.
3. `NavigationBar` and `NavigationRail` are the same item visual language
   (icon, `56×32px` pill, label) in two orientations — a short, largely
   duplicated pair of components rather than a forced shared internal
   render helper, since their container semantics (fixed horizontal row
   vs. vertical column with an optional header) differ enough that a
   shared abstraction would need real parameterization for modest savings.
   A T20 conformance repair preserves the source's separate placeables in
   CSS: the icon and full-size interaction layer keep fixed geometry while a
   centered background pseudo-element alone animates from zero width to the
   `56×32px` active pill. Scaling the wrapper would incorrectly halve the
   inactive icon and change the item geometry.
4. `NavigationDrawer` unifies three pinned composables
   (`ModalNavigationDrawer`/`DismissibleNavigationDrawer`/
   `PermanentNavigationDrawer`) into one component with a `variant` prop.
   `'modal'` independently duplicates Dialog's own small native-`<dialog>`
   lifecycle (~20 lines: imperative `showModal()`/`close()` plus a native
   `close` event listener) rather than sharing an extracted primitive —
   the two components' exact backdrop/escape nuances differ enough that a
   forced shared abstraction would need its own parameterization, and this
   is only the second native-`<dialog>` caller so far. It slides in by
   animating `inset-inline-start` (not `transform`), so the slide
   direction auto-corrects under RTL with no JS branching, using the same
   `[open]`-attribute-driven `@starting-style` technique ADR 0016
   established for `Dialog`. `'dismissible'` collapses its own
   `inline-size` to `0` in place — a plain, non-modal panel participating
   in normal document flow, matching the source's own non-scrimmed reveal.
   `'permanent'` is always rendered with no open/close state at all,
   matching the source's own `PermanentNavigationDrawer`, which has no
   visibility parameter. The source's `anchoredDraggable` swipe-to-dismiss
   gesture on the modal variant is excluded — Compose-specific gesture
   machinery with no clean web equivalent, the same basis Menu's excluded
   drag-select uses.
5. `NavigationDrawer` items tint **both** icon and label
   `onSecondaryContainer` when selected — unlike `NavigationBar`/
   `NavigationRail`, which split icon (`onSecondaryContainer`) and label
   (`secondary`) — and use `labelLarge` typography, larger than
   `NavigationBar`/`NavigationRail`'s `labelMedium`. Both are genuine
   sourced differences between the token files, not inconsistencies to
   reconcile.
6. **`NavigationSuite` is the first v1 component to render another public
   v1 component internally**: it composes `NavigationBar`/
   `NavigationRail`/`NavigationDrawer` directly rather than reimplementing
   their rendering, since it exists specifically to interoperate with
   them — no prior component pair had this relationship (they only ever
   shared styling/tokens). It switches between them via a new
   `window.matchMedia`-driven internal hook (kept local to
   `NavigationSuite.tsx`, not extracted to `src/internal`, since no
   other component needs it — the same "don't extract ahead of a second
   caller" discipline `Tabs`' own sliding-indicator logic already
   followed) using the pinned source's own real `Compact`/`Medium`/
   `Expanded` width breakpoints (`0`/`600`/`840px`).
7. **Deliberate 3-tier mapping, diverging from the pinned source's own
   `calculateFromAdaptiveInfo`**: that function only ever returns
   `NavigationBar` or `NavigationRail` — it never auto-selects a drawer at
   any width. This task maps compact → `NavigationBar`, medium →
   `NavigationRail`, expanded → `NavigationDrawer` (`'permanent'`)
   instead, because the task's own name explicitly groups "Bar, rail,
   drawer" under one adaptive suite, and the sourced Compact/Medium/
   Expanded breakpoint *tier names* already exist for exactly this
   three-way split elsewhere in the same pinned module — a permanent
   drawer at the expanded tier is the more useful, expected behavior for
   this library's own component matrix. The breakpoint *values* themselves
   are unchanged from the source; only which component each tier maps to
   differs from that one specific pinned function.
8. SSR/pre-hydration renders the `'compact'` tier (`NavigationBar`) until
   a client effect measures the real viewport and corrects it, since there
   is no real width to measure server-side — the same "renders a
   reasonable default before a real measurement is available" category
   `Tabs`' indicator and `Snackbar`'s auto-dismiss timing both already
   established in different forms.
9. Measured output stayed within the T19 bundle-budget ceilings; no budget
   update was needed for this task.

## Consequences

- The `NavigationItem` re-export chain (`NavigationBar` → `NavigationRail`/
  `NavigationDrawer`/`NavigationSuite`, always through the public barrel)
  is the first precedent for genuinely interoperating components sharing
  a type; a future component group with the same relationship should
  follow the same "canonical owner + barrel re-export" shape rather than
  duplicating the interface or reaching for a new shared-types module.
- `NavigationSuite` composing public components directly is a new,
  deliberate pattern specific to "meta" components explicitly designed to
  interoperate — it should not be reached for by a future component that
  only shares styling or tokens with another, the same boundary `Select`'s
  own token-reuse-without-composition precedent already drew.
- The web-native navigation pattern (vs. `Tabs`' tablist pattern) is now
  the second time this project has diverged from a literal ported ARIA
  role in favor of the semantically correct web pattern for a genuinely
  different use case; a future navigation-adjacent component should ask
  the same question (site navigation vs. in-page composite widget) rather
  than defaulting to whichever role the pinned Compose source happens to
  use.
- The disabled-link role fix (explicit `role="link"` when `href` was
  defined but omitted for a disabled item) applies to `NavigationBar`,
  `NavigationRail`, and `NavigationDrawer` alike; a future link-safe
  component reusing the "omit `href` to disable" technique should apply
  the same fix rather than rediscovering the gap.

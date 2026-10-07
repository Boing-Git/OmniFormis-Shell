# ADR 0009: Native Expressive FloatingActionButton modes

Status: accepted
Date: 2026-07-19
Task: T09

## Context

Current AndroidX Material 3 publishes separate standard, medium, large,
size-aware extended, and Expressive toggle FAB composables. Ordinary and
extended controls use primary-container colors with interaction-dependent
elevation. Toggle FAB is designed beside a future menu: it interpolates size,
corner, color, and icon toward a fixed close-button geometry while preserving
the initial layout footprint.

React consumers need one predictable component owner path without losing the
important mode distinctions. The control must also remain a native web button;
generic clickable surfaces or custom keyboard listeners would weaken form,
disabled, focus, and activation behavior. A collapsed extended label and a
toggle icon create different accessible-name requirements that public types
must make hard to mix accidentally.

## Decision

1. `FloatingActionButton` always renders a native `<button>`, defaults to
   `type="button"`, and forwards its native props and `HTMLButtonElement` ref.
   It owns no page positioning, link, tooltip, loading, scroll, or menu logic.
2. One discriminated props union exposes three modes: icon-only momentary;
   `label`-driven extended with optional `expanded`; and icon-only
   `toggle={true}` with controlled/uncontrolled selected state. Invalid
   extended-toggle combinations fail TypeScript and warn untyped callers.
3. Literal `size` values standard/medium/large map to current 56/80/96px
   containers, 24/28/36px icons, and 16/20/28px corners. Extended mode uses
   matching title-medium/title-large/headline-small type and sourced logical
   padding. Source corrections, rather than stale generated TODO values, set
   medium/large icon-label gaps to 12/16px and the large icon to 36px.
4. Extended label stays mounted and semantically available when visually
   collapsed. Its max inline size and opacity transition separately so the
   button keeps a stable accessible name rather than depending on decorative
   icon semantics.
5. Toggle selection interpolates to current 56px/28px/20px close geometry and
   primary/on-primary colors. An 80px or 96px toggle retains its initial outer
   footprint, with the selected visual at logical top-end. Alternate selected
   artwork is optional.
6. Toggle state uses boolean `aria-pressed`. Consumer `onClick` runs first and
   `preventDefault()` cancels internal mutation through the shared event and
   controllable-state primitives. Native Enter, Space, forms, and disabled
   behavior stay browser-owned.
7. `elevation` is `default`, `lowered`, or `none` for momentary/extended FABs.
   Default shadows are Level 3 at rest/focus/press and Level 4 on hover;
   lowered uses Level 1 and Level 2; none uses Level 0. Toggle rejects the prop
   and stays at the first-party fixed Level 3 in every interaction state.
8. Extended and toggle geometry consume Expressive fast-spatial motion; color,
   label opacity, and state layers consume fast-effects; shadow consumes
   default-effects. Reduced motion makes all outcomes immediate. Forced colors
   removes authored shadows/state layers and keeps focus, selection, and
   disabled state visible through system colors and outlines.
9. T09 records the complete post-build baselines and explicit ceilings:

   - public v1 JavaScript closure: 114,204 bytes / 22,736 aggregate gzip;
     ceiling 132,000 / 26,500;
   - public v1 declaration closure: 34,120 / 9,288 aggregate gzip; ceiling
     40,500 / 11,500;
   - full CSS: 158,798 / 13,354 gzip; ceiling 183,000 / 15,800;
   - token CSS: 80,547 / 6,829 gzip; ceiling 93,000 / 8,200;
   - packed package: 247,582 bytes; ceiling 285,000.

   The pre-task reference is T08 commit
   `d919142ed2e3d4d6bd0b6720cb1f9dca3de5159f`. The increase comprises 42
   sourced FAB component tokens, one discriminated native component using
   existing shared state/event primitives, and an explicit size/mode/elevation
   stylesheet. The ceilings retain measured task headroom while all reports
   continue to count imported artifact closures.

## Consequences

- React developers receive current Expressive FAB geometry, extended layout,
  toggle transformation, and elevation without Next.js, Tailwind, an animation
  runtime, or a menu/positioning dependency.
- The one component path is not an untyped mega-API: the mode union prevents
  selected props on ordinary controls, extension on toggles, and elevation
  overrides where first-party behavior is fixed.
- Stable extended naming is a deliberate web improvement over delegating a
  collapsed control name to arbitrary icon content.
- `FabMenu` can later consume controlled toggle state without making T09 own
  APG menu composition or back-propagating menu concepts into this control.
- The selected toggle visual stays top-end within a stable footprint, so app
  layout does not jump and RTL follows logical CSS automatically.

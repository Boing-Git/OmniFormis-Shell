# ADR 0007: Native Expressive Button and CSS spring projection

Status: accepted
Date: 2026-07-19
Task: T07

## Context

Current AndroidX Material 3 has five Button emphasis components and five
Expressive size tiers. Its expressive overload morphs a resting shape to a
size-aware pressed shape using the theme's default-effects spring; the source
explicitly chooses effects motion to prevent bounce. Compose modifiers provide
width, target expansion, content padding, and custom shapes that do not map
directly to a safe React web contract.

The web must also preserve native form, keyboard, focus, disabled, and
activation behavior. Replacing a `<button>` with a generic clickable surface or
synthesizing keyboard callbacks would lose that platform behavior. CSS cannot
use damping ratio and stiffness as a transition directly, but the token model
already retains those first-party spring parameters and custom themes may
override them.

## Decision

1. `Button` always renders a native `<button>` and defaults to `type="button"`.
   It forwards `HTMLButtonElement`, form attributes, ARIA/data attributes,
   class/style, and native React handlers. It adds no activation handlers,
   redundant role, link polymorphism, or toggle/loading semantics.
2. One `variant` union represents filled, tonal, elevated, outlined, and text.
   One `size` union represents extra-small, small, medium, large, and extra-
   large. `width` is bounded to intrinsic/full and `shape` to round/square.
   Stable data attributes make every choice searchable and styleable.
3. The semantic root reserves the theme's 48px minimum inline/block target. A
   nested visual container retains sourced 32/40/56/96/136px minimum heights,
   padding, outline, shape, state layer, and elevation. This avoids relying on a
   pseudo-element outside an element's border for hit testing.
4. Label typography delegates to public `Text` through its component barrel.
   Optional leading/trailing visuals are wrapped and hidden from assistive
   technology so the button label owns the accessible name. Arbitrary nested
   interactive elements remain invalid consumer content.
5. Round resting shapes use exact half-height radii rather than CSS `9999px`.
   They render the same pill geometry but interpolate correctly to sourced
   pressed radii. Square resting and pressed radii use system shape roles.
6. Token CSS serialization becomes the shared web spring projection. For every
   system motion slot it calculates a unit-mass step response from damping ratio
   and stiffness, finds a 0.001 settlement threshold, and emits a duration plus
   a deterministic ten-sample CSS `linear()` easing. These derived variables
   are scoped with the source spring values and recomputed for custom themes.
7. Button consumes Expressive default effects, matching the first-party no-
   bounce choice. `prefers-reduced-motion: reduce` removes transitions while
   preserving immediate state, and forced colors uses system colors and a
   visible focus/outline treatment.
8. T07 records the complete post-build baselines and explicit ceilings:

   - public v1 JavaScript closure: 91,684 bytes / 20,588 aggregate gzip;
     ceiling 105,000 / 24,000;
   - public v1 declaration closure: 28,677 / 8,525 aggregate gzip; ceiling
     34,000 / 10,500;
   - full CSS: 123,405 / 10,669 gzip; ceiling 142,000 / 12,500;
   - token CSS: 71,076 / 6,109 gzip; ceiling 82,000 / 7,200;
   - packed package: 233,771 bytes; ceiling 269,000.

   The pre-task reference is T06 commit
   `60ce047267bab81cef7729bcd2780a70889dfd42`. The increase comprises 83
   sourced Button component variables, 24 derived system-motion variables, the
   native component, and the complete variant/size/state stylesheet. The
   ceilings restore measured per-task headroom and remain checked against
   aggregate imported closures rather than only entry-file size.

## Consequences

- React developers receive native form and keyboard behavior with a complete,
  explicit Expressive Button API and no framework adapter or runtime animation
  dependency.
- Smaller visual sizes keep a 48px layout target. Adjacent controls therefore
  reserve accessible hit space rather than overlapping invisible hit regions.
- Theme motion overrides affect generated CSS without React subscriptions,
  browser measurement, hydration state, or runtime style injection. Future
  components can consume the same derived semantic variables.
- Sampled CSS curves are a documented web projection, not byte-for-byte Compose
  physics. The source damping/stiffness, settlement rule, sample count, and
  reduced-motion outcome are deterministic and testable.
- Link buttons, toggle/icon-only actions, loading, groups, split controls, and
  arbitrary polygon shape morphs remain separate purpose-built tasks.

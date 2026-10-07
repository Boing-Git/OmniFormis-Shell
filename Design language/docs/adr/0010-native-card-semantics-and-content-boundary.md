# ADR 0010: Native Card semantics and content boundary

Status: accepted
Date: 2026-07-19
Task: T10

## Context

AndroidX publishes filled, elevated, and outlined Card functions with passive
and clickable overloads. Their content is a generic Compose `Column`, which can
hold arbitrary composables. HTML has a stricter boundary: a native button is the
correct whole-card action, but its descendants must be phrasing content and may
not include nested interactive content. A generic clickable `div` would allow
richer descendants at the cost of reimplementing button semantics, while an
overlay action would create ambiguous pointer, focus, and nested-action order.

Current AndroidX Card and generated Card tokens do not add a separate
Expressive size, shape morph, or selected-card API. Expressive behavior in this
web library therefore comes from the shared theme and motion foundation rather
than invented Card modes.

## Decision

1. One `Card` export provides filled, elevated, and outlined variants and owns
   no content slots, content padding, typography, media, or application model.
2. Its props are a discriminated union. Passive mode is the default, renders an
   `article`, and permits only `article`, `div`, `section`, or `aside` through
   `as`. It statically rejects activation, keyboard-focus, disabled, form, and
   toggle props and discards those values with an actionable development
   warning for untyped runtime callers.
3. `interactive={true}` always renders a native `<button>` and defaults to
   `type="button"`. It forwards the button ref and native form, activation,
   focus, disabled, ARIA, data, class, and style behavior without custom
   keyboard handlers.
4. Interactive children must be phrasing content with no links, controls,
   focusable descendants, or block elements. A development check catches
   inspectable intrinsic violations; documentation makes the unavoidable custom
   component boundary explicit. Rich cards use passive mode with nested
   purpose-built actions.
5. Filled uses surface-container-highest and Level 0, elevated uses
   surface-container-low and Level 1, and outlined uses surface with a 1px
   outline-variant border and Level 0. Interactive hover raises them to Levels
   1, 2, and 1 respectively; focus and press retain their resting levels.
   Disabled colors, opacity, outlines, and elevation follow the pinned generated
   tokens.
6. State-layer opacity uses Expressive fast-effects motion. Background, border,
   and shadow use the existing default-effects spring projection. Reduced
   motion is immediate, and forced colors keeps borders, focus, and disabled
   state visible without authored shadows or translucent overlays.
7. Selection/toggle state, link navigation, drag elevation, long press, swipe,
   overlay-link patterns, and custom shape/color/elevation props are excluded
   until a separately sourced web contract can provide valid semantics.
8. T10 records the complete post-build baselines and explicit ceilings:

   - public v1 JavaScript closure: 124,365 bytes / 24,094 aggregate gzip;
     ceiling 144,000 / 28,000;
   - public v1 declaration closure: 36,294 / 9,725 aggregate gzip; ceiling
     43,000 / 12,000;
   - full CSS: 170,444 / 14,314 gzip; ceiling 197,000 / 17,000;
   - token CSS: 83,969 / 7,053 gzip; ceiling 97,000 / 8,500;
   - packed package: 255,218 bytes; ceiling 294,000.

   The pre-task reference is T09 commit
   `cea87cb179dc62490dda64406b9760ac32bd33b5`. The increase comprises 45
   sourced Card component tokens, the discriminated passive/native component,
   and its explicit variant/state stylesheet. The ceilings restore measured
   per-task headroom while reports continue to count imported artifact closures.

## Consequences

- React consumers can compose rich semantic cards without inheriting accidental
  interaction, and whole-card actions retain native form and keyboard behavior.
- The explicit `interactive` discriminator and content warning make the HTML
  tradeoff discoverable to human and agentic contributors at the component
  boundary.
- A card containing nested controls cannot also make its entire container a
  button. Consumers must expose a clear primary control inside passive content.
- The library does not claim new Expressive Card geometry that is absent from
  the current first-party implementation.

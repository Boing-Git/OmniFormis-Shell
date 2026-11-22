# ADR 0005: Text semantics and the Expressive type scale

Status: accepted
Date: 2026-07-19
Task: T05

## Context

Material 3 Expressive adds emphasized counterparts to the complete baseline
type scale. Android Compose applies a `TextStyle` independently from platform
text semantics, while React for the web must also preserve a valid HTML document
outline, native label behavior, and consumer-owned font loading.

One implementation could infer headings from display/headline roles or construct
token variable names dynamically. Both would create hidden conventions: visual
redesigns could change accessibility, and token typos would become runtime-only
failures.

## Decision

1. `Text` separates `variant`, `emphasis`, and `as`. `variant` is the 15-role
   Material scale, `emphasis` selects baseline or emphasized, and only `as`
   determines HTML semantics.
2. The defaults are `span`, `bodyLarge`, and `baseline`. `bodyLarge` matches the
   default text style provided by AndroidX MaterialTheme; `span` is the neutral
   inline web adaptation that does not manufacture document structure.
3. Polymorphism is bounded to native non-link text, grouping, heading, labeling,
   and caption elements. Links and controls remain purpose-built APIs. Generic
   custom components are excluded so native attributes and refs remain exact.
4. Text inherits content color and has no component-token registration. Its
   first-party styling inputs are system typography and the content color of its
   surrounding container. Consumer CSS remains the explicit escape hatch.
5. Every style consumes family, weight, size, line height, tracking, and all nine
   modeled variable-font axes. The emphasized scale is resolved independently
   rather than simulated by increasing baseline font weight.
6. Colocated CSS contains a literal selector and literal system-token references
   for every one of the 30 combinations. The repetition is intentional: source
   searches, CSS validation, and packed-output checks can prove every mapping
   without runtime-generated variable names or style injection.
7. The component removes native element margins for predictable Material layout
   but preserves native display mode and semantics. Rendering never fetches a
   font, emits `@font-face`, inserts a style tag, auto-sizes, or truncates text.
8. T05 records the complete post-build baselines and explicit ceilings:

   - public v1 JavaScript closure: 72,519 bytes / 16,869 aggregate gzip;
     ceiling 82,000 / 19,000;
   - public v1 declaration closure: 24,521 / 7,278 aggregate gzip; ceiling
     28,000 / 8,500;
   - full CSS: 101,303 / 7,694 gzip; ceiling 115,000 / 9,000;
   - token CSS: 62,865 / 5,067 gzip; ceiling 70,000 / 6,000;
   - packed package: 214,539 bytes; ceiling 245,000.

   The pre-task reference commit is T04 commit
   `a0994c6fd3d123cde9cbbfc2151db07d1b9a5522`. Token CSS is effectively
   unchanged; the full stylesheet grows because it now contains all 30 literal
   mappings. The gzip increase is much smaller than the raw increase because
   those mappings repeat one checked structure.

## Consequences

- A visual typography change cannot silently alter the accessible heading level
  or label relationship.
- Consumers can use the same semantic element with baseline or emphasized
  styling and can theme either scale independently, including capable variable
  fonts.
- Semantic `strong` and `em` remain semantic elements, while their visual weight
  and variable axes follow the selected Material role. Consumer CSS can add an
  intentional typographic exception.
- The explicit 30-style CSS table costs raw stylesheet bytes but compresses
  efficiently. T05 records the measured package ceilings rather than hiding the
  conformance cost behind convention-based runtime code.

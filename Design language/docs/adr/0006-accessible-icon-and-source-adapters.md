# ADR 0006: Accessible Icon and source adapters

Status: accepted
Date: 2026-07-19
Task: T06

## Context

First-party Material `Icon` accepts vector, bitmap, or painter sources, inherits
content color, and is decorative when it has no content description. React web
consumers instead encounter several incompatible source shapes: SVG component
packages, copied SVG markup, and Material Symbols ligature fonts. Bundling one
icon registry would couple the foundation to a vendor, age independently from
Google's symbol set, and make every consumer pay for application-specific names.

Web accessibility also differs from a Compose semantics node. If an arbitrary
SVG source owns its own title and role, icon-only controls can acquire duplicate
names and third-party source changes can alter the accessibility tree.

## Decision

1. `Icon` owns one passive `span` root. A string `source` is a Material Symbols
   ligature; a React component `source` is called with a minimal SVG adapter
   contract (`className`, `aria-hidden`, and `focusable`). No registry, font,
   image loader, or framework type is bundled.
2. The root owns accessibility. Decorative is the default and sets
   `aria-hidden`; `decorative={false}` requires `label` and produces one named
   `img` role. The visual source is always hidden from assistive technology.
3. The SVG adapter sizes and tints monochrome artwork through colocated CSS and
   `currentColor`. Explicit SVG paint remains source-owned, allowing a source to
   preserve `fill="none"` or other intentional vector details.
4. The glyph adapter exposes outlined, rounded, and sharp family hooks plus
   `FILL`, `wght`, `GRAD`, `opsz`, and current Expressive `ROND`. Defaults are
   registered component tokens: 24px, fill 0, weight 400, grade 0, optical size
   24, and roundness 50. Rendering never loads a font.
5. Axis inputs are continuous numbers rather than a legacy named-instance
   union. Development warnings document sourced ranges. When size is explicit
   and optical size is not, the optical axis follows size within 20–48.
6. RTL mirroring is explicit. The ligature source remains LTR, and
   `mirrored` applies `scaleX(-1)` only when the Icon itself resolves RTL. Icon
   defines no motion; interactive state animation remains with later controls.
7. Direct props use stable instance custom properties, while themes own the
   component defaults. CSS contains literal source/style/mirroring selectors and
   performs no fetching or runtime injection.
8. T06 records the complete post-build baselines and explicit ceilings:

   - public v1 JavaScript closure: 77,827 bytes / 18,281 aggregate gzip;
     ceiling 90,000 / 21,000;
   - public v1 declaration closure: 27,294 / 8,178 aggregate gzip; ceiling
     32,000 / 9,500;
   - full CSS: 103,377 / 8,242 gzip; ceiling 118,000 / 9,500;
   - token CSS: 63,254 / 5,178 gzip; ceiling 72,000 / 6,200;
   - packed package: 219,796 bytes; ceiling 252,000.

   The pre-task reference is T05 commit
   `138f81643414276d52428617894e67bdf8a2160e`. The increase includes the
   source-adapter runtime and declarations, nine registered Icon defaults, and
   one compact literal component stylesheet. The ceilings restore measured
   per-task headroom rather than leaving the next conformant component less than
   three percent declaration budget.

## Consequences

- Consumers can adapt ordinary SVG icon packages and use current Material
  Symbols without coupling v1 to Next.js, Vite, a font CDN, or a private
  consumer's icon registry.
- A source component must honor its small adapter-prop contract. Sources that do
  not forward props are incompatible because Icon cannot enforce sizing and
  source hiding across an opaque React component boundary.
- Decorative icons compose safely inside named controls; meaningful standalone
  icons have an explicit localized name. Visual fill is not treated as an
  accessible selected/toggled state.
- Material Symbols users control font delivery and subsetting. Until their font
  is available, browser ligature fallback behavior remains an application font-
  loading concern; SVG sources avoid that dependency.

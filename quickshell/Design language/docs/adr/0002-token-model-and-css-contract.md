# ADR 0002: Token model and CSS contract

Status: accepted
Date: 2026-07-19

> Path note: this ADR names the `./v1*` export paths and `src/v1/` layout that
> ADR 0027 replaced. The decision still stands; read `./v1` as the package root
> and `./v1/theme`, `./v1/tokens`, `./v1/styles.css` as `./theme`, `./tokens`,
> `./styles.css`.

## Context

v1 needs one framework-neutral foundation for authored defaults, consumer theme
overrides, generated CSS, and later component tokens. Material's current web and
Android implementations expose overlapping but not identical generated data, and
Material 3 Expressive is still evolving. The public model must therefore be
traceable, deterministic, and strict without leaking a validation dependency.

## Decision

The canonical token set is a JSON-like TypeScript structure covering color,
typography, shape, motion, elevation, state, density, and component-token
registrations. Runtime parsing validates exact domain keys, value kinds, units,
references, serializability, and required color contrast. It returns a deep
clone that is recursively frozen. Stable serialization sorts object keys.

Material Web design-system version 34.0.21 at revision
`b4de401eb665ec63474f39319a4ba8f2145974cc` is the primary source for web
palette, system color, typography, shape, elevation, and state defaults.
AndroidX Material 3 at revision
`0be207d91046b7376beeef5544d331a02d6fa87c` supplies the standard and
expressive spring schemes and the tonal elevation formula. Exact files and web
adaptations are recorded in `docs/TOKEN_PROVENANCE.md`.

Token references use canonical dot paths. CSS generation maps them
deterministically into `--m3e-ref-*`, `--m3e-sys-*`, and `--m3e-comp-*`
properties inside `@layer m3e.tokens`. Light is the root default. Explicit
`data-m3e-color-mode="light"`, `"dark"`, and `"system"` scopes support nested
and system-driven schemes without runtime framework code.

Foreground/background role pairs are checked at a minimum 4.5:1 WCAG contrast
ratio in both default schemes. Component-token registrations are typed and
kind-checked but remain empty until each component task supplies sourced values.

The build produces `dist/tokens.css` as the token-only artifact required by
the v1 specification. ADR 0001 permits only `./v1` and `./v1/styles.css` as
pre-cutover package exports, so a public token-only subpath waits for the stable
cutover decision.

T02 changes the formerly empty v1 boundary into a complete foundation. The
recorded bundle baselines are 54,752 bytes for JavaScript, 13,380 bytes for
declarations, 47,602 bytes for the full stylesheet, 47,557 bytes for the
token-only stylesheet, and 186,945 bytes for the packed package. Their budgets
allow roughly 15–28 percent headroom so later changes must remain deliberate
without forcing a decision record for minifier noise.

## Consequences

- Token consumers can validate, serialize, extend, and generate CSS without
  React, DOM, Next.js, Vite, or private application dependencies.
- One schema drives public types, validation, reference resolution, and CSS,
  reducing implicit contracts for human and agentic contributors.
- Upstream changes require an explicit provenance and baseline update rather
  than silently changing visual output.
- The initial runtime includes complete validation metadata; later size work may
  introduce separately approved entry points but must preserve this contract.

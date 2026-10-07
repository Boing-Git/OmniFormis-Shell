# ADR 0001: Parallel v1 boundary

Status: superseded by ADR 0027 (2026-07-21)
Date: 2026-07-19

> Historical record. This ADR describes the parallel-development boundary that
> governed T01–T26. Its paths (`src/v1/`, `./v1*`) no longer exist: the cutover
> in ADR 0027 deleted the 0.3 surface and flattened `src/v1/` to `src/`.

## Context

The published package has an existing legacy API used by pinned consumers. v1 is
a ground-up, general-purpose Material 3 Expressive implementation and must be
developed without changing those consumers or inheriting application-specific
contracts.

## Decision

All new runtime code lives under `src/v1/`. Before the separately approved stable
cutover, consumers access it only through approved additive `./v1`,
`./v1/styles.css`, `./v1/theme`, and `./v1/tokens` exports. The two data subpaths
were approved in T03 to keep theme and token creation callable from server
modules while `./v1` exposes React client APIs. Legacy runtime, type, export-map,
and CSS contracts are captured by executable baselines.

v1 cannot import legacy implementation files. Reusable ideas must be
reimplemented against the v1 specification and sources of truth rather than
coupled across the boundary.

## Consequences

- Legacy consumers remain unaffected until they deliberately update.
- Temporary duplication is acceptable when it preserves the boundary.
- Package and CI configuration must build and verify two independent surfaces.
- Next.js and Vite may exist as development-only consumer fixtures; neither is a
  runtime dependency or public API dependency of the React library.
- Redirecting the stable package root is a later, explicitly approved task.

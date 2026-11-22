# ADR 0028: In-repository documentation site

Status: accepted
Date: 2026-07-21
Task: T28

## Context

`1.0.0` is released and its documentation exists only as repository Markdown.
A public showcase is needed at `m3e.language-lit.com` to demonstrate the
components running, not merely described.

This creates an apparent conflict. `SPEC.md` §2.2 makes framework independence a
non-goal violation for the library core, and `check-architecture.mjs` forbids
importing `next`, `vite`, or a router anywhere under `src/`. A documentation site
is necessarily framework-coupled. Placing it in this repository appears to import
a framework into a framework-neutral project.

The alternative — a separate repository — was considered and rejected. A live
demonstration must render the actual components, so a separate repository can
only consume a published version. Every style fix would require a release before
it could be seen, and the site's component list, prose, and examples would drift
from `component-inventory.json`, `docs/components/`, and `playground/examples/`
with nothing to detect the drift. The repository already generates
`SUPPORTED_COMPONENTS.md` from the inventory precisely to prevent that class of
divergence.

## Decision

1. The site lives at `site/` in this repository and is a **consumer** of the
   package, never part of it. It has its own `package.json` and lockfile. The
   library gains no dependency, no peer, and no export from the site's existence.

2. The framework boundary is directional, not absolute. `src/` may not import a
   framework; `site/` may, because the site is an application. The architecture
   gate is extended to enforce the direction: `src/`, `tests/`, and `playground/`
   may not import from `site/`. The existing prohibition on framework imports
   under `src/` is unchanged and unweakened.

3. The site resolves the library through its published export map only — `.`,
   `./theme`, `./tokens`, and `./styles.css`. It may not deep-import `src/`, a
   private component file, or an unexported subpath. This makes the site the
   repository's largest consumer fixture: it exercises the same surface a real
   application does, including the React Server Component boundaries that
   `add-directives.mjs` emits, across every component at once rather than the
   sample that `tests/fixtures/next/` covers.

4. The site derives content from existing sources of truth and authors no
   component fact of its own. Routes and conformance status come from
   `component-inventory.json`, contract prose from `docs/components/`, and live
   demonstrations and their displayed source from `playground/examples/`.
   `check-site.mjs` fails the build when a `conformant` component has no route or
   a route has no `conformant` entry, so the site cannot advertise past the
   matrix that §4 governs.

5. The site's interface is built from the library's own public components and
   ships no third-party UI, styling, or component dependency. A design system
   that cannot build its own documentation site is not finished; the site is
   therefore a standing test of sufficiency, not only a marketing surface.

6. `package.json` `files` remains `["dist"]`, so no site path can reach the
   published tarball. The packed artifact is unaffected by this task and its
   bundle budgets are unmoved.

7. The parity gate runs inside `npm run verify` because it is structural and
   fast. The production Next build does not; it runs as its own CI job and on
   deploy, so routine library verification does not pay a framework build cost.

## Consequences

- A library change and its documentation change land in one commit and are
  reviewed together. The site cannot describe a version of the library that does
  not exist in the same tree.
- The site breaking is a real signal. Because it consumes only public exports, a
  site build failure means a consumer would have failed the same way.
- The repository now contains a framework-coupled application, so contributors
  must know which tree they are editing. The architecture gate enforces the
  boundary rather than relying on that knowledge.
- Adding a public export to serve the site is a breaking-change decision under
  the existing export-map rules, not a site implementation detail. If the site
  needs something the export map does not offer, that is evidence about the
  public API and must be raised as its own task.
- Multi-version documentation is deferred. Routes are shaped to accept a version
  segment later, but the site documents the current release only.

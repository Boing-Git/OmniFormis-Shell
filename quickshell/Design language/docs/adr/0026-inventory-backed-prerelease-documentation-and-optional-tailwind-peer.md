# ADR 0026: Inventory-backed prerelease documentation and optional Tailwind peer

Status: accepted; Tailwind-peer decision superseded by ADR 0027 (2026-07-21)
Date: 2026-07-20
Task: T25

> The inventory-backed documentation decision below still governs. The optional
> `tailwindcss` peer it introduced no longer exists: ADR 0027 removed the 0.3
> surface that required Tailwind, so the peer was dropped entirely rather than
> made optional. Read the `/v1*` paths below as the package root, `./theme`,
> `./tokens`, and `./styles.css`.

## Context

The package must present two truthful installation contracts during the v1
prerelease. Existing root and subpath exports remain the frozen legacy surface,
whose Tailwind preset still requires Tailwind. The additive `/v1` surface ships
complete precompiled CSS and normatively requires no Tailwind setup. Leaving
`tailwindcss` as a mandatory package peer would make the v1 installation claim
false even though no v1 source or stylesheet uses it.

The prerelease also needs a public support matrix that cannot drift from the
machine-readable component inventory. Hand-maintained support claims could list
planned or incomplete components and would not satisfy the repository's
conformance model.

## Decision

1. Prepare `1.0.0-next.0` without publishing, tagging, or redirecting the stable
   package root. `/v1`, `/v1/theme`, `/v1/tokens`, and `/v1/styles.css` remain
   additive prerelease entries under ADR 0001.
2. Keep `tailwindcss` in `peerDependencies` for the legacy setup but mark it
   optional with `peerDependenciesMeta`. A v1-only installation therefore does
   not install or configure Tailwind, while legacy documentation continues to
   state when the peer is needed.
3. Generate `docs/SUPPORTED_COMPONENTS.md` deterministically from
   `docs/component-inventory.json`. Only `conformant` entries are advertised.
4. `check:docs` verifies the generated matrix, a public page and required
   content categories for every conformant component, required v1 guides,
   prerelease notes matching the package version, local documentation links,
   and the optional Tailwind peer declaration.
5. The root README clearly separates v1 prerelease and legacy setup. Generic
   migration guidance may compare public package contracts, subject to ADR 0025;
   it must never reproduce a private consumer inventory or rollout plan.

## Consequences

- A consumer can install and use v1 with React and the precompiled stylesheet
  without Tailwind warnings or automatic peer installation.
- Legacy users retain the same Tailwind compatibility range and runtime API.
- Inventory changes make stale public support documentation fail verification
  until the generated matrix and required component page are updated.
- Version, support, and migration claims are reviewable repository artifacts,
  while publication and stable cutover remain later explicit decisions.

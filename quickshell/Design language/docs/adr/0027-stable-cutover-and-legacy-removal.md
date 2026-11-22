# ADR 0027: Stable cutover, 0.3 removal, and flattened namespace

Status: accepted
Date: 2026-07-21
Task: T27
Supersedes: ADR 0001; the Tailwind-peer half of ADR 0026

## Context

ADR 0001 established a parallel boundary: the ground-up rewrite lived under
`src/v1/` and reached consumers only through additive `./v1*` exports, while the
0.3 implementation stayed frozen at the package root behind executable contract
baselines. That boundary did its job — T01 through T26 completed the rewrite,
32 components reached `conformant`, and `1.0.0-next.0` passed the full
release-readiness audit.

The boundary also carried permanent costs. The repository built, typechecked,
tested, and size-budgeted two independent surfaces. Every public path, script
name, documentation sentence, and directory carried a `v1` qualifier whose only
meaning was "not the frozen one". Fourteen runtime dependencies existed solely
for 0.3 code, and `tailwindcss` remained a peer that the rewrite never used.

`V1_SPEC.md` §13 step 7 left the endgame open: retain the superseded exports
under a documented compatibility path for an agreed deprecation period, or
remove them. The owner resolved it toward removal. The only known consumer of
the 0.3 surface completed its migration before this task, and every other
consumer keeps a working option in the already-published `0.3.x` versions, which
no action here can withdraw.

## Decision

Delete the 0.3 implementation outright rather than deprecate it in place, and
make the rewrite the package's only surface.

- Remove all 0.3 source, styles, tokens, showcase, hooks, utilities, provider,
  Tailwind preset, playground, contract baselines, and consumer fixtures.
- Flatten the parallel namespace: `src/v1/` → `src/`, `tests/v1/` → `tests/`,
  `playground/v1/` → `playground/`, `docs/v1/` → `docs/`. No `v1` path segment
  survives anywhere in the repository, and the `check:v1:*` scripts lose their
  prefix.
- Replace the export map with exactly `.`, `./theme`, `./tokens`, and
  `./styles.css`. The `./v1*` paths are removed rather than aliased, so a stale
  import fails loudly at resolution instead of silently resolving.
- Declare no runtime dependencies and no Tailwind peer. React and React DOM
  remain the only peers.
- Retire the frozen-contract guard (`scripts/legacy-contract.mjs`, its three
  baselines, the render snapshot, and the 0.3 consumer fixture) and replace it
  with a closed-set export/dependency assertion in `scripts/check-release.mjs`,
  which joins the aggregate gate.
- Release as `1.0.0`.

## Consequences

- Upgrading from `0.3.x` is a deliberate migration, not a version bump: the same
  import paths now resolve to a different API. `docs/MIGRATION.md` documents the
  break, and the README states it before the install instructions.
- `./v1` imports raise `ERR_PACKAGE_PATH_NOT_EXPORTED`. This is intended; a
  silent alias would have let stale imports survive unnoticed indefinitely.
- The repository builds, tests, and budgets one surface. The aggregate gate drops
  from 13 to 12 checks while covering strictly more of what ships.
- The packed tarball fell from 433,861 to 306,055 bytes, and `npm install`
  removed 82 transitive packages. Bundle baselines were re-measured against the
  single-surface artifacts; the recorded budget change is this ADR.
- ADR 0001's parallel boundary is fully discharged. Its historical text keeps
  the original `src/v1/` paths; every other ADR's paths were updated in place,
  since those decisions describe code that still exists at a new location.
- The specification retains the seven-step sequence as an executed record, with
  step 7 marked resolved by removal.

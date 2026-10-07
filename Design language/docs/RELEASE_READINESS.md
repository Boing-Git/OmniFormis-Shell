# 1.0.0 release-readiness audit

Audit date: 2026-07-21  
Release: `@language-lit/material3-expressive@1.0.0`  
Rollback: `@language-lit/material3-expressive@0.3.0` (tag `v0.3.0`)  
Registry publication: not performed

## Recommendation

**GO for a separately owner-approved `1.0.0` release.** The cutover removed the
0.3 surface, flattened the parallel namespace, and reduced the package to a
single dependency-free surface. Every public repository gate passes. Publication,
remote release creation, and registry dist-tag changes require separate owner
approval and are outside this audit.

## Package and compatibility evidence

`npm run check:release` creates an ignored-script tarball in a temporary
directory, inspects its manifest and file list, and removes it. The gate checks:

- the exact `1.0.0` version and the closed export set `.`, `./theme`,
  `./tokens`, `./styles.css`;
- the absence of runtime dependencies, of a Tailwind peer, and of any peer
  beyond React and React DOM;
- existence of every exported file in the tarball and exclusion of source,
  tests, playground, scripts, and repository documentation;
- all 32 inventory entries against public barrels, component pages,
  conformance records, SSR tests, behavior tests, and examples; and
- the local versioned history boundary represented by tag `v0.3.0`, whose
  package manifest identifies the documented rollback version.

`1.0.0` reuses the package root for a new API, so this is a hard break rather
than an additive release. Rollback for a consumer is to restore the exact
`@language-lit/material3-expressive@0.3.x` dependency and its imports and
styles. Application-specific rollout procedures are deliberately outside this
public repository.

## Automated verification

| Gate | Command | Result |
| --- | --- | --- |
| Aggregate verification | `npm run verify` | Pass: 12 gates |
| Unit, interaction, accessibility, SSR, hydration, CSS, and theme tests | `npm run test` (inside aggregate) | Pass: 165 files, 942 tests |
| Production playground | `npm run playground:build` (inside aggregate) | Pass: built from `dist` |
| Architecture, browser, CSS, and token checks | aggregate gates | Pass: 32 inventory entries, 35 stylesheets, 1,493 properties |
| Release artifact and rollback | `npm run check:release` (inside aggregate) | Pass: 32 components; `1.0.0` and `v0.3.0` rollback verified |
| Bundle budgets | `npm run check:bundle-size` (inside aggregate) | Pass: package 306,055 / 342,900 bytes; every budget green |
| Packed consumers | `npm run check:consumer-fixtures` (inside aggregate) | Pass: Vite and Next SSR/static against the packed tarball |

## Cutover effects

- The packed tarball fell from 433,861 bytes to 306,055 bytes.
- `npm install` removed 82 packages; the package now declares no runtime
  dependencies.
- The aggregate gate went from 13 checks to 12: the frozen-contract guard and
  the isolated-typecheck gate were retired, and the release audit joined.
- Bundle baselines were re-measured for the single-surface artifacts. The
  previous `dist/styles.css` budget had less than 1% headroom remaining; the new
  baselines restore the recorded 12% allowance. ADR 0027 is the required
  decision record for that budget change.

## Remaining boundaries

- The support claim is limited to the generated component matrix.
- The 0.3 surface is gone from this version. Consumers not ready to migrate stay
  on the published `0.3.x` versions; this audit makes no claim about their
  migration.
- Automated coverage for the browser support matrix is compilation targets, CSS
  checks, semantic tests, and packed consumer builds. Broader visual regression
  automation remains a worthwhile post-release improvement.
- No registry availability, dist-tag, or remote release claim is made by this
  local audit.
- No private-consumer inventory, route, model, dependency, or rollout detail is
  part of this record.

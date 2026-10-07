# ADR 0025: Private downstream information boundary

Status: accepted
Date: 2026-07-20
Task: P01

## Context

This package and its implementation are public, while some downstream
applications are private. Public compatibility documentation had begun to mix
the package's legitimate legacy API contract with consumer-specific dependency
revisions, usage inventories, domain examples, and migration sequencing. Even
when technically useful, those details disclose private application internals
and are not required to define or verify this library.

The package scope `@language-lit/material3-expressive` is itself public product
identity and is not confidential. The boundary applies to private consumers,
not to the package name.

## Decision

1. This repository may record only public package contracts, generic consumer
   fixtures, and generic legacy-to-v1 migration guidance.
2. A private consumer's name, repository path, dependency revision, imported
   symbol inventory, routes, domain models, compatibility gaps, and migration
   status must remain in that consumer's repository or another access-controlled
   system.
3. Private consumer source must not be read or modified as part of public
   library work. A generic feature enters v1 only through Material/web rationale
   and the normal public task and conformance process.
4. The legacy contract guard remains package-owned: it verifies exported names,
   types, styles, representative renders, and generic build fixtures without
   reproducing any private application.
5. Public release readiness depends only on this repository's documented
   component matrix and package gates. Adoption or migration by a particular
   downstream application is not a public roadmap task.
6. Because the affected v1 commits had not been pushed, their history is
   rewritten before publication so sensitive text is absent from every public
   commit, not merely deleted in a later commit.

## Consequences

- The public package identity and generic compatibility promises remain intact.
- Contributors can reason about legacy safety without access to a private
  consumer.
- Consumer-specific migration audits and rollback procedures are maintained
  privately by each application's owner.
- Future repository checks and reviews treat private-consumer details as a
  publication-boundary violation.

# ADR 0004: Passive Surface and CSS component assembly

Status: accepted
Date: 2026-07-19
Task: T04

> Path note: this ADR names the `./v1*` export paths and `src/v1/` layout that
> ADR 0027 replaced. The decision still stands; read `./v1` as the package root
> and `./v1/theme`, `./v1/tokens`, `./v1/styles.css` as `./theme`, `./tokens`,
> `./styles.css`.

## Context

Material's first-party Surface API separates a passive visual container from
clickable, selectable, and toggleable overloads. On the web, placing those
behaviors behind one polymorphic API would let presentation silently replace
native element semantics and would make later controls depend on div-based
interaction emulation.

The component architecture also requires each component stylesheet to live
beside its implementation while the package contract requires one complete,
dependency-free stylesheet. A runtime CSS import would expose repository paths
inside the published artifact.

## Decision

1. v1 `Surface` is passive. It has no click, selection, toggle, disabled, focus,
   or keyboard state API. Interactive components own their native semantics and
   may consume Surface only through its public component barrel when that reuse
   becomes concrete.
2. Polymorphism is bounded to passive block and landmark elements: `div`,
   `section`, `article`, `aside`, `main`, `header`, `footer`, and `nav`. The
   generic props type narrows native attributes and the forwarded ref.
3. Container colors are finite Material roles paired with their documented
   content roles. Arbitrary colors remain possible through normal consumer CSS
   but do not weaken the typed role contract.
4. Tonal and shadow elevation are independent discrete system levels. Tonal
   mixing applies only to `surface`; surface-container roles provide the
   preferred explicit tonal hierarchy. Shadows do not establish stacking order.
5. Shape, color, and elevation choices serialize to literal `data-m3e-*`
   attributes. CSS consumes registered component defaults and system tokens.
   Start/end shape roles swap in RTL.
6. `src/styles/styles.css` is the authored manifest. The build recursively
   inlines only relative imports contained by `src`, rejects cycles and
   escapes, then compiles the assembled source with generated tokens. Published
   CSS therefore contains no component-source imports.

## Consequences

- Consumers choose HTML semantics explicitly and receive a correspondingly
  typed ref without being offered interactive elements as styling aliases.
- Later controls cannot inherit accidental div-button behavior from Surface.
- Component CSS stays colocated and discoverable while the supported import
  remains one precompiled `v1/styles.css` file.
- Compose's cumulative arbitrary tonal elevation is adapted to explicit web
  levels. Nested web surfaces choose a role or level deliberately, avoiding a
  React context subscription and preserving static theme overrides.

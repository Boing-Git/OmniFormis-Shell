# Repository instructions

## Required context

Before changing this library, read:

1. `docs/SPEC.md`
2. `docs/ACTIVE_TASK.md`
3. `docs/ARCHITECTURE.md`
4. The ADRs relevant to the change in `docs/adr/`

The specification is normative. Only the task recorded in `ACTIVE_TASK.md` may
be implemented. State a new task's scope, expected files, and acceptance checks
and obtain owner approval before changing its status to active.

## Safety boundary

- Private downstream applications are outside this repository. Never record
  their internals here or read/edit their repositories as part of library work.
- `src/` is the only implementation tree. The 0.3 surface was deleted at the
  1.0 cutover and must not be reintroduced.
- The package exports exactly `.`, `./theme`, `./tokens`, and `./styles.css`.
  Adding, renaming, or removing a public path is a breaking change that requires
  owner approval and an ADR.
- The package ships no runtime dependencies. React and React DOM are its only
  peers.

## Conventions

- Follow the dependency layers and component layout in
  `docs/ARCHITECTURE.md`.
- Add or update `docs/component-inventory.json` with every public component
  change.
- Public components use named exports and exported props types.
- Do not deep-import another component's private files.
- Keep component behavior, types, styles, tests, conformance record, and example
  in their predictable mirrored locations.
- Prefer explicit, small modules. Share behavior only after it is repeated or is
  required as a platform-wide primitive.
- Record cross-component or public-API decisions in an ADR.
- Do not hand-edit generated artifacts. Regenerate them with the documented
  script.

## Verification

Use the narrowest relevant command while iterating. Before completing a task,
run the aggregate verification command documented in `package.json` and all
task-specific acceptance checks in `docs/ACTIVE_TASK.md`.

The unit tests run in jsdom, which has no layout, so they cannot see a clipped
elevation shadow, an undersized hit area, or a state layer that never paints.
After changing component geometry, elevation, or state layers, also run the
browser audit:

```bash
npm run build && npm run playground:build
M3E_CHROMIUM_PATH=<chromium binary> npm run audit:rendering
```

It is not part of `npm run verify` because it needs a real browser. Its
allowlists record which clips and target sizes are contract rather than defect;
add to them with a reason rather than loosening a check.

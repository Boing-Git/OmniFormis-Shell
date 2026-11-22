# Material 3 Expressive React

`@language-lit/material3-expressive` is a framework-neutral React implementation
of Material 3 Expressive with precompiled styles, no runtime dependencies, and
no Tailwind requirement.

## Start here

1. [Install and render a component](GETTING_STARTED.md).
2. [Configure themes and nested scopes](THEMING.md).
3. [Configure SSR and system color mode](SSR.md).
4. Browse the generated [supported-component matrix](SUPPORTED_COMPONENTS.md).

Upgrading from `0.3.x`? Read the [migration guide](MIGRATION.md), the documented
[web deviations](WEB_DEVIATIONS.md), and the [release notes](RELEASE_NOTES.md).

## Public entry points

| Entry | Purpose | Runtime boundary |
| --- | --- | --- |
| `@language-lit/material3-expressive` | React components, providers, hooks, themes, and tokens | Client-capable React entry |
| `@language-lit/material3-expressive/theme` | Theme creation, extension, parsing, and types | React-free; safe in server modules |
| `@language-lit/material3-expressive/tokens` | Token schemas, defaults, validation, and CSS generation | React-free; safe in server modules |
| `@language-lit/material3-expressive/styles.css` | Complete tokens and component styles | Import once per application bundle |

These four paths are the entire public surface. The 0.3 subpaths, the Tailwind
preset, and the `./styles` export were removed at the 1.0 cutover.

## Support claim

The package advertises only components marked `conformant` in
`component-inventory.json`. The generated matrix links each supported component
to its public page, while its colocated conformance record contains the detailed
source and verification evidence.

Additional Material components are not implied by the package name. Items such
as chips, sliders, search, sheets, list items, app bars, and carousel remain
outside the 1.0 matrix unless a later public task adds and verifies them.

## Contributing

Repository architecture and ownership rules are in [ARCHITECTURE.md](ARCHITECTURE.md).
Run the narrow documentation gate while editing guides:

```bash
npm run check:docs
```

Regenerate the supported matrix after an approved inventory change:

```bash
npm run generate:docs
```

The aggregate completion gate remains `npm run verify`.

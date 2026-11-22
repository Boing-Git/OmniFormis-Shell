# @language-lit/material3-expressive

A framework-neutral React implementation of Material 3 Expressive. It ships
precompiled CSS, typed theme and token APIs, native web semantics, and 32
conformant public components with no runtime dependencies.

## Install

```bash
npm install @language-lit/material3-expressive
```

React 18 or React 19 is the only peer requirement.

## Use

Import components from the package root and the complete stylesheet once:

```tsx
import {
  Button,
  Material3Provider,
} from '@language-lit/material3-expressive'
import '@language-lit/material3-expressive/styles.css'

export function App() {
  return (
    <Material3Provider colorMode="system">
      <Button>Continue</Button>
    </Material3Provider>
  )
}
```

The library does not require Tailwind, a content glob, a preset, runtime style
injection, or framework-specific adapters. `Material3Provider` defaults to the
complete theme and system color mode.

## Entry points

| Entry | Purpose |
| --- | --- |
| `@language-lit/material3-expressive` | React components, provider, and hooks |
| `@language-lit/material3-expressive/theme` | Theme creation and types; React-free |
| `@language-lit/material3-expressive/tokens` | Token schemas, defaults, and CSS generation; React-free |
| `@language-lit/material3-expressive/styles.css` | Complete tokens and component styles |

## Documentation

The full documentation, with live component demos and an interactive theme
playground, is at **[m3e.language-lit.com](https://m3e.language-lit.com)**. It is
built from this repository — see [`site/`](site/README.md).

- [Documentation index](docs/README.md)
- [Getting started](docs/GETTING_STARTED.md)
- [Theming](docs/THEMING.md)
- [SSR and system color mode](docs/SSR.md)
- [Supported components](docs/SUPPORTED_COMPONENTS.md)
- [Migrating from 0.3](docs/MIGRATION.md)
- [Web deviations](docs/WEB_DEVIATIONS.md)
- [Release notes and breaking changes](docs/RELEASE_NOTES.md)

The supported-component matrix is generated from the machine-readable inventory.
Only entries marked `conformant` are part of the advertised support surface.

## Upgrading from 0.3

`1.0.0` replaces the 0.3 API entirely. The Tailwind preset, the
`components/*` subpaths, the `./styles` export, and the legacy hooks and
utilities are gone; imports move to the root entry and CSS moves to
`/styles.css`. Read the [migration guide](docs/MIGRATION.md) before upgrading.
Applications that are not ready can stay on `0.3.x`, which remains published.

## Development

```bash
npm install
npm run playground
npm run check:docs
npm run verify
```

The playground runs at `http://localhost:5173`. The aggregate verification
checks types, tests, package output, architecture, documentation, CSS, tokens,
the release contract, bundle budgets, and packed Vite/Next consumer fixtures.

## License

MIT

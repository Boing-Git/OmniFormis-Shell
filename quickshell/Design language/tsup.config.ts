import { defineConfig } from 'tsup'

// Subpath entries mirror the package `exports` map so consumers can import
// `@language-lit/material3-expressive/theme` and `/tokens` as React-free
// modules that stay safe in server code.
//
// esbuild strips module-level "use client" when bundling with code splitting,
// so the directive is re-added to the client entry barrel afterwards by
// scripts/add-directives.mjs (theme + tokens are intentionally left out of that
// list so they stay server/Node-safe).
export default defineConfig({
  entry: {
    index: 'src/index.ts',
    theme: 'src/theme/data.ts',
    tokens: 'src/tokens/index.ts',
  },
  format: ['esm'],
  dts: true,
  splitting: true,
  treeshake: true,
  sourcemap: true,
  clean: true,
  external: ['react', 'react-dom'],
})

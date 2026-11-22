import { existsSync } from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

const here = path.dirname(fileURLToPath(import.meta.url))
const repoRoot = path.resolve(here, '..')
const installedPackage = path.join(
  here,
  'node_modules/@language-lit/material3-expressive/package.json',
)
const localBuildAliases = existsSync(installedPackage)
  ? []
  : [
      {
        find: '@language-lit/material3-expressive/styles.css',
        replacement: path.join(repoRoot, 'dist/styles.css'),
      },
      {
        find: '@language-lit/material3-expressive',
        replacement: path.join(repoRoot, 'dist/index.js'),
      },
    ]

// Production/release playground: unlike vite.dev.config.ts, this deliberately
// resolves the package's built export map instead of aliasing authored source.
export default defineConfig({
  root: here,
  plugins: [react()],
  resolve: {
    alias: localBuildAliases,
  },
  build: {
    outDir: path.join(here, 'dist'),
    emptyOutDir: true,
  },
})

import { defineConfig } from 'vitest/config'

// Self-contained config so the package doesn't inherit the app's vitest setup
// (which references app-relative setup files).
export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['tests/**/*.test.ts', 'tests/**/*.test.tsx'],
    exclude: ['node_modules', 'dist'],
  },
})

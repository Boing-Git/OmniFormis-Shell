import { execFileSync } from 'node:child_process'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const checks = [
  ['Typecheck source', 'typecheck'],
  ['Run tests', 'test'],
  ['Build distributable package', 'build'],
  ['Build production playground', 'playground:build'],
  ['Validate architecture', 'check:architecture'],
  ['Validate documentation', 'check:docs'],
  ['Validate browser support', 'check:browsers'],
  ['Validate CSS boundary', 'check:styles'],
  ['Validate token contract', 'check:tokens'],
  ['Validate release contract', 'check:release'],
  ['Validate bundle-size budgets', 'check:bundle-size'],
  ['Build packed consumer fixtures', 'check:consumer-fixtures'],
  // Structural only: asserts the documentation site matches the inventory and
  // respects the export map. The site's Next build is a separate CI job so
  // routine library verification does not pay a framework build cost.
  ['Validate documentation site', 'check:site'],
]

for (const [label, script] of checks) {
  console.log(`\n=== ${label} ===`)
  execFileSync('npm', ['run', script], { cwd: root, stdio: 'inherit' })
}

console.log(`\nAggregate verification passed (${checks.length} gates).`)

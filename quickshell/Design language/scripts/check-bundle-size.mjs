import { execFileSync } from 'node:child_process'
import { mkdtempSync, readFileSync, rmSync } from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import process from 'node:process'
import { fileURLToPath } from 'node:url'
import { gzipSync } from 'node:zlib'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const budgets = JSON.parse(readFileSync(path.join(root, 'docs/bundle-budgets.json'), 'utf8'))
const temporaryRoot = mkdtempSync(path.join(os.tmpdir(), 'm3e-size-'))
const errors = []

function resolveRelativeImport(importer, specifier) {
  let resolved = path.resolve(path.dirname(importer), specifier)
  if (importer.endsWith('.d.ts') && resolved.endsWith('.js')) {
    resolved = `${resolved.slice(0, -3)}.d.ts`
  } else if (!path.extname(resolved)) {
    resolved = `${resolved}${importer.endsWith('.d.ts') ? '.d.ts' : '.js'}`
  }
  return resolved
}

function readArtifactWithImports(artifact) {
  const entry = path.join(root, artifact)
  if (!artifact.endsWith('.js') && !artifact.endsWith('.d.ts')) return [readFileSync(entry)]

  const pending = [entry]
  const files = new Map()
  const importPattern = /\b(?:from\s*|import\s*)['"]([^'"]+)['"]/g
  while (pending.length > 0) {
    const file = pending.pop()
    if (files.has(file)) continue
    const contents = readFileSync(file)
    files.set(file, contents)
    const source = contents.toString('utf8')
    for (const match of source.matchAll(importPattern)) {
      if (!match[1].startsWith('.')) continue
      const dependency = resolveRelativeImport(file, match[1])
      if (!dependency.startsWith(`${path.join(root, 'dist')}${path.sep}`)) {
        throw new Error(`Artifact import escapes dist: ${path.relative(root, file)} -> ${match[1]}`)
      }
      pending.push(dependency)
    }
  }

  return [...files.entries()]
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([, contents]) => contents)
}

function checkLimit(label, actual, maximum) {
  if (actual > maximum) errors.push(`${label}: ${actual} bytes exceeds ${maximum} bytes`)
  return `${label} ${actual}/${maximum} bytes`
}

try {
  const reports = []
  for (const [artifact, budget] of Object.entries(budgets.artifacts)) {
    if (artifact === 'packedPackage') continue
    const contents = readArtifactWithImports(artifact)
    const bytes = contents.reduce((total, value) => total + value.byteLength, 0)
    const gzipBytes = contents.reduce(
      (total, value) => total + gzipSync(value, { level: 9 }).byteLength,
      0,
    )
    const label = artifact.endsWith('.js') || artifact.endsWith('.d.ts')
      ? `${artifact} + imports`
      : artifact
    reports.push(checkLimit(label, bytes, budget.maxBytes))
    reports.push(checkLimit(`${label} gzip`, gzipBytes, budget.maxGzipBytes))
  }

  const output = execFileSync(
    'npm',
    ['pack', '--json', '--ignore-scripts', '--pack-destination', temporaryRoot],
    {
      cwd: root,
      encoding: 'utf8',
      env: { ...process.env, npm_config_cache: path.join(temporaryRoot, 'npm-cache') },
    },
  )
  const [{ size }] = JSON.parse(output)
  reports.push(checkLimit('packed package', size, budgets.artifacts.packedPackage.maxBytes))

  if (errors.length > 0) {
    console.error('Bundle-size check failed:')
    for (const error of errors) console.error(`- ${error}`)
    console.error(`Measured artifacts:\n- ${reports.join('\n- ')}`)
    console.error('A budget change requires a recorded decision; do not update baselines silently.')
    process.exitCode = 1
  } else {
    console.log(`Bundle-size budgets passed:\n- ${reports.join('\n- ')}`)
  }
} finally {
  rmSync(temporaryRoot, { recursive: true, force: true })
}

// Re-add the "use client" directive to the client entry barrel.
//
// esbuild (via tsup) strips module-level directives when bundling with code
// splitting. Next.js only needs the directive on the module a consumer imports
// (the entry barrel) — chunks pulled in by a client module are already part of
// the client graph — so we prepend it to the entry file here, post-build.
//
// theme.js and tokens.js are deliberately absent: they carry no React runtime
// and must stay importable from server modules.
import { readFileSync, writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import path from 'node:path'

const distDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', 'dist')

const clientEntries = ['index.js']

const DIRECTIVE = "'use client';\n"

for (const rel of clientEntries) {
  const file = path.join(distDir, rel)
  const contents = readFileSync(file, 'utf8')
  if (contents.startsWith("'use client'") || contents.startsWith('"use client"')) continue
  writeFileSync(file, DIRECTIVE + contents)
}

console.log(`Added "use client" to ${clientEntries.length} entry files.`)

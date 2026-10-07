import { mkdir, lstat, readlink, rm, symlink } from 'node:fs/promises'
import path from 'node:path'
import process from 'node:process'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const scope = path.join(root, 'node_modules/@language-lit')
const link = path.join(scope, 'material3-expressive')

/**
 * Links the package into its own `node_modules` under its published name.
 *
 * The site compiles the playground examples, which live above `site/` and
 * import `@language-lit/material3-expressive` the way any consumer does. Module
 * resolution for those files walks up from `playground/`, so it never reaches
 * `site/node_modules`. Node would resolve this case through its package
 * self-reference rule; Turbopack does not implement it.
 *
 * The link points at the package root, so resolution still goes through the
 * `exports` map — a deep import into `src/` fails exactly as it does for a real
 * consumer, which is the property ADR 0028 depends on. Aliasing straight to
 * `dist/` would have resolved the build error while quietly removing that
 * guarantee.
 */
async function currentTarget() {
  try {
    const stats = await lstat(link)
    if (!stats.isSymbolicLink()) return { kind: 'not-a-link' }
    return { kind: 'link', target: path.resolve(scope, await readlink(link)) }
  } catch {
    return { kind: 'missing' }
  }
}

const existing = await currentTarget()

if (existing.kind === 'link' && existing.target === root) {
  process.stdout.write('Self-link already present\n')
} else {
  if (existing.kind !== 'missing') await rm(link, { recursive: true, force: true })
  await mkdir(scope, { recursive: true })
  await symlink(path.relative(scope, root), link, 'junction')
  process.stdout.write(`Linked ${path.relative(root, link)} -> package root\n`)
}

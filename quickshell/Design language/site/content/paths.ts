import path from 'node:path'

// The site reads three repository sources at build time. They live above this
// directory because they are the repository's sources of truth, not the site's:
// duplicating them into `site/` is exactly the drift ADR 0028 exists to prevent.
export const repoRoot = path.resolve(process.cwd(), '..')
export const docsRoot = path.join(repoRoot, 'docs')
export const componentDocsRoot = path.join(docsRoot, 'components')
export const examplesRoot = path.join(repoRoot, 'playground/examples')
export const inventoryPath = path.join(docsRoot, 'component-inventory.json')

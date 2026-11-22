import { readFile, readdir, stat } from 'node:fs/promises'
import path from 'node:path'
import process from 'node:process'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const sourceRoot = path.join(root, 'src')
const inventoryPath = path.join(root, 'docs/component-inventory.json')
const requiredDirectories = [
  'src/components',
  'src/internal',
  'src/motion',
  'src/styles',
  'src/theme',
  'src/tokens',
  'src/types',
  'tests',
  'playground',
  // The documentation site is a consumer of the package, not part of it. Its
  // boundary rules are asserted by `check:site` (ADR 0028); this entry only
  // records that the tree is expected to exist.
  'site',
]

const errors = []
const forbiddenFrameworkImports = [
  'next',
  'next/',
  'vite',
  '@vitejs/',
  'react-router',
  'react-router-dom',
]
const forbiddenFoundationImports = ['react', 'react-dom']
const reactFreeThemeFiles = new Set([
  'theme/data.ts',
  'theme/theme.ts',
  'theme/theme.types.ts',
])

async function exists(target) {
  try {
    await stat(target)
    return true
  } catch {
    return false
  }
}

async function walk(directory) {
  if (!(await exists(directory))) return []
  const entries = await readdir(directory, { withFileTypes: true })
  const files = await Promise.all(entries.map(async (entry) => {
    const target = path.join(directory, entry.name)
    return entry.isDirectory() ? walk(target) : [target]
  }))
  return files.flat()
}

for (const directory of requiredDirectories) {
  if (!(await exists(path.join(root, directory)))) {
    errors.push(`Missing required directory: ${directory}`)
  }
}

const inventory = JSON.parse(await readFile(inventoryPath, 'utf8'))
const allowedStatuses = new Set(['planned', 'experimental', 'conformant', 'deprecated'])
const names = new Set()
const exports = new Set()
const componentStyleEntryPath = path.join(root, 'src/styles/styles.css')
const componentBarrelPath = path.join(root, 'src/components/index.ts')
const entryPath = path.join(root, 'src/index.ts')

if (inventory.schemaVersion !== 1 || !Array.isArray(inventory.components)) {
  errors.push('Component inventory must use schemaVersion 1 and contain a components array')
} else {
  for (const component of inventory.components) {
    const label = component.name ?? '<unnamed>'
    if (!component.name || names.has(component.name)) errors.push(`Duplicate or missing component name: ${label}`)
    names.add(component.name)
    if (!allowedStatuses.has(component.status)) errors.push(`${label} has invalid status: ${component.status}`)
    if (!/^T\d{2}$/.test(component.task ?? '')) errors.push(`${label} has invalid task: ${component.task}`)
    if (typeof component.path !== 'string' || !component.path.startsWith('src/')) {
      errors.push(`${label} has an ownership path outside src`)
    }
    if (!Array.isArray(component.dependencies) || !Array.isArray(component.publicExports)) {
      errors.push(`${label} must declare dependencies and publicExports arrays`)
      continue
    }
    for (const publicExport of component.publicExports) {
      if (exports.has(publicExport)) errors.push(`Duplicate public export in inventory: ${publicExport}`)
      exports.add(publicExport)
    }
    if (component.status !== 'planned' && !(await exists(path.join(root, component.path)))) {
      errors.push(`${label} is ${component.status} but its ownership path does not exist`)
    }

    if (component.status !== 'planned' && component.path.startsWith('src/components/')) {
      const owner = path.join(root, component.path)
      const canonicalFiles = [
        path.join(owner, `${label}.tsx`),
        path.join(owner, `${label}.types.ts`),
        path.join(owner, `${label}.css`),
        path.join(owner, 'index.ts'),
        path.join(root, 'tests/components', label, `${label}.test.tsx`),
        path.join(root, 'tests/components', label, `${label}.ssr.test.tsx`),
        path.join(root, 'tests/components', label, `${label}.a11y.test.tsx`),
        path.join(root, 'tests/components', label, `${label}.conformance.md`),
        path.join(root, 'playground/examples', `${label}.example.tsx`),
        path.join(root, 'docs/components', `${label}.md`),
      ]
      for (const canonicalFile of canonicalFiles) {
        if (!(await exists(canonicalFile))) {
          errors.push(`${label} is ${component.status} but is missing ${path.relative(root, canonicalFile)}`)
        }
      }

      const publicIndex = path.join(owner, 'index.ts')
      if (await exists(publicIndex)) {
        const source = await readFile(publicIndex, 'utf8')
        for (const publicExport of component.publicExports) {
          if (!new RegExp(`\\b${publicExport}\\b`).test(source)) {
            errors.push(`${label} public index does not name inventory export ${publicExport}`)
          }
        }
      }

      const styleEntry = await readFile(componentStyleEntryPath, 'utf8')
      if (!styleEntry.includes(`../components/${label}/${label}.css`)) {
        errors.push(`${label} stylesheet is not assembled by src/styles/styles.css`)
      }
      const componentBarrel = await readFile(componentBarrelPath, 'utf8')
      if (!componentBarrel.includes(`./${label}`)) {
        errors.push(`${label} is missing from src/components/index.ts`)
      }

      if (component.status === 'conformant') {
        const conformancePath = path.join(
          root,
          'tests/components',
          label,
          `${label}.conformance.md`,
        )
        if (await exists(conformancePath)) {
          const conformance = await readFile(conformancePath, 'utf8')
          if (!/^Status: conformant$/m.test(conformance)) {
            errors.push(`${label} inventory is conformant but its conformance record is not`)
          }
        }
      }
    }
  }

  for (const component of inventory.components) {
    for (const dependency of component.dependencies ?? []) {
      if (!names.has(dependency)) errors.push(`${component.name} has unknown component dependency: ${dependency}`)
    }
  }
}

const entrySource = await readFile(entryPath, 'utf8')
if (!entrySource.includes("'./components'")) {
  errors.push('src/index.ts does not expose the public component barrel')
}

const sourceFiles = (await walk(sourceRoot)).filter((file) => /\.(?:ts|tsx|mts|cts)$/.test(file))
const importPattern = /(?:from\s*|import\s*\()\s*['"]([^'"]+)['"]/g

for (const file of sourceFiles) {
  const source = await readFile(file, 'utf8')
  const sourceRelative = path.relative(sourceRoot, file)
  const isFoundationFile =
    sourceRelative.startsWith(`tokens${path.sep}`) ||
    sourceRelative.startsWith(`types${path.sep}`) ||
    reactFreeThemeFiles.has(sourceRelative.split(path.sep).join('/'))
  const isThemeFile = sourceRelative.startsWith(`theme${path.sep}`)
  for (const match of source.matchAll(importPattern)) {
    const specifier = match[1]
    if (forbiddenFrameworkImports.some((entry) => specifier === entry || specifier.startsWith(entry))) {
      errors.push(`${path.relative(root, file)} imports app/framework-specific module: ${specifier}`)
      continue
    }
    if (
      isFoundationFile &&
      forbiddenFoundationImports.some(
        (entry) => specifier === entry || specifier.startsWith(`${entry}/`),
      )
    ) {
      errors.push(`${path.relative(root, file)} imports React from a foundation layer: ${specifier}`)
      continue
    }
    if (specifier.startsWith('@/')) {
      errors.push(`${path.relative(root, file)} uses a non-relative @/ alias: ${specifier}`)
      continue
    }
    if (!specifier.startsWith('.')) continue

    const resolved = path.resolve(path.dirname(file), specifier)
    if (resolved !== sourceRoot && !resolved.startsWith(`${sourceRoot}${path.sep}`)) {
      errors.push(`${path.relative(root, file)} imports outside src: ${specifier}`)
      continue
    }

    if (
      isThemeFile &&
      (resolved === path.join(sourceRoot, 'components') ||
        resolved.startsWith(`${path.join(sourceRoot, 'components')}${path.sep}`))
    ) {
      errors.push(`${path.relative(root, file)} imports upward from the component layer: ${specifier}`)
      continue
    }

    const sourceComponent = path.relative(path.join(sourceRoot, 'components'), file).split(path.sep)[0]
    const targetParts = path.relative(path.join(sourceRoot, 'components'), resolved).split(path.sep)
    const targetComponent = targetParts[0]
    if (
      !sourceComponent.startsWith('..') &&
      !targetComponent.startsWith('..') &&
      sourceComponent !== targetComponent &&
      targetParts.length > 1 &&
      targetParts[1] !== 'index'
    ) {
      errors.push(`${path.relative(root, file)} deep-imports component ${targetComponent}: ${specifier}`)
    }
  }
}

const packageJson = JSON.parse(await readFile(path.join(root, 'package.json'), 'utf8'))
for (const section of ['dependencies', 'peerDependencies']) {
  if (packageJson[section]?.next || packageJson[section]?.vite) {
    errors.push(`${section} must not contain Next.js or Vite; they are development fixtures only`)
  }
}

const requiredExports = ['.', './theme', './tokens', './styles.css']
for (const publicPath of requiredExports) {
  if (!packageJson.exports?.[publicPath]) {
    errors.push(`package exports is missing required path: ${publicPath}`)
  }
}
for (const publicPath of Object.keys(packageJson.exports ?? {})) {
  if (!requiredExports.includes(publicPath)) {
    errors.push(`package exports declares an unapproved path: ${publicPath}`)
  }
}
if (Object.keys(packageJson.dependencies ?? {}).length > 0) {
  errors.push('the package must ship no runtime dependencies')
}

if (errors.length > 0) {
  console.error('architecture check failed:')
  for (const error of errors) console.error(`- ${error}`)
  process.exitCode = 1
} else {
  const conformant = inventory.components.filter((component) => component.status === 'conformant').length
  console.log(
    `architecture check passed (${inventory.components.length} inventory entries; ${conformant} conformant)`,
  )
}

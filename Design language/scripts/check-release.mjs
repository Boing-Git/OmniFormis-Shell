import { execFileSync } from 'node:child_process'
import { mkdtemp, readFile, rm, stat } from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'
import process from 'node:process'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const releaseVersion = '1.0.0'
const rollbackVersion = '0.3.0'
const rollbackTag = `v${rollbackVersion}`
const publicExportPaths = ['.', './theme', './tokens', './styles.css']
const errors = []

async function read(relativePath) {
  return readFile(path.join(root, relativePath), 'utf8')
}

async function exists(relativePath) {
  try {
    await stat(path.join(root, relativePath))
    return true
  } catch {
    return false
  }
}

function equal(left, right) {
  return JSON.stringify(left) === JSON.stringify(right)
}

function fail(message) {
  errors.push(message)
}

const packageJson = JSON.parse(await read('package.json'))
const inventory = JSON.parse(await read('docs/component-inventory.json'))
const releaseReport = await read('docs/RELEASE_READINESS.md')

if (packageJson.version !== releaseVersion) {
  fail(`release version must be ${releaseVersion}, received ${packageJson.version}`)
}

// The cutover removed the 0.3 surface outright, so the export map is a closed
// set to assert rather than a frozen baseline plus approved additions.
if (!equal(Object.keys(packageJson.exports ?? {}).sort(), [...publicExportPaths].sort())) {
  fail(`package must export exactly ${publicExportPaths.join(', ')}`)
}
if (Object.keys(packageJson.dependencies ?? {}).length > 0) {
  fail('the package must ship no runtime dependencies')
}
if (packageJson.peerDependencies?.tailwindcss || packageJson.peerDependenciesMeta?.tailwindcss) {
  fail('Tailwind must not be a peer; the package ships precompiled CSS')
}
if (!equal(Object.keys(packageJson.peerDependencies ?? {}).sort(), ['react', 'react-dom'])) {
  fail('peer dependencies must be exactly react and react-dom')
}

const conformant = inventory.components.filter((component) => component.status === 'conformant')
if (conformant.length !== 32) fail(`expected 32 conformant components, received ${conformant.length}`)

for (const component of conformant) {
  const provider = component.name === 'Material3Provider'
  const sourceIndex = `${component.path}/index.ts`
  const source = (await exists(sourceIndex)) ? await read(sourceIndex) : ''
  if (!source) fail(`${component.name} is missing its public source barrel: ${sourceIndex}`)
  for (const publicExport of component.publicExports) {
    if (!new RegExp(`\\b${publicExport}\\b`).test(source)) {
      fail(`${component.name} barrel does not declare ${publicExport}`)
    }
  }

  const doc = `docs/components/${component.name}.md`
  const conformance = provider
    ? 'tests/theme/Material3Provider.conformance.md'
    : `tests/components/${component.name}/${component.name}.conformance.md`
  const ssr = provider
    ? 'tests/theme/Material3Provider.ssr.test.tsx'
    : `tests/components/${component.name}/${component.name}.ssr.test.tsx`
  const behavior = provider
    ? 'tests/theme/Material3Provider.test.tsx'
    : `tests/components/${component.name}/${component.name}.test.tsx`
  const example = provider
    ? 'playground/src/main.tsx'
    : `playground/examples/${component.name}.example.tsx`

  for (const requiredPath of [doc, conformance, ssr, behavior, example]) {
    if (!(await exists(requiredPath))) fail(`${component.name} is missing ${requiredPath}`)
  }
  if (provider) {
    const playground = await read(example)
    if (!playground.includes('<Material3Provider')) {
      fail('playground does not exercise Material3Provider')
    }
  }
}

let taggedPackage
try {
  taggedPackage = JSON.parse(execFileSync(
    'git',
    ['show', `${rollbackTag}:package.json`],
    { cwd: root, encoding: 'utf8' },
  ))
} catch {
  fail(`rollback tag ${rollbackTag} is not available locally`)
}
if (taggedPackage?.name !== packageJson.name || taggedPackage?.version !== rollbackVersion) {
  fail(`${rollbackTag} does not identify ${packageJson.name}@${rollbackVersion}`)
}
for (const requiredText of [
  `Release: \`${packageJson.name}@${releaseVersion}\``,
  `Rollback: \`${packageJson.name}@${rollbackVersion}\` (tag \`${rollbackTag}\`)`,
  'Registry publication: not performed',
]) {
  if (!releaseReport.includes(requiredText)) fail(`release report is missing: ${requiredText}`)
}

const temporaryDirectory = await mkdtemp(path.join(os.tmpdir(), 'm3e-release-audit-'))
try {
  let packResult
  try {
    packResult = JSON.parse(execFileSync(
      'npm',
      ['pack', '--json', '--ignore-scripts', '--pack-destination', temporaryDirectory],
      { cwd: root, encoding: 'utf8' },
    ))[0]
  } catch (error) {
    fail(`npm pack failed: ${error.message}`)
  }

  if (packResult) {
    if (packResult.name !== packageJson.name || packResult.version !== packageJson.version) {
      fail('packed identity does not match package.json')
    }

    const packedPaths = new Set(packResult.files.map((file) => file.path))
    for (const requiredPath of ['LICENSE', 'README.md', 'package.json']) {
      if (!packedPaths.has(requiredPath)) fail(`packed artifact is missing ${requiredPath}`)
    }

    for (const target of Object.values(packageJson.exports).flatMap((value) => {
      if (typeof value === 'string') return [value]
      return Object.values(value)
    })) {
      const packedPath = target.replace(/^\.\//, '')
      if (!packedPaths.has(packedPath)) fail(`packed artifact is missing export target ${target}`)
    }

    for (const packedPath of packedPaths) {
      if (/^(?:src|tests|playground|docs|scripts)\//.test(packedPath)) {
        fail(`packed artifact contains repository-only path ${packedPath}`)
      }
    }

    const tarball = path.join(temporaryDirectory, packResult.filename)
    const packedManifest = JSON.parse(execFileSync(
      'tar',
      ['-xOf', tarball, 'package/package.json'],
      { encoding: 'utf8' },
    ))
    if (!equal(packedManifest.exports, packageJson.exports)) {
      fail('packed export map differs from package.json')
    }
    if (!equal(packedManifest.peerDependencies, packageJson.peerDependencies)) {
      fail('packed peer dependencies differ from package.json')
    }
  }
} finally {
  await rm(temporaryDirectory, { recursive: true, force: true })
}

if (errors.length > 0) {
  console.error('release audit failed:')
  for (const error of errors) console.error(`- ${error}`)
  process.exitCode = 1
} else {
  console.log(
    `release audit passed (${conformant.length} components; ${packageJson.version}; rollback ${rollbackTag})`,
  )
}

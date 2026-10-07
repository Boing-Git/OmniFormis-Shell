import { execFileSync } from 'node:child_process'
import {
  cpSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readdirSync,
  rmSync,
  symlinkSync,
} from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import process from 'node:process'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const temporaryRoot = mkdtempSync(path.join(os.tmpdir(), 'm3e-fixtures-'))
const rootNodeModules = path.join(root, 'node_modules')

function run(command, args, cwd, environment = {}) {
  execFileSync(command, args, {
    cwd,
    env: { ...process.env, ...environment },
    stdio: 'inherit',
  })
}

function linkDevelopmentDependencies(targetNodeModules) {
  mkdirSync(targetNodeModules, { recursive: true })
  for (const entry of readdirSync(rootNodeModules, { withFileTypes: true })) {
    if (entry.name.startsWith('.') || entry.name === '@language-lit') continue
    symlinkSync(path.join(rootNodeModules, entry.name), path.join(targetNodeModules, entry.name), 'junction')
  }
}

function installPackedLibrary(targetNodeModules, tarball) {
  const packageDirectory = path.join(targetNodeModules, '@language-lit/material3-expressive')
  mkdirSync(packageDirectory, { recursive: true })
  run('tar', ['-xzf', tarball, '--strip-components=1', '-C', packageDirectory], root)
}

function prepareFixture(name, source, tarball) {
  const target = path.join(temporaryRoot, name)
  cpSync(source, target, { recursive: true })
  const targetNodeModules = path.join(target, 'node_modules')
  linkDevelopmentDependencies(targetNodeModules)
  installPackedLibrary(targetNodeModules, tarball)
  return target
}

try {
  if (!existsSync(path.join(root, 'dist/index.js'))) {
    throw new Error('Package build is missing; run npm run build before consumer verification')
  }

  const packOutput = execFileSync(
    'npm',
    ['pack', '--json', '--ignore-scripts', '--pack-destination', temporaryRoot],
    {
      cwd: root,
      encoding: 'utf8',
      env: {
        ...process.env,
        npm_config_cache: path.join(temporaryRoot, 'npm-cache'),
      },
    },
  )
  const packResult = JSON.parse(packOutput)[0]
  const tarball = path.join(temporaryRoot, packResult.filename)
  const packedPaths = new Set(packResult.files.map((file) => file.path))
  const requiredPaths = [
    'dist/index.js',
    'dist/index.d.ts',
    'dist/theme.js',
    'dist/theme.d.ts',
    'dist/tokens.js',
    'dist/tokens.d.ts',
    'dist/styles.css',
    'dist/tokens.css',
    'package.json',
  ]
  for (const requiredPath of requiredPaths) {
    if (!packedPaths.has(requiredPath)) throw new Error(`Packed package is missing ${requiredPath}`)
  }

  const vite = prepareFixture('vite', path.join(root, 'playground'), tarball)
  run(path.join(rootNodeModules, '.bin/vite'), ['build', '--config', 'vite.config.ts'], vite)

  const next = prepareFixture('next', path.join(root, 'tests/fixtures/next'), tarball)
  run(
    path.join(rootNodeModules, '.bin/next'),
    ['build', '.', '--webpack'],
    next,
    { NEXT_TELEMETRY_DISABLED: '1' },
  )

  console.log(`Packed-package consumer fixtures passed (${packResult.size} byte tarball).`)
} finally {
  rmSync(temporaryRoot, { recursive: true, force: true })
}

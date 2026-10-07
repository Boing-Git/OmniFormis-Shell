#!/usr/bin/env node
// REPL driver for the component playground (playground/). Drives a real Chromium
// page against the PACKED package build — the same thing a real consumer
// would import — not the raw source tree.
//
// Why this exists: playground imports `@language-lit/material3-expressive`
// by package name, which only resolves once the package is built and that
// package is actually present in playground's own node_modules. There is
// no dev-mode workspace link for this repo. `setup` below reproduces exactly
// what `scripts/verify-consumer-fixtures.mjs` does for its production-build
// gate, but launches `vite` in DEV mode instead of `vite build`, into an
// isolated scratch fixture (never the repo itself — see Gotchas in SKILL.md
// for why not to symlink the repo into its own node_modules).
//
// Usage: node .claude/skills/run-playground/driver.mjs
// Then pipe commands on stdin, one per line. `help` lists them.

import { chromium } from 'playwright-core'
import { execFileSync } from 'node:child_process'
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readdirSync,
  rmSync,
  symlinkSync,
} from 'node:fs'
import net from 'node:net'
import os from 'node:os'
import path from 'node:path'
import * as readline from 'node:readline'
import { fileURLToPath } from 'node:url'
import { spawn } from 'node:child_process'

const ROOT = path.resolve(fileURLToPath(import.meta.url), '../../../..')
const SHOT_DIR = process.env.SCREENSHOT_DIR || path.join(os.tmpdir(), 'm3e-playground-shots')
mkdirSync(SHOT_DIR, { recursive: true })

let fixtureDir = null
let viteProcess = null
let vitePort = null
let browser = null
let page = null
const consoleErrors = []

function run(command, args, cwd, env = {}) {
  execFileSync(command, args, { cwd, env: { ...process.env, ...env }, stdio: 'inherit' })
}

function runCapture(command, args, cwd) {
  return execFileSync(command, args, { cwd, encoding: 'utf8' })
}

async function findFreePort() {
  return new Promise((resolve, reject) => {
    const server = net.createServer()
    server.unref()
    server.on('error', reject)
    server.listen(0, '127.0.0.1', () => {
      const { port } = server.address()
      server.close(() => resolve(port))
    })
  })
}

async function waitForHttp(url, timeoutMs) {
  const deadline = Date.now() + timeoutMs
  while (Date.now() < deadline) {
    try {
      const response = await fetch(url)
      if (response.ok || response.status === 404) return true
    } catch {
      // not up yet
    }
    await new Promise((resolve) => setTimeout(resolve, 300))
  }
  return false
}

const COMMANDS = {
  // Builds the package, packs it, and extracts it into a fresh scratch
  // fixture copied from playground — mirrors verify-consumer-fixtures.mjs.
  // Re-run this after any src change; it always starts from a clean copy.
  async setup() {
    console.log('building package (npm run build)...')
    run('npm', ['run', 'build'], ROOT)

    if (fixtureDir) rmSync(fixtureDir, { recursive: true, force: true })
    const scratchRoot = mkdtempSync(path.join(os.tmpdir(), 'm3e-playground-'))
    fixtureDir = path.join(scratchRoot, 'playground-run')
    console.log('copying playground to', fixtureDir)
    run('cp', ['-r', path.join(ROOT, 'playground'), fixtureDir])

    console.log('packing package...')
    const packOutput = runCapture(
      'npm',
      ['pack', '--json', '--ignore-scripts', '--pack-destination', scratchRoot],
      ROOT,
    )
    const tarball = path.join(scratchRoot, JSON.parse(packOutput)[0].filename)

    const targetNodeModules = path.join(fixtureDir, 'node_modules')
    mkdirSync(targetNodeModules, { recursive: true })
    const rootNodeModules = path.join(ROOT, 'node_modules')
    for (const entry of readdirSync(rootNodeModules, { withFileTypes: true })) {
      // .bin is dot-prefixed but required — it's how `vite` resolves as an
      // executable. Skipping all dot-entries here breaks the fixture.
      if (entry.name.startsWith('.') && entry.name !== '.bin') continue
      if (entry.name === '@language-lit') continue
      symlinkSync(
        path.join(rootNodeModules, entry.name),
        path.join(targetNodeModules, entry.name),
        'dir',
      )
    }

    const packageDir = path.join(targetNodeModules, '@language-lit/material3-expressive')
    mkdirSync(packageDir, { recursive: true })
    run('tar', ['-xzf', tarball, '--strip-components=1', '-C', packageDir])

    console.log('fixture ready at', fixtureDir)
  },

  // Launches `vite` dev mode INSIDE the fixture directory. vite.config.ts
  // there sets no explicit `root`, so it defaults to process.cwd() — if you
  // launch vite without actually cd-ing into the fixture first, it silently
  // serves the wrong tree and every route 404s. This spawns with `cwd` set
  // for exactly that reason.
  async serve() {
    if (!fixtureDir) return console.log('ERROR: run `setup` first')
    if (viteProcess) return console.log('already serving on port', vitePort)
    vitePort = await findFreePort()
    const viteBin = path.join(fixtureDir, 'node_modules/.bin/vite')
    viteProcess = spawn(viteBin, ['--config', 'vite.config.ts', '--port', String(vitePort), '--strictPort'], {
      cwd: fixtureDir,
      stdio: 'ignore',
    })
    viteProcess.on('exit', (code) => {
      if (code !== null && code !== 0) console.log(`vite exited with code ${code}`)
      viteProcess = null
    })
    const ready = await waitForHttp(`http://localhost:${vitePort}/`, 20_000)
    console.log(ready ? `serving on http://localhost:${vitePort}` : 'TIMEOUT waiting for vite')
  },

  // Launches a headless Chromium page pointed at the running dev server.
  async launch() {
    if (!vitePort) return console.log('ERROR: run `setup` then `serve` first')
    if (browser) return console.log('already launched')
    browser = await chromium.launch({ args: ['--no-sandbox'] })
    page = await browser.newPage({ viewport: { width: 1200, height: 1400 } })
    page.on('console', (msg) => {
      if (msg.type() === 'error') consoleErrors.push(msg.text())
    })
    page.on('pageerror', (err) => consoleErrors.push(String(err)))
    await page.goto(`http://localhost:${vitePort}/`, { waitUntil: 'networkidle' })
    console.log('launched, on', page.url())
  },

  // Screenshots one `<component>-example` section (the convention every
  // playground/examples/<Name>.example.tsx follows) instead of the whole
  // page. Pass the lowercase component name, e.g. `section checkbox`.
  async section(name) {
    if (!page) return console.log('ERROR: launch first')
    const selector = `.${name}-example`
    try {
      await page.waitForSelector(selector, { timeout: 10_000 })
    } catch {
      return console.log('NOT_FOUND:', selector, '— is playground/src/main.tsx wired to render it?')
    }
    const locator = page.locator(selector)
    await locator.scrollIntoViewIfNeeded()
    const file = path.join(SHOT_DIR, `${name}-${Date.now()}.png`)
    await locator.screenshot({ path: file })
    console.log('screenshot:', file)
  },

  async ss(name) {
    if (!page) return console.log('ERROR: launch first')
    const file = path.join(SHOT_DIR, `${name || `ss-${Date.now()}`}.png`)
    await page.screenshot({ path: file, fullPage: true })
    console.log('screenshot:', file)
  },

  async click(selector) {
    if (!page) return console.log('ERROR: launch first')
    await page.locator(selector).click()
    console.log('clicked', selector)
  },

  async hover(selector) {
    if (!page) return console.log('ERROR: launch first')
    await page.locator(selector).hover()
    console.log('hovered', selector)
  },

  async pressDown(selector) {
    if (!page) return console.log('ERROR: launch first')
    await page.locator(selector).hover()
    await page.mouse.down()
    console.log('pressed down', selector)
  },

  async release() {
    if (!page) return console.log('ERROR: launch first')
    await page.mouse.up()
    console.log('released')
  },

  async focus(selector) {
    if (!page) return console.log('ERROR: launch first')
    await page.locator(selector).focus()
    console.log('focused', selector)
  },

  async wait(selector) {
    if (!page) return console.log('ERROR: launch first')
    try {
      await page.waitForSelector(selector, { timeout: 10_000 })
      console.log('found:', selector)
    } catch {
      console.log('TIMEOUT:', selector)
    }
  },

  async eval(expr) {
    if (!page) return console.log('ERROR: launch first')
    try {
      console.log(JSON.stringify(await page.evaluate(expr)))
    } catch (error) {
      console.log('ERROR:', error.message)
    }
  },

  console() {
    console.log('CONSOLE_ERRORS:', JSON.stringify(consoleErrors))
  },

  async quit() {
    if (browser) await browser.close().catch(() => {})
    browser = null
    page = null
    if (viteProcess) viteProcess.kill()
    viteProcess = null
    if (fixtureDir && existsSync(fixtureDir)) rmSync(path.dirname(fixtureDir), { recursive: true, force: true })
    fixtureDir = null
    console.log('stopped and cleaned up')
  },

  help() {
    console.log('commands:', Object.keys(COMMANDS).join(', '))
    console.log('typical sequence: setup -> serve -> launch -> section <name> -> quit')
  },
}

const rl = readline.createInterface({ input: process.stdin, output: process.stdout, prompt: 'driver> ' })

// Commands must run strictly one at a time (`setup` must finish before
// `serve` starts, etc.), so lines can't be handled by a plain
// `rl.on('line', async ...)` listener — Node fires 'line' for every already
// buffered line before an async handler's internal awaits resolve, which
// races setup/serve/launch against each other on a piped heredoc.
//
// The natural fix, `for await (const line of rl)`, has a WORSE bug on piped
// (non-TTY) stdin: readline emits every buffered 'line' synchronously the
// moment the input arrives, but the async iterator only listens for one line
// at a time. If the consumer is still awaiting a previous command when later
// lines fire, those 'line' events have no listener and are silently dropped
// — readline then sees the stream end and closes, having delivered only the
// first line of a whole heredoc. Piping a full command script is exactly how
// this driver is meant to be used, so that silent data loss is worse than
// the race it would have replaced.
//
// The fix that is safe for both a piped heredoc and real interactive typing:
// buffer every 'line' into a queue as it arrives (that part is synchronous
// and never drops anything), and drain the queue with one async worker that
// processes commands strictly in order at its own pace.
const queue = []
let queueClosed = false
let wakeWorker = null

rl.on('line', (line) => {
  queue.push(line)
  wakeWorker?.()
})
rl.on('close', () => {
  queueClosed = true
  wakeWorker?.()
})

async function nextLine() {
  while (queue.length === 0) {
    if (queueClosed) return null
    await new Promise((resolve) => {
      wakeWorker = resolve
    })
    wakeWorker = null
  }
  return queue.shift()
}

// On piped/heredoc stdin, `rl` closes itself as soon as the input stream
// hits EOF — which happens almost immediately, well before the queued
// commands finish processing. Calling `rl.prompt()` after that throws
// ERR_USE_AFTER_CLOSE, so every prompt call must go through this guard.
function safePrompt() {
  if (!queueClosed) rl.prompt()
}

console.log('playground driver — "help" for commands, "setup" to start')
safePrompt()
try {
  for (let line = await nextLine(); line !== null; line = await nextLine()) {
    const [cmd, ...rest] = line.trim().split(/\s+/)
    if (!cmd) {
      safePrompt()
      continue
    }
    const fn = COMMANDS[cmd]
    if (!fn) {
      console.log('unknown:', cmd, '— try: help')
      safePrompt()
      continue
    }
    try {
      await fn(rest.join(' '))
    } catch (error) {
      console.log('ERROR:', error.message)
    }
    if (cmd === 'quit') break
    safePrompt()
  }
} finally {
  // `quit` is idempotent, so this is safe whether the loop ended via an
  // explicit `quit` line, stdin EOF, or an uncaught error — a fixture and a
  // background vite process left behind on exit is a real cost (disk +
  // orphaned port) for something that will run many times across T12-T29.
  await COMMANDS.quit()
  process.exit(0)
}

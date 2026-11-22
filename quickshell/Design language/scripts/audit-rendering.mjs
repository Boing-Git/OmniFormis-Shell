import { createServer } from 'node:http'
import { createReadStream, existsSync, statSync } from 'node:fs'
import path from 'node:path'
import process from 'node:process'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const playgroundDist = path.join(root, 'playground/dist')

/**
 * Browser rendering audit for the component set.
 *
 * The unit tests run in jsdom, which has no layout: it cannot know that an
 * element's shadow is being clipped by an ancestor, that a control's hit area
 * is too small, or that a hover state never paints. Those defects compile,
 * pass every existing gate, and are still wrong on screen — T29 exists because
 * one of them shipped.
 *
 * This is deliberately not part of `npm run verify`: it needs a real browser
 * and the built playground. Run it after changing component geometry, state
 * layers, or elevation:
 *
 *   npm run build && npm run playground:build && npm run audit:rendering
 *
 * Findings are reported, not thrown, except where they are unambiguous. Judge
 * each one — a clip can be a component's documented shape contract rather than
 * a defect. Cleared findings belong in the allowlists below with their reason.
 */

/**
 * Clipping that is a component's contract rather than a defect.
 *
 * `Surface` clips content to its shape, which is what Material's own
 * `Modifier.clip(shape)` does, and the progress components draw an oversized
 * path inside a clip to express their value. A child shadow cut by either is
 * expected.
 */
const legitimateClips = [
  { selector: 'm3e-surface', reason: 'Surface clips content to its shape by contract' },
  { selector: 'wave-clip', reason: 'WavyProgress clips an oversized wave path to the value' },
  { selector: 'progress', reason: 'Progress indicators clip their track/indicator geometry' },
  { selector: 'example__frame', reason: 'Playground example frame, not library CSS' },
]

/**
 * Controls whose measured hit area is smaller than 44px on an axis, with the
 * conformance reason. `SegmentedButtonGroup` matches the pinned Compose source,
 * which applies no `minimumInteractiveComponentSize` there.
 */
const smallTargetExemptions = [
  {
    selector: 'm3e-segmented-button__input',
    reason:
      'Pinned Compose source applies no minimumInteractiveComponentSize to segmented buttons; ' +
      '40px container height still clears WCAG 2.2 SC 2.5.8 (24px). Recorded in the component conformance file.',
  },
  {
    selector: 'm3e-split-button__trailing',
    reason:
      'Width is the sum of the pinned trailing-leading-space, icon size, and trailing-trailing-space ' +
      'tokens per size tier, so it is spec geometry rather than a layout choice. 48px tall and at least ' +
      '32px wide, which clears WCAG 2.2 SC 2.5.8 (24px).',
  },
]

/*
 * Hover, focus, and pressed rendering is deliberately NOT audited here.
 *
 * It was tried and removed. Measuring it reliably needs per-component knowledge
 * of where the state layer lives — it sits on a sibling for the native inputs
 * and on a descendant container for the buttons — and `:focus-visible` only
 * matches once keyboard modality is established, so a naive pass reports every
 * component as broken. Every state was verified by hand during T29 and paints
 * correctly. A gate that cries wolf is worse than no gate, so this file only
 * asserts what it can assert without false positives.
 */

function serve(directory, port) {
  const types = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'text/javascript',
    '.svg': 'image/svg+xml',
    '.woff2': 'font/woff2',
  }
  const server = createServer((request, response) => {
    const url = decodeURIComponent(request.url.split('?')[0])
    let file = path.join(directory, url)
    if (!existsSync(file) || statSync(file).isDirectory()) file = path.join(directory, 'index.html')
    response.setHeader('content-type', types[path.extname(file)] ?? 'application/octet-stream')
    createReadStream(file).pipe(response)
  })
  return new Promise((resolve) => server.listen(port, () => resolve(server)))
}

if (!existsSync(path.join(playgroundDist, 'index.html'))) {
  process.stderr.write(
    'playground/dist is missing. Run npm run build && npm run playground:build first.\n',
  )
  process.exit(1)
}

let chromium
try {
  ;({ chromium } = await import('playwright-core'))
} catch {
  process.stderr.write('playwright-core is not installed; skipping the rendering audit.\n')
  process.exit(0)
}

const executablePath = process.env.M3E_CHROMIUM_PATH
if (!executablePath) {
  process.stderr.write(
    'Set M3E_CHROMIUM_PATH to a Chromium/Chrome executable to run the rendering audit.\n',
  )
  process.exit(0)
}

const server = await serve(playgroundDist, 4599)
const browser = await chromium.launch({ executablePath })
const context = await browser.newContext({ viewport: { width: 1400, height: 1200 }, hasTouch: false })
const page = await context.newPage()
await page.goto('http://localhost:4599/', { waitUntil: 'networkidle' })
await page.waitForTimeout(900)

// The library gates hover styles behind `@media (hover: hover)`, correctly. An
// audit run without a fine pointer reports every hover state as missing, which
// is a harness failure rather than a finding.
const pointer = await page.evaluate(() => ({
  hover: matchMedia('(hover: hover)').matches,
  fine: matchMedia('(pointer: fine)').matches,
}))
if (!pointer.hover || !pointer.fine) {
  process.stderr.write(
    'This browser reports no hover-capable fine pointer; hover findings would all be false. Aborting.\n',
  )
  await browser.close()
  server.close()
  process.exit(1)
}

// Expand anything that hides content behind an interaction.
const trigger = await page.$('.m3e-fab-menu__trigger')
if (trigger) {
  await trigger.click()
  await page.waitForTimeout(1000)
}

const findings = []

// --- Elevation shadows clipped by an ancestor -------------------------------
const clipped = await page.evaluate(() => {
  const extentOf = (shadow) => {
    let extent = 0
    for (const layer of shadow.split(/,(?![^()]*\))/)) {
      const numbers = [...layer.matchAll(/(-?[\d.]+)px/g)].map((match) => parseFloat(match[1]))
      if (numbers.length >= 3) {
        extent = Math.max(extent, Math.abs(numbers[0]) + Math.abs(numbers[1]) + numbers[2] + (numbers[3] ?? 0))
      }
    }
    return extent
  }
  const results = []
  for (const element of document.querySelectorAll('*')) {
    const styles = getComputedStyle(element)
    if (!styles.boxShadow || styles.boxShadow === 'none' || styles.boxShadow.includes('inset')) continue
    const extent = extentOf(styles.boxShadow)
    if (extent < 2) continue
    const box = element.getBoundingClientRect()
    if (box.width < 6 || box.height < 6) continue
    let ancestor = element.parentElement
    while (ancestor && ancestor !== document.body) {
      const ancestorStyles = getComputedStyle(ancestor)
      if (/hidden|clip/.test(ancestorStyles.overflowX) || /hidden|clip/.test(ancestorStyles.overflowY)) {
        const ancestorBox = ancestor.getBoundingClientRect()
        const cut =
          box.left - extent < ancestorBox.left - 0.5 ||
          box.right + extent > ancestorBox.right + 0.5 ||
          box.top - extent < ancestorBox.top - 0.5 ||
          box.bottom + extent > ancestorBox.bottom + 0.5
        if (cut) {
          results.push({
            element: `${element.tagName}.${String(element.className).slice(0, 40)}`,
            clipper: String(ancestor.className).slice(0, 60),
            extent: Math.round(extent),
          })
        }
        break
      }
      ancestor = ancestor.parentElement
    }
    }
  return results
})

for (const hit of clipped) {
  const allowed = legitimateClips.find((entry) => hit.clipper.includes(entry.selector))
  if (allowed) continue
  findings.push(
    `Elevation shadow clipped: ${hit.element} (~${hit.extent}px) cut by .${hit.clipper}. ` +
      'A wrapper that clips a shadowed child without a shape of its own leaves only the shadow corners.',
  )
}

// --- Interactive target size ------------------------------------------------
const small = await page.evaluate(() => {
  const results = []
  const selector =
    'button,[role=tab],[role=menuitem],[role=menuitemcheckbox],input[type=checkbox],input[type=radio],a[href],[role=switch]'
  for (const element of document.querySelectorAll(selector)) {
    const box = element.getBoundingClientRect()
    if (box.width === 0 || box.height === 0) continue
    if (element.closest('[aria-hidden="true"]')) continue
    if (box.height < 44 || box.width < 44) {
      results.push({
        element: `${element.tagName}.${String(element.className).slice(0, 40)}`,
        size: `${Math.round(box.width)}x${Math.round(box.height)}`,
      })
    }
  }
  return results
})

for (const hit of small) {
  const exempt = smallTargetExemptions.find((entry) => hit.element.includes(entry.selector))
  if (exempt) continue
  findings.push(`Interactive target under 44px: ${hit.element} is ${hit.size}`)
}

await browser.close()
server.close()

if (findings.length > 0) {
  process.stderr.write(
    `Rendering audit findings:\n${findings.map((line) => `  - ${line}`).join('\n')}\n`,
  )
  process.exit(1)
}

process.stdout.write(
  'Rendering audit passed: no clipped elevation shadows and no undersized interactive targets ' +
    'outside the recorded exemptions\n',
)

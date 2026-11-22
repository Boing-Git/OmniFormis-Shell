import { mkdir, readFile, readdir, stat, writeFile } from 'node:fs/promises'
import path from 'node:path'
import process from 'node:process'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const scanRoots = [
  path.join(root, 'playground/examples'),
  path.join(root, 'site/ui'),
  path.join(root, 'site/app'),
]
const fontDirectory = path.join(root, 'site/public/fonts')
const manifestPath = path.join(fontDirectory, 'icons.json')

/**
 * `Icon`'s `symbolStyle` selects one of three families, and each is a separate
 * font. All three are fetched because the Icon example demonstrates all three;
 * loading only the default left `rounded` and `sharp` rendering their ligature
 * text as words.
 */
const families = [
  { style: 'outlined', family: 'Material Symbols Outlined', file: 'material-symbols-outlined.woff2' },
  { style: 'rounded', family: 'Material Symbols Rounded', file: 'material-symbols-rounded.woff2' },
  { style: 'sharp', family: 'Material Symbols Sharp', file: 'material-symbols-sharp.woff2' },
]

/**
 * Downloads a Material Symbols font subset containing exactly the icons this
 * site renders.
 *
 * `Icon.md` says the library "does not download, subset, or declare a Material
 * Symbols font" and that applications should "request only the glyphs and axes
 * they use". This is the site doing that. The full variable family is several
 * megabytes; the subset for this site is a few kilobytes, and self-hosting it
 * means the published site makes no third-party request at runtime.
 *
 * The result is committed, so ordinary builds — including Vercel's — need no
 * network access. Re-run this script when the set of icons changes; it rewrites
 * the font only when that set actually differs.
 */

async function walk(directory) {
  const entries = await readdir(directory, { withFileTypes: true })
  const files = await Promise.all(
    entries.map(async (entry) => {
      const target = path.join(directory, entry.name)
      if (entry.isDirectory()) return walk(target)
      return /\.tsx?$/.test(entry.name) ? [target] : []
    }),
  )
  return files.flat()
}

async function collectIconNames() {
  const names = new Set()
  for (const scanRoot of scanRoots) {
    for (const file of await walk(scanRoot)) {
      const source = await readFile(file, 'utf8')
      for (const match of source.matchAll(/source=["']([a-z0-9_]+)["']/g)) {
        names.add(match[1])
      }
    }
  }
  return [...names].sort()
}

async function readManifest() {
  try {
    return JSON.parse(await readFile(manifestPath, 'utf8'))
  } catch {
    return null
  }
}

const icons = await collectIconNames()
const manifest = await readManifest()

const allFontsExist = (
  await Promise.all(
    families.map((entry) =>
      stat(path.join(fontDirectory, entry.file)).then(
        () => true,
        () => false,
      ),
    ),
  )
).every(Boolean)

if (
  allFontsExist &&
  manifest &&
  manifest.families?.length === families.length &&
  manifest.icons.length === icons.length &&
  manifest.icons.every((name, index) => name === icons[index])
) {
  process.stdout.write(
    `Material Symbols subsets are current (${icons.length} icons, ${families.length} families)\n`,
  )
  process.exit(0)
}

if (process.env.M3E_SITE_OFFLINE === '1') {
  process.stderr.write(
    'Material Symbols subset is stale and M3E_SITE_OFFLINE=1 is set; refusing to fetch.\n',
  )
  process.exit(1)
}

const axes = 'opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200'

// Google serves woff2 only to clients that advertise support for it.
const modernUserAgent =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' +
  '(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36'

await mkdir(fontDirectory, { recursive: true })

let totalBytes = 0

for (const entry of families) {
  const cssUrl =
    `https://fonts.googleapis.com/css2?family=${entry.family.replace(/ /g, '+')}:${axes}` +
    `&icon_names=${icons.join(',')}&display=block`

  const cssResponse = await fetch(cssUrl, { headers: { 'user-agent': modernUserAgent } })
  if (!cssResponse.ok) {
    throw new Error(`Google Fonts CSS request failed for ${entry.family}: ${cssResponse.status}`)
  }
  const css = await cssResponse.text()

  // A subset request is served from `/l/font?kit=…` with no file extension, so
  // the format hint is what identifies it rather than the URL.
  const fontUrl = css.match(/url\((https:\/\/[^)]+)\)\s*format\(['"]woff2['"]\)/)?.[1]
  if (!fontUrl) {
    throw new Error(`No woff2 source for ${entry.family}:\n${css.slice(0, 400)}`)
  }

  const fontResponse = await fetch(fontUrl, { headers: { 'user-agent': modernUserAgent } })
  if (!fontResponse.ok) {
    throw new Error(`Font download failed for ${entry.family}: ${fontResponse.status}`)
  }
  const bytes = Buffer.from(await fontResponse.arrayBuffer())
  totalBytes += bytes.length

  await writeFile(path.join(fontDirectory, entry.file), bytes)
  process.stdout.write(
    `  ${entry.family} — ${Math.round(bytes.length / 1024)} kB\n`,
  )
}

await writeFile(
  manifestPath,
  `${JSON.stringify({ families, axes, icons }, null, 2)}\n`,
  'utf8',
)

process.stdout.write(
  `Wrote ${families.length} Material Symbols subsets — ${icons.length} icons, ` +
    `${Math.round(totalBytes / 1024)} kB total\n`,
)

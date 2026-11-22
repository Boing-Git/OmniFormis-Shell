import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { pathToFileURL } from 'node:url'
import { compileCss } from './compile-css.mjs'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const dist = path.join(root, 'dist')

function assembleAuthoredCss(entry, ancestors = []) {
  if (ancestors.includes(entry)) {
    const cycle = [...ancestors, entry].map((file) => path.relative(root, file)).join(' -> ')
    throw new Error(`Circular stylesheet import: ${cycle}`)
  }

  const source = readFileSync(entry, 'utf8')
  return source.replace(/@import\s+['"]([^'"]+)['"];?/g, (statement, specifier) => {
    if (!specifier.startsWith('.')) {
      throw new Error(`Stylesheet imports must be relative: ${statement}`)
    }
    const imported = path.resolve(path.dirname(entry), specifier)
    const sourceRoot = path.join(root, 'src')
    if (imported !== sourceRoot && !imported.startsWith(`${sourceRoot}${path.sep}`)) {
      throw new Error(`Stylesheet import escapes src: ${specifier}`)
    }
    if (path.extname(imported) !== '.css') {
      throw new Error(`Stylesheet imports must target CSS files: ${specifier}`)
    }
    return assembleAuthoredCss(imported, [...ancestors, entry]).trim()
  })
}

mkdirSync(dist, { recursive: true })

const entry = path.join(dist, 'index.js')
const { defaultTokenSet, generateTokenCss } = await import(pathToFileURL(entry).href)
const tokenSource = generateTokenCss(defaultTokenSet)
const authoredSource = assembleAuthoredCss(path.join(root, 'src/styles/styles.css'))
if (/@import\s/.test(authoredSource)) {
  throw new Error('Stylesheet contains an unsupported import syntax after assembly')
}
const tokenResult = compileCss('src/styles/tokens.css', tokenSource)
const fullResult = compileCss(
  'src/styles/styles.css',
  `${authoredSource.trim()}\n${tokenSource}`,
)

writeFileSync(path.join(dist, 'tokens.css'), tokenResult.code)
writeFileSync(path.join(dist, 'tokens.css.map'), tokenResult.map)
writeFileSync(path.join(dist, 'styles.css'), fullResult.code)
writeFileSync(path.join(dist, 'styles.css.map'), fullResult.map)

console.log('Generated token and full stylesheets.')

import { readFile } from 'node:fs/promises'
import path from 'node:path'
import process from 'node:process'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const packageJson = JSON.parse(await readFile(path.join(root, 'package.json'), 'utf8'))
const browserSupport = JSON.parse(await readFile(path.join(root, 'docs/browser-support.json'), 'utf8'))
const expected = browserSupport.browsers.map((browser) => browser.browserslist)

if (browserSupport.schemaVersion !== 1 || browserSupport.browsers.length !== 5) {
  console.error('Browser support data must use schemaVersion 1 and define all five supported browsers.')
  process.exit(1)
}

if (JSON.stringify(packageJson.browserslist) !== JSON.stringify(expected)) {
  console.error('Browser support changed without updating the T01 contract.')
  console.error(`Expected: ${JSON.stringify(expected)}`)
  console.error(`Received: ${JSON.stringify(packageJson.browserslist)}`)
  process.exitCode = 1
} else {
  console.log(`Browser support check passed (${expected.join(', ')})`)
}

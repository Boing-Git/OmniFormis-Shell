import { readFile } from 'node:fs/promises'
import path from 'node:path'
import process from 'node:process'
import { fileURLToPath, pathToFileURL } from 'node:url'
import { compileCss } from './compile-css.mjs'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const distEntry = path.join(root, 'dist/index.js')
const distTokens = path.join(root, 'dist/tokens.css')
const api = await import(pathToFileURL(distEntry).href)
const errors = []

const validation = api.validateTokenSet(api.defaultTokenSet)
if (!validation.success) {
  errors.push(...validation.issues.map((issue) => `${issue.path}: ${issue.message}`))
}
if (!api.isDeeplyFrozen(api.defaultTokenSet)) errors.push('Default token data is not deeply frozen')

const first = api.generateTokenCss(api.defaultTokenSet)
const second = api.generateTokenCss(api.defaultTokenSet)
if (first !== second) errors.push('Token CSS generation is not deterministic')

const compiled = compileCss('src/styles/tokens.css', first).code
const distributed = await readFile(distTokens)
if (!compiled.equals(distributed)) errors.push('dist/tokens.css is stale')

const definitions = new Set([...first.matchAll(/(--m3e-[a-z0-9-]+)\s*:/g)].map((match) => match[1]))
for (const match of first.matchAll(/var\(\s*(--m3e-[a-z0-9-]+)/g)) {
  if (!definitions.has(match[1])) errors.push(`Unresolved generated CSS reference: ${match[1]}`)
}
const surfaceRegistration = api.defaultTokenSet.componentTokens.find(
  (registration) => registration.component === 'surface',
)
if (!surfaceRegistration || surfaceRegistration.task !== 'T04') {
  errors.push('Default component-token registry is missing the sourced T04 Surface registration')
}
const iconRegistration = api.defaultTokenSet.componentTokens.find(
  (registration) => registration.component === 'icon',
)
if (!iconRegistration || iconRegistration.task !== 'T06') {
  errors.push('Default component-token registry is missing the sourced T06 Icon registration')
}
const buttonRegistration = api.defaultTokenSet.componentTokens.find(
  (registration) => registration.component === 'button',
)
if (!buttonRegistration || buttonRegistration.task !== 'T07') {
  errors.push('Default component-token registry is missing the sourced T07 Button registration')
}
const floatingActionButtonRegistration = api.defaultTokenSet.componentTokens.find(
  (registration) => registration.component === 'floating-action-button',
)
if (!floatingActionButtonRegistration || floatingActionButtonRegistration.task !== 'T09') {
  errors.push('Default component-token registry is missing the sourced T09 FloatingActionButton registration')
}

const checkboxRegistration = api.defaultTokenSet.componentTokens.find(
  (registration) => registration.component === 'checkbox',
)
if (!checkboxRegistration || checkboxRegistration.task !== 'T11') {
  errors.push('Default component-token registry is missing the sourced T11 Checkbox registration')
}

const radioRegistration = api.defaultTokenSet.componentTokens.find(
  (registration) => registration.component === 'radio',
)
if (!radioRegistration || radioRegistration.task !== 'T12') {
  errors.push('Default component-token registry is missing the sourced T12 Radio registration')
}

const switchRegistration = api.defaultTokenSet.componentTokens.find(
  (registration) => registration.component === 'switch',
)
if (!switchRegistration || switchRegistration.task !== 'T13') {
  errors.push('Default component-token registry is missing the sourced T13 Switch registration')
}

const textFieldRegistration = api.defaultTokenSet.componentTokens.find(
  (registration) => registration.component === 'text-field',
)
if (!textFieldRegistration || textFieldRegistration.task !== 'T14') {
  errors.push('Default component-token registry is missing the sourced T14 TextField registration')
}

const segmentedButtonGroupRegistration = api.defaultTokenSet.componentTokens.find(
  (registration) => registration.component === 'segmented-button-group',
)
if (!segmentedButtonGroupRegistration || segmentedButtonGroupRegistration.task !== 'T15') {
  errors.push(
    'Default component-token registry is missing the sourced T15 SegmentedButtonGroup registration',
  )
}

const dialogRegistration = api.defaultTokenSet.componentTokens.find(
  (registration) => registration.component === 'dialog',
)
if (!dialogRegistration || dialogRegistration.task !== 'T16') {
  errors.push('Default component-token registry is missing the sourced T16 Dialog registration')
}

const menuRegistration = api.defaultTokenSet.componentTokens.find(
  (registration) => registration.component === 'menu',
)
if (!menuRegistration || menuRegistration.task !== 'T17') {
  errors.push('Default component-token registry is missing the sourced T17 Menu registration')
}

const tooltipRegistration = api.defaultTokenSet.componentTokens.find(
  (registration) => registration.component === 'tooltip',
)
if (!tooltipRegistration || tooltipRegistration.task !== 'T18') {
  errors.push('Default component-token registry is missing the sourced T18 Tooltip registration')
}

const snackbarRegistration = api.defaultTokenSet.componentTokens.find(
  (registration) => registration.component === 'snackbar',
)
if (!snackbarRegistration || snackbarRegistration.task !== 'T18') {
  errors.push('Default component-token registry is missing the sourced T18 Snackbar registration')
}

const tabsRegistration = api.defaultTokenSet.componentTokens.find(
  (registration) => registration.component === 'tabs',
)
if (!tabsRegistration || tabsRegistration.task !== 'T19') {
  errors.push('Default component-token registry is missing the sourced T19 Tabs registration')
}

for (const component of ['navigation-bar', 'navigation-rail', 'navigation-drawer']) {
  const registration = api.defaultTokenSet.componentTokens.find(
    (candidate) => candidate.component === component,
  )
  if (!registration || registration.task !== 'T20') {
    errors.push(`Default component-token registry is missing the sourced T20 ${component} registration`)
  }
}

if (errors.length > 0) {
  console.error('token check failed:')
  for (const error of errors) console.error(`- ${error}`)
  process.exitCode = 1
} else {
  console.log(`token check passed (${definitions.size} generated custom properties).`)
}

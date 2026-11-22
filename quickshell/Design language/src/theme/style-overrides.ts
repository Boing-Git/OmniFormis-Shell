import { COLOR_ROLE_NAMES } from '../tokens'
import { generateTokenStyle, type TokenCustomProperties } from '../tokens/css'
import { tokenPathToCssVariable } from '../tokens/paths'
import { defaultTheme, themeToTokenSet } from './theme'
import type { ColorMode, Material3Theme, ResolvedColorMode } from './theme.types'

const colorProperties = new Set<string>(
  COLOR_ROLE_NAMES.map((role) => tokenPathToCssVariable(`sys.color.${role}`)),
)
const defaultTokenSet = themeToTokenSet(defaultTheme)
const defaultLightStyle = generateTokenStyle(defaultTokenSet, 'light')
const defaultDarkStyle = generateTokenStyle(defaultTokenSet, 'dark')

function aliasColorProperty(name: string, mode: ResolvedColorMode): `--m3e-${string}` {
  return name.replace(
    '--m3e-sys-color-',
    `--m3e-theme-color-${mode}-`,
  ) as `--m3e-${string}`
}

function addDifference(
  target: Record<string, string>,
  name: string,
  value: string | undefined,
  baseline: string | undefined,
): void {
  if (value !== baseline) target[name] = value ?? 'initial'
}

function addNonColorDifferences(
  target: Record<string, string>,
  themeStyle: TokenCustomProperties,
): void {
  const names = new Set([...Object.keys(defaultLightStyle), ...Object.keys(themeStyle)])
  for (const name of names) {
    if (!colorProperties.has(name)) {
      addDifference(
        target,
        name,
        themeStyle[name as keyof typeof themeStyle],
        defaultLightStyle[name as keyof typeof defaultLightStyle],
      )
    }
  }
}

function addColorDifferences(
  target: Record<string, string>,
  themeStyle: TokenCustomProperties,
  baseline: TokenCustomProperties,
  mode: ResolvedColorMode,
  alias: boolean,
): void {
  for (const name of colorProperties) {
    addDifference(
      target,
      alias ? aliasColorProperty(name, mode) : name,
      themeStyle[name as keyof typeof themeStyle],
      baseline[name as keyof typeof baseline],
    )
  }
}

export function createThemeStyleOverrides(
  theme: Material3Theme,
  colorMode: ColorMode,
): TokenCustomProperties {
  const tokenSet = themeToTokenSet(theme)
  const light = generateTokenStyle(tokenSet, 'light')
  const target: Record<string, string> = {}
  addNonColorDifferences(target, light)

  if (colorMode === 'system') {
    const dark = generateTokenStyle(tokenSet, 'dark')
    addColorDifferences(target, light, defaultLightStyle, 'light', true)
    addColorDifferences(target, dark, defaultDarkStyle, 'dark', true)
  } else {
    const style = colorMode === 'light' ? light : generateTokenStyle(tokenSet, 'dark')
    const baseline = colorMode === 'light' ? defaultLightStyle : defaultDarkStyle
    addColorDifferences(target, style, baseline, colorMode, false)
  }

  return Object.freeze(target) as TokenCustomProperties
}

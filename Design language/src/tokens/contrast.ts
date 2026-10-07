import {
  COLOR_ROLE_NAMES,
  type ColorContrastResult,
  type ColorRoleName,
  type FoundationTokenSet,
  type HexColor,
} from './schema'

const contrastPairs = [
  ['onBackground', 'background'],
  ['onError', 'error'],
  ['onErrorContainer', 'errorContainer'],
  ['onPrimary', 'primary'],
  ['onPrimaryContainer', 'primaryContainer'],
  ['onSecondary', 'secondary'],
  ['onSecondaryContainer', 'secondaryContainer'],
  ['onSurface', 'surface'],
  ['onSurfaceVariant', 'surfaceVariant'],
  ['onTertiary', 'tertiary'],
  ['onTertiaryContainer', 'tertiaryContainer'],
  ['inverseOnSurface', 'inverseSurface'],
  ['onPrimaryFixed', 'primaryFixed'],
  ['onPrimaryFixed', 'primaryFixedDim'],
  ['onPrimaryFixedVariant', 'primaryFixed'],
  ['onPrimaryFixedVariant', 'primaryFixedDim'],
  ['onSecondaryFixed', 'secondaryFixed'],
  ['onSecondaryFixed', 'secondaryFixedDim'],
  ['onSecondaryFixedVariant', 'secondaryFixed'],
  ['onSecondaryFixedVariant', 'secondaryFixedDim'],
  ['onTertiaryFixed', 'tertiaryFixed'],
  ['onTertiaryFixed', 'tertiaryFixedDim'],
  ['onTertiaryFixedVariant', 'tertiaryFixed'],
  ['onTertiaryFixedVariant', 'tertiaryFixedDim'],
] as const satisfies readonly (readonly [ColorRoleName, ColorRoleName])[]

function linearChannel(channel: number): number {
  const value = channel / 255
  return value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4
}

function luminance(color: HexColor): number {
  const red = Number.parseInt(color.slice(1, 3), 16)
  const green = Number.parseInt(color.slice(3, 5), 16)
  const blue = Number.parseInt(color.slice(5, 7), 16)
  return 0.2126 * linearChannel(red) + 0.7152 * linearChannel(green) + 0.0722 * linearChannel(blue)
}

export function colorContrastRatio(foreground: HexColor, background: HexColor): number {
  const foregroundLuminance = luminance(foreground)
  const backgroundLuminance = luminance(background)
  const lighter = Math.max(foregroundLuminance, backgroundLuminance)
  const darker = Math.min(foregroundLuminance, backgroundLuminance)
  return (lighter + 0.05) / (darker + 0.05)
}

export function resolveColorScheme(
  tokenSet: FoundationTokenSet,
  mode: 'light' | 'dark',
): Readonly<Record<ColorRoleName, HexColor>> {
  return Object.fromEntries(
    COLOR_ROLE_NAMES.map((role) => {
      const paletteName = tokenSet.system.color[mode][role].$ref.slice('ref.palette.'.length)
      return [role, tokenSet.reference.palette[paletteName as keyof typeof tokenSet.reference.palette]]
    }),
  ) as Readonly<Record<ColorRoleName, HexColor>>
}

export function validateColorContrasts(tokenSet: FoundationTokenSet): readonly ColorContrastResult[] {
  return (['light', 'dark'] as const).flatMap((mode) => {
    const scheme = resolveColorScheme(tokenSet, mode)
    return contrastPairs.map(([foreground, background]) => {
      const ratio = colorContrastRatio(scheme[foreground], scheme[background])
      return {
        mode,
        foreground,
        background,
        ratio,
        minimum: 4.5,
        passes: ratio >= 4.5,
      }
    })
  })
}

export const PALETTE_TOKEN_NAMES = [
  'black',
  'error-0',
  'error-10',
  'error-20',
  'error-30',
  'error-40',
  'error-50',
  'error-60',
  'error-70',
  'error-80',
  'error-90',
  'error-95',
  'error-98',
  'error-99',
  'error-100',
  'neutral-0',
  'neutral-4',
  'neutral-6',
  'neutral-10',
  'neutral-12',
  'neutral-17',
  'neutral-20',
  'neutral-22',
  'neutral-24',
  'neutral-30',
  'neutral-40',
  'neutral-50',
  'neutral-60',
  'neutral-70',
  'neutral-80',
  'neutral-87',
  'neutral-90',
  'neutral-92',
  'neutral-94',
  'neutral-95',
  'neutral-96',
  'neutral-98',
  'neutral-99',
  'neutral-100',
  'neutral-variant-0',
  'neutral-variant-10',
  'neutral-variant-20',
  'neutral-variant-30',
  'neutral-variant-40',
  'neutral-variant-50',
  'neutral-variant-60',
  'neutral-variant-70',
  'neutral-variant-80',
  'neutral-variant-90',
  'neutral-variant-95',
  'neutral-variant-98',
  'neutral-variant-99',
  'neutral-variant-100',
  'primary-0',
  'primary-10',
  'primary-20',
  'primary-30',
  'primary-40',
  'primary-50',
  'primary-60',
  'primary-70',
  'primary-80',
  'primary-90',
  'primary-95',
  'primary-98',
  'primary-99',
  'primary-100',
  'secondary-0',
  'secondary-10',
  'secondary-20',
  'secondary-30',
  'secondary-40',
  'secondary-50',
  'secondary-60',
  'secondary-70',
  'secondary-80',
  'secondary-90',
  'secondary-95',
  'secondary-98',
  'secondary-99',
  'secondary-100',
  'tertiary-0',
  'tertiary-10',
  'tertiary-20',
  'tertiary-30',
  'tertiary-40',
  'tertiary-50',
  'tertiary-60',
  'tertiary-70',
  'tertiary-80',
  'tertiary-90',
  'tertiary-95',
  'tertiary-98',
  'tertiary-99',
  'tertiary-100',
  'white',
] as const

export const TYPEFACE_FAMILY_TOKEN_NAMES = ['brand', 'plain'] as const
export const TYPEFACE_WEIGHT_TOKEN_NAMES = ['regular', 'medium', 'bold'] as const

export const COLOR_ROLE_NAMES = [
  'background',
  'error',
  'errorContainer',
  'inverseOnSurface',
  'inversePrimary',
  'inverseSurface',
  'onBackground',
  'onError',
  'onErrorContainer',
  'onPrimary',
  'onPrimaryContainer',
  'onPrimaryFixed',
  'onPrimaryFixedVariant',
  'onSecondary',
  'onSecondaryContainer',
  'onSecondaryFixed',
  'onSecondaryFixedVariant',
  'onSurface',
  'onSurfaceVariant',
  'onTertiary',
  'onTertiaryContainer',
  'onTertiaryFixed',
  'onTertiaryFixedVariant',
  'outline',
  'outlineVariant',
  'primary',
  'primaryContainer',
  'primaryFixed',
  'primaryFixedDim',
  'scrim',
  'secondary',
  'secondaryContainer',
  'secondaryFixed',
  'secondaryFixedDim',
  'shadow',
  'surface',
  'surfaceBright',
  'surfaceContainer',
  'surfaceContainerHigh',
  'surfaceContainerHighest',
  'surfaceContainerLow',
  'surfaceContainerLowest',
  'surfaceDim',
  'surfaceTint',
  'surfaceVariant',
  'tertiary',
  'tertiaryContainer',
  'tertiaryFixed',
  'tertiaryFixedDim',
] as const

export const TYPOGRAPHY_ROLE_NAMES = [
  'displayLarge',
  'displayMedium',
  'displaySmall',
  'headlineLarge',
  'headlineMedium',
  'headlineSmall',
  'titleLarge',
  'titleMedium',
  'titleSmall',
  'bodyLarge',
  'bodyMedium',
  'bodySmall',
  'labelLarge',
  'labelMedium',
  'labelSmall',
] as const

export const TYPOGRAPHY_EMPHASES = ['baseline', 'emphasized'] as const
export const FONT_AXIS_TAGS = [
  'CRSV',
  'FILL',
  'GRAD',
  'HEXP',
  'ROND',
  'opsz',
  'slnt',
  'wdth',
  'wght',
] as const

export const SHAPE_CORNER_VALUE_NAMES = [
  'none',
  'extraSmall',
  'small',
  'medium',
  'large',
  'largeIncreased',
  'extraLarge',
  'extraLargeIncreased',
  'extraExtraLarge',
] as const

export const SHAPE_ROLE_NAMES = [
  'cornerNone',
  'cornerExtraSmall',
  'cornerExtraSmallTop',
  'cornerSmall',
  'cornerMedium',
  'cornerLarge',
  'cornerLargeStart',
  'cornerLargeEnd',
  'cornerLargeTop',
  'cornerLargeIncreased',
  'cornerExtraLarge',
  'cornerExtraLargeTop',
  'cornerExtraLargeIncreased',
  'cornerExtraExtraLarge',
  'cornerFull',
] as const

export const MOTION_SCHEME_NAMES = ['standard', 'expressive'] as const
export const MOTION_SPEED_NAMES = ['fast', 'default', 'slow'] as const
export const MOTION_CATEGORY_NAMES = ['spatial', 'effects'] as const
export const ELEVATION_LEVEL_NAMES = [
  'level0',
  'level1',
  'level2',
  'level3',
  'level4',
  'level5',
] as const
export const STATE_OPACITY_NAMES = ['disabled', 'dragged', 'focus', 'hover', 'pressed'] as const

export type PaletteTokenName = (typeof PALETTE_TOKEN_NAMES)[number]
export type TypefaceFamilyTokenName = (typeof TYPEFACE_FAMILY_TOKEN_NAMES)[number]
export type TypefaceWeightTokenName = (typeof TYPEFACE_WEIGHT_TOKEN_NAMES)[number]
export type ColorRoleName = (typeof COLOR_ROLE_NAMES)[number]
export type TypographyRoleName = (typeof TYPOGRAPHY_ROLE_NAMES)[number]
export type TypographyEmphasis = (typeof TYPOGRAPHY_EMPHASES)[number]
export type FontAxisTag = (typeof FONT_AXIS_TAGS)[number]
export type ShapeCornerValueName = (typeof SHAPE_CORNER_VALUE_NAMES)[number]
export type ShapeRoleName = (typeof SHAPE_ROLE_NAMES)[number]
export type MotionSchemeName = (typeof MOTION_SCHEME_NAMES)[number]
export type MotionSpeedName = (typeof MOTION_SPEED_NAMES)[number]
export type MotionCategoryName = (typeof MOTION_CATEGORY_NAMES)[number]
export type ElevationLevelName = (typeof ELEVATION_LEVEL_NAMES)[number]
export type StateOpacityName = (typeof STATE_OPACITY_NAMES)[number]
type Digit = 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
export type TaskId = `T${Digit}${Digit}`

export type HexColor = `#${string}`
export type CssLength = `${number}px` | `${number}rem`

export interface TokenReference<TPath extends string = string> {
  readonly $ref: TPath
}

export type PaletteTokenPath = `ref.palette.${PaletteTokenName}`
export type TypefaceFamilyTokenPath = `ref.typeface.${TypefaceFamilyTokenName}`
export type TypefaceWeightTokenPath = `ref.typeface.weight.${TypefaceWeightTokenName}`

export interface SourceAttribution {
  readonly id: string
  readonly url: string
  readonly revision: string
  readonly accessed: `${number}-${number}-${number}`
}

export interface TokenMetadata {
  readonly schemaVersion: 1
  readonly materialVersion: string
  readonly sources: readonly SourceAttribution[]
}

export interface ReferenceTokens {
  readonly palette: Readonly<Record<PaletteTokenName, HexColor>>
  readonly typeface: {
    readonly brand: readonly string[]
    readonly plain: readonly string[]
    readonly weight: Readonly<Record<TypefaceWeightTokenName, number>>
  }
}

export type ColorScheme = Readonly<Record<ColorRoleName, TokenReference<PaletteTokenPath>>>

export interface TypographyStyle {
  readonly fontFamily: TokenReference<TypefaceFamilyTokenPath>
  readonly fontWeight: TokenReference<TypefaceWeightTokenPath>
  readonly fontSize: CssLength
  readonly lineHeight: CssLength
  readonly letterSpacing: CssLength
  readonly axes: Readonly<Record<FontAxisTag, number>>
}

export type TypographyScale = Readonly<Record<TypographyRoleName, TypographyStyle>>
export type TypographyScheme = Readonly<Record<TypographyEmphasis, TypographyScale>>

export interface ShapeScheme {
  readonly cornerValues: Readonly<Record<ShapeCornerValueName, CssLength>>
  readonly corners: Readonly<Record<ShapeRoleName, string>>
}

export interface SpringMotionSpec {
  readonly kind: 'spring'
  readonly dampingRatio: number
  readonly stiffness: number
}

export type MotionCategory = Readonly<Record<MotionCategoryName, SpringMotionSpec>>
export type MotionSpeedScale = Readonly<Record<MotionSpeedName, MotionCategory>>
export type MotionScheme = Readonly<Record<MotionSchemeName, MotionSpeedScale>>

export interface ShadowLayer {
  readonly x: CssLength
  readonly y: CssLength
  readonly blur: CssLength
  readonly spread: CssLength
  readonly opacity: number
}

export interface ElevationLevel {
  readonly dp: CssLength
  readonly tonalOverlayOpacity: number
  readonly shadow: {
    readonly key: ShadowLayer
    readonly ambient: ShadowLayer
  }
}

export type ElevationScheme = Readonly<Record<ElevationLevelName, ElevationLevel>>
export type StateScheme = Readonly<Record<StateOpacityName, number>>

export interface DensityScheme {
  readonly scale: number
  readonly minimumInteractiveTarget: CssLength
}

export interface SystemTokens {
  readonly color: {
    readonly light: ColorScheme
    readonly dark: ColorScheme
  }
  readonly typography: TypographyScheme
  readonly shape: ShapeScheme
  readonly motion: MotionScheme
  readonly elevation: ElevationScheme
  readonly state: StateScheme
  readonly density: DensityScheme
}

export type TypographyTokenPath =
  | `sys.typography.${TypographyEmphasis}.${TypographyRoleName}.${
      | 'fontFamily'
      | 'fontWeight'
      | 'fontSize'
      | 'lineHeight'
      | 'letterSpacing'}`
  | `sys.typography.${TypographyEmphasis}.${TypographyRoleName}.axes.${FontAxisTag}`
export type ShapeTokenPath =
  | `sys.shape.cornerValues.${ShapeCornerValueName}`
  | `sys.shape.corners.${ShapeRoleName}`
export type MotionTokenPath =
  `sys.motion.${MotionSchemeName}.${MotionSpeedName}.${MotionCategoryName}.${
    | 'dampingRatio'
    | 'stiffness'}`
export type ElevationTokenPath =
  | `sys.elevation.${ElevationLevelName}.${'dp' | 'tonalOverlayOpacity' | 'shadow'}`
export type StateTokenPath = `sys.state.${StateOpacityName}`
export type DensityTokenPath = `sys.density.${'scale' | 'minimumInteractiveTarget'}`
export type FoundationTokenPath =
  | PaletteTokenPath
  | TypefaceFamilyTokenPath
  | TypefaceWeightTokenPath
  | `sys.color.${ColorRoleName}`
  | TypographyTokenPath
  | ShapeTokenPath
  | MotionTokenPath
  | ElevationTokenPath
  | StateTokenPath
  | DensityTokenPath

export type TokenValueKind =
  | 'color'
  | 'dimension'
  | 'font-family'
  | 'font-weight'
  | 'number'
  | 'opacity'
  | 'shadow'
  | 'shape'
  | 'string'

export interface ComponentTokenDefinition {
  readonly kind: TokenValueKind
  readonly value: TokenReference<FoundationTokenPath> | number | string
}

export interface ComponentTokenRegistration {
  readonly component: string
  readonly task: TaskId
  readonly source: SourceAttribution
  readonly tokens: Readonly<Record<string, ComponentTokenDefinition>>
}

export interface FoundationTokenSet {
  readonly metadata: TokenMetadata
  readonly reference: ReferenceTokens
  readonly system: SystemTokens
  readonly componentTokens: readonly ComponentTokenRegistration[]
}

export interface TokenValidationIssue {
  readonly code: string
  readonly path: string
  readonly message: string
}

export type TokenValidationResult =
  | { readonly success: true; readonly issues: readonly [] }
  | { readonly success: false; readonly issues: readonly TokenValidationIssue[] }

export interface ColorContrastResult {
  readonly mode: 'light' | 'dark'
  readonly foreground: ColorRoleName
  readonly background: ColorRoleName
  readonly ratio: number
  readonly minimum: number
  readonly passes: boolean
}

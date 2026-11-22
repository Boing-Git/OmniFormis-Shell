import type {
  ColorScheme,
  ComponentTokenRegistration,
  DensityScheme,
  ElevationScheme,
  MotionScheme,
  ReferenceTokens,
  ShapeScheme,
  StateScheme,
  TokenValidationIssue,
  TypographyScheme,
} from '../tokens'

export type ColorMode = 'light' | 'dark' | 'system'
export type ResolvedColorMode = Exclude<ColorMode, 'system'>

/**
 * Serializable Material 3 theme data. References are included because color
 * schemes and typography roles resolve through the reference-token layer.
 */
export interface Material3Theme {
  readonly reference: ReferenceTokens
  readonly colorSchemes: {
    readonly light: ColorScheme
    readonly dark: ColorScheme
  }
  readonly typography: TypographyScheme
  readonly shapes: ShapeScheme
  readonly motion: MotionScheme
  readonly elevation: ElevationScheme
  readonly state: StateScheme
  readonly density: DensityScheme
  readonly componentTokens: readonly ComponentTokenRegistration[]
}

type DeepPartial<T> = T extends readonly unknown[]
  ? T
  : T extends object
    ? { readonly [TKey in keyof T]?: DeepPartial<T[TKey]> }
    : T

export type Material3ThemeOverrides = DeepPartial<Material3Theme>

export type ThemeValidationResult =
  | { readonly success: true; readonly issues: readonly [] }
  | { readonly success: false; readonly issues: readonly TokenValidationIssue[] }

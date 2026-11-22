import {
  TYPOGRAPHY_ROLE_NAMES,
  type CssLength,
  type TypefaceFamilyTokenName,
  type TypefaceWeightTokenName,
  type TypographyRoleName,
  type TypographyScale,
  type TypographyScheme,
  type TypographyStyle,
} from '../schema'

interface TypographyMetric {
  readonly family: TypefaceFamilyTokenName
  readonly fontSize: CssLength
  readonly lineHeight: CssLength
  readonly letterSpacing: CssLength
  readonly opticalSize: number
}

const metrics = {
  displayLarge: {
    family: 'brand',
    fontSize: '3.5625rem',
    lineHeight: '4rem',
    letterSpacing: '-0.015625rem',
    opticalSize: 57,
  },
  displayMedium: {
    family: 'brand',
    fontSize: '2.8125rem',
    lineHeight: '3.25rem',
    letterSpacing: '0rem',
    opticalSize: 45,
  },
  displaySmall: {
    family: 'brand',
    fontSize: '2.25rem',
    lineHeight: '2.75rem',
    letterSpacing: '0rem',
    opticalSize: 36,
  },
  headlineLarge: {
    family: 'brand',
    fontSize: '2rem',
    lineHeight: '2.5rem',
    letterSpacing: '0rem',
    opticalSize: 32,
  },
  headlineMedium: {
    family: 'brand',
    fontSize: '1.75rem',
    lineHeight: '2.25rem',
    letterSpacing: '0rem',
    opticalSize: 28,
  },
  headlineSmall: {
    family: 'brand',
    fontSize: '1.5rem',
    lineHeight: '2rem',
    letterSpacing: '0rem',
    opticalSize: 24,
  },
  titleLarge: {
    family: 'brand',
    fontSize: '1.375rem',
    lineHeight: '1.75rem',
    letterSpacing: '0rem',
    opticalSize: 22,
  },
  titleMedium: {
    family: 'plain',
    fontSize: '1rem',
    lineHeight: '1.5rem',
    letterSpacing: '0.009375rem',
    opticalSize: 16,
  },
  titleSmall: {
    family: 'plain',
    fontSize: '0.875rem',
    lineHeight: '1.25rem',
    letterSpacing: '0.00625rem',
    opticalSize: 14,
  },
  bodyLarge: {
    family: 'plain',
    fontSize: '1rem',
    lineHeight: '1.5rem',
    letterSpacing: '0.03125rem',
    opticalSize: 16,
  },
  bodyMedium: {
    family: 'plain',
    fontSize: '0.875rem',
    lineHeight: '1.25rem',
    letterSpacing: '0.015625rem',
    opticalSize: 14,
  },
  bodySmall: {
    family: 'plain',
    fontSize: '0.75rem',
    lineHeight: '1rem',
    letterSpacing: '0.025rem',
    opticalSize: 12,
  },
  labelLarge: {
    family: 'plain',
    fontSize: '0.875rem',
    lineHeight: '1.25rem',
    letterSpacing: '0.00625rem',
    opticalSize: 14,
  },
  labelMedium: {
    family: 'plain',
    fontSize: '0.75rem',
    lineHeight: '1rem',
    letterSpacing: '0.03125rem',
    opticalSize: 12,
  },
  labelSmall: {
    family: 'plain',
    fontSize: '0.6875rem',
    lineHeight: '1rem',
    letterSpacing: '0.03125rem',
    opticalSize: 11,
  },
} satisfies Record<TypographyRoleName, TypographyMetric>

const baselineWeights = {
  displayLarge: 'regular',
  displayMedium: 'regular',
  displaySmall: 'regular',
  headlineLarge: 'regular',
  headlineMedium: 'regular',
  headlineSmall: 'regular',
  titleLarge: 'regular',
  titleMedium: 'medium',
  titleSmall: 'medium',
  bodyLarge: 'regular',
  bodyMedium: 'regular',
  bodySmall: 'regular',
  labelLarge: 'medium',
  labelMedium: 'medium',
  labelSmall: 'medium',
} satisfies Record<TypographyRoleName, TypefaceWeightTokenName>

const emphasizedWeights = {
  displayLarge: 'medium',
  displayMedium: 'medium',
  displaySmall: 'medium',
  headlineLarge: 'medium',
  headlineMedium: 'medium',
  headlineSmall: 'medium',
  titleLarge: 'medium',
  titleMedium: 'bold',
  titleSmall: 'bold',
  bodyLarge: 'medium',
  bodyMedium: 'medium',
  bodySmall: 'medium',
  labelLarge: 'bold',
  labelMedium: 'bold',
  labelSmall: 'bold',
} satisfies Record<TypographyRoleName, TypefaceWeightTokenName>

const numericWeight = { regular: 400, medium: 500, bold: 700 } as const

function createScale(
  weights: Readonly<Record<TypographyRoleName, TypefaceWeightTokenName>>,
): TypographyScale {
  return Object.fromEntries(
    TYPOGRAPHY_ROLE_NAMES.map((role) => {
      const metric = metrics[role]
      const weight = weights[role]
      const style: TypographyStyle = {
        fontFamily: { $ref: `ref.typeface.${metric.family}` },
        fontWeight: { $ref: `ref.typeface.weight.${weight}` },
        fontSize: metric.fontSize,
        lineHeight: metric.lineHeight,
        letterSpacing: metric.letterSpacing,
        axes: {
          CRSV: 0,
          FILL: 0,
          GRAD: 0,
          HEXP: 0,
          ROND: 0,
          opsz: metric.opticalSize,
          slnt: 0,
          wdth: 100,
          wght: numericWeight[weight],
        },
      }
      return [role, style]
    }),
  ) as unknown as TypographyScale
}

export const defaultTypography = {
  baseline: createScale(baselineWeights),
  emphasized: createScale(emphasizedWeights),
} satisfies TypographyScheme

import { assertTokenSet } from './validation'
import { tokenPathToCssVariable } from './paths'
import {
  COLOR_ROLE_NAMES,
  ELEVATION_LEVEL_NAMES,
  FONT_AXIS_TAGS,
  MOTION_CATEGORY_NAMES,
  MOTION_SCHEME_NAMES,
  MOTION_SPEED_NAMES,
  PALETTE_TOKEN_NAMES,
  SHAPE_CORNER_VALUE_NAMES,
  SHAPE_ROLE_NAMES,
  STATE_OPACITY_NAMES,
  TYPEFACE_FAMILY_TOKEN_NAMES,
  TYPEFACE_WEIGHT_TOKEN_NAMES,
  TYPOGRAPHY_EMPHASES,
  TYPOGRAPHY_ROLE_NAMES,
  type ComponentTokenDefinition,
  type FoundationTokenPath,
  type FoundationTokenSet,
  type ShadowLayer,
  type SpringMotionSpec,
} from './schema'

interface CssDeclaration {
  readonly name: string
  readonly value: string
}

export type TokenCustomProperties = Readonly<Record<`--m3e-${string}`, string>>

const genericFontFamilies = new Set([
  'cursive',
  'emoji',
  'fangsong',
  'fantasy',
  'math',
  'monospace',
  'sans-serif',
  'serif',
  'system-ui',
  'ui-monospace',
  'ui-rounded',
  'ui-sans-serif',
  'ui-serif',
])

function fontFamilyValue(families: readonly string[]): string {
  return families
    .map((family) => (genericFontFamilies.has(family) ? family : JSON.stringify(family)))
    .join(', ')
}

function referenceValue(path: FoundationTokenPath): string {
  return `var(${tokenPathToCssVariable(path)})`
}

function valueOf(definition: ComponentTokenDefinition): string {
  if (
    definition.value !== null &&
    typeof definition.value === 'object' &&
    '$ref' in definition.value
  ) {
    return referenceValue(definition.value.$ref)
  }
  return String(definition.value)
}

function shadowLayerValue(layer: ShadowLayer): string {
  const color = `color-mix(in srgb, var(--m3e-sys-color-shadow) ${layer.opacity * 100}%, transparent)`
  return `${layer.x} ${layer.y} ${layer.blur} ${layer.spread} ${color}`
}

function referenceDeclarations(tokenSet: FoundationTokenSet): CssDeclaration[] {
  const declarations: CssDeclaration[] = PALETTE_TOKEN_NAMES.map((name) => ({
    name: tokenPathToCssVariable(`ref.palette.${name}`),
    value: tokenSet.reference.palette[name],
  }))
  for (const name of TYPEFACE_FAMILY_TOKEN_NAMES) {
    declarations.push({
      name: tokenPathToCssVariable(`ref.typeface.${name}`),
      value: fontFamilyValue(tokenSet.reference.typeface[name]),
    })
  }
  for (const name of TYPEFACE_WEIGHT_TOKEN_NAMES) {
    declarations.push({
      name: tokenPathToCssVariable(`ref.typeface.weight.${name}`),
      value: String(tokenSet.reference.typeface.weight[name]),
    })
  }
  return declarations
}

function colorDeclarations(
  tokenSet: FoundationTokenSet,
  mode: 'light' | 'dark',
): CssDeclaration[] {
  return COLOR_ROLE_NAMES.map((role) => ({
    name: tokenPathToCssVariable(`sys.color.${role}`),
    value: referenceValue(tokenSet.system.color[mode][role].$ref),
  }))
}

function scopedColorDeclarations(
  tokenSet: FoundationTokenSet,
  mode: 'light' | 'dark',
): CssDeclaration[] {
  return colorDeclarations(tokenSet, mode).map(({ name, value }) => ({
    name,
    value: `var(${name.replace('--m3e-sys-color-', `--m3e-theme-color-${mode}-`)})`,
  }))
}

function themeColorDeclarations(
  tokenSet: FoundationTokenSet,
  mode: 'light' | 'dark',
): CssDeclaration[] {
  return colorDeclarations(tokenSet, mode).map(({ name, value }) => ({
    name: name.replace('--m3e-sys-color-', `--m3e-theme-color-${mode}-`),
    value,
  }))
}

function typographyDeclarations(tokenSet: FoundationTokenSet): CssDeclaration[] {
  const declarations: CssDeclaration[] = []
  for (const emphasis of TYPOGRAPHY_EMPHASES) {
    for (const role of TYPOGRAPHY_ROLE_NAMES) {
      const style = tokenSet.system.typography[emphasis][role]
      const prefix = `sys.typography.${emphasis}.${role}` as const
      declarations.push(
        {
          name: tokenPathToCssVariable(`${prefix}.fontFamily`),
          value: referenceValue(style.fontFamily.$ref),
        },
        {
          name: tokenPathToCssVariable(`${prefix}.fontWeight`),
          value: referenceValue(style.fontWeight.$ref),
        },
        { name: tokenPathToCssVariable(`${prefix}.fontSize`), value: style.fontSize },
        { name: tokenPathToCssVariable(`${prefix}.lineHeight`), value: style.lineHeight },
        { name: tokenPathToCssVariable(`${prefix}.letterSpacing`), value: style.letterSpacing },
      )
      for (const axis of FONT_AXIS_TAGS) {
        declarations.push({
          name: tokenPathToCssVariable(`${prefix}.axes.${axis}`),
          value: String(style.axes[axis]),
        })
      }
    }
  }
  return declarations
}

function shapeDeclarations(tokenSet: FoundationTokenSet): CssDeclaration[] {
  const declarations: CssDeclaration[] = SHAPE_CORNER_VALUE_NAMES.map((name) => ({
    name: tokenPathToCssVariable(`sys.shape.cornerValues.${name}`),
    value: tokenSet.system.shape.cornerValues[name],
  }))
  for (const name of SHAPE_ROLE_NAMES) {
    declarations.push({
      name: tokenPathToCssVariable(`sys.shape.corners.${name}`),
      value: tokenSet.system.shape.corners[name],
    })
  }
  return declarations
}

const springSettlementThreshold = 0.001
const springSampleCount = 10

function springProgress(spec: SpringMotionSpec, seconds: number): number {
  const naturalFrequency = Math.sqrt(spec.stiffness)
  const dampingRatio = spec.dampingRatio

  if (Math.abs(dampingRatio - 1) < 0.000001) {
    const scaledTime = naturalFrequency * seconds
    return 1 - (1 + scaledTime) * Math.exp(-scaledTime)
  }

  if (dampingRatio < 1) {
    const dampedFrequency = naturalFrequency * Math.sqrt(1 - dampingRatio ** 2)
    const decay = Math.exp(-dampingRatio * naturalFrequency * seconds)
    const sineScale = dampingRatio / Math.sqrt(1 - dampingRatio ** 2)
    return 1 - decay * (
      Math.cos(dampedFrequency * seconds) + sineScale * Math.sin(dampedFrequency * seconds)
    )
  }

  const discriminant = Math.sqrt(dampingRatio ** 2 - 1)
  const slowRoot = -naturalFrequency * (dampingRatio - discriminant)
  const fastRoot = -naturalFrequency * (dampingRatio + discriminant)
  const slowScale = -fastRoot / (slowRoot - fastRoot)
  const fastScale = slowRoot / (slowRoot - fastRoot)
  return 1 - slowScale * Math.exp(slowRoot * seconds) - fastScale * Math.exp(fastRoot * seconds)
}

function springDurationMilliseconds(spec: SpringMotionSpec): number {
  const naturalFrequency = Math.sqrt(spec.stiffness)
  if (spec.dampingRatio < 1) {
    const amplitude = 1 / Math.sqrt(1 - spec.dampingRatio ** 2)
    return Math.max(1, Math.ceil(
      (Math.log(amplitude / springSettlementThreshold) /
        (spec.dampingRatio * naturalFrequency)) * 1000,
    ))
  }

  let lowerSeconds = 0
  let upperSeconds = 1 / naturalFrequency
  while (Math.abs(1 - springProgress(spec, upperSeconds)) > springSettlementThreshold) {
    lowerSeconds = upperSeconds
    upperSeconds *= 2
  }
  for (let iteration = 0; iteration < 60; iteration += 1) {
    const middleSeconds = (lowerSeconds + upperSeconds) / 2
    if (Math.abs(1 - springProgress(spec, middleSeconds)) > springSettlementThreshold) {
      lowerSeconds = middleSeconds
    } else {
      upperSeconds = middleSeconds
    }
  }
  return Math.max(1, Math.ceil(upperSeconds * 1000))
}

function formatSpringPoint(value: number): string {
  const rounded = Math.round(value * 10_000) / 10_000
  return Object.is(rounded, -0) ? '0' : String(rounded)
}

function springEasing(spec: SpringMotionSpec, durationMilliseconds: number): string {
  const points = Array.from({ length: springSampleCount + 1 }, (_, index) => {
    if (index === 0) return '0'
    if (index === springSampleCount) return '1'
    const progress = springProgress(
      spec,
      (durationMilliseconds * (index / springSampleCount)) / 1000,
    )
    return `${formatSpringPoint(progress)} ${index * 10}%`
  })
  return `linear(${points.join(', ')})`
}

function motionDeclarations(tokenSet: FoundationTokenSet): CssDeclaration[] {
  const declarations: CssDeclaration[] = []
  for (const scheme of MOTION_SCHEME_NAMES) {
    for (const speed of MOTION_SPEED_NAMES) {
      for (const category of MOTION_CATEGORY_NAMES) {
        const spec = tokenSet.system.motion[scheme][speed][category]
        const prefix = `sys.motion.${scheme}.${speed}.${category}` as const
        const durationMilliseconds = springDurationMilliseconds(spec)
        const cssPrefix = `--m3e-sys-motion-${scheme}-${speed}-${category}`
        declarations.push(
          {
            name: tokenPathToCssVariable(`${prefix}.dampingRatio`),
            value: String(spec.dampingRatio),
          },
          {
            name: tokenPathToCssVariable(`${prefix}.stiffness`),
            value: String(spec.stiffness),
          },
          {
            name: `${cssPrefix}-duration`,
            value: `${durationMilliseconds}ms`,
          },
          {
            name: `${cssPrefix}-easing`,
            value: springEasing(spec, durationMilliseconds),
          },
        )
      }
    }
  }
  return declarations
}

function elevationDeclarations(tokenSet: FoundationTokenSet): CssDeclaration[] {
  const declarations: CssDeclaration[] = []
  for (const name of ELEVATION_LEVEL_NAMES) {
    const level = tokenSet.system.elevation[name]
    declarations.push(
      { name: tokenPathToCssVariable(`sys.elevation.${name}.dp`), value: level.dp },
      {
        name: tokenPathToCssVariable(`sys.elevation.${name}.tonalOverlayOpacity`),
        value: String(level.tonalOverlayOpacity),
      },
      {
        name: tokenPathToCssVariable(`sys.elevation.${name}.shadow`),
        value: `${shadowLayerValue(level.shadow.key)}, ${shadowLayerValue(level.shadow.ambient)}`,
      },
    )
  }
  return declarations
}

function remainingSystemDeclarations(tokenSet: FoundationTokenSet): CssDeclaration[] {
  const declarations = [
    ...typographyDeclarations(tokenSet),
    ...shapeDeclarations(tokenSet),
    ...motionDeclarations(tokenSet),
    ...elevationDeclarations(tokenSet),
  ]
  for (const name of STATE_OPACITY_NAMES) {
    declarations.push({
      name: tokenPathToCssVariable(`sys.state.${name}`),
      value: String(tokenSet.system.state[name]),
    })
  }
  declarations.push(
    {
      name: tokenPathToCssVariable('sys.density.scale'),
      value: String(tokenSet.system.density.scale),
    },
    {
      name: tokenPathToCssVariable('sys.density.minimumInteractiveTarget'),
      value: tokenSet.system.density.minimumInteractiveTarget,
    },
  )
  return declarations
}

function componentDeclarations(tokenSet: FoundationTokenSet): CssDeclaration[] {
  return tokenSet.componentTokens.flatMap((registration) =>
    Object.entries(registration.tokens).map(([name, definition]) => ({
      name: `--m3e-comp-${registration.component}-${name}`,
      value: valueOf(definition),
    })),
  )
}

function renderRule(selector: string, declarations: readonly CssDeclaration[], indent = '  '): string {
  const body = [...declarations]
    .sort((left, right) => left.name.localeCompare(right.name))
    .map(({ name, value }) => `${indent}  ${name}: ${value};`)
    .join('\n')
  return `${indent}${selector} {\n${body}\n${indent}}`
}

export function generateTokenStyle(
  value: unknown,
  mode: 'light' | 'dark',
): TokenCustomProperties {
  assertTokenSet(value)
  const tokenSet = value as FoundationTokenSet
  const declarations = [
    ...referenceDeclarations(tokenSet),
    ...remainingSystemDeclarations(tokenSet),
    ...componentDeclarations(tokenSet),
    ...colorDeclarations(tokenSet, mode),
  ]
  return Object.freeze(
    Object.fromEntries(
      declarations
        .sort((left, right) => left.name.localeCompare(right.name))
        .map(({ name, value: declarationValue }) => [name, declarationValue]),
    ),
  ) as TokenCustomProperties
}

export function generateTokenCss(value: unknown): string {
  assertTokenSet(value)
  const tokenSet = value as FoundationTokenSet
  const baseDeclarations = [
    ...referenceDeclarations(tokenSet),
    ...remainingSystemDeclarations(tokenSet),
    ...componentDeclarations(tokenSet),
  ]
  const light = colorDeclarations(tokenSet, 'light')
  const dark = colorDeclarations(tokenSet, 'dark')
  const themeScope = [
    ...themeColorDeclarations(tokenSet, 'light'),
    ...themeColorDeclarations(tokenSet, 'dark'),
  ]
  const scopedSystemLight = scopedColorDeclarations(tokenSet, 'light')
  const scopedSystemDark = scopedColorDeclarations(tokenSet, 'dark')
  const systemDarkRule = renderRule('[data-m3e-color-mode="system"]', dark, '    ')
  const scopedSystemDarkRule = renderRule(
    '.m3e-theme[data-m3e-color-mode="system"]',
    scopedSystemDark,
    '    ',
  )

  return [
    '@layer m3e.tokens {',
    renderRule(':root, .m3e-theme', baseDeclarations),
    renderRule(':root', light),
    renderRule('.m3e-theme', themeScope),
    renderRule('[data-m3e-color-mode="light"], [data-m3e-color-mode="system"]', light),
    renderRule('[data-m3e-color-mode="dark"]', dark),
    renderRule('.m3e-theme[data-m3e-color-mode="system"]', scopedSystemLight),
    '  @media (prefers-color-scheme: dark) {',
    systemDarkRule,
    scopedSystemDarkRule,
    '  }',
    '}',
    '',
  ].join('\n')
}

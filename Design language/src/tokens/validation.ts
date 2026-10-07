import { validateColorContrasts } from './contrast'
import { cloneAndDeepFreeze } from './immutability'
import { FOUNDATION_TOKEN_KINDS } from './paths'
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
  type FoundationTokenPath,
  type FoundationTokenSet,
  type TokenValidationIssue,
  type TokenValidationResult,
  type TokenValueKind,
} from './schema'

const tokenKinds = new Set<TokenValueKind>([
  'color',
  'dimension',
  'font-family',
  'font-weight',
  'number',
  'opacity',
  'shadow',
  'shape',
  'string',
])
const hexColorPattern = /^#[0-9a-f]{6}$/
const cssLengthPattern = /^-?(?:0|[1-9]\d*)(?:\.\d+)?(?:px|rem)$/
const safeCssStringPattern = /^[^;{}]+$/
const kebabNamePattern = /^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/
const taskPattern = /^T\d{2}$/
const datePattern = /^\d{4}-\d{2}-\d{2}$/

interface ReferenceCheck {
  readonly path: string
  readonly reference: string
  readonly expectedKind: TokenValueKind
}

function isRecord(value: unknown): value is Record<string, unknown> {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) return false
  const prototype = Object.getPrototypeOf(value)
  return prototype === Object.prototype || prototype === null
}

function validateSerializable(
  value: unknown,
  path: string,
  issues: TokenValidationIssue[],
  active: WeakSet<object>,
): void {
  if (value === null || typeof value === 'string' || typeof value === 'boolean') return
  if (typeof value === 'number') {
    if (!Number.isFinite(value)) {
      issues.push({ code: 'non-serializable', path, message: 'Numbers must be finite.' })
    }
    return
  }
  if (typeof value !== 'object') {
    issues.push({
      code: 'non-serializable',
      path,
      message: `Unsupported JSON value type: ${typeof value}.`,
    })
    return
  }
  if (active.has(value)) {
    issues.push({ code: 'non-serializable', path, message: 'Circular references are not allowed.' })
    return
  }
  if (!Array.isArray(value) && !isRecord(value)) {
    issues.push({
      code: 'non-serializable',
      path,
      message: 'Only arrays and plain objects are allowed.',
    })
    return
  }
  if (Object.getOwnPropertySymbols(value).length > 0) {
    issues.push({ code: 'non-serializable', path, message: 'Symbol keys are not allowed.' })
  }
  active.add(value)
  for (const [key, descriptor] of Object.entries(Object.getOwnPropertyDescriptors(value))) {
    if (descriptor.get || descriptor.set) {
      issues.push({
        code: 'non-serializable',
        path: `${path}.${key}`,
        message: 'Getters and setters are not allowed.',
      })
      continue
    }
    validateSerializable(descriptor.value, `${path}.${key}`, issues, active)
  }
  active.delete(value)
}

function expectRecord(
  value: unknown,
  path: string,
  expectedKeys: readonly string[],
  issues: TokenValidationIssue[],
): Record<string, unknown> | undefined {
  if (!isRecord(value)) {
    issues.push({ code: 'type', path, message: 'Expected a plain object.' })
    return undefined
  }
  const expected = new Set(expectedKeys)
  for (const key of expectedKeys) {
    if (!Object.hasOwn(value, key)) {
      issues.push({ code: 'missing-key', path: `${path}.${key}`, message: 'Required token is missing.' })
    }
  }
  for (const key of Object.keys(value)) {
    if (!expected.has(key)) {
      issues.push({ code: 'unknown-key', path: `${path}.${key}`, message: 'Unknown token key.' })
    }
  }
  return value
}

function expectString(
  value: unknown,
  path: string,
  issues: TokenValidationIssue[],
  pattern?: RegExp,
): value is string {
  if (typeof value !== 'string' || value.length === 0 || (pattern && !pattern.test(value))) {
    issues.push({ code: 'value', path, message: 'Expected a valid non-empty string.' })
    return false
  }
  return true
}

function expectNumber(
  value: unknown,
  path: string,
  issues: TokenValidationIssue[],
  minimum = Number.NEGATIVE_INFINITY,
  maximum = Number.POSITIVE_INFINITY,
): value is number {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < minimum || value > maximum) {
    issues.push({
      code: 'value',
      path,
      message: `Expected a finite number from ${minimum} through ${maximum}.`,
    })
    return false
  }
  return true
}

function expectCssLength(
  value: unknown,
  path: string,
  issues: TokenValidationIssue[],
  minimum?: number,
): value is string {
  if (!expectString(value, path, issues, cssLengthPattern)) return false
  if (minimum !== undefined && Number.parseFloat(value) < minimum) {
    issues.push({ code: 'value', path, message: `Length must be at least ${minimum}.` })
    return false
  }
  return true
}

function expectReference(
  value: unknown,
  path: string,
  expectedKind: TokenValueKind,
  issues: TokenValidationIssue[],
  referenceChecks: ReferenceCheck[],
): void {
  const reference = expectRecord(value, path, ['$ref'], issues)
  if (!reference || !expectString(reference.$ref, `${path}.$ref`, issues)) return
  referenceChecks.push({ path: `${path}.$ref`, reference: reference.$ref, expectedKind })
}

function validateSource(
  value: unknown,
  path: string,
  issues: TokenValidationIssue[],
): void {
  const source = expectRecord(value, path, ['id', 'url', 'revision', 'accessed'], issues)
  if (!source) return
  expectString(source.id, `${path}.id`, issues, kebabNamePattern)
  if (expectString(source.url, `${path}.url`, issues) && !source.url.startsWith('https://')) {
    issues.push({ code: 'value', path: `${path}.url`, message: 'Source URLs must use HTTPS.' })
  }
  expectString(source.revision, `${path}.revision`, issues)
  expectString(source.accessed, `${path}.accessed`, issues, datePattern)
}

function validateMetadata(value: unknown, issues: TokenValidationIssue[]): void {
  const metadata = expectRecord(
    value,
    'tokens.metadata',
    ['schemaVersion', 'materialVersion', 'sources'],
    issues,
  )
  if (!metadata) return
  if (metadata.schemaVersion !== 1) {
    issues.push({ code: 'value', path: 'tokens.metadata.schemaVersion', message: 'Expected schema version 1.' })
  }
  expectString(metadata.materialVersion, 'tokens.metadata.materialVersion', issues)
  if (!Array.isArray(metadata.sources) || metadata.sources.length === 0) {
    issues.push({ code: 'value', path: 'tokens.metadata.sources', message: 'At least one source is required.' })
  } else {
    metadata.sources.forEach((source, index) =>
      validateSource(source, `tokens.metadata.sources.${index}`, issues),
    )
  }
}

function validateReferenceTokens(value: unknown, issues: TokenValidationIssue[]): void {
  const reference = expectRecord(value, 'tokens.reference', ['palette', 'typeface'], issues)
  if (!reference) return
  const palette = expectRecord(reference.palette, 'tokens.reference.palette', PALETTE_TOKEN_NAMES, issues)
  if (palette) {
    for (const name of PALETTE_TOKEN_NAMES) {
      if (Object.hasOwn(palette, name)) {
        expectString(palette[name], `tokens.reference.palette.${name}`, issues, hexColorPattern)
      }
    }
  }

  const typeface = expectRecord(
    reference.typeface,
    'tokens.reference.typeface',
    [...TYPEFACE_FAMILY_TOKEN_NAMES, 'weight'],
    issues,
  )
  if (!typeface) return
  for (const name of TYPEFACE_FAMILY_TOKEN_NAMES) {
    const families = typeface[name]
    if (!Array.isArray(families) || families.length === 0) {
      issues.push({
        code: 'value',
        path: `tokens.reference.typeface.${name}`,
        message: 'Font families must be a non-empty array.',
      })
      continue
    }
    families.forEach((family, index) =>
      expectString(
        family,
        `tokens.reference.typeface.${name}.${index}`,
        issues,
        safeCssStringPattern,
      ),
    )
  }
  const weight = expectRecord(
    typeface.weight,
    'tokens.reference.typeface.weight',
    TYPEFACE_WEIGHT_TOKEN_NAMES,
    issues,
  )
  if (weight) {
    for (const name of TYPEFACE_WEIGHT_TOKEN_NAMES) {
      if (expectNumber(weight[name], `tokens.reference.typeface.weight.${name}`, issues, 1, 1000)) {
        if (!Number.isInteger(weight[name])) {
          issues.push({
            code: 'value',
            path: `tokens.reference.typeface.weight.${name}`,
            message: 'Font weights must be integers.',
          })
        }
      }
    }
  }
}

function validateColorTokens(
  value: unknown,
  issues: TokenValidationIssue[],
  referenceChecks: ReferenceCheck[],
): void {
  const color = expectRecord(value, 'tokens.system.color', ['light', 'dark'], issues)
  if (!color) return
  for (const mode of ['light', 'dark'] as const) {
    const scheme = expectRecord(color[mode], `tokens.system.color.${mode}`, COLOR_ROLE_NAMES, issues)
    if (!scheme) continue
    for (const role of COLOR_ROLE_NAMES) {
      if (Object.hasOwn(scheme, role)) {
        expectReference(
          scheme[role],
          `tokens.system.color.${mode}.${role}`,
          'color',
          issues,
          referenceChecks,
        )
      }
    }
  }
}

function validateTypographyTokens(
  value: unknown,
  issues: TokenValidationIssue[],
  referenceChecks: ReferenceCheck[],
): void {
  const typography = expectRecord(
    value,
    'tokens.system.typography',
    TYPOGRAPHY_EMPHASES,
    issues,
  )
  if (!typography) return
  for (const emphasis of TYPOGRAPHY_EMPHASES) {
    const scale = expectRecord(
      typography[emphasis],
      `tokens.system.typography.${emphasis}`,
      TYPOGRAPHY_ROLE_NAMES,
      issues,
    )
    if (!scale) continue
    for (const role of TYPOGRAPHY_ROLE_NAMES) {
      const path = `tokens.system.typography.${emphasis}.${role}`
      const style = expectRecord(
        scale[role],
        path,
        ['fontFamily', 'fontWeight', 'fontSize', 'lineHeight', 'letterSpacing', 'axes'],
        issues,
      )
      if (!style) continue
      expectReference(style.fontFamily, `${path}.fontFamily`, 'font-family', issues, referenceChecks)
      expectReference(style.fontWeight, `${path}.fontWeight`, 'font-weight', issues, referenceChecks)
      expectCssLength(style.fontSize, `${path}.fontSize`, issues, 0.000001)
      expectCssLength(style.lineHeight, `${path}.lineHeight`, issues, 0.000001)
      expectCssLength(style.letterSpacing, `${path}.letterSpacing`, issues)
      const axes = expectRecord(style.axes, `${path}.axes`, FONT_AXIS_TAGS, issues)
      if (axes) {
        for (const axis of FONT_AXIS_TAGS) expectNumber(axes[axis], `${path}.axes.${axis}`, issues)
      }
    }
  }
}

function validateShapeTokens(value: unknown, issues: TokenValidationIssue[]): void {
  const shape = expectRecord(value, 'tokens.system.shape', ['cornerValues', 'corners'], issues)
  if (!shape) return
  const values = expectRecord(
    shape.cornerValues,
    'tokens.system.shape.cornerValues',
    SHAPE_CORNER_VALUE_NAMES,
    issues,
  )
  if (values) {
    for (const name of SHAPE_CORNER_VALUE_NAMES) {
      expectCssLength(values[name], `tokens.system.shape.cornerValues.${name}`, issues, 0)
    }
  }
  const corners = expectRecord(
    shape.corners,
    'tokens.system.shape.corners',
    SHAPE_ROLE_NAMES,
    issues,
  )
  if (corners) {
    for (const name of SHAPE_ROLE_NAMES) {
      const path = `tokens.system.shape.corners.${name}`
      if (!expectString(corners[name], path, issues, safeCssStringPattern)) continue
      const lengths = corners[name].split(/\s+/)
      if (lengths.length < 1 || lengths.length > 4 || lengths.some((part) => !cssLengthPattern.test(part))) {
        issues.push({ code: 'value', path, message: 'Shape must contain one through four CSS lengths.' })
      } else if (lengths.some((part) => Number.parseFloat(part) < 0)) {
        issues.push({ code: 'value', path, message: 'Shape lengths cannot be negative.' })
      }
    }
  }
}

function validateMotionTokens(value: unknown, issues: TokenValidationIssue[]): void {
  const motion = expectRecord(value, 'tokens.system.motion', MOTION_SCHEME_NAMES, issues)
  if (!motion) return
  for (const schemeName of MOTION_SCHEME_NAMES) {
    const scheme = expectRecord(
      motion[schemeName],
      `tokens.system.motion.${schemeName}`,
      MOTION_SPEED_NAMES,
      issues,
    )
    if (!scheme) continue
    for (const speed of MOTION_SPEED_NAMES) {
      const categories = expectRecord(
        scheme[speed],
        `tokens.system.motion.${schemeName}.${speed}`,
        MOTION_CATEGORY_NAMES,
        issues,
      )
      if (!categories) continue
      for (const category of MOTION_CATEGORY_NAMES) {
        const path = `tokens.system.motion.${schemeName}.${speed}.${category}`
        const spec = expectRecord(
          categories[category],
          path,
          ['kind', 'dampingRatio', 'stiffness'],
          issues,
        )
        if (!spec) continue
        if (spec.kind !== 'spring') {
          issues.push({ code: 'value', path: `${path}.kind`, message: 'Expected a spring motion spec.' })
        }
        expectNumber(spec.dampingRatio, `${path}.dampingRatio`, issues, 0.000001)
        expectNumber(spec.stiffness, `${path}.stiffness`, issues, 0.000001)
      }
    }
  }
}

function validateShadowLayer(value: unknown, path: string, issues: TokenValidationIssue[]): void {
  const layer = expectRecord(value, path, ['x', 'y', 'blur', 'spread', 'opacity'], issues)
  if (!layer) return
  expectCssLength(layer.x, `${path}.x`, issues)
  expectCssLength(layer.y, `${path}.y`, issues)
  expectCssLength(layer.blur, `${path}.blur`, issues, 0)
  expectCssLength(layer.spread, `${path}.spread`, issues)
  expectNumber(layer.opacity, `${path}.opacity`, issues, 0, 1)
}

function validateElevationTokens(value: unknown, issues: TokenValidationIssue[]): void {
  const elevation = expectRecord(value, 'tokens.system.elevation', ELEVATION_LEVEL_NAMES, issues)
  if (!elevation) return
  for (const name of ELEVATION_LEVEL_NAMES) {
    const path = `tokens.system.elevation.${name}`
    const level = expectRecord(elevation[name], path, ['dp', 'tonalOverlayOpacity', 'shadow'], issues)
    if (!level) continue
    expectCssLength(level.dp, `${path}.dp`, issues, 0)
    expectNumber(level.tonalOverlayOpacity, `${path}.tonalOverlayOpacity`, issues, 0, 1)
    const shadow = expectRecord(level.shadow, `${path}.shadow`, ['key', 'ambient'], issues)
    if (shadow) {
      validateShadowLayer(shadow.key, `${path}.shadow.key`, issues)
      validateShadowLayer(shadow.ambient, `${path}.shadow.ambient`, issues)
    }
  }
}

function validateStateTokens(value: unknown, issues: TokenValidationIssue[]): void {
  const state = expectRecord(value, 'tokens.system.state', STATE_OPACITY_NAMES, issues)
  if (!state) return
  for (const name of STATE_OPACITY_NAMES) {
    expectNumber(state[name], `tokens.system.state.${name}`, issues, 0, 1)
  }
}

function validateDensityTokens(value: unknown, issues: TokenValidationIssue[]): void {
  const density = expectRecord(
    value,
    'tokens.system.density',
    ['scale', 'minimumInteractiveTarget'],
    issues,
  )
  if (!density) return
  if (expectNumber(density.scale, 'tokens.system.density.scale', issues, -5, 0)) {
    if (!Number.isInteger(density.scale)) {
      issues.push({
        code: 'value',
        path: 'tokens.system.density.scale',
        message: 'Density scale must be an integer.',
      })
    }
  }
  expectCssLength(
    density.minimumInteractiveTarget,
    'tokens.system.density.minimumInteractiveTarget',
    issues,
    48,
  )
}

function validateSystemTokens(
  value: unknown,
  issues: TokenValidationIssue[],
  referenceChecks: ReferenceCheck[],
): void {
  const system = expectRecord(
    value,
    'tokens.system',
    ['color', 'typography', 'shape', 'motion', 'elevation', 'state', 'density'],
    issues,
  )
  if (!system) return
  validateColorTokens(system.color, issues, referenceChecks)
  validateTypographyTokens(system.typography, issues, referenceChecks)
  validateShapeTokens(system.shape, issues)
  validateMotionTokens(system.motion, issues)
  validateElevationTokens(system.elevation, issues)
  validateStateTokens(system.state, issues)
  validateDensityTokens(system.density, issues)
}

function validateDirectComponentValue(
  kind: TokenValueKind,
  value: unknown,
  path: string,
  issues: TokenValidationIssue[],
): void {
  switch (kind) {
    case 'color':
      expectString(value, path, issues, hexColorPattern)
      return
    case 'dimension':
      expectCssLength(value, path, issues)
      return
    case 'font-family':
    case 'shadow':
    case 'shape':
    case 'string':
      expectString(value, path, issues, safeCssStringPattern)
      return
    case 'font-weight':
      expectNumber(value, path, issues, 1, 1000)
      return
    case 'number':
      expectNumber(value, path, issues)
      return
    case 'opacity':
      expectNumber(value, path, issues, 0, 1)
  }
}

function validateComponentTokens(
  value: unknown,
  issues: TokenValidationIssue[],
  referenceChecks: ReferenceCheck[],
): void {
  if (!Array.isArray(value)) {
    issues.push({ code: 'type', path: 'tokens.componentTokens', message: 'Expected an array.' })
    return
  }
  const components = new Set<string>()
  value.forEach((registrationValue, registrationIndex) => {
    const path = `tokens.componentTokens.${registrationIndex}`
    const registration = expectRecord(
      registrationValue,
      path,
      ['component', 'task', 'source', 'tokens'],
      issues,
    )
    if (!registration) return
    if (expectString(registration.component, `${path}.component`, issues, kebabNamePattern)) {
      if (components.has(registration.component)) {
        issues.push({ code: 'duplicate', path: `${path}.component`, message: 'Duplicate component.' })
      }
      components.add(registration.component)
    }
    expectString(registration.task, `${path}.task`, issues, taskPattern)
    validateSource(registration.source, `${path}.source`, issues)
    if (!isRecord(registration.tokens) || Object.keys(registration.tokens).length === 0) {
      issues.push({
        code: 'value',
        path: `${path}.tokens`,
        message: 'A component registration must contain at least one token.',
      })
      return
    }
    for (const [name, definitionValue] of Object.entries(registration.tokens)) {
      const definitionPath = `${path}.tokens.${name}`
      if (!kebabNamePattern.test(name)) {
        issues.push({ code: 'value', path: definitionPath, message: 'Token names must be kebab-case.' })
      }
      const definition = expectRecord(definitionValue, definitionPath, ['kind', 'value'], issues)
      if (!definition || typeof definition.kind !== 'string' || !tokenKinds.has(definition.kind as TokenValueKind)) {
        issues.push({ code: 'value', path: `${definitionPath}.kind`, message: 'Unknown token value kind.' })
        continue
      }
      const kind = definition.kind as TokenValueKind
      if (isRecord(definition.value) && Object.hasOwn(definition.value, '$ref')) {
        expectReference(definition.value, `${definitionPath}.value`, kind, issues, referenceChecks)
      } else {
        validateDirectComponentValue(kind, definition.value, `${definitionPath}.value`, issues)
      }
    }
  })
}

export function validateTokenSet(value: unknown): TokenValidationResult {
  const issues: TokenValidationIssue[] = []
  const referenceChecks: ReferenceCheck[] = []
  validateSerializable(value, 'tokens', issues, new WeakSet())
  const root = expectRecord(
    value,
    'tokens',
    ['metadata', 'reference', 'system', 'componentTokens'],
    issues,
  )
  if (root) {
    validateMetadata(root.metadata, issues)
    validateReferenceTokens(root.reference, issues)
    validateSystemTokens(root.system, issues, referenceChecks)
    validateComponentTokens(root.componentTokens, issues, referenceChecks)
  }

  for (const check of referenceChecks) {
    const actualKind = FOUNDATION_TOKEN_KINDS.get(check.reference as FoundationTokenPath)
    if (!actualKind) {
      issues.push({ code: 'unresolved-reference', path: check.path, message: `Unknown token: ${check.reference}.` })
    } else if (actualKind !== check.expectedKind) {
      issues.push({
        code: 'reference-kind',
        path: check.path,
        message: `Expected ${check.expectedKind}, but ${check.reference} is ${actualKind}.`,
      })
    }
  }

  if (issues.length === 0) {
    for (const result of validateColorContrasts(value as FoundationTokenSet)) {
      if (!result.passes) {
        issues.push({
          code: 'contrast',
          path: `tokens.system.color.${result.mode}.${result.foreground}`,
          message: `${result.foreground} on ${result.background} is ${result.ratio.toFixed(2)}:1; expected at least ${result.minimum}:1.`,
        })
      }
    }
  }

  return issues.length === 0
    ? { success: true, issues: [] }
    : { success: false, issues: Object.freeze(issues.map((issue) => Object.freeze(issue))) }
}

export class TokenValidationError extends TypeError {
  readonly issues: readonly TokenValidationIssue[]

  constructor(issues: readonly TokenValidationIssue[]) {
    super(issues.map((issue) => `${issue.path}: ${issue.message}`).join('\n'))
    this.name = 'TokenValidationError'
    this.issues = issues
  }
}

export function assertTokenSet(value: unknown): asserts value is FoundationTokenSet {
  const result = validateTokenSet(value)
  if (!result.success) throw new TokenValidationError(result.issues)
}

export function parseTokenSet(value: unknown): FoundationTokenSet {
  assertTokenSet(value)
  return cloneAndDeepFreeze(value) as FoundationTokenSet
}

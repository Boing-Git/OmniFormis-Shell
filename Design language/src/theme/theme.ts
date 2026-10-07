import {
  defaultTokenSet,
  validateTokenSet,
  type FoundationTokenSet,
  type TokenValidationIssue,
} from '../tokens'
import type {
  Material3Theme,
  Material3ThemeOverrides,
  ThemeValidationResult,
} from './theme.types'
import { cloneAndDeepFreeze } from '../tokens/immutability'

const themeKeys = [
  'reference',
  'colorSchemes',
  'typography',
  'shapes',
  'motion',
  'elevation',
  'state',
  'density',
  'componentTokens',
] as const

function isRecord(value: unknown): value is Record<string, unknown> {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) return false
  const prototype = Object.getPrototypeOf(value)
  return prototype === Object.prototype || prototype === null
}

function themeShapeIssues(value: unknown): TokenValidationIssue[] {
  if (!isRecord(value)) {
    return [{ code: 'type', path: 'theme', message: 'Expected a plain object.' }]
  }
  const issues: TokenValidationIssue[] = []
  const expected = new Set<string>(themeKeys)
  for (const key of themeKeys) {
    if (!Object.hasOwn(value, key)) {
      issues.push({ code: 'missing-key', path: `theme.${key}`, message: 'Required theme field is missing.' })
    }
  }
  for (const key of Object.keys(value)) {
    if (!expected.has(key)) {
      issues.push({ code: 'unknown-key', path: `theme.${key}`, message: 'Unknown theme field.' })
    }
  }
  return issues
}

function remapPath(path: string): string {
  return path
    .replace(/^tokens\.reference/, 'theme.reference')
    .replace(/^tokens\.system\.color/, 'theme.colorSchemes')
    .replace(/^tokens\.system\.typography/, 'theme.typography')
    .replace(/^tokens\.system\.shape/, 'theme.shapes')
    .replace(/^tokens\.system\.motion/, 'theme.motion')
    .replace(/^tokens\.system\.elevation/, 'theme.elevation')
    .replace(/^tokens\.system\.state/, 'theme.state')
    .replace(/^tokens\.system\.density/, 'theme.density')
    .replace(/^tokens\.componentTokens/, 'theme.componentTokens')
}

function remapIssues(issues: readonly TokenValidationIssue[]): readonly TokenValidationIssue[] {
  return Object.freeze(
    issues.map((issue) => Object.freeze({ ...issue, path: remapPath(issue.path) })),
  )
}

function themeCandidateToTokenSet(value: Record<string, unknown>): unknown {
  return {
    metadata: defaultTokenSet.metadata,
    reference: value.reference,
    system: {
      color: value.colorSchemes,
      typography: value.typography,
      shape: value.shapes,
      motion: value.motion,
      elevation: value.elevation,
      state: value.state,
      density: value.density,
    },
    componentTokens: value.componentTokens,
  }
}

function tokenSetToTheme(tokenSet: FoundationTokenSet): Material3Theme {
  return Object.freeze({
    reference: tokenSet.reference,
    colorSchemes: tokenSet.system.color,
    typography: tokenSet.system.typography,
    shapes: tokenSet.system.shape,
    motion: tokenSet.system.motion,
    elevation: tokenSet.system.elevation,
    state: tokenSet.system.state,
    density: tokenSet.system.density,
    componentTokens: tokenSet.componentTokens,
  })
}

export function themeToTokenSet(theme: Material3Theme): FoundationTokenSet {
  return Object.freeze({
    metadata: defaultTokenSet.metadata,
    reference: theme.reference,
    system: Object.freeze({
      color: theme.colorSchemes,
      typography: theme.typography,
      shape: theme.shapes,
      motion: theme.motion,
      elevation: theme.elevation,
      state: theme.state,
      density: theme.density,
    }),
    componentTokens: theme.componentTokens,
  })
}

export function validateTheme(value: unknown): ThemeValidationResult {
  const shapeIssues = themeShapeIssues(value)
  if (shapeIssues.length > 0) {
    return { success: false, issues: Object.freeze(shapeIssues.map((issue) => Object.freeze(issue))) }
  }
  const result = validateTokenSet(themeCandidateToTokenSet(value as Record<string, unknown>))
  return result.success ? result : { success: false, issues: remapIssues(result.issues) }
}

export class ThemeValidationError extends TypeError {
  readonly issues: readonly TokenValidationIssue[]

  constructor(issues: readonly TokenValidationIssue[]) {
    super(issues.map((issue) => `${issue.path}: ${issue.message}`).join('\n'))
    this.name = 'ThemeValidationError'
    this.issues = issues
  }
}

export function parseTheme(value: unknown): Material3Theme {
  const shapeIssues = themeShapeIssues(value)
  if (shapeIssues.length > 0) throw new ThemeValidationError(remapIssues(shapeIssues))
  const candidate = themeCandidateToTokenSet(value as Record<string, unknown>)
  const result = validateTokenSet(candidate)
  if (!result.success) throw new ThemeValidationError(remapIssues(result.issues))
  return tokenSetToTheme(cloneAndDeepFreeze(candidate) as FoundationTokenSet)
}

function mergeValue(base: unknown, overrides: unknown): unknown {
  if (!isRecord(base) || !isRecord(overrides)) return overrides
  const merged = Object.fromEntries(Object.entries(base))
  for (const [key, value] of Object.entries(overrides)) {
    Object.defineProperty(merged, key, {
      configurable: true,
      enumerable: true,
      writable: true,
      value: Object.hasOwn(base, key) ? mergeValue(base[key], value) : value,
    })
  }
  return merged
}

export const defaultTheme = tokenSetToTheme(defaultTokenSet)

export function extendTheme(
  base: Material3Theme,
  overrides: Material3ThemeOverrides,
): Material3Theme {
  const parsedBase = parseTheme(base)
  return parseTheme(mergeValue(parsedBase, overrides))
}

export function createTheme(overrides: Material3ThemeOverrides = {}): Material3Theme {
  return extendTheme(defaultTheme, overrides)
}

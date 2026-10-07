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
  type TokenValueKind,
} from './schema'

function buildFoundationTokenKinds(): ReadonlyMap<FoundationTokenPath, TokenValueKind> {
  const entries: Array<[FoundationTokenPath, TokenValueKind]> = []
  const add = (path: FoundationTokenPath, kind: TokenValueKind) => entries.push([path, kind])

  for (const name of PALETTE_TOKEN_NAMES) add(`ref.palette.${name}`, 'color')
  for (const name of TYPEFACE_FAMILY_TOKEN_NAMES) add(`ref.typeface.${name}`, 'font-family')
  for (const name of TYPEFACE_WEIGHT_TOKEN_NAMES) {
    add(`ref.typeface.weight.${name}`, 'font-weight')
  }
  for (const name of COLOR_ROLE_NAMES) add(`sys.color.${name}`, 'color')

  for (const emphasis of TYPOGRAPHY_EMPHASES) {
    for (const role of TYPOGRAPHY_ROLE_NAMES) {
      add(`sys.typography.${emphasis}.${role}.fontFamily`, 'font-family')
      add(`sys.typography.${emphasis}.${role}.fontWeight`, 'font-weight')
      add(`sys.typography.${emphasis}.${role}.fontSize`, 'dimension')
      add(`sys.typography.${emphasis}.${role}.lineHeight`, 'dimension')
      add(`sys.typography.${emphasis}.${role}.letterSpacing`, 'dimension')
      for (const axis of FONT_AXIS_TAGS) {
        add(`sys.typography.${emphasis}.${role}.axes.${axis}`, 'number')
      }
    }
  }

  for (const name of SHAPE_CORNER_VALUE_NAMES) {
    add(`sys.shape.cornerValues.${name}`, 'dimension')
  }
  for (const name of SHAPE_ROLE_NAMES) add(`sys.shape.corners.${name}`, 'shape')

  for (const scheme of MOTION_SCHEME_NAMES) {
    for (const speed of MOTION_SPEED_NAMES) {
      for (const category of MOTION_CATEGORY_NAMES) {
        add(`sys.motion.${scheme}.${speed}.${category}.dampingRatio`, 'number')
        add(`sys.motion.${scheme}.${speed}.${category}.stiffness`, 'number')
      }
    }
  }

  for (const name of ELEVATION_LEVEL_NAMES) {
    add(`sys.elevation.${name}.dp`, 'dimension')
    add(`sys.elevation.${name}.tonalOverlayOpacity`, 'opacity')
    add(`sys.elevation.${name}.shadow`, 'shadow')
  }
  for (const name of STATE_OPACITY_NAMES) add(`sys.state.${name}`, 'opacity')
  add('sys.density.scale', 'number')
  add('sys.density.minimumInteractiveTarget', 'dimension')

  return new Map(entries)
}

export const FOUNDATION_TOKEN_KINDS = buildFoundationTokenKinds()

function kebabCase(value: string): string {
  return value
    .replace(/([a-z0-9])([A-Z])/g, '$1-$2')
    .replace(/_/g, '-')
    .toLowerCase()
}

export function tokenPathToCssVariable(path: FoundationTokenPath): `--m3e-${string}` {
  const normalized = path
    .replace(/^sys\.typography\./, 'sys.typescale.')
    .replace(/^sys\.shape\.cornerValues\./, 'sys.shape.corner-value.')
    .replace(/^sys\.shape\.corners\.corner/, 'sys.shape.corner.')
  return `--m3e-${normalized.split('.').map(kebabCase).join('-')}`
}

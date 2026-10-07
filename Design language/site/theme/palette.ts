/**
 * Tonal palette generation for the site's theme playground.
 *
 * Material derives tonal palettes in HCT. Shipping HCT would mean adding a
 * color library to a site whose subject is a package with no runtime
 * dependencies, so this uses CIELAB instead: Material tone numbers are L*
 * values, which is exactly the axis CIELAB parameterizes. The result is not
 * byte-identical to HCT — chroma behaves differently near the gamut boundary —
 * but tone-to-lightness is faithful, which is what the role mappings and the
 * library's contrast validation depend on.
 *
 * If a generated scheme ever fails that validation, the site reports it rather
 * than hiding it. See `SiteProviders`.
 */

export const defaultSourceColor = '#6750a4'

/** Tone stops per family, matching the reference palette exactly. */
const standardTones = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 98, 99, 100] as const
const neutralTones = [
  0, 4, 6, 10, 12, 17, 20, 22, 24, 30, 40, 50, 60, 70, 80, 87, 90, 92, 94, 95, 96, 98, 99, 100,
] as const

/**
 * Chroma and hue rotation per family, in CIELAB chroma units.
 *
 * Calibrated so that a `#6750a4` source reproduces the reference palette
 * closely; `npm run check:site` pins that agreement so a change here cannot
 * silently drift the playground away from the shipped default.
 */
const families = {
  primary: { chroma: 48, hueShift: 0, tones: standardTones },
  secondary: { chroma: 18, hueShift: 0, tones: standardTones },
  tertiary: { chroma: 30, hueShift: 60, tones: standardTones },
  neutral: { chroma: 4, hueShift: 0, tones: neutralTones },
  'neutral-variant': { chroma: 10, hueShift: 0, tones: standardTones },
} as const

// ---------------------------------------------------------------------------
// sRGB <-> CIELAB (D65)
// ---------------------------------------------------------------------------

const whiteD65 = { x: 95.047, y: 100, z: 108.883 }

function linearize(channel: number): number {
  const value = channel / 255
  return value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4
}

function delinearize(channel: number): number {
  const value = channel <= 0.0031308 ? channel * 12.92 : 1.055 * channel ** (1 / 2.4) - 0.055
  return Math.round(Math.min(1, Math.max(0, value)) * 255)
}

function rgbToXyz(r: number, g: number, b: number) {
  const red = linearize(r) * 100
  const green = linearize(g) * 100
  const blue = linearize(b) * 100
  return {
    x: red * 0.4124564 + green * 0.3575761 + blue * 0.1804375,
    y: red * 0.2126729 + green * 0.7151522 + blue * 0.072175,
    z: red * 0.0193339 + green * 0.119192 + blue * 0.9503041,
  }
}

function xyzToLab(x: number, y: number, z: number) {
  const f = (value: number) =>
    value > 0.008856 ? Math.cbrt(value) : (903.3 * value + 16) / 116
  const fx = f(x / whiteD65.x)
  const fy = f(y / whiteD65.y)
  const fz = f(z / whiteD65.z)
  return { l: 116 * fy - 16, a: 500 * (fx - fy), b: 200 * (fy - fz) }
}

function labToXyz(l: number, a: number, b: number) {
  const fy = (l + 16) / 116
  const fx = fy + a / 500
  const fz = fy - b / 200
  const inverse = (value: number) => {
    const cubed = value ** 3
    return cubed > 0.008856 ? cubed : (116 * value - 16) / 903.3
  }
  return {
    x: inverse(fx) * whiteD65.x,
    y: l > 8 ? ((l + 16) / 116) ** 3 * whiteD65.y : (l / 903.3) * whiteD65.y,
    z: inverse(fz) * whiteD65.z,
  }
}

function xyzToLinearRgb(x: number, y: number, z: number) {
  const scaledX = x / 100
  const scaledY = y / 100
  const scaledZ = z / 100
  return {
    r: scaledX * 3.2404542 + scaledY * -1.5371385 + scaledZ * -0.4985314,
    g: scaledX * -0.969266 + scaledY * 1.8760108 + scaledZ * 0.041556,
    b: scaledX * 0.0556434 + scaledY * -0.2040259 + scaledZ * 1.0572252,
  }
}

function inGamut({ r, g, b }: { r: number; g: number; b: number }): boolean {
  const epsilon = 0.0001
  return (
    r >= -epsilon && r <= 1 + epsilon &&
    g >= -epsilon && g <= 1 + epsilon &&
    b >= -epsilon && b <= 1 + epsilon
  )
}

function toHex(r: number, g: number, b: number): string {
  return `#${[r, g, b].map((c) => c.toString(16).padStart(2, '0')).join('')}`
}

export function parseHex(hex: string): { r: number; g: number; b: number } | null {
  const match = /^#?([\da-f]{6})$/i.exec(hex.trim())
  if (!match) return null
  const value = Number.parseInt(match[1], 16)
  return { r: (value >> 16) & 255, g: (value >> 8) & 255, b: value & 255 }
}

/** Source hue in CIELAB degrees, and its chroma, for deriving a scheme. */
export function sourceHue(hex: string): number {
  const rgb = parseHex(hex)
  if (!rgb) return 0
  const { x, y, z } = rgbToXyz(rgb.r, rgb.g, rgb.b)
  const { a, b } = xyzToLab(x, y, z)
  const hue = (Math.atan2(b, a) * 180) / Math.PI
  return hue < 0 ? hue + 360 : hue
}

/**
 * Builds one tone, reducing chroma until the color is representable in sRGB.
 * Clamping rather than clipping keeps hue stable: a clipped RGB triple shifts
 * hue visibly at high tones, which would break the tonal ramp's coherence.
 */
function toneToHex(lightness: number, chroma: number, hue: number): string {
  if (lightness <= 0) return '#000000'
  if (lightness >= 100) return '#ffffff'

  const radians = (hue * Math.PI) / 180
  let low = 0
  let high = chroma
  let best = { r: 0, g: 0, b: 0 }

  for (let iteration = 0; iteration < 24; iteration += 1) {
    const candidateChroma = (low + high) / 2
    const a = Math.cos(radians) * candidateChroma
    const b = Math.sin(radians) * candidateChroma
    const xyz = labToXyz(lightness, a, b)
    const rgb = xyzToLinearRgb(xyz.x, xyz.y, xyz.z)
    if (inGamut(rgb)) {
      best = rgb
      low = candidateChroma
    } else {
      high = candidateChroma
    }
  }

  return toHex(delinearize(best.r), delinearize(best.g), delinearize(best.b))
}

/**
 * Generates every palette entry the theme's reference layer expects, except
 * `error`, `black`, and `white`. Error keeps its own hue by design: a red-free
 * error color would be a worse default than an off-brand one.
 */
export function buildPalette(source: string): Record<string, string> {
  const hue = sourceHue(source)
  const palette: Record<string, string> = {}

  for (const [family, spec] of Object.entries(families)) {
    for (const tone of spec.tones) {
      palette[`${family}-${tone}`] = toneToHex(tone, spec.chroma, hue + spec.hueShift)
    }
  }

  return palette
}

/** Preset source colors offered in the theme panel. */
export const presetSources: readonly { name: string; value: string }[] = [
  { name: 'Baseline', value: defaultSourceColor },
  { name: 'Cobalt', value: '#2f5bd0' },
  { name: 'Viridian', value: '#1c7a5b' },
  { name: 'Amber', value: '#9a6b12' },
  { name: 'Crimson', value: '#b33247' },
  { name: 'Slate', value: '#4a5a6b' },
]

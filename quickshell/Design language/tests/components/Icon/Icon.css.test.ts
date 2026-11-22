import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/Icon/Icon.css', import.meta.url)),
  'utf8',
)

describe('Icon stylesheet contract', () => {
  it('uses stable namespaced component tokens and inherited content color', () => {
    expect(css).toContain('@layer m3e.components')
    expect(css).toContain('.m3e-icon')
    expect(css).toContain('var(--m3e-comp-icon-size)')
    expect(css).toContain('color: inherit')
    expect(css).toContain('currentColor')
    expect(css).toContain('.m3e-icon__svg:not([fill])')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('maps every current Material Symbols and Expressive axis', () => {
    const axes = {
      FILL: '--m3e-comp-icon-symbol-fill',
      wght: '--m3e-comp-icon-symbol-weight',
      GRAD: '--m3e-comp-icon-symbol-grade',
      opsz: '--m3e-comp-icon-symbol-optical-size',
      ROND: '--m3e-comp-icon-symbol-roundness',
    }
    for (const [axis, token] of Object.entries(axes)) {
      expect(css).toContain(`"${axis}" var(`)
      expect(css).toContain(`var(${token})`)
    }
    for (const style of ['outlined', 'rounded', 'sharp']) {
      expect(css).toContain(`[data-m3e-symbol-style="${style}"]`)
      expect(css).toContain(`var(--m3e-comp-icon-symbol-family-${style})`)
    }
  })

  it('mirrors only opted-in directional artwork under RTL', () => {
    expect(css).toContain('[data-m3e-mirrored="true"]:dir(rtl)')
    expect(css).toContain('transform: scaleX(-1)')
    expect(css).not.toContain('[dir="rtl"] .m3e-icon__')
  })

  it('performs no font fetching, style animation, or runtime-dependent loading', () => {
    expect(css).not.toContain('@font-face')
    expect(css).not.toContain('url(')
    expect(css).not.toMatch(/\b(?:animation|transition)\s*:/)
    expect(css).not.toMatch(/\b\d*\.?\d+(?:px|rem|em|pt)\b/)
  })
})

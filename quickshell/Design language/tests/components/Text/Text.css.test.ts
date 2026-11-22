import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import {
  FONT_AXIS_TAGS,
  TYPOGRAPHY_EMPHASES,
  TYPOGRAPHY_ROLE_NAMES,
} from '../../../src/tokens'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/Text/Text.css', import.meta.url)),
  'utf8',
)

function kebabCase(value: string): string {
  return value.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase()
}

describe('Text stylesheet contract', () => {
  it('uses stable namespaced selectors without owning content color or font loading', () => {
    expect(css).toContain('@layer m3e.components')
    expect(css).toContain('.m3e-text')
    expect(css).toContain('margin: 0')
    expect(css).not.toMatch(/(?:^|[;{]\s*)color\s*:/m)
    expect(css).not.toContain('@font-face')
    expect(css).not.toContain('url(')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('maps every baseline and Expressive emphasized role to all typography tokens', () => {
    for (const emphasis of TYPOGRAPHY_EMPHASES) {
      for (const role of TYPOGRAPHY_ROLE_NAMES) {
        const prefix = `--m3e-sys-typescale-${emphasis}-${kebabCase(role)}`
        expect(css).toContain(
          `.m3e-text[data-m3e-variant="${role}"][data-m3e-emphasis="${emphasis}"]`,
        )
        for (const property of [
          'font-family',
          'font-weight',
          'font-size',
          'line-height',
          'letter-spacing',
        ]) {
          expect(css).toContain(`var(${prefix}-${property})`)
        }
        for (const axis of FONT_AXIS_TAGS) {
          expect(css).toContain(`var(${prefix}-axes-${axis.toLowerCase()})`)
        }
      }
    }
  })

  it('contains no raw type metrics and applies variable axes through CSS', () => {
    expect(css).not.toMatch(/\b\d*\.?\d+(?:px|rem|em|pt)\b/)
    expect(css.match(/font-variation-settings:/g)).toHaveLength(30)
    for (const axis of FONT_AXIS_TAGS) expect(css).toContain(`"${axis}" var(`)
  })
})

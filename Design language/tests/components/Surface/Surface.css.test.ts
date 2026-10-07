import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/Surface/Surface.css', import.meta.url)),
  'utf8',
)

describe('Surface stylesheet contract', () => {
  it('uses stable namespaced selectors and clips content to the selected shape', () => {
    expect(css).toContain('@layer m3e.components')
    expect(css).toContain('.m3e-surface')
    expect(css).toContain('border-radius: var(--m3e-comp-surface-container-shape)')
    expect(css).toContain('overflow: clip')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('maps every exposed container family to Material system color roles', () => {
    const colors = [
      'surface', 'surface-dim', 'surface-bright', 'surface-container-lowest',
      'surface-container-low', 'surface-container', 'surface-container-high',
      'surface-container-highest', 'primary', 'primary-container', 'primary-fixed',
      'primary-fixed-dim', 'secondary', 'secondary-container', 'secondary-fixed',
      'secondary-fixed-dim', 'tertiary', 'tertiary-container', 'tertiary-fixed',
      'tertiary-fixed-dim', 'error', 'error-container', 'inverse-surface',
    ]

    for (const color of colors) expect(css).toContain(`data-m3e-color="${color}"`)
    expect(css).toContain('var(--m3e-sys-color-on-primary-container)')
    expect(css).toContain('var(--m3e-sys-color-inverse-on-surface)')
  })

  it('keeps tonal and shadow elevation independent and theme-backed', () => {
    for (const level of [1, 2, 3, 4, 5]) {
      expect(css).toContain(`data-m3e-shadow-elevation="${level}"`)
      expect(css).toContain(`var(--m3e-sys-elevation-level${level}-shadow)`)
      expect(css).toContain(`data-m3e-tonal-elevation="${level}"`)
      expect(css).toContain(
        `var(--m3e-sys-elevation-level${level}-tonal-overlay-opacity)`,
      )
    }
    expect(css).toContain('var(--m3e-sys-color-surface-tint)')
    expect(css).toContain('color-mix(')
  })

  it('maps every non-default shape to a system corner token', () => {
    const shapes = [
      'extra-small', 'extra-small-top', 'small', 'medium', 'large', 'large-start',
      'large-end', 'large-top', 'large-increased', 'extra-large', 'extra-large-top',
      'extra-large-increased', 'extra-extra-large', 'full',
    ]

    for (const shape of shapes) {
      expect(css).toContain(`data-m3e-shape="${shape}"`)
      expect(css).toContain(`var(--m3e-sys-shape-corner-${shape})`)
    }
    expect(css).toContain('[data-m3e-shape="large-start"]:dir(rtl)')
    expect(css).toContain('[data-m3e-shape="large-end"]:dir(rtl)')
  })
})

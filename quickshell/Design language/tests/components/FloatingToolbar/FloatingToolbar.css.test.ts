import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(
    new URL('../../../src/components/FloatingToolbar/FloatingToolbar.css', import.meta.url),
  ),
  'utf8',
)

describe('FloatingToolbar stylesheet contract', () => {
  it('maps sourced color and geometry through stable component variables', () => {
    expect(css).toContain('var(--m3e-comp-floating-toolbar-standard-container-color)')
    expect(css).toContain('var(--m3e-comp-floating-toolbar-vibrant-container-color)')
    expect(css).toContain('var(--m3e-comp-floating-toolbar-container-shape)')
    expect(css).toContain('var(--m3e-comp-floating-toolbar-container-height)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('collapses via max-size + opacity, transitioning on the shared expressive fast-spatial slot', () => {
    expect(css).toContain('max-inline-size')
    expect(css).toContain('max-block-size')
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-spatial-duration)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-spatial-easing)')
  })

  it('switches main-axis flex-direction by orientation', () => {
    expect(css).toContain('[data-m3e-orientation="vertical"]')
    expect(css).toContain('flex-direction: column')
  })

  it('becomes immediate under reduced motion', () => {
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('transition: none')
  })

  it('keeps the container visibly distinct in forced colors', () => {
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('CanvasText')
    expect(css).toContain('forced-color-adjust: none')
  })
})

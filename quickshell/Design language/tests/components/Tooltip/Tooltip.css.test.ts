import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/Tooltip/Tooltip.css', import.meta.url)),
  'utf8',
)

describe('Tooltip stylesheet contract', () => {
  it('maps sourced plain and rich container geometry/color through stable component variables', () => {
    expect(css).toContain('var(--m3e-comp-tooltip-plain-container-color)')
    expect(css).toContain('var(--m3e-comp-tooltip-plain-container-shape)')
    expect(css).toContain('var(--m3e-comp-tooltip-rich-container-color)')
    expect(css).toContain('var(--m3e-comp-tooltip-rich-container-shape)')
    expect(css).toContain('var(--m3e-comp-tooltip-rich-container-shadow)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('drives open state from a data attribute, not a native top-layer element', () => {
    expect(css).toContain('.m3e-tooltip[data-m3e-open="true"]')
    expect(css).toContain('opacity: 0')
    expect(css).toContain('transform: scale(0.8)')
    expect(css).toContain('transform: scale(1)')
    expect(css).not.toContain('@starting-style')
  })

  it('uses the theme’s own body-small/title-small/body-medium typescale roles directly', () => {
    expect(css).toContain('var(--m3e-sys-typescale-baseline-body-small-font-size)')
    expect(css).toContain('var(--m3e-sys-typescale-baseline-title-small-font-size)')
    expect(css).toContain('var(--m3e-sys-typescale-baseline-body-medium-font-size)')
  })

  it('uses semantic Expressive fast motion with an immediate reduced-motion outcome', () => {
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-spatial-duration)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-effects-duration)')
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('transition: none')
  })

  it('uses logical layout and retains a visible boundary in forced colors', () => {
    expect(css).toContain('inline-size')
    expect(css).toContain('padding-inline')
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('CanvasText')
    expect(css).not.toMatch(
      /^\s*(?:left|right|width|height|margin-left|margin-right|padding-left|padding-right)\s*:/m,
    )
  })
})

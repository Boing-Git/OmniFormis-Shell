import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/Tabs/Tabs.css', import.meta.url)),
  'utf8',
)

describe('Tabs stylesheet contract', () => {
  it('maps sourced container/indicator geometry and color through stable component variables', () => {
    expect(css).toContain('var(--m3e-comp-tabs-container-color)')
    expect(css).toContain('var(--m3e-comp-tabs-indicator-color)')
    expect(css).toContain('var(--m3e-comp-tabs-indicator-height)')
    expect(css).toContain('var(--m3e-comp-tabs-indicator-shape)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('slides the indicator via transform/inline-size, not a native top-layer or JS-animated framework', () => {
    expect(css).toContain('.m3e-tabs__indicator')
    expect(css).toContain('transform: translateX(0)')
    expect(css).toContain('transition:')
    expect(css).not.toContain('@starting-style')
  })

  it('uses the sourced DefaultSpatial motion slot for the indicator, not FastSpatial', () => {
    expect(css).toContain('var(--m3e-sys-motion-expressive-default-spatial-duration)')
    expect(css).not.toContain('var(--m3e-sys-motion-expressive-fast-spatial-duration)')
  })

  it('uses the shared state-layer system for hover/focus/pressed tab feedback', () => {
    expect(css).toContain('var(--m3e-sys-state-hover)')
    expect(css).toContain('var(--m3e-sys-state-focus)')
    expect(css).toContain('var(--m3e-sys-state-pressed)')
    expect(css).toContain('background: currentColor')
  })

  it('dims a disabled tab using color-mix against its own disabled opacity token', () => {
    expect(css).toContain('[aria-disabled="true"]')
    expect(css).toContain('color-mix(')
    expect(css).toContain('var(--m3e-comp-tabs-disabled-label-opacity)')
    expect(css).toContain('pointer-events: none')
  })

  it('uses the theme’s own title-small typescale role directly', () => {
    expect(css).toContain('var(--m3e-sys-typescale-baseline-title-small-font-size)')
  })

  it('uses an immediate reduced-motion outcome', () => {
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('transition: none')
  })

  it('uses logical layout and retains a visible boundary in forced colors', () => {
    expect(css).toContain('inline-size')
    expect(css).toContain('inset-inline-start')
    expect(css).toContain('padding-inline')
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('CanvasText')
    expect(css).not.toMatch(
      /^\s*(?:left|right|width|height|margin-left|margin-right|padding-left|padding-right)\s*:/m,
    )
  })
})

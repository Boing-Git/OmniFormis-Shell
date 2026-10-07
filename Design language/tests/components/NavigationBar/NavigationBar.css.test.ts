import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/NavigationBar/NavigationBar.css', import.meta.url)),
  'utf8',
)

describe('NavigationBar stylesheet contract', () => {
  it('maps sourced container/indicator geometry and color through stable component variables', () => {
    expect(css).toContain('var(--m3e-comp-navigation-bar-container-color)')
    expect(css).toContain('var(--m3e-comp-navigation-bar-item-active-indicator-color)')
    expect(css).toContain('var(--m3e-comp-navigation-bar-item-active-indicator-shape)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('expands only the active background from the selected data attribute', () => {
    expect(css).toContain('[data-m3e-selected="true"]')
    expect(css).toMatch(
      /\.m3e-navigation-bar__indicator::before\s*{[\s\S]*?inline-size:\s*0;/,
    )
    expect(css).toMatch(
      /\[data-m3e-selected="true"\] \.m3e-navigation-bar__indicator::before\s*{[\s\S]*?inline-size:\s*100%;/,
    )
    expect(css).toContain(
      'inline-size var(--m3e-sys-motion-expressive-fast-spatial-duration)',
    )
  })

  it('keeps the indicator footprint and icon size stable instead of scaling the icon', () => {
    expect(css).toMatch(
      /\.m3e-navigation-bar__indicator\s*{[\s\S]*?block-size:\s*var\(--m3e-comp-navigation-bar-item-active-indicator-height\);[\s\S]*?inline-size:\s*var\(--m3e-comp-navigation-bar-item-active-indicator-width\);/,
    )
    expect(css).toMatch(
      /\.m3e-navigation-bar__icon\s*{[\s\S]*?block-size:\s*var\(--m3e-comp-navigation-bar-item-icon-size\);[\s\S]*?inline-size:\s*var\(--m3e-comp-navigation-bar-item-icon-size\);/,
    )
    expect(css).not.toMatch(/transform:\s*scale/)
  })

  it('uses the shared state-layer system for hover/focus/pressed item feedback', () => {
    expect(css).toContain('var(--m3e-sys-state-hover)')
    expect(css).toContain('var(--m3e-sys-state-focus)')
    expect(css).toContain('var(--m3e-sys-state-pressed)')
    expect(css).toContain('background: currentColor')
    expect(css).toContain('.m3e-navigation-bar__indicator::after')
  })

  it('dims a disabled item using color-mix against its own disabled opacity token', () => {
    expect(css).toContain('[aria-disabled="true"]')
    expect(css).toContain('color-mix(')
    expect(css).toContain('var(--m3e-comp-navigation-bar-item-disabled-opacity)')
    expect(css).toContain('pointer-events: none')
  })

  it('uses the theme’s own label-medium typescale role directly', () => {
    expect(css).toContain('var(--m3e-sys-typescale-baseline-label-medium-font-size)')
  })

  it('uses an immediate reduced-motion outcome', () => {
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('transition: none')
  })

  it('uses logical layout and retains a visible boundary in forced colors', () => {
    expect(css).toContain('inline-size')
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('CanvasText')
    expect(css).not.toMatch(
      /^\s*(?:left|right|width|height|margin-left|margin-right|padding-left|padding-right)\s*:/m,
    )
  })
})

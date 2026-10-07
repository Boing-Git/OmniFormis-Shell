import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/NavigationRail/NavigationRail.css', import.meta.url)),
  'utf8',
)

describe('NavigationRail stylesheet contract', () => {
  it('maps sourced container/indicator geometry and color through stable component variables', () => {
    expect(css).toContain('var(--m3e-comp-navigation-rail-container-color)')
    expect(css).toContain('var(--m3e-comp-navigation-rail-item-active-indicator-color)')
    expect(css).toContain('var(--m3e-comp-navigation-rail-item-active-indicator-shape)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('lays out items in a vertical column', () => {
    expect(css).toContain('flex-direction: column')
  })

  it('expands only the active background while retaining fixed indicator and icon geometry', () => {
    expect(css).toMatch(
      /\.m3e-navigation-rail__indicator::before\s*{[\s\S]*?inline-size:\s*0;/,
    )
    expect(css).toMatch(
      /\[data-m3e-selected="true"\] \.m3e-navigation-rail__indicator::before\s*{[\s\S]*?inline-size:\s*100%;/,
    )
    expect(css).toMatch(
      /\.m3e-navigation-rail__indicator\s*{[\s\S]*?block-size:\s*var\(--m3e-comp-navigation-rail-item-active-indicator-height\);[\s\S]*?inline-size:\s*var\(--m3e-comp-navigation-rail-item-active-indicator-width\);/,
    )
    expect(css).toMatch(
      /\.m3e-navigation-rail__icon\s*{[\s\S]*?block-size:\s*var\(--m3e-comp-navigation-rail-item-icon-size\);[\s\S]*?inline-size:\s*var\(--m3e-comp-navigation-rail-item-icon-size\);/,
    )
    expect(css).not.toMatch(/transform:\s*scale/)
  })

  it('uses the shared state-layer system for hover/focus/pressed item feedback', () => {
    expect(css).toContain('var(--m3e-sys-state-hover)')
    expect(css).toContain('var(--m3e-sys-state-focus)')
    expect(css).toContain('var(--m3e-sys-state-pressed)')
    expect(css).toContain('background: currentColor')
    expect(css).toContain('.m3e-navigation-rail__indicator::after')
  })

  it('dims a disabled item using color-mix against its own disabled opacity token', () => {
    expect(css).toContain('[aria-disabled="true"]')
    expect(css).toContain('color-mix(')
    expect(css).toContain('var(--m3e-comp-navigation-rail-item-disabled-opacity)')
  })

  it('uses an immediate reduced-motion outcome', () => {
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('transition: none')
  })

  it('uses logical layout and retains a visible boundary in forced colors', () => {
    expect(css).toContain('inline-size')
    expect(css).toContain('border-inline-end')
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('CanvasText')
    expect(css).not.toMatch(
      /^\s*(?:left|right|width|height|margin-left|margin-right|padding-left|padding-right)\s*:/m,
    )
  })
})

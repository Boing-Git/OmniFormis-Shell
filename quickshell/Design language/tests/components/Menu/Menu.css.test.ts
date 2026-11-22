import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/Menu/Menu.css', import.meta.url)),
  'utf8',
)

describe('Menu stylesheet contract', () => {
  it('maps sourced container geometry and color through stable component variables', () => {
    expect(css).toContain('var(--m3e-comp-menu-container-color)')
    expect(css).toContain('var(--m3e-comp-menu-container-shape)')
    expect(css).toContain('var(--m3e-comp-menu-container-shadow)')
    expect(css).toContain('var(--m3e-comp-menu-container-min-width)')
    expect(css).toContain('var(--m3e-comp-menu-container-max-width)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('drives open state from a data attribute, not a native top-layer element', () => {
    expect(css).toContain('.m3e-menu[data-m3e-open="true"]')
    expect(css).toContain('opacity: 0')
    expect(css).toContain('transform: scale(0.8)')
    expect(css).toContain('transform: scale(1)')
    expect(css).not.toContain('@starting-style')
  })

  it('uses the shared state-layer system for hover/focus/pressed item feedback', () => {
    expect(css).toContain('var(--m3e-sys-state-hover)')
    expect(css).toContain('var(--m3e-sys-state-focus)')
    expect(css).toContain('var(--m3e-sys-state-pressed)')
    expect(css).toContain('background: currentColor')
  })

  it('registers a visible keyboard focus ring despite the source color model having none', () => {
    expect(css).toContain('.m3e-menu__item:focus-visible')
    expect(css).toContain('var(--m3e-comp-menu-item-focus-ring-color)')
  })

  it('styles a checked item with the sourced tertiary-container roles', () => {
    expect(css).toContain('[data-m3e-checked="true"]')
    expect(css).toContain('var(--m3e-comp-menu-item-checked-container-color)')
    expect(css).toContain('var(--m3e-comp-menu-item-checked-label-color)')
  })

  it('dims a disabled item using color-mix against its own disabled opacity token', () => {
    expect(css).toContain('[aria-disabled="true"]')
    expect(css).toContain('color-mix(')
    expect(css).toContain('var(--m3e-comp-menu-item-disabled-label-opacity)')
    expect(css).toContain('pointer-events: none')
  })

  it('uses the theme’s own label-large typescale role directly', () => {
    expect(css).toContain('var(--m3e-sys-typescale-baseline-label-large-font-size)')
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

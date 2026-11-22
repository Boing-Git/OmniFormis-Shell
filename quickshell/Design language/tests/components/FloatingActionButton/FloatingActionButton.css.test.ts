import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(
    new URL(
      '../../../src/components/FloatingActionButton/FloatingActionButton.css',
      import.meta.url,
    ),
  ),
  'utf8',
)

describe('FloatingActionButton stylesheet contract', () => {
  it('maps all current sizes and their container, icon, shape, and extended tokens', () => {
    for (const size of ['standard', 'medium', 'large']) {
      expect(css).toContain(`[data-m3e-size="${size}"]`)
      expect(css).toContain(`var(--m3e-comp-floating-action-button-${size}-container-size)`)
      expect(css).toContain(`var(--m3e-comp-floating-action-button-${size}-container-shape)`)
      expect(css).toContain(`var(--m3e-comp-floating-action-button-${size}-icon-size)`)
      expect(css).toContain(`var(--m3e-comp-floating-action-button-${size}-extended-leading-space)`)
      expect(css).toContain(`var(--m3e-comp-floating-action-button-${size}-extended-trailing-space)`)
      expect(css).toContain(`var(--m3e-comp-floating-action-button-${size}-extended-icon-label-space)`)
    }
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('keeps target sizing and the toggle initial footprint explicit', () => {
    expect(css).toContain('var(--m3e-comp-floating-action-button-minimum-interactive-target)')
    expect(css).toContain('[data-m3e-toggle="true"]')
    expect(css).toContain('place-self: start end')
    expect(css).toContain('var(--m3e-comp-floating-action-button-toggle-selected-container-size)')
    expect(css).toContain('var(--m3e-comp-floating-action-button-toggle-selected-container-shape)')
    expect(css).toContain('var(--m3e-comp-floating-action-button-toggle-selected-icon-size)')
  })

  it('uses separate spatial/effects motion and a reduced-motion outcome', () => {
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-spatial-duration)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-spatial-easing)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-effects-duration)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-effects-easing)')
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('transition: none')
  })

  it('covers elevation, state, disabled, focus, and forced colors', () => {
    expect(css).toContain('[data-m3e-elevation="lowered"]')
    expect(css).toContain('[data-m3e-elevation="none"]')
    expect(css).toContain('var(--m3e-fab-hover-container-shadow)')
    expect(css).toContain('.m3e-fab:disabled')
    expect(css).toContain('.m3e-fab:focus-visible')
    expect(css).toContain('var(--m3e-sys-state-hover)')
    expect(css).toContain('var(--m3e-sys-state-focus)')
    expect(css).toContain('var(--m3e-sys-state-pressed)')
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('background: Highlight')
    expect(css).toContain('color: GrayText')
  })

  it('uses logical properties for size, spacing, and toggle alignment', () => {
    expect(css).toContain('inline-size:')
    expect(css).toContain('block-size:')
    expect(css).toContain('padding-inline:')
    expect(css).toContain('margin-inline-start:')
    expect(css).not.toMatch(
      /^\s*(?:left|right|width|height|margin-left|margin-right|padding-left|padding-right)\s*:/m,
    )
  })
})

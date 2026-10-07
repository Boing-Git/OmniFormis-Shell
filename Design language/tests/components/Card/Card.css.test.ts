import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/Card/Card.css', import.meta.url)),
  'utf8',
)

describe('Card stylesheet contract', () => {
  it('maps all three Material variants through stable component variables', () => {
    for (const variant of ['filled', 'elevated', 'outlined']) {
      expect(css).toContain(`[data-m3e-variant="${variant}"]`)
      expect(css).toContain(`var(--m3e-comp-card-${variant}-container-color)`)
      expect(css).toContain(`var(--m3e-comp-card-${variant}-container-shadow)`)
      expect(css).toContain(`var(--m3e-comp-card-${variant}-hover-container-shadow)`)
    }
    expect(css).toContain('var(--m3e-comp-card-container-shape)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('keeps passive and native interactive styling explicitly separate', () => {
    expect(css).toContain('[data-m3e-interactive="true"]')
    expect(css).toContain('var(--m3e-comp-card-minimum-interactive-target)')
    expect(css).toContain('min-block-size:')
    expect(css).toContain('min-inline-size:')
    expect(css).toContain('touch-action: manipulation')
    expect(css).toContain('text-align: start')
  })

  it('covers sourced elevation, outline, state, and disabled behavior', () => {
    expect(css).toContain('var(--m3e-comp-card-filled-focus-container-shadow)')
    expect(css).toContain('var(--m3e-comp-card-elevated-pressed-container-shadow)')
    expect(css).toContain('var(--m3e-comp-card-outlined-hover-container-shadow)')
    expect(css).toContain('var(--m3e-comp-card-outlined-focus-outline-color)')
    expect(css).toContain(':focus-visible')
    expect(css).toContain(':active:not(:disabled)')
    expect(css).toContain(':disabled')
    expect(css).toContain('var(--m3e-sys-state-hover)')
    expect(css).toContain('var(--m3e-sys-state-focus)')
    expect(css).toContain('var(--m3e-sys-state-pressed)')
    expect(css).toContain('color-mix(')
  })

  it('uses semantic Expressive effects motion with an immediate reduced-motion outcome', () => {
    expect(css).toContain('var(--m3e-sys-motion-expressive-default-effects-duration)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-default-effects-easing)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-effects-duration)')
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('transition: none')
  })

  it('uses logical layout and retains visible state in forced colors', () => {
    expect(css).toContain('inline-size:')
    expect(css).toContain('block-size:')
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('outline-color: Highlight')
    expect(css).toContain('color: GrayText')
    expect(css).not.toMatch(
      /^\s*(?:left|right|width|height|margin-left|margin-right|padding-left|padding-right)\s*:/m,
    )
  })
})

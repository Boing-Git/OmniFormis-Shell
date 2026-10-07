import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/Button/Button.css', import.meta.url)),
  'utf8',
)

describe('Button stylesheet contract', () => {
  it('maps all Material variants and Expressive size tiers through component variables', () => {
    for (const variant of ['filled', 'tonal', 'elevated', 'outlined', 'text']) {
      expect(css).toContain(`[data-m3e-variant="${variant}"]`)
    }
    for (const size of ['extra-small', 'small', 'medium', 'large', 'extra-large']) {
      expect(css).toContain(`[data-m3e-size="${size}"]`)
      expect(css).toContain(`var(--m3e-comp-button-${size}-container-height)`)
      expect(css).toContain(`var(--m3e-comp-button-${size}-pressed-container-shape)`)
    }
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('preserves a 48px theme target independently from visual size and width', () => {
    expect(css).toContain('var(--m3e-comp-button-minimum-interactive-target)')
    expect(css).toContain('var(--m3e-comp-button-extra-small-container-height)')
    expect(css).toContain('[data-m3e-width="full"]')
    expect(css).toContain('inline-size: 100%')
  })

  it('uses size-aware resting and pressed shapes with semantic spring motion', () => {
    expect(css).toContain('[data-m3e-shape="square"]')
    expect(css).toContain(':active:not(:disabled)')
    expect(css).toContain('border-radius: var(--m3e-button-pressed-container-shape)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-default-effects-duration)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-default-effects-easing)')
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('transition: none')
  })

  it('covers native states, visible focus, state layers, and forced colors', () => {
    expect(css).toContain('.m3e-button:disabled')
    expect(css).toContain('.m3e-button:focus-visible')
    expect(css).toContain('var(--m3e-sys-state-hover)')
    expect(css).toContain('var(--m3e-sys-state-focus)')
    expect(css).toContain('var(--m3e-sys-state-pressed)')
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('outline-color: Highlight')
    expect(css).toContain('color: GrayText')
  })

  it('uses logical layout and leaves RTL ordering to native direction', () => {
    expect(css).toContain('padding-inline:')
    expect(css).toContain('padding-block:')
    expect(css).toContain('inline-size:')
    expect(css).toContain('block-size:')
    expect(css).not.toMatch(
      /^\s*(?:left|right|width|height|margin-left|margin-right|padding-left|padding-right)\s*:/m,
    )
  })
})

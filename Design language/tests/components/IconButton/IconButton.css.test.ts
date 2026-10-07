import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/IconButton/IconButton.css', import.meta.url)),
  'utf8',
)

describe('IconButton stylesheet contract', () => {
  it('maps all Material variants, Expressive sizes, and width options', () => {
    for (const variant of ['standard', 'filled', 'tonal', 'outlined']) {
      expect(css).toContain(`[data-m3e-variant="${variant}"]`)
    }
    for (const size of ['extra-small', 'small', 'medium', 'large', 'extra-large']) {
      expect(css).toContain(`[data-m3e-size="${size}"]`)
      expect(css).toContain(`var(--m3e-comp-icon-button-${size}-container-height)`)
      expect(css).toContain(`var(--m3e-comp-icon-button-${size}-pressed-container-shape)`)
      for (const width of ['narrow', 'uniform', 'wide']) {
        expect(css).toContain(`var(--m3e-comp-icon-button-${size}-container-width-${width})`)
      }
    }
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('keeps the 48px target independent from smaller visual dimensions', () => {
    expect(css).toContain('var(--m3e-comp-icon-button-minimum-interactive-target)')
    expect(css).toContain('var(--m3e-comp-icon-button-extra-small-container-height)')
    expect(css).toContain('var(--m3e-comp-icon-button-extra-small-container-width-narrow)')
  })

  it('uses size-aware resting, pressed, and selected shapes with semantic motion', () => {
    expect(css).toContain('[data-m3e-shape="square"]')
    expect(css).toContain('[data-m3e-selected="true"][data-m3e-shape="round"]')
    expect(css).toContain('[data-m3e-selected="true"][data-m3e-shape="square"]')
    expect(css).toContain(':active:not(:disabled)')
    expect(css).toContain('var(--m3e-icon-button-pressed-container-shape)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-default-effects-duration)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-default-effects-easing)')
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('transition: none')
  })

  it('covers focus, hover, pressed, disabled, selected, and forced-color states', () => {
    expect(css).toContain('.m3e-icon-button:disabled')
    expect(css).toContain('.m3e-icon-button:focus-visible')
    expect(css).toContain('var(--m3e-sys-state-hover)')
    expect(css).toContain('var(--m3e-sys-state-focus)')
    expect(css).toContain('var(--m3e-sys-state-pressed)')
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('background: Highlight')
    expect(css).toContain('color: GrayText')
  })

  it('uses logical sizing and leaves direction to native CSS direction', () => {
    expect(css).toContain('inline-size:')
    expect(css).toContain('block-size:')
    expect(css).not.toMatch(
      /^\s*(?:left|right|width|height|margin-left|margin-right|padding-left|padding-right)\s*:/m,
    )
  })
})

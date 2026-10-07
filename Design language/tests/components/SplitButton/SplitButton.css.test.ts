import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/SplitButton/SplitButton.css', import.meta.url)),
  'utf8',
)

describe('SplitButton stylesheet contract', () => {
  it('maps sourced color and geometry through stable component variables', () => {
    expect(css).toContain('var(--m3e-comp-split-button-filled-container-color)')
    expect(css).toContain('var(--m3e-comp-split-button-outer-corner)')
    expect(css).toContain('var(--m3e-comp-split-button-trailing-checked-shape)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('uses logical border-radius properties so shape mirrors correctly under RTL with no explicit RTL CSS', () => {
    expect(css).toContain('border-start-start-radius')
    expect(css).toContain('border-end-start-radius')
    expect(css).toContain('border-start-end-radius')
    expect(css).toContain('border-end-end-radius')
    expect(css).not.toMatch(/\[dir=["']?rtl["']?\]/)
  })

  it('expands each button\'s own inner corner independently on hover/press', () => {
    expect(css).toContain('--m3e-split-button-inner-corner-hover')
    expect(css).toContain('.m3e-split-button__leading:active:not(:disabled)')
    expect(css).toContain('.m3e-split-button__trailing:active:not(:disabled):not([data-m3e-selected="true"])')
  })

  it('defines all five sizes', () => {
    for (const size of ['extra-small', 'small', 'medium', 'large', 'extra-large']) {
      expect(css).toContain(`[data-m3e-size="${size}"]`)
    }
  })

  it('defines all four variants', () => {
    for (const variant of ['filled', 'tonal', 'elevated', 'outlined']) {
      expect(css).toContain(`[data-m3e-variant="${variant}"]`)
    }
  })

  it('becomes immediate under reduced motion', () => {
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('transition: none')
  })

  it('keeps every part visibly distinct in forced colors', () => {
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('ButtonText')
    expect(css).toContain('GrayText')
  })
})

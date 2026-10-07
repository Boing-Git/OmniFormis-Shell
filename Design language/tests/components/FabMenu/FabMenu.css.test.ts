import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/FabMenu/FabMenu.css', import.meta.url)),
  'utf8',
)

describe('FabMenu stylesheet contract', () => {
  it('maps sourced color and geometry through stable component variables', () => {
    expect(css).toContain('var(--m3e-comp-fab-menu-trigger-container-color-collapsed)')
    expect(css).toContain('var(--m3e-comp-fab-menu-trigger-container-color-expanded)')
    expect(css).toContain('var(--m3e-comp-fab-menu-trigger-shape-collapsed)')
    expect(css).toContain('var(--m3e-comp-fab-menu-trigger-shape-expanded)')
    expect(css).toContain('var(--m3e-comp-fab-menu-item-container-color)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('does not animate the trigger size between collapsed and expanded, only shape/color/icon-size', () => {
    expect(css).not.toMatch(/\.m3e-fab-menu__trigger\s*\{[^}]*\btransition:[^}]*\b(width|height|inline-size|block-size)\b/)
    expect(css).toContain('transition:')
    expect(css).toContain('border-radius')
  })

  it('stages each item slot with a per-item transition-delay set from the component', () => {
    expect(css).toContain('.m3e-fab-menu__item-slot')
    expect(css).toContain('transition-delay')
  })

  it('does not clip the item slot, which would cut the item elevation shadow to a rectangle', () => {
    // The slot is exactly the size of the item it wraps, and the item carries
    // `--m3e-comp-fab-menu-item-elevation`, which paints outside its border box
    // by definition. Any clipping here removes everything but the shadow's
    // corners, so a rounded item reads as a square halo. The reveal is scaleY
    // plus opacity on the slot itself, and the item scales with it, so no clip
    // is needed to stage the animation.
    const slotRule = css.match(/\.m3e-fab-menu__item-slot\s*\{([^}]*)\}/)?.[1] ?? ''
    expect(slotRule).not.toMatch(/overflow\s*:\s*(hidden|clip|auto|scroll)/)
  })

  it('cross-fades the trigger icon between collapsed and expanded state', () => {
    expect(css).toContain('[data-m3e-icon="default"]')
    expect(css).toContain('[data-m3e-icon="close"]')
  })

  it('becomes immediate under reduced motion', () => {
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('transition: none')
  })

  it('keeps every part visibly distinct in forced colors', () => {
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('ButtonText')
    expect(css).toContain('forced-color-adjust: none')
  })
})

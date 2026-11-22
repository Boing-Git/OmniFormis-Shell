import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/Radio/Radio.css', import.meta.url)),
  'utf8',
)

describe('Radio stylesheet contract', () => {
  it('maps sourced geometry through stable component variables', () => {
    expect(css).toContain('var(--m3e-comp-radio-container-size)')
    expect(css).toContain('var(--m3e-comp-radio-outline-width)')
    expect(css).toContain('var(--m3e-comp-radio-dot-size)')
    expect(css).toContain('var(--m3e-comp-radio-state-layer-size)')
    expect(css).toContain('var(--m3e-comp-radio-minimum-interactive-target)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('drives visual state from the native :checked/:disabled pseudo-classes, not a React-rendered attribute', () => {
    // A sibling radio in the same native `name` group can become unchecked
    // with no event firing on this element, so any styling keyed off a
    // React-rendered data attribute could go stale. `:checked` is always
    // live-accurate because the browser owns it.
    expect(css).toContain('.m3e-radio__input:checked ~ .m3e-radio__container')
    expect(css).toContain('.m3e-radio__input:disabled ~ .m3e-radio__container')
    expect(css).not.toMatch(/\[data-m3e-(?:state|disabled)=/)
    expect(css).toContain('var(--m3e-comp-radio-selected-icon-color)')
    expect(css).toContain('var(--m3e-comp-radio-unselected-icon-color)')
    expect(css).toContain('var(--m3e-comp-radio-disabled-selected-icon-color)')
    expect(css).toContain('var(--m3e-comp-radio-disabled-unselected-icon-color)')
    expect(css).toContain('color-mix(')
  })

  it('animates the dot scale unconditionally and snaps color while disabled', () => {
    expect(css).toContain('transform: scale(var(--m3e-radio-dot-scale))')
    expect(css).toContain('.m3e-radio__input:disabled ~ .m3e-radio__container {')
    expect(css).toContain('.m3e-radio__input:disabled ~ .m3e-radio__container .m3e-radio__dot')
  })

  it('uses semantic Expressive motion with an immediate reduced-motion outcome', () => {
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-spatial-duration)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-spatial-easing)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-default-effects-duration)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-effects-duration)')
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('transition: none')
  })

  it('exposes state layers and a visible focus ring', () => {
    expect(css).toContain('var(--m3e-sys-state-hover)')
    expect(css).toContain('var(--m3e-sys-state-focus)')
    expect(css).toContain('var(--m3e-sys-state-pressed)')
    expect(css).toContain(':focus-visible')
    expect(css).toContain('var(--m3e-comp-radio-focus-ring-color)')
    expect(css).toContain('var(--m3e-comp-radio-selected-state-layer-color)')
    expect(css).toContain('var(--m3e-comp-radio-unselected-state-layer-color)')
  })

  it('centers the oversized state layer with 50%/translate, not inset:0/margin:auto', () => {
    // `inset: 0; margin: auto;` only centers an absolutely positioned box
    // that is *larger* than its containing block on the block axis — per
    // CSS2.1 10.3.7, equal-and-negative auto margins on the inline axis
    // clamp to zero in LTR, so the box goes flush-start instead of
    // centering. The 40px state layer inside the 20px container hit this
    // exactly, rendering visibly off-center. 50%-offset + translate avoids
    // auto margins entirely.
    expect(css).toContain('inset-block-start: 50%')
    expect(css).toContain('inset-inline-start: 50%')
    expect(css).toContain('translate: -50% -50%')
  })

  it('uses logical layout and retains visible state in forced colors', () => {
    expect(css).toContain('inline-size:')
    expect(css).toContain('block-size:')
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('outline-color: Highlight')
    expect(css).toContain('GrayText')
    expect(css).not.toMatch(
      /^\s*(?:left|right|width|height|margin-left|margin-right|padding-left|padding-right)\s*:/m,
    )
  })
})

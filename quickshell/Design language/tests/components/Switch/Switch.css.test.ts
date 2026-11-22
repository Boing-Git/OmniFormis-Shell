import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/Switch/Switch.css', import.meta.url)),
  'utf8',
)

describe('Switch stylesheet contract', () => {
  it('maps sourced geometry through stable component variables', () => {
    expect(css).toContain('var(--m3e-comp-switch-track-width)')
    expect(css).toContain('var(--m3e-comp-switch-track-height)')
    expect(css).toContain('var(--m3e-comp-switch-track-outline-width)')
    expect(css).toContain('var(--m3e-comp-switch-unselected-handle-size)')
    expect(css).toContain('var(--m3e-comp-switch-selected-handle-size)')
    expect(css).toContain('var(--m3e-comp-switch-pressed-handle-size)')
    expect(css).toContain('var(--m3e-comp-switch-icon-size)')
    expect(css).toContain('var(--m3e-comp-switch-state-layer-size)')
    expect(css).toContain('var(--m3e-comp-switch-minimum-interactive-target)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('adapts every source outer-box offset to the bordered CSS padding-box origin', () => {
    // Resting positions subtract the border already consumed by the absolute
    // containing block, producing outer-box starts of 8px/4px/24px.
    expect(css).toMatch(
      /\(var\(--m3e-comp-switch-track-height\)\s*-\s*var\(--m3e-comp-switch-unselected-handle-size\)\)\s*\/\s*2\s*-\s*var\(--m3e-comp-switch-track-outline-width\)/,
    )
    expect(css).toMatch(
      /var\(--m3e-comp-switch-track-width\)\s*-\s*var\(--m3e-comp-switch-selected-handle-size\)[\s\S]*?\/\s*2\s*-\s*var\(--m3e-comp-switch-track-outline-width\)/,
    )
    // Pressed source offsets are 2px/22px in the outer box; from the padding
    // edge those become 0px/20px.
    expect(css).toContain('inset-inline-start: 0;')
    expect(css).toMatch(
      /var\(--m3e-comp-switch-track-width\)\s*-\s*var\(--m3e-comp-switch-pressed-handle-size\)\s*-\s*var\(--m3e-comp-switch-track-outline-width\)\s*-\s*var\(--m3e-comp-switch-track-outline-width\)/,
    )
  })

  it('forces the selected handle size whenever a thumb icon is present, independent of checked state', () => {
    expect(css).toContain('[data-m3e-has-thumb-icon="true"] .m3e-switch__thumb')
  })

  it('centers and constrains direct thumb artwork to the sourced 16px slot', () => {
    expect(css).toMatch(
      /\.m3e-switch__thumb-icon\s*{[\s\S]*?align-items:\s*center;[\s\S]*?block-size:\s*var\(--m3e-comp-switch-icon-size\);[\s\S]*?inline-size:\s*var\(--m3e-comp-switch-icon-size\);[\s\S]*?justify-content:\s*center;/,
    )
    expect(css).toContain('.m3e-switch__thumb-icon > .m3e-icon')
    expect(css).toContain('--m3e-icon-size: var(--m3e-comp-switch-icon-size);')
    expect(css).toContain('.m3e-switch__thumb-icon > svg')
    expect(css).toContain('.m3e-switch__thumb-icon > img')
  })

  it('drives visual state from the native :checked/:disabled/:active pseudo-classes, not a React-rendered attribute', () => {
    expect(css).toContain('.m3e-switch__input:checked ~ .m3e-switch__track')
    expect(css).toContain('.m3e-switch__input:disabled ~ .m3e-switch__track')
    expect(css).toContain('.m3e-switch__input:active:not(:disabled)')
    expect(css).not.toMatch(/\[data-m3e-(?:state|disabled)=/)
    expect(css).toContain('var(--m3e-comp-switch-selected-track-color)')
    expect(css).toContain('var(--m3e-comp-switch-unselected-track-color)')
    expect(css).toContain('var(--m3e-comp-switch-disabled-selected-track-color)')
    expect(css).toContain('var(--m3e-comp-switch-disabled-unselected-track-color)')
    expect(css).toContain('color-mix(')
  })

  it('snaps the press-driven size/offset transition and animates its release, matching the SnapSpec asymmetry', () => {
    expect(css).toContain('transition-duration: var(--m3e-sys-motion-expressive-default-effects-duration), 0s, 0s, 0s;')
  })

  it('uses semantic Expressive motion with an immediate reduced-motion outcome', () => {
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-spatial-duration)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-spatial-easing)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-default-effects-duration)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-effects-duration)')
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('transition: none')
  })

  it('exposes a thumb-anchored state layer and a visible focus ring', () => {
    expect(css).toContain('var(--m3e-sys-state-hover)')
    expect(css).toContain('var(--m3e-sys-state-focus)')
    expect(css).toContain('var(--m3e-sys-state-pressed)')
    expect(css).toContain(':focus-visible')
    expect(css).toContain('var(--m3e-comp-switch-focus-ring-color)')
    expect(css).toContain('var(--m3e-comp-switch-selected-state-layer-color)')
    expect(css).toContain('var(--m3e-comp-switch-unselected-state-layer-color)')
    expect(css).toContain('translate: -50% -50%;')
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

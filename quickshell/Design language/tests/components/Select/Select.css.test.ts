import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/Select/Select.css', import.meta.url)),
  'utf8',
)

describe('Select stylesheet contract', () => {
  it('registers no new component-token variables of its own — it reuses text-field and menu', () => {
    expect(css).not.toMatch(/var\(--m3e-comp-select-/)
  })

  it('rotates the chevron off the trigger input’s own aria-expanded attribute', () => {
    expect(css).toContain('.m3e-text-field__input[aria-expanded="true"]')
    expect(css).toContain('rotate(180deg)')
  })

  it('lifts the shared menu container’s intrinsic width bounds for a width-matched listbox', () => {
    expect(css).toContain('.m3e-menu.m3e-select__listbox')
    expect(css).toContain('max-inline-size: none')
    expect(css).toContain('min-inline-size: 0')
  })

  it('highlights the keyboard-active option using the shared state-layer opacity', () => {
    expect(css).toContain('[data-m3e-active="true"]')
    expect(css).toContain('var(--m3e-sys-state-focus)')
  })

  it('contains no hardcoded hex colors', () => {
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })
})

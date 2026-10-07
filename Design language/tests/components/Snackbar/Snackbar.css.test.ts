import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/Snackbar/Snackbar.css', import.meta.url)),
  'utf8',
)

describe('Snackbar stylesheet contract', () => {
  it('maps sourced container geometry and color through stable component variables', () => {
    expect(css).toContain('var(--m3e-comp-snackbar-container-color)')
    expect(css).toContain('var(--m3e-comp-snackbar-container-shape)')
    expect(css).toContain('var(--m3e-comp-snackbar-container-shadow)')
    expect(css).toContain('var(--m3e-comp-snackbar-action-label-color)')
    expect(css).toContain('var(--m3e-comp-snackbar-dismiss-icon-color)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('drives open state from a data attribute, not a native top-layer element', () => {
    expect(css).toContain('.m3e-snackbar[data-m3e-open="true"]')
    expect(css).toContain('opacity: 0')
    expect(css).toContain('opacity: 1')
    expect(css).not.toContain('@starting-style')
  })

  it('uses the shared state-layer system for hover/focus/pressed action/dismiss feedback', () => {
    expect(css).toContain('var(--m3e-sys-state-hover)')
    expect(css).toContain('var(--m3e-sys-state-focus)')
    expect(css).toContain('var(--m3e-sys-state-pressed)')
    expect(css).toContain('background: currentColor')
  })

  it('uses semantic Expressive fast motion with an immediate reduced-motion outcome', () => {
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-spatial-duration)')
    expect(css).toContain('var(--m3e-sys-motion-expressive-fast-effects-duration)')
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('transition: none')
  })

  it('uses logical layout and retains a visible boundary in forced colors', () => {
    expect(css).toContain('inset-block-end')
    expect(css).toContain('inset-inline-start')
    expect(css).toContain('padding-inline')
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('CanvasText')
    expect(css).not.toMatch(
      /^\s*(?:left|right|bottom|width|height|margin-left|margin-right|padding-left|padding-right)\s*:/m,
    )
  })
})

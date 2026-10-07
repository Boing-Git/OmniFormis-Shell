import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(
    new URL('../../../src/components/NavigationDrawer/NavigationDrawer.css', import.meta.url),
  ),
  'utf8',
)

describe('NavigationDrawer stylesheet contract', () => {
  it('maps sourced container/indicator geometry and color through stable component variables', () => {
    expect(css).toContain('var(--m3e-comp-navigation-drawer-modal-container-color)')
    expect(css).toContain('var(--m3e-comp-navigation-drawer-standard-container-color)')
    expect(css).toContain('var(--m3e-comp-navigation-drawer-item-active-indicator-color)')
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })

  it('drives the modal variant from the native [open] attribute, not a custom data attribute', () => {
    expect(css).toContain('[data-m3e-variant="modal"][open]')
    expect(css).toContain('@starting-style')
    expect(css).toContain('allow-discrete')
  })

  it('slides the modal variant via inset-inline-start, not a physical transform, for RTL correctness', () => {
    expect(css).toContain('inset-inline-start')
    expect(css).not.toContain('translateX')
  })

  it('collapses the dismissible variant in place via a data attribute', () => {
    expect(css).toContain('[data-m3e-variant="dismissible"][data-m3e-open="true"]')
  })

  it('gives the modal variant a backdrop scrim', () => {
    expect(css).toContain('::backdrop')
    expect(css).toContain('var(--m3e-comp-navigation-drawer-scrim-color)')
    expect(css).toContain('var(--m3e-comp-navigation-drawer-scrim-opacity)')
  })

  it('uses the shared state-layer system for hover/focus/pressed item feedback', () => {
    expect(css).toContain('var(--m3e-sys-state-hover)')
    expect(css).toContain('var(--m3e-sys-state-focus)')
    expect(css).toContain('var(--m3e-sys-state-pressed)')
  })

  it('registers a visible keyboard focus ring', () => {
    expect(css).toContain('.m3e-navigation-drawer__item:focus-visible')
    expect(css).toContain('var(--m3e-comp-navigation-drawer-item-focus-ring-color)')
  })

  it('dims a disabled item using color-mix against its own disabled opacity token', () => {
    expect(css).toContain('[aria-disabled="true"]')
    expect(css).toContain('color-mix(')
    expect(css).toContain('var(--m3e-comp-navigation-drawer-item-disabled-opacity)')
  })

  it('uses an immediate reduced-motion outcome', () => {
    expect(css).toContain('@media (prefers-reduced-motion: reduce)')
    expect(css).toContain('transition: none')
  })

  it('uses logical layout and retains a visible boundary in forced colors', () => {
    expect(css).toContain('inline-size')
    expect(css).toContain('padding-inline-start')
    expect(css).toContain('@media (forced-colors: active)')
    expect(css).toContain('CanvasText')
    expect(css).not.toMatch(
      /^\s*(?:left|right|width|height|margin-left|margin-right|padding-left|padding-right)\s*:/m,
    )
  })
})

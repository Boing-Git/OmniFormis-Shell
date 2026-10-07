import { renderToString } from 'react-dom/server'
import { Material3Provider, createTheme } from '../../src'

describe('Material3Provider server rendering', () => {
  it('renders deterministic markup from the configured system fallback', () => {
    const render = () =>
      renderToString(
        <Material3Provider systemModeFallback="dark">
          <span>server child</span>
        </Material3Provider>,
      )

    expect(render()).toBe(render())
    expect(render()).toContain('data-m3e-color-mode="system"')
    expect(render()).toContain('data-m3e-resolved-color-mode="dark"')
  })

  it('serializes only scoped custom-property differences', () => {
    const html = renderToString(
      <Material3Provider theme={createTheme({ density: { scale: -1 } })} colorMode="dark">
        custom
      </Material3Provider>,
    )
    expect(html).toContain('--m3e-sys-density-scale:-1')
    expect(html).not.toContain('--m3e-ref-palette-black')
  })

  it('omits initialization by default and applies a nonce when enabled', () => {
    expect(renderToString(<Material3Provider />)).not.toContain('<script')
    const html = renderToString(
      <Material3Provider preventColorSchemeFlash nonce="request-nonce" />,
    )
    expect(html).toContain('<script nonce="request-nonce">')
    expect(html).toContain('document.currentScript')
    expect(html).not.toContain('document.documentElement')
  })
})

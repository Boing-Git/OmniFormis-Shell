import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const css = readFileSync(
  fileURLToPath(new URL('../../../src/components/NavigationSuite/NavigationSuite.css', import.meta.url)),
  'utf8',
)

describe('NavigationSuite stylesheet contract', () => {
  it('imposes no layout opinion of its own — the wrapper stays invisible to the page layout', () => {
    expect(css).toContain('.m3e-navigation-suite')
    expect(css).toContain('display: contents')
  })

  it('defines no component tokens or colors of its own — it reuses the other three components entirely', () => {
    expect(css).not.toMatch(/--m3e-comp-navigation-suite-/)
    expect(css).not.toMatch(/#[0-9a-f]{3,8}/i)
  })
})

import { readFile } from 'node:fs/promises'
import path from 'node:path'
import { Icon, Surface, Text } from '@language-lit/material3-expressive'
import { getConformantComponents } from '../content/inventory'
import { repoRoot, docsRoot } from '../content/paths'
import { Ramp, RampRule } from '../ui/Ramp'
import { InstallCommand } from '../ui/InstallCommand'
import { LinkButton } from '../ui/LinkButton'
import { ThemeShowcase } from '../ui/ThemeShowcase'

/**
 * Every figure on this page is read from the repository at build time. A claim
 * the site makes is a claim the repository can be checked against.
 */
async function getFacts() {
  const [components, budgets, browsers, packageJson] = await Promise.all([
    getConformantComponents(),
    readFile(path.join(docsRoot, 'bundle-budgets.json'), 'utf8').then(JSON.parse),
    readFile(path.join(docsRoot, 'browser-support.json'), 'utf8').then(JSON.parse),
    readFile(path.join(repoRoot, 'package.json'), 'utf8').then(JSON.parse),
  ])

  const kilobytes = (bytes: number) => Math.round(bytes / 102.4) / 10

  return {
    componentCount: components.length,
    jsGzip: kilobytes(budgets.artifacts['dist/index.js'].baselineGzipBytes),
    cssGzip: kilobytes(budgets.artifacts['dist/styles.css'].baselineGzipBytes),
    runtimeDependencies: Object.keys(packageJson.dependencies ?? {}).length,
    entryPoints: Object.keys(packageJson.exports).length,
    browsers: browsers.browsers.map(
      (browser: { name: string; minimum: string }) =>
        `${browser.name} ${browser.minimum}`,
    ),
  }
}

export default async function HomePage() {
  const facts = await getFacts()

  return (
    <>
      <section className="hero">
        <div className="hero__grid">
          <div>
            <p className="hero__eyebrow">Material 3 Expressive · React 18 and 19</p>
            <Text as="h1" variant="displayLarge" emphasis="emphasized" className="hero__title">
              The design system, not a screenshot of it.
            </Text>
            <Text as="p" variant="bodyLarge" className="hero__lede">
              {facts.componentCount} conformant components with native web
              semantics, precompiled CSS, and typed theme and token APIs. No
              Tailwind, no runtime style injection, no dependencies.
            </Text>

            <InstallCommand command="npm install @language-lit/material3-expressive" />

            <div className="hero__actions">
              <LinkButton
                href="/docs/getting-started/"
                variant="filled"
                trailingIcon={<Icon source="arrow_forward" mirrored />}
              >
                Get started
              </LinkButton>
              <LinkButton href="/components/" variant="outlined">
                Browse components
              </LinkButton>
            </div>
          </div>

          <figure className="hero__figure">
            <Ramp />
            <figcaption className="hero__caption">
              <Text as="span" variant="bodyMedium">
                These are the tonal palettes this page is currently painted
                from. Change the source color in the theme menu and every
                component, surface, and code block moves with them.
              </Text>
            </figcaption>
          </figure>
        </div>
      </section>

      <section className="section section--tinted">
        <div className="section__inner">
          <div className="section__head">
            <Text as="h2" variant="headlineMedium" emphasis="emphasized">
              One source color, one validated theme
            </Text>
            <Text as="p" variant="bodyLarge" className="section__lede">
              Themes are created through a typed API and validated before they
              render — including role-pair contrast. A theme that would be
              unreadable is rejected rather than shipped.
            </Text>
          </div>
          <ThemeShowcase />
        </div>
      </section>

      <section className="section">
        <div className="section__inner">
          <div className="section__head">
            <Text as="h2" variant="headlineMedium" emphasis="emphasized">
              What you actually install
            </Text>
            <Text as="p" variant="bodyLarge" className="section__lede">
              Every number here is read from the repository at build time.
            </Text>
          </div>

          <div className="claims">
            <Surface as="article" color="surface-container-low" shape="large" className="claim">
              <span className="claim__value">{facts.runtimeDependencies}</span>
              <Text as="h3" variant="titleMedium">
                Runtime dependencies
              </Text>
              <Text as="p" variant="bodyMedium" className="claim__body">
                React and React DOM are peers. Nothing else ships.
              </Text>
            </Surface>

            <Surface as="article" color="surface-container-low" shape="large" className="claim">
              <span className="claim__value">{facts.jsGzip} kB</span>
              <Text as="h3" variant="titleMedium">
                JavaScript, gzipped
              </Text>
              <Text as="p" variant="bodyMedium" className="claim__body">
                Plus {facts.cssGzip} kB of precompiled CSS for the complete
                stylesheet. Both are budgeted in CI.
              </Text>
            </Surface>

            <Surface as="article" color="surface-container-low" shape="large" className="claim">
              <span className="claim__value">{facts.entryPoints}</span>
              <Text as="h3" variant="titleMedium">
                Entry points
              </Text>
              <Text as="p" variant="bodyMedium" className="claim__body">
                Components, <code>/theme</code>, <code>/tokens</code>, and{' '}
                <code>/styles.css</code>. The theme and token entries are
                React-free.
              </Text>
            </Surface>

            <Surface as="article" color="surface-container-low" shape="large" className="claim">
              <span className="claim__value">{facts.componentCount}</span>
              <Text as="h3" variant="titleMedium">
                Conformant components
              </Text>
              <Text as="p" variant="bodyMedium" className="claim__body">
                Counted from the inventory that gates the release. Anything
                unfinished is absent, not listed as partial.
              </Text>
            </Surface>
          </div>
        </div>
      </section>

      <section className="section section--tinted">
        <div className="section__inner">
          <RampRule />
          <div className="section__head" style={{ marginBlockStart: '2.5rem' }}>
            <Text as="h2" variant="headlineMedium" emphasis="emphasized">
              Built on the platform
            </Text>
            <Text as="p" variant="bodyLarge" className="section__lede">
              A button is a <code>&lt;button&gt;</code>. A dialog is a{' '}
              <code>&lt;dialog&gt;</code>. A checkbox is a real form control
              that submits. Focus, keyboard, RTL, reduced motion, and
              forced-colors behavior come from the browser wherever the browser
              already gets them right, and the deliberate exceptions are
              written down.
            </Text>
          </div>
          <div className="hero__actions">
            <LinkButton href="/docs/web-deviations/" variant="tonal" size="small">
              Read the web deviations
            </LinkButton>
            <LinkButton href="/docs/ssr/" variant="text" size="small">
              SSR and color mode
            </LinkButton>
          </div>
          <Text
            as="p"
            variant="bodySmall"
            style={{ marginBlockStart: '2rem', opacity: 0.8 }}
          >
            Supported browsers: {facts.browsers.join(', ')}.
          </Text>
        </div>
      </section>
    </>
  )
}

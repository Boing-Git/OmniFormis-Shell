import type { Metadata } from 'next'
import type { ReactNode } from 'react'
import { Roboto_Flex } from 'next/font/google'
import { readFile } from 'node:fs/promises'
import path from 'node:path'
import { SiteProviders } from './providers'
import { SiteBar } from '../ui/SiteBar'
import { buildSearchIndex } from '../content/search'
import { buildNavigationGroups } from '../content/navigation'
import { repoRoot } from '../content/paths'

// The library's complete stylesheet, imported once through its public entry —
// exactly the line the getting-started guide tells consumers to write.
import '@language-lit/material3-expressive/styles.css'
import './globals.css'

const siteUrl = 'https://m3e.language-lit.com'

/*
 * The library ships no fonts by design. The typeface tokens name Roboto without
 * providing it, so the site self-hosts it here; the Material Symbols subset is
 * declared in globals.css from a font this repository vendors. Neither costs
 * the published site a third-party request at runtime.
 */
const roboto = Roboto_Flex({
  subsets: ['latin'],
  display: 'swap',
  variable: '--site-font-sans',
})

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: 'Material 3 Expressive for React',
    template: '%s · Material 3 Expressive',
  },
  description:
    'A framework-neutral React implementation of Material 3 Expressive: 32 conformant components, typed theme and token APIs, native web semantics, and no runtime dependencies.',
  openGraph: {
    type: 'website',
    url: siteUrl,
    siteName: 'Material 3 Expressive for React',
  },
}

async function getVersion(): Promise<string> {
  const packageJson = JSON.parse(
    await readFile(path.join(repoRoot, 'package.json'), 'utf8'),
  )
  return packageJson.version as string
}

export default async function RootLayout({ children }: { children: ReactNode }) {
  const [version, index, groups] = await Promise.all([
    getVersion(),
    buildSearchIndex(),
    buildNavigationGroups(),
  ])

  return (
    <html lang="en" className={roboto.variable}>
      <body>
        <SiteProviders>
          <a href="#content" className="visually-hidden">
            Skip to content
          </a>
          <SiteBar version={version} index={index} groups={groups} />
          <div id="content">{children}</div>
          <footer className="footer">
            <div className="footer__inner">
              <span>
                MIT licensed. Material 3 Expressive is a Google design system;
                this is an independent implementation.
              </span>
              <nav className="footer__links" aria-label="Footer">
                <a href="https://github.com/romulloqueiroz/material3-expressive">
                  Repository
                </a>
                <a href="https://www.npmjs.com/package/@language-lit/material3-expressive">
                  npm
                </a>
                <a href="https://m3.material.io/">Material 3</a>
              </nav>
            </div>
          </footer>
        </SiteProviders>
      </body>
    </html>
  )
}

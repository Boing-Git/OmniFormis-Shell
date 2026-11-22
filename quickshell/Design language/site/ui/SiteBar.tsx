'use client'

import Link from 'next/link'
import { Icon } from '@language-lit/material3-expressive'
import type { SearchEntry } from '../content/search'
import type { NavigationGroup } from '../content/navigation'
import { MobileNav } from './MobileNav'
import { BrandMark } from './Ramp'
import { Search } from './Search'
import { ThemeControls } from './ThemeControls'

export function SiteBar({
  version,
  index,
  groups,
}: {
  version: string
  index: SearchEntry[]
  groups: NavigationGroup[]
}) {
  return (
    <header className="bar">
      <Link href="/" className="bar__brand">
        <BrandMark />
        <span className="bar__name">Material 3 Expressive</span>
        <span className="bar__version">v{version}</span>
      </Link>

      <nav className="bar__actions" aria-label="Site">
        <div className="bar__desktop-only" style={{ display: 'contents' }}>
          <Link href="/components/" className="sidebar__link">
            Components
          </Link>
          <Link href="/docs/getting-started/" className="sidebar__link">
            Guides
          </Link>
        </div>
        <Search index={index} />
        <MobileNav groups={groups} />
        <ThemeControls />
        {/* A link is an anchor. `IconButton` renders a native `<button>` by
            contract and deliberately offers no link mode, so navigation uses
            the platform element instead of a button that fakes one. */}
        <a
          className="sidebar__link"
          href="https://github.com/romulloqueiroz/material3-expressive"
          target="_blank"
          rel="noreferrer"
          aria-label="Open the repository on GitHub"
          style={{ display: 'grid', placeItems: 'center', inlineSize: '2.5rem', blockSize: '2.5rem' }}
        >
          <Icon source="code" />
        </a>
      </nav>
    </header>
  )
}

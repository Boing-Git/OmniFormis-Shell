import type { Metadata } from 'next'
import Link from 'next/link'
import { Surface, Text } from '@language-lit/material3-expressive'
import { docPages } from '../../content/docs'
import { DocsShell } from '../../ui/DocsShell'

export const metadata: Metadata = {
  title: 'Guides',
  description:
    'Installation, theming, server rendering, migration, and the deliberate web deviations.',
}

export default function DocsIndexPage() {
  return (
    <DocsShell>
      <div className="page-head">
        <span className="page-head__eyebrow">Guides</span>
        <Text as="h1" variant="displaySmall" emphasis="emphasized" className="page-head__title">
          Guides
        </Text>
        <Text as="p" variant="bodyLarge">
          Everything that is not a single component: how to install it, how to
          theme it, how it renders on a server, and where it deliberately
          differs from the platform APIs it implements.
        </Text>
      </div>

      <div className="catalog__grid">
        {docPages.map((page) => (
          <Surface key={page.slug} as="article" color="surface-container-low" shape="large">
            <Link href={`/docs/${page.slug}/`} className="catalog__card">
              <span className="catalog__name">{page.title}</span>
              <span className="claim__body" style={{ fontSize: '0.8125rem', lineHeight: 1.5 }}>
                {page.summary}
              </span>
            </Link>
          </Surface>
        ))}
      </div>
    </DocsShell>
  )
}

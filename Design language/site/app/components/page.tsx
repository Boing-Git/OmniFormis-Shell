import type { Metadata } from 'next'
import Link from 'next/link'
import { Surface, Text } from '@language-lit/material3-expressive'
import { getComponentsByKind, getConformantComponents } from '../../content/inventory'
import { DocsShell } from '../../ui/DocsShell'

export const metadata: Metadata = {
  title: 'Components',
  description:
    'Every conformant component in the package, grouped by role. Only components that pass the release gates appear here.',
}

export default async function ComponentsPage() {
  const [groups, all] = await Promise.all([
    getComponentsByKind(),
    getConformantComponents(),
  ])

  return (
    <DocsShell>
      <div className="page-head">
        <span className="page-head__eyebrow">Components</span>
        <Text as="h1" variant="displaySmall" emphasis="emphasized" className="page-head__title">
          {all.length} conformant components
        </Text>
        <Text as="p" variant="bodyLarge">
          A component appears here only after it passes the package's release
          gates. The list is generated from the same inventory that produces the
          supported-component matrix, so it cannot claim more than the library
          delivers.
        </Text>
      </div>

      <div className="catalog">
        {groups.map((group) => (
          <section key={group.kind} aria-labelledby={`kind-${group.kind}`}>
            <Text
              as="h2"
              id={`kind-${group.kind}`}
              variant="titleMedium"
              emphasis="emphasized"
              style={{ marginBlockEnd: '0.75rem' }}
            >
              {group.label}
            </Text>
            <div className="catalog__grid">
              {group.components.map((component) => (
                <Surface
                  key={component.name}
                  as="article"
                  color="surface-container-low"
                  shape="large"
                >
                  <Link href={`/components/${component.name}/`} className="catalog__card">
                    <span className="catalog__name">{component.name}</span>
                    <span className="catalog__meta">
                      {component.publicExports.length} exports
                      {component.dependencies.length > 0 &&
                        ` · builds on ${component.dependencies.join(', ')}`}
                    </span>
                  </Link>
                </Surface>
              ))}
            </div>
          </section>
        ))}
      </div>
    </DocsShell>
  )
}

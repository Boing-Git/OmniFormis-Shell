import type { Metadata } from 'next'
import { notFound } from 'next/navigation'
import { readFile } from 'node:fs/promises'
import path from 'node:path'
import { Text } from '@language-lit/material3-expressive'
import { getComponent, getConformantComponents } from '../../../content/inventory'
import { componentDocsRoot } from '../../../content/paths'
import { componentsWithoutExample, hasExample, readExampleSource } from '../../../content/examples'
import { highlight } from '../../../content/highlight'
import { renderMarkdown, stripLeadingHeading } from '../../../content/markdown'
import { DocsShell } from '../../../ui/DocsShell'
import { DemoFrame } from '../../../ui/DemoFrame'
import { Prose } from '../../../ui/Prose'

interface PageProps {
  params: Promise<{ component: string }>
}

/**
 * One route per conformant component, and no others. The inventory is the only
 * input, so a component cannot be documented into existence here.
 */
export async function generateStaticParams() {
  const components = await getConformantComponents()
  return components.map((component) => ({ component: component.name }))
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { component: name } = await params
  const component = await getComponent(name)
  if (!component) return {}
  return {
    title: component.name,
    description: `${component.name} — anatomy, variants, states, accessibility, and tokens in the Material 3 Expressive React package.`,
  }
}

export default async function ComponentPage({ params }: PageProps) {
  const { component: name } = await params
  const component = await getComponent(name)
  if (!component) notFound()

  const markdown = await readFile(
    path.join(componentDocsRoot, `${component.name}.md`),
    'utf8',
  )
  const { body } = stripLeadingHeading(markdown)
  const { html } = renderMarkdown(body)

  const demonstrated = await hasExample(component.name)
  const exampleSource = demonstrated ? await readExampleSource(component.name) : null

  return (
    <DocsShell>
      <article>
        <div className="page-head">
          <span className="page-head__eyebrow">
            {component.kind} · conformant
          </span>
          <Text
            as="h1"
            variant="displaySmall"
            emphasis="emphasized"
            className="page-head__title"
          >
            {component.name}
          </Text>
          <div className="page-head__exports">
            {component.publicExports.map((exported) => (
              <span key={exported} className="export-chip">
                {exported}
              </span>
            ))}
          </div>
        </div>

        {exampleSource ? (
          <DemoFrame
            component={component.name}
            source={exampleSource}
            sourceHtml={`<figure class="code"><pre class="code__pre"><code>${highlight(
              exampleSource,
              'tsx',
            )}</code></pre></figure>`}
          />
        ) : (
          <Text as="p" variant="bodyMedium" style={{ marginBlockEnd: '1.5rem' }}>
            {componentsWithoutExample[component.name]}
          </Text>
        )}

        <Prose html={html} />
      </article>
    </DocsShell>
  )
}

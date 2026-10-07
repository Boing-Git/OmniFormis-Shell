import type { Metadata } from 'next'
import { notFound } from 'next/navigation'
import { Text } from '@language-lit/material3-expressive'
import { docPages, getDocPage, readDocSource } from '../../../content/docs'
import { renderMarkdown, stripLeadingHeading } from '../../../content/markdown'
import { DocsShell } from '../../../ui/DocsShell'
import { Prose } from '../../../ui/Prose'

interface PageProps {
  params: Promise<{ slug: string }>
}

export async function generateStaticParams() {
  return docPages.map((page) => ({ slug: page.slug }))
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params
  const page = getDocPage(slug)
  if (!page) return {}
  return { title: page.title, description: page.summary }
}

export default async function DocPage({ params }: PageProps) {
  const { slug } = await params
  const page = getDocPage(slug)
  if (!page) notFound()

  const source = await readDocSource(page)
  const { title, body } = stripLeadingHeading(source)
  const { html } = renderMarkdown(body)

  return (
    <DocsShell>
      <article>
        <div className="page-head">
          <span className="page-head__eyebrow">Guide</span>
          <Text
            as="h1"
            variant="displaySmall"
            emphasis="emphasized"
            className="page-head__title"
          >
            {title ?? page.title}
          </Text>
          <Text as="p" variant="bodyLarge">
            {page.summary}
          </Text>
        </div>
        <Prose html={html} />
      </article>
    </DocsShell>
  )
}

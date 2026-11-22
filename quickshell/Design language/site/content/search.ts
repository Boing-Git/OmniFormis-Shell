import { readFile } from 'node:fs/promises'
import path from 'node:path'
import { getConformantComponents, kindLabels } from './inventory'
import { docPages } from './docs'
import { componentDocsRoot, docsRoot } from './paths'

export interface SearchEntry {
  title: string
  href: string
  group: string
  /** Lowercased haystack: title, exported symbol names, and a prose excerpt. */
  terms: string
  excerpt: string
}

/** The first paragraph of a Markdown document, flattened to plain text. */
function firstParagraph(source: string): string {
  const body = source.replace(/^#\s+.+\n+/, '')
  const paragraph = body.split(/\n\s*\n/).find((block) => {
    const trimmed = block.trim()
    return trimmed.length > 0 && !trimmed.startsWith('```') && !trimmed.startsWith('|')
  })
  return (paragraph ?? '')
    .replace(/`/g, '')
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
    .replace(/\s+/g, ' ')
    .trim()
}

/**
 * Builds the client search index at build time.
 *
 * A static export has no server to query, and the site takes no search
 * dependency, so the index ships as data and is filtered in the browser. It
 * stays small because it indexes titles, exported symbols, and one excerpt per
 * page rather than full document text.
 */
export async function buildSearchIndex(): Promise<SearchEntry[]> {
  const components = await getConformantComponents()

  const componentEntries = await Promise.all(
    components.map(async (component): Promise<SearchEntry> => {
      const source = await readFile(
        path.join(componentDocsRoot, `${component.name}.md`),
        'utf8',
      )
      const excerpt = firstParagraph(source)
      return {
        title: component.name,
        href: `/components/${component.name}/`,
        group: kindLabels[component.kind],
        terms: [component.name, ...component.publicExports, excerpt]
          .join(' ')
          .toLowerCase(),
        excerpt,
      }
    }),
  )

  const docEntries = await Promise.all(
    docPages.map(async (page): Promise<SearchEntry> => {
      const source = await readFile(path.join(docsRoot, page.file), 'utf8')
      const excerpt = page.summary || firstParagraph(source)
      return {
        title: page.title,
        href: `/docs/${page.slug}/`,
        group: 'Guides',
        terms: [page.title, page.summary, firstParagraph(source)].join(' ').toLowerCase(),
        excerpt,
      }
    }),
  )

  return [...docEntries, ...componentEntries]
}

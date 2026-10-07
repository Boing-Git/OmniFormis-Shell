import { readFile } from 'node:fs/promises'
import path from 'node:path'
import { docsRoot } from './paths'

export interface DocPage {
  slug: string
  file: string
  title: string
  summary: string
}

/**
 * The long-form documents published as site routes, in reading order.
 *
 * Contributor-facing documents — the specification, architecture, ADRs, release
 * readiness — are deliberately absent. They describe how the library is built
 * rather than how it is used, and they link to repository paths that have no
 * meaning on the site. `repositoryOnlyDocs` routes them to GitHub instead.
 */
export const docPages: readonly DocPage[] = [
  {
    slug: 'getting-started',
    file: 'GETTING_STARTED.md',
    title: 'Getting started',
    summary: 'Install the package, render a provider, and load the stylesheet.',
  },
  {
    slug: 'theming',
    file: 'THEMING.md',
    title: 'Theming',
    summary: 'Create themes, override tokens, and nest theme scopes.',
  },
  {
    slug: 'ssr',
    file: 'SSR.md',
    title: 'SSR and color mode',
    summary: 'Server rendering, hydration, and the system color-mode path.',
  },
  {
    slug: 'web-deviations',
    file: 'WEB_DEVIATIONS.md',
    title: 'Web deviations',
    summary: 'Where this implementation departs from the platform APIs, and why.',
  },
  {
    slug: 'migration',
    file: 'MIGRATION.md',
    title: 'Migrating from 0.3',
    summary: 'The 0.3 to 1.0 API, token, and stylesheet moves.',
  },
  {
    slug: 'release-notes',
    file: 'RELEASE_NOTES.md',
    title: 'Release notes',
    summary: 'Versioned changes and breaking changes.',
  },
]

const repositoryBlob =
  'https://github.com/romulloqueiroz/material3-expressive/blob/main/docs'

/** Documents that stay in the repository; links to them leave the site. */
const repositoryOnlyDocs: Record<string, string> = {
  'ARCHITECTURE.md': `${repositoryBlob}/ARCHITECTURE.md`,
  'SPEC.md': `${repositoryBlob}/SPEC.md`,
  'RELEASE_READINESS.md': `${repositoryBlob}/RELEASE_READINESS.md`,
  'TOKEN_PROVENANCE.md': `${repositoryBlob}/TOKEN_PROVENANCE.md`,
  'BROWSER_SUPPORT.md': `${repositoryBlob}/BROWSER_SUPPORT.md`,
}

/**
 * Rewrites a repository-relative Markdown link to its site route. Returns null
 * when the target has no site route and no repository fallback, so the caller
 * can fail rather than emit a link that 404s on the published site.
 */
export function resolveDocLink(href: string): string | null {
  if (/^(https?:)?\/\//.test(href) || href.startsWith('#')) return href

  const [target, hash = ''] = href.split('#')
  const suffix = hash ? `#${hash}` : ''
  const file = path.basename(target)

  if (file === 'SUPPORTED_COMPONENTS.md') return `/components/${suffix}`
  if (file === 'README.md') return `/docs/${suffix}`

  const page = docPages.find((candidate) => candidate.file === file)
  if (page) return `/docs/${page.slug}/${suffix}`

  if (target.startsWith('components/') || target.includes('/components/')) {
    const component = path.basename(target, '.md')
    return `/components/${component}/${suffix}`
  }

  const repositoryDoc = repositoryOnlyDocs[file]
  if (repositoryDoc) return `${repositoryDoc}${suffix}`

  return null
}

export function getDocPage(slug: string): DocPage | undefined {
  return docPages.find((page) => page.slug === slug)
}

export async function readDocSource(page: DocPage): Promise<string> {
  return readFile(path.join(docsRoot, page.file), 'utf8')
}

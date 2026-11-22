import { Marked, type Tokens } from 'marked'
import { escapeHtml, highlight } from './highlight'
import { resolveDocLink } from './docs'

export interface Heading {
  id: string
  depth: number
  text: string
}

export interface RenderedMarkdown {
  html: string
  headings: Heading[]
}

export function slugify(value: string): string {
  return value
    .toLowerCase()
    .replace(/`/g, '')
    .replace(/[^\w\s-]/g, '')
    .trim()
    .replace(/\s+/g, '-')
}

/** Strips the leading `# Title` so a page can render its own heading. */
export function stripLeadingHeading(source: string): { title: string | null; body: string } {
  const match = source.match(/^#\s+(.+)\n+/)
  if (!match) return { title: null, body: source }
  return { title: match[1].trim(), body: source.slice(match[0].length) }
}

export function renderMarkdown(source: string): RenderedMarkdown {
  const headings: Heading[] = []
  const used = new Map<string, number>()
  // A link the repository can resolve but the site cannot is a real defect —
  // it would ship as a 404. Collect them and throw once, with every bad target
  // named, rather than failing on the first.
  const unresolved: string[] = []

  const marked = new Marked({ gfm: true })

  marked.use({
    renderer: {
      code({ text, lang }: Tokens.Code) {
        const language = (lang || 'tsx').trim().split(/\s+/)[0]
        return (
          `<figure class="code" data-language="${escapeHtml(language)}">` +
          `<pre class="code__pre"><code>${highlight(text, language)}</code></pre>` +
          `</figure>`
        )
      },

      heading({ tokens, depth }: Tokens.Heading) {
        const text = this.parser.parseInline(tokens)
        const plain = text.replace(/<[^>]+>/g, '')
        const base = slugify(plain)
        const seen = used.get(base) ?? 0
        used.set(base, seen + 1)
        const id = seen === 0 ? base : `${base}-${seen}`
        headings.push({ id, depth, text: plain })
        return `<h${depth} id="${id}" class="prose__heading">${text}</h${depth}>`
      },

      link({ href, title, tokens }: Tokens.Link) {
        const text = this.parser.parseInline(tokens)
        const resolved = resolveDocLink(href)
        if (resolved === null) {
          unresolved.push(href)
          return text
        }
        const external = /^https?:/.test(resolved)
        const attributes = [
          `href="${escapeHtml(resolved)}"`,
          title ? `title="${escapeHtml(title)}"` : '',
          external ? 'target="_blank" rel="noreferrer"' : '',
        ]
          .filter(Boolean)
          .join(' ')
        return `<a ${attributes}>${text}</a>`
      },

      table(token: Tokens.Table) {
        const head = token.header
          .map((cell) => `<th>${this.parser.parseInline(cell.tokens)}</th>`)
          .join('')
        const body = token.rows
          .map(
            (row) =>
              `<tr>${row
                .map((cell) => `<td>${this.parser.parseInline(cell.tokens)}</td>`)
                .join('')}</tr>`,
          )
          .join('')
        // Wide tables must scroll inside their own container rather than
        // widening the page.
        return (
          `<div class="prose__table-scroll"><table class="prose__table">` +
          `<thead><tr>${head}</tr></thead><tbody>${body}</tbody></table></div>`
        )
      },
    },
  })

  const html = marked.parse(source, { async: false }) as string

  if (unresolved.length > 0) {
    throw new Error(
      `Markdown links have no site route: ${[...new Set(unresolved)].join(', ')}. ` +
        'Add a mapping in site/content/docs.ts or change the link.',
    )
  }

  return { html, headings }
}

/**
 * A small TSX/CSS/shell tokenizer used at build time.
 *
 * The site deliberately does not depend on a syntax-highlighting library. Its
 * code colors are Material system color roles, so a code block re-themes with
 * the rest of the page when the theme panel changes the token custom
 * properties. A foreign highlighter theme would be the one region of the site
 * that ignores the design system it documents.
 *
 * This is a presentation tokenizer, not a parser. It is allowed to be
 * approximate; it is not allowed to lose or reorder source text. `tokenize`
 * always emits tokens whose concatenated values equal the input exactly.
 */

export type TokenType =
  | 'plain'
  | 'comment'
  | 'string'
  | 'keyword'
  | 'entity'
  | 'number'
  | 'attr'
  | 'punct'

export interface Token {
  type: TokenType
  value: string
}

const keywords = new Set([
  'as', 'async', 'await', 'break', 'case', 'catch', 'class', 'const', 'continue',
  'default', 'delete', 'do', 'else', 'export', 'extends', 'false', 'finally',
  'for', 'from', 'function', 'if', 'implements', 'import', 'in', 'instanceof',
  'interface', 'let', 'new', 'null', 'of', 'readonly', 'return', 'satisfies',
  'static', 'switch', 'this', 'throw', 'true', 'try', 'type', 'typeof',
  'undefined', 'var', 'void', 'while', 'yield',
])

const scanner = new RegExp(
  [
    '(?<comment>\\/\\/[^\\n]*|\\/\\*[\\s\\S]*?\\*\\/)',
    '(?<string>`(?:\\\\.|[^`\\\\])*`|\'(?:\\\\.|[^\'\\\\\\n])*\'|"(?:\\\\.|[^"\\\\\\n])*")',
    '(?<number>\\b\\d[\\w.]*)',
    '(?<ident>[A-Za-z_$][\\w$]*)',
    '(?<space>\\s+)',
    '(?<punct>[^\\s\\w$])',
  ].join('|'),
  'gy',
)

export function tokenize(source: string): Token[] {
  const tokens: Token[] = []
  // Tracks whether the scanner is between `<Tag` and its closing `>`, which is
  // the only place an identifier should be colored as a JSX attribute. Brace
  // depth excludes expression values like `onClick={handler}`, whose contents
  // are ordinary code rather than attribute names.
  let inTag = false
  let expectTagName = false
  let braceDepth = 0
  scanner.lastIndex = 0

  const push = (type: TokenType, value: string) => {
    const previous = tokens[tokens.length - 1]
    if (previous && previous.type === type) previous.value += value
    else tokens.push({ type, value })
  }

  let match: RegExpExecArray | null
  while ((match = scanner.exec(source))) {
    const groups = match.groups as Record<string, string | undefined>

    if (groups.comment !== undefined) {
      push('comment', groups.comment)
      continue
    }
    if (groups.string !== undefined) {
      push('string', groups.string)
      continue
    }
    if (groups.number !== undefined) {
      push('number', groups.number)
      continue
    }
    if (groups.space !== undefined) {
      push('plain', groups.space)
      continue
    }

    if (groups.ident !== undefined) {
      const identifier = groups.ident
      if (expectTagName) {
        expectTagName = false
        // Lowercase tag names are intrinsic elements; both read as the entity
        // being rendered, so both take the entity color.
        push('entity', identifier)
        continue
      }
      if (keywords.has(identifier)) push('keyword', identifier)
      else if (inTag && braceDepth === 0) push('attr', identifier)
      else if (/^[A-Z]/.test(identifier)) push('entity', identifier)
      else push('plain', identifier)
      continue
    }

    const punctuation = groups.punct as string
    if (punctuation === '<') {
      // `<` opens a tag only when an identifier follows it directly. Anything
      // else is a comparison or a generic parameter list.
      const next = source[scanner.lastIndex]
      if (next && /[A-Za-z_$>]/.test(next)) {
        inTag = true
        expectTagName = next !== '>'
      }
    } else if (punctuation === '{' && inTag) {
      braceDepth += 1
    } else if (punctuation === '}' && inTag && braceDepth > 0) {
      braceDepth -= 1
    } else if (punctuation === '>' && braceDepth === 0) {
      inTag = false
      expectTagName = false
    }
    push('punct', punctuation)
  }

  return tokens
}

const escapes: Record<string, string> = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;',
}

export function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, (character) => escapes[character])
}

/**
 * Renders source to HTML spans. Plain tokens are emitted as bare text so a
 * typical code block is mostly unwrapped text rather than a span per word.
 */
export function highlight(source: string, language = 'tsx'): string {
  if (language === 'bash' || language === 'sh' || language === 'shell') {
    return highlightShell(source)
  }
  return tokenize(source)
    .map((token) =>
      token.type === 'plain'
        ? escapeHtml(token.value)
        : `<span class="tok tok--${token.type}">${escapeHtml(token.value)}</span>`,
    )
    .join('')
}

/** Shell blocks are almost always an install line; only comments and the
 * leading command word carry meaning worth coloring. */
function highlightShell(source: string): string {
  return source
    .split('\n')
    .map((line) => {
      const comment = line.match(/^(\s*)(#.*)$/)
      if (comment) {
        return `${escapeHtml(comment[1])}<span class="tok tok--comment">${escapeHtml(comment[2])}</span>`
      }
      const command = line.match(/^(\s*)([\w.-]+)(.*)$/)
      if (!command) return escapeHtml(line)
      return (
        escapeHtml(command[1]) +
        `<span class="tok tok--keyword">${escapeHtml(command[2])}</span>` +
        escapeHtml(command[3])
      )
    })
    .join('\n')
}

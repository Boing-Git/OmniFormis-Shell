'use client'

import { useEffect, useMemo, useState } from 'react'
import { useRouter } from 'next/navigation'
import { Dialog, Icon, IconButton, Text, TextField } from '@language-lit/material3-expressive'
import type { SearchEntry } from '../content/search'

function rank(entry: SearchEntry, query: string): number {
  const title = entry.title.toLowerCase()
  if (title === query) return 0
  if (title.startsWith(query)) return 1
  if (title.includes(query)) return 2
  if (entry.terms.includes(query)) return 3
  return Number.POSITIVE_INFINITY
}

export function Search({ index }: { index: SearchEntry[] }) {
  const router = useRouter()
  const [open, setOpen] = useState(false)
  const [query, setQuery] = useState('')

  // `/` is the conventional docs shortcut. It must not fire while the visitor
  // is typing somewhere else.
  useEffect(() => {
    function onKeyDown(event: KeyboardEvent) {
      const target = event.target as HTMLElement | null
      const typing =
        target?.tagName === 'INPUT' ||
        target?.tagName === 'TEXTAREA' ||
        target?.isContentEditable
      if (event.key === '/' && !typing) {
        event.preventDefault()
        setOpen(true)
      }
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [])

  const results = useMemo(() => {
    const normalized = query.trim().toLowerCase()
    if (!normalized) return index.slice(0, 8)
    return index
      .map((entry) => ({ entry, score: rank(entry, normalized) }))
      .filter((scored) => Number.isFinite(scored.score))
      .sort((left, right) => left.score - right.score || left.entry.title.localeCompare(right.entry.title))
      .slice(0, 10)
      .map((scored) => scored.entry)
  }, [index, query])

  function go(href: string) {
    setOpen(false)
    setQuery('')
    router.push(href)
  }

  return (
    <>
      <IconButton
        aria-label="Search documentation"
        variant="standard"
        onClick={() => setOpen(true)}
      >
        <Icon source="search" />
      </IconButton>

      <Dialog open={open} onOpenChange={setOpen} title="Search">
        <div className="stack">
          <TextField
            variant="outlined"
            label="Search components and guides"
            value={query}
            autoFocus
            leadingIcon={<Icon source="search" />}
            onChange={(event) => setQuery(event.currentTarget.value)}
            onKeyDown={(event) => {
              if (event.key === 'Enter' && results[0]) {
                event.preventDefault()
                go(results[0].href)
              }
            }}
          />

          {results.length === 0 ? (
            <Text as="p" variant="bodyMedium">
              Nothing matches “{query.trim()}”. Try a component name such as
              Button, or a topic such as theming.
            </Text>
          ) : (
            <ul className="sidebar__list" style={{ gap: '0.25rem' }}>
              {results.map((entry) => (
                <li key={entry.href}>
                  <a
                    className="sidebar__link"
                    href={entry.href}
                    onClick={(event) => {
                      event.preventDefault()
                      go(entry.href)
                    }}
                  >
                    <span style={{ display: 'flex', justifyContent: 'space-between', gap: '1rem' }}>
                      <strong>{entry.title}</strong>
                      <span className="catalog__meta">{entry.group}</span>
                    </span>
                  </a>
                </li>
              ))}
            </ul>
          )}
        </div>
      </Dialog>
    </>
  )
}

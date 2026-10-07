'use client'

import { useId, useState } from 'react'
import { Button, Icon } from '@language-lit/material3-expressive'
import { getDemo } from '../demos/registry'
// The playground's own example styles. Reused rather than reimplemented so a
// demo looks the same here as it does in the workbench the components are
// developed against.
import '../../playground/src/playground.css'

export function DemoFrame({
  component,
  sourceHtml,
  source,
}: {
  component: string
  sourceHtml: string
  source: string
}) {
  const [showSource, setShowSource] = useState(false)
  const [copied, setCopied] = useState(false)
  const sourceId = useId()
  const Demo = getDemo(component)

  if (!Demo) return null

  async function copy() {
    try {
      await navigator.clipboard.writeText(source)
      setCopied(true)
      window.setTimeout(() => setCopied(false), 2000)
    } catch {
      setCopied(false)
    }
  }

  return (
    <div className="demo">
      <div className="demo__stage">
        <Demo />
      </div>

      <div className="demo__bar">
        <span className="demo__label">
          playground/examples/{component}.example.tsx
        </span>
        <span style={{ display: 'flex', gap: '0.25rem' }}>
          <Button
            variant="text"
            size="extra-small"
            aria-expanded={showSource}
            aria-controls={sourceId}
            leadingIcon={<Icon source={showSource ? 'expand_less' : 'code'} />}
            onClick={() => setShowSource((current) => !current)}
          >
            {showSource ? 'Hide code' : 'Show code'}
          </Button>
          <Button
            variant="text"
            size="extra-small"
            leadingIcon={<Icon source={copied ? 'check' : 'content_copy'} />}
            onClick={copy}
          >
            {copied ? 'Copied' : 'Copy'}
          </Button>
        </span>
      </div>

      <div className="demo__source" id={sourceId} hidden={!showSource}>
        <div dangerouslySetInnerHTML={{ __html: sourceHtml }} />
      </div>
    </div>
  )
}

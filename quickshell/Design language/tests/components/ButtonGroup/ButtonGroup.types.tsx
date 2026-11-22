import { createRef } from 'react'
import { Button } from '../../../src/components/Button'
import { ButtonGroup } from '../../../src/components/ButtonGroup'

const ref = createRef<HTMLDivElement>()

;<ButtonGroup ref={ref} aria-label="Actions">
  <Button>One</Button>
</ButtonGroup>

;<ButtonGroup aria-label="Actions" role="toolbar">
  <Button>One</Button>
  <Button>Two</Button>
</ButtonGroup>

// @ts-expect-error ButtonGroup requires children
;<ButtonGroup aria-label="Actions" />

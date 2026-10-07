// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import { createRef } from 'react'
import { afterEach } from 'vitest'
import { Button } from '../../../src/components/Button'
import { ButtonGroup } from '../../../src/components/ButtonGroup'

afterEach(cleanup)

describe('ButtonGroup', () => {
  it('renders children in a group role', () => {
    render(
      <ButtonGroup aria-label="Formatting">
        <Button>Bold</Button>
        <Button>Italic</Button>
      </ButtonGroup>,
    )
    const group = screen.getByRole('group', { name: 'Formatting' })
    expect(group.getAttribute('class')).toBe('m3e-button-group')
    expect(screen.getByRole('button', { name: 'Bold' })).not.toBeNull()
    expect(screen.getByRole('button', { name: 'Italic' })).not.toBeNull()
  })

  it('allows the role to be overridden by the consumer', () => {
    render(
      <ButtonGroup role="toolbar" aria-label="Actions">
        <Button>One</Button>
      </ButtonGroup>,
    )
    expect(screen.getByRole('toolbar', { name: 'Actions' })).not.toBeNull()
  })

  it('forwards ref, className, and style to the root', () => {
    const ref = createRef<HTMLDivElement>()
    render(
      <ButtonGroup
        ref={ref}
        aria-label="Actions"
        className="consumer-class"
        data-owner="consumer"
      >
        <Button>One</Button>
      </ButtonGroup>,
    )
    expect(ref.current?.getAttribute('role')).toBe('group')
    expect(ref.current?.className).toContain('m3e-button-group')
    expect(ref.current?.className).toContain('consumer-class')
    expect(ref.current?.getAttribute('data-owner')).toBe('consumer')
  })

  it('renders an arbitrary number of children directly, with no wrapper per item', () => {
    render(
      <ButtonGroup aria-label="Actions">
        <Button>One</Button>
        <Button>Two</Button>
        <Button>Three</Button>
      </ButtonGroup>,
    )
    const group = screen.getByRole('group', { name: 'Actions' })
    expect(group.children).toHaveLength(3)
    for (const child of Array.from(group.children)) {
      expect(child.className).toContain('m3e-button')
    }
  })

  it('exposes a stable component name for React tooling', () => {
    expect(ButtonGroup.displayName).toBe('ButtonGroup')
  })
})

// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach } from 'vitest'
import { Button } from '../../../src/components/Button'
import { ButtonGroup } from '../../../src/components/ButtonGroup'

afterEach(cleanup)

describe('ButtonGroup accessibility', () => {
  it('supports aria-label for the group as a whole', () => {
    render(
      <ButtonGroup aria-label="Text formatting">
        <Button>Bold</Button>
      </ButtonGroup>,
    )
    expect(screen.getByRole('group', { name: 'Text formatting' })).not.toBeNull()
  })

  it('supports aria-labelledby as an alternative accessible name', () => {
    render(
      <>
        <h2 id="group-heading">Text formatting</h2>
        <ButtonGroup aria-labelledby="group-heading">
          <Button>Bold</Button>
        </ButtonGroup>
      </>,
    )
    expect(screen.getByRole('group', { name: 'Text formatting' })).not.toBeNull()
  })

  it('keeps every child independently focusable and clickable via native tab order', async () => {
    const user = userEvent.setup()
    render(
      <ButtonGroup aria-label="Actions">
        <Button>One</Button>
        <Button>Two</Button>
      </ButtonGroup>,
    )
    await user.tab()
    expect(document.activeElement).toBe(screen.getByRole('button', { name: 'One' }))
    await user.tab()
    expect(document.activeElement).toBe(screen.getByRole('button', { name: 'Two' }))
  })

  it('keeps the group readable inside an RTL scope', () => {
    render(
      <div dir="rtl">
        <ButtonGroup aria-label="Actions">
          <Button>One</Button>
          <Button>Two</Button>
        </ButtonGroup>
      </div>,
    )
    expect(screen.getByRole('group', { name: 'Actions' })).not.toBeNull()
  })
})

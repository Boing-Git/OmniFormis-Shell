// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createElement, createRef, type ComponentType } from 'react'
import { afterEach, vi } from 'vitest'
import {
  Card,
  type CardElement,
  type CardVariant,
} from '../../../src/components/Card'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('Card', () => {
  it('renders a passive filled article by default', () => {
    render(<Card data-testid="card">Account summary</Card>)
    const card = screen.getByTestId('card')

    expect(card.tagName).toBe('ARTICLE')
    expect(card.getAttribute('class')).toBe('m3e-card')
    expect(card.getAttribute('data-m3e-variant')).toBe('filled')
    expect(card.getAttribute('data-m3e-interactive')).toBe('false')
    expect(card.hasAttribute('data-m3e-disabled')).toBe(false)
    expect(card.hasAttribute('role')).toBe(false)
    expect(card.hasAttribute('tabindex')).toBe(false)
    expect(card.querySelector('.m3e-card__content')?.tagName).toBe('DIV')
  })

  it.each(['filled', 'elevated', 'outlined'] satisfies readonly CardVariant[])(
    'serializes the %s variant through one stable attribute',
    (variant) => {
      render(<Card variant={variant}>{variant}</Card>)
      expect(
        screen.getByText(variant).closest('.m3e-card')?.getAttribute('data-m3e-variant'),
      ).toBe(variant)
      cleanup()
    },
  )

  it.each(['article', 'div', 'section', 'aside'] satisfies readonly CardElement[])(
    'supports the passive %s semantic element without inferred behavior',
    (element) => {
      const { container, unmount } = render(<Card as={element}>{element}</Card>)
      expect(container.firstElementChild?.tagName.toLowerCase()).toBe(element)
      expect(container.firstElementChild?.hasAttribute('tabindex')).toBe(false)
      unmount()
    },
  )

  it('preserves passive native props, styling, pointer observation, and the selected ref', async () => {
    const user = userEvent.setup()
    const ref = createRef<HTMLElementTagNameMap['section']>()
    const onPointerEnter = vi.fn()
    render(
      <Card
        as="section"
        ref={ref}
        aria-labelledby="summary-title"
        data-owner="consumer"
        className="summary-card"
        style={{ padding: 16 }}
        onPointerEnter={onPointerEnter}
      >
        Summary
      </Card>,
    )
    const card = screen.getByText('Summary').closest('section')

    if (!card) throw new Error('Expected section card')
    await user.hover(card)
    expect(onPointerEnter).toHaveBeenCalledTimes(1)
    expect(ref.current).toBe(card)
    expect(card.getAttribute('aria-labelledby')).toBe('summary-title')
    expect(card.getAttribute('data-owner')).toBe('consumer')
    expect(card.getAttribute('class')).toBe('m3e-card summary-card')
    expect(card.getAttribute('style')).toContain('padding: 16px')
  })

  it('renders interactive mode as a safe native button with a phrasing-content wrapper', () => {
    const ref = createRef<HTMLButtonElement>()
    render(
      <Card interactive ref={ref} variant="elevated" aria-describedby="card-help">
        <span>Open lesson</span>
      </Card>,
    )
    const button = screen.getByRole('button', { name: 'Open lesson' })

    expect(button).toBeInstanceOf(HTMLButtonElement)
    expect(ref.current).toBe(button)
    expect(button.getAttribute('type')).toBe('button')
    expect(button.getAttribute('aria-describedby')).toBe('card-help')
    expect(button.getAttribute('data-m3e-interactive')).toBe('true')
    expect(button.getAttribute('data-m3e-disabled')).toBe('false')
    expect(button.hasAttribute('aria-pressed')).toBe(false)
    expect(button.querySelector('.m3e-card__content')?.tagName).toBe('SPAN')
  })

  it('preserves native form attributes and keeps submission opt-in', async () => {
    const user = userEvent.setup()
    const onSubmit = vi.fn((event: React.FormEvent) => event.preventDefault())
    render(
      <form id="lesson-form" onSubmit={onSubmit}>
        <Card interactive name="intent" value="preview" form="lesson-form">
          Preview
        </Card>
        <Card interactive type="submit" name="intent" value="publish" form="lesson-form">
          Publish
        </Card>
      </form>,
    )

    const preview = screen.getByRole('button', { name: 'Preview' })
    expect(preview.getAttribute('name')).toBe('intent')
    expect(preview.getAttribute('value')).toBe('preview')
    expect(preview.getAttribute('form')).toBe('lesson-form')
    await user.click(preview)
    expect(onSubmit).not.toHaveBeenCalled()
    await user.click(screen.getByRole('button', { name: 'Publish' }))
    expect(onSubmit).toHaveBeenCalledTimes(1)
  })

  it('uses native disabled behavior and does not dispatch activation', async () => {
    const user = userEvent.setup()
    const onClick = vi.fn()
    render(
      <Card interactive disabled onClick={onClick}>
        Unavailable
      </Card>,
    )
    const button = screen.getByRole('button', { name: 'Unavailable' })

    await user.click(button)
    expect(onClick).not.toHaveBeenCalled()
    expect((button as HTMLButtonElement).disabled).toBe(true)
    expect(button.getAttribute('data-m3e-disabled')).toBe('true')
  })

  it('warns and discards interactive-only props supplied to passive mode at runtime', () => {
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    const UntypedCard = Card as ComponentType<Record<string, unknown>>
    render(
      createElement(
        UntypedCard,
        { onClick: vi.fn(), disabled: true, type: 'submit' },
        'Passive',
      ),
    )
    const card = screen.getByText('Passive').closest('article')

    expect(warning).toHaveBeenCalledWith(
      'Card: button, focus, and activation props require interactive={true}; passive cards discard them.',
    )
    expect(card?.hasAttribute('disabled')).toBe(false)
    expect(card?.hasAttribute('type')).toBe(false)
  })

  it('warns for invalid button content and unsupported toggle semantics', () => {
    const warning = vi.spyOn(console, 'warn').mockImplementation(() => undefined)
    const UntypedCard = Card as ComponentType<Record<string, unknown>>
    render(
      createElement(
        UntypedCard,
        { interactive: true, 'aria-pressed': true },
        createElement('div', null, createElement('a', { href: '/lesson' }, 'Lesson')),
      ),
    )

    expect(warning).toHaveBeenCalledWith(
      'Card: Card does not own toggle state; remove aria-pressed and use a dedicated selection control.',
    )
    expect(warning).toHaveBeenCalledWith(
      'Card: interactive card children must be phrasing content without links, controls, focusable descendants, or block elements. Use a passive Card when content owns nested actions or rich structure.',
    )
    expect(document.querySelector('.m3e-card')?.hasAttribute('aria-pressed')).toBe(false)
  })

  it('exposes a stable component name for React tooling', () => {
    expect(Card.displayName).toBe('Card')
  })
})

// @vitest-environment jsdom

import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createRef } from 'react'
import { afterEach, vi } from 'vitest'
import { TextArea } from '../../../src/components/TextArea'

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

describe('TextArea', () => {
  it('renders one native multiline control associated with its label', () => {
    render(<TextArea label="Feedback" />)
    const control = screen.getByLabelText('Feedback')
    const root = control.closest('.m3e-text-field')

    expect(control).toBeInstanceOf(HTMLTextAreaElement)
    expect(root?.getAttribute('data-m3e-variant')).toBe('filled')
    expect(root?.getAttribute('data-m3e-multiline')).toBe('true')
    expect(root?.querySelector('.m3e-text-field__indicator')).not.toBeNull()
  })

  it('renders the outlined variant with a notched border', () => {
    render(<TextArea variant="outlined" label="Notes" />)
    const root = screen.getByLabelText('Notes').closest('.m3e-text-field')
    const outline = root?.querySelector('.m3e-text-field__outline')

    expect(root?.getAttribute('data-m3e-variant')).toBe('outlined')
    expect(outline?.querySelector('.m3e-text-field__outline-start')).not.toBeNull()
    expect(root?.querySelector('.m3e-text-field__notch')?.textContent).toBe('Notes')
    expect(outline?.querySelector('.m3e-text-field__outline-end')).not.toBeNull()
  })

  it('defaults its native placeholder to a single space so :placeholder-shown stays reliable', () => {
    render(<TextArea label="Notes" />)
    expect(screen.getByLabelText('Notes').getAttribute('placeholder')).toBe(' ')
  })

  it('forwards rows and other native textarea attributes', () => {
    const ref = createRef<HTMLTextAreaElement>()
    render(<TextArea ref={ref} label="Feedback" rows={6} maxLength={500} />)
    const control = screen.getByLabelText('Feedback') as HTMLTextAreaElement

    expect(ref.current).toBe(control)
    expect(control.rows).toBe(6)
    expect(control.maxLength).toBe(500)
  })

  it('sends className and style to the root while native props stay on the control', () => {
    render(
      <TextArea
        label="Feedback"
        className="review-notes"
        style={{ marginInlineEnd: 8 }}
        id="review-notes"
        name="notes"
      />,
    )
    const control = document.querySelector('textarea')
    const root = document.querySelector('.m3e-text-field')

    if (!control || !root) throw new Error('Expected a rendered text area')
    expect(root.getAttribute('class')).toBe('m3e-text-field review-notes')
    expect(root.getAttribute('style')).toContain('margin-inline-end: 8px')
    expect(control.getAttribute('id')).toBe('review-notes')
    expect(control.getAttribute('name')).toBe('notes')
  })

  it('accepts typed multiline input through the browser', async () => {
    const user = userEvent.setup()
    render(<TextArea label="Feedback" />)
    const control = screen.getByLabelText('Feedback') as HTMLTextAreaElement

    await user.type(control, 'Line one{enter}Line two')
    expect(control.value).toBe('Line one\nLine two')
  })

  it('inherits both logical icon regions and the whole-field focus target from shared chrome', async () => {
    const user = userEvent.setup()
    render(
      <TextArea
        label="Message"
        leadingIcon={<span data-testid="leading" />}
        trailingIcon={<span data-testid="trailing" />}
      />,
    )
    const control = screen.getByLabelText('Message') as HTMLTextAreaElement
    const field = control.closest('.m3e-text-field__field')
    const hitTarget = field?.querySelector('.m3e-text-field__hit-target')

    expect(field?.getAttribute('data-m3e-has-leading-icon')).toBe('true')
    expect(field?.getAttribute('data-m3e-has-trailing-icon')).toBe('true')
    expect(screen.getByTestId('leading').closest('[data-m3e-position="leading"]')).not.toBeNull()
    expect(screen.getByTestId('trailing').closest('[data-m3e-position="trailing"]')).not.toBeNull()
    await user.click(hitTarget as HTMLLabelElement)
    expect(document.activeElement).toBe(control)
  })

  it('renders supporting text and associates it through aria-describedby', () => {
    render(<TextArea label="Notes" supportingText="Optional" />)
    const control = screen.getByLabelText('Notes')
    const supporting = screen.getByText('Optional')

    expect(control.getAttribute('aria-describedby')).toBe(supporting.id)
  })

  it('flags the error state on the root and the control', () => {
    render(<TextArea label="Notes" error supportingText="Required" />)
    const control = screen.getByLabelText('Notes')

    expect(control.getAttribute('aria-invalid')).toBe('true')
    expect(control.closest('.m3e-text-field')?.getAttribute('data-m3e-error')).toBe('true')
  })

  it('uses native disabled behavior and reflects it on the root', () => {
    render(<TextArea label="Locked" disabled defaultValue="Read only" />)
    const control = screen.getByLabelText('Locked') as HTMLTextAreaElement

    expect(control.disabled).toBe(true)
    expect(control.closest('.m3e-text-field')?.getAttribute('data-m3e-disabled')).toBe('true')
  })

  it('participates in form submission and native reset like any native textarea', async () => {
    const user = userEvent.setup()
    let submitted = ''
    render(
      <form
        onSubmit={(event) => {
          event.preventDefault()
          submitted = String(new FormData(event.currentTarget).get('notes'))
        }}
      >
        <TextArea label="Notes" name="notes" defaultValue="Draft" />
        <button type="submit">Save</button>
        <button type="reset">Reset</button>
      </form>,
    )
    const control = screen.getByLabelText('Notes') as HTMLTextAreaElement

    await user.clear(control)
    await user.type(control, 'Final')
    await user.click(screen.getByRole('button', { name: 'Save' }))
    expect(submitted).toBe('Final')

    await user.click(screen.getByRole('button', { name: 'Reset' }))
    expect(control.value).toBe('Draft')
  })

  it('exposes a stable component name for React tooling', () => {
    expect(TextArea.displayName).toBe('TextArea')
  })
})

// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { Dialog } from '../../../src/components/Dialog'
import { installDialogPolyfill } from './dialog-native-polyfill'

installDialogPolyfill()

describe('Dialog server rendering', () => {
  it('renders deterministic markup for every resolved state', () => {
    const render = () =>
      renderToString(
        <>
          <Dialog title="Delete item?" defaultOpen>
            This cannot be undone.
          </Dialog>
          <Dialog title="Closed" />
          <Dialog title="Non-modal" defaultOpen modal={false} />
          <Dialog role="alertdialog" title="Alert" defaultOpen />
          <Dialog
            title="With icon"
            icon={<span>*</span>}
            actions={<button type="button">OK</button>}
          />
        </>,
      )

    const first = render()
    expect(first).toBe(render())
    // A true modal (backdrop, focus trap, inert background) only exists
    // once showModal() runs on the client; SSR must never paint the `open`
    // attribute itself, even when `open`/`defaultOpen` requests it.
    expect(first).not.toContain(' open=""')
    expect(first).toContain('role="dialog"')
    expect(first).toContain('role="alertdialog"')
    expect(first).toContain('data-m3e-has-icon="true"')
    expect(first).toContain('data-m3e-has-icon="false"')
    expect(first).toContain('m3e-dialog__actions')
  })

  it('hydrates without changing markup or injecting styles, then opens on the client', async () => {
    const tree = (
      <Dialog title="Delete item?" defaultOpen>
        This cannot be undone.
      </Dialog>
    )
    const container = document.createElement('div')
    container.innerHTML = renderToString(tree)
    document.body.append(container)
    const serverHtml = container.innerHTML
    expect(serverHtml).not.toContain(' open=""')

    const recoverableErrors: unknown[] = []
    const root = hydrateRoot(container, tree, {
      onRecoverableError: (error) => recoverableErrors.push(error),
    })

    await act(async () => {})
    expect(recoverableErrors).toEqual([])
    expect(document.querySelector('style')).toBeNull()
    // The post-hydration client effect performs the first open imperatively.
    expect(container.querySelector('dialog')?.open).toBe(true)

    await act(async () => root.unmount())
    container.remove()
  })
})

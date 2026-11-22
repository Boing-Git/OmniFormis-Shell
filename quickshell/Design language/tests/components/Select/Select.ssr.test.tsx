// @vitest-environment jsdom

import { act } from '@testing-library/react'
import { hydrateRoot } from 'react-dom/client'
import { renderToString } from 'react-dom/server'
import { beforeAll } from 'vitest'
import { Select } from '../../../src/components/Select'
import type { SelectOption } from '../../../src/components/Select'
import { installScrollIntoViewPolyfill } from './select-native-polyfill'

beforeAll(installScrollIntoViewPolyfill)

const options: SelectOption[] = [
  { value: 'apple', label: 'Apple' },
  { value: 'cherry', label: 'Cherry' },
]

describe('Select server rendering', () => {
  it('renders deterministic markup and no listbox portal for every resolved state', () => {
    const render = () =>
      renderToString(
        <>
          <Select label="Fruit" options={options} />
          <Select label="Fruit" options={options} defaultValue="cherry" />
          <Select label="Fruit" options={options} defaultOpen />
          <Select label="Fruit" options={options} variant="outlined" />
          <Select label="Fruit" options={options} name="fruit" defaultValue="apple" />
        </>,
      )

    const first = render()
    expect(first).toBe(render())
    expect(first).not.toContain('role="listbox"')
    expect(first).toContain('role="combobox"')
    expect(first).toContain('value="Cherry"')
    expect(first).toContain('name="fruit"')
    expect(first).toContain('class="m3e-text-field__hit-target"')
  })

  it('hydrates without changing markup or injecting styles, then mounts the listbox on open', async () => {
    const tree = <Select label="Fruit" options={options} defaultOpen />
    const container = document.createElement('div')
    container.innerHTML = renderToString(tree)
    document.body.append(container)
    const serverHtml = container.innerHTML
    expect(serverHtml).not.toContain('role="listbox"')

    const recoverableErrors: unknown[] = []
    const root = hydrateRoot(container, tree, {
      onRecoverableError: (error) => recoverableErrors.push(error),
    })

    await act(async () => {})
    expect(recoverableErrors).toEqual([])
    expect(document.querySelector('style')).toBeNull()
    expect(document.querySelector('[role="listbox"]')).not.toBeNull()

    await act(async () => root.unmount())
    container.remove()
  })
})

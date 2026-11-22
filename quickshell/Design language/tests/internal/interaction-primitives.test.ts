import { composeEventHandlers } from '../../src/internal/composeEventHandlers'

describe('interaction primitives', () => {
  it('composes consumer and library handlers in order', () => {
    const calls: string[] = []
    const event = { defaultPrevented: false }
    const handler = composeEventHandlers(
      () => calls.push('consumer'),
      () => calls.push('library'),
    )

    handler(event)
    expect(calls).toEqual(['consumer', 'library'])
  })

  it('uses preventDefault as the cancellation signal for library behavior', () => {
    const calls: string[] = []
    const event = { defaultPrevented: false }
    const handler = composeEventHandlers(
      (currentEvent) => {
        calls.push('consumer')
        currentEvent.defaultPrevented = true
      },
      () => calls.push('library'),
    )

    handler(event)
    expect(calls).toEqual(['consumer'])
  })
})

/**
 * Runs consumer behavior before library behavior and treats preventDefault as
 * the native cancellation signal for the library action.
 */
export function composeEventHandlers<TEvent extends { readonly defaultPrevented: boolean }>(
  consumerHandler: ((event: TEvent) => void) | undefined,
  libraryHandler: ((event: TEvent) => void) | undefined,
): (event: TEvent) => void {
  return (event) => {
    consumerHandler?.(event)
    if (!event.defaultPrevented) libraryHandler?.(event)
  }
}

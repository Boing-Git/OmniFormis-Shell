import type { ComponentPropsWithRef } from 'react'

interface LoadingIndicatorOwnProps {
  /**
   * Determinate progress in `[0, max]`. Omit (or pass `undefined`) for
   * indeterminate mode — the same contract a native `<progress>` element
   * uses for its own determinate/indeterminate state.
   */
  readonly value?: number
  /** Upper bound for `value`. Defaults to `1`, matching the source's `0..1` fraction. */
  readonly max?: number
}

type LoadingIndicatorNativeProps = Omit<
  ComponentPropsWithRef<'div'>,
  keyof LoadingIndicatorOwnProps | 'children' | 'role'
>

export type LoadingIndicatorProps = LoadingIndicatorOwnProps & LoadingIndicatorNativeProps

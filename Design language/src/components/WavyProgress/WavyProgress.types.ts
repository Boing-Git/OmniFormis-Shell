import type { ComponentPropsWithRef } from 'react'

export type WavyProgressShape = 'linear' | 'circular'

interface WavyProgressOwnProps {
  /**
   * `'linear'` (default): the `LinearWavyProgressIndicator` treatment, a
   * traveling sine wave along a bar. `'circular'`: the
   * `CircularWavyProgressIndicator` treatment, a rippling ring.
   */
  readonly shape?: WavyProgressShape
  /**
   * Determinate progress in `[0, max]`. Omit (or pass `undefined`) for
   * indeterminate mode — the same contract a native `<progress>` element
   * uses for its own determinate/indeterminate state.
   */
  readonly value?: number
  /** Upper bound for `value`. Defaults to `1`, matching the source's `0..1` fraction. */
  readonly max?: number
}

type WavyProgressNativeProps = Omit<
  ComponentPropsWithRef<'div'>,
  keyof WavyProgressOwnProps | 'children' | 'role'
>

export type WavyProgressProps = WavyProgressOwnProps & WavyProgressNativeProps

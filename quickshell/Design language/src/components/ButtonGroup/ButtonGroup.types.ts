import type { ComponentPropsWithRef, ReactNode } from 'react'

interface ButtonGroupOwnProps {
  /**
   * The buttons (or other interactive elements) to arrange in a row —
   * typically `Button`/`IconButton` elements. Pressing one visibly grows
   * it and compresses its immediate siblings.
   */
  readonly children: ReactNode
}

type ButtonGroupNativeProps = Omit<ComponentPropsWithRef<'div'>, keyof ButtonGroupOwnProps>

export type ButtonGroupProps = ButtonGroupOwnProps & ButtonGroupNativeProps

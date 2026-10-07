import type { ComponentPropsWithRef, ReactNode } from 'react'

export type FloatingToolbarOrientation = 'horizontal' | 'vertical'
export type FloatingToolbarVariant = 'standard' | 'vibrant'

interface FloatingToolbarOwnProps {
  /** The toolbar's items, typically `IconButton`s. */
  readonly children: ReactNode
  /** Main-axis direction. Defaults to `'horizontal'`. */
  readonly orientation?: FloatingToolbarOrientation
  /** Container/content color pairing. Defaults to `'standard'`. */
  readonly variant?: FloatingToolbarVariant
  /**
   * Controlled expanded state. Collapsing visibly shrinks the container
   * and hides its content — wire this to your own scroll listener for
   * scroll-driven show/hide.
   */
  readonly expanded?: boolean
  /** Initial expanded state when uncontrolled. Defaults to `true`. */
  readonly defaultExpanded?: boolean
  readonly onExpandedChange?: (expanded: boolean) => void
}

type FloatingToolbarNativeProps = Omit<
  ComponentPropsWithRef<'div'>,
  keyof FloatingToolbarOwnProps | 'role'
>

export type FloatingToolbarProps = FloatingToolbarOwnProps & FloatingToolbarNativeProps

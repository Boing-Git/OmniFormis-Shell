import type { ComponentPropsWithRef, ReactNode } from 'react'

export type IconButtonVariant = 'standard' | 'filled' | 'tonal' | 'outlined'
export type IconButtonSize = 'extra-small' | 'small' | 'medium' | 'large' | 'extra-large'
export type IconButtonWidth = 'narrow' | 'uniform' | 'wide'
export type IconButtonShape = 'round' | 'square'

interface IconButtonOwnProps {
  /** Decorative default visual, normally an Icon. */
  readonly children: ReactNode
  /** Material emphasis variant. */
  readonly variant?: IconButtonVariant
  /** Material 3 Expressive container and icon size. */
  readonly size?: IconButtonSize
  /** Narrow, uniform, or wide size-aware visual container. */
  readonly width?: IconButtonWidth
  /** Round or size-aware square resting container shape. */
  readonly shape?: IconButtonShape
}

interface MomentaryIconButtonProps {
  /** Momentary action mode is the default. */
  readonly toggle?: false
  readonly selected?: never
  readonly defaultSelected?: never
  readonly onSelectedChange?: never
  readonly selectedIcon?: never
}

interface ControlledToggleIconButtonProps {
  readonly toggle: true
  /** Controlled selected state. */
  readonly selected: boolean
  readonly defaultSelected?: never
  readonly onSelectedChange: (selected: boolean) => void
  /** Optional decorative visual shown instead of children while selected. */
  readonly selectedIcon?: ReactNode
}

interface UncontrolledToggleIconButtonProps {
  readonly toggle: true
  readonly selected?: never
  /** Initial selected state when selection is uncontrolled. */
  readonly defaultSelected?: boolean
  readonly onSelectedChange?: (selected: boolean) => void
  /** Optional decorative visual shown instead of children while selected. */
  readonly selectedIcon?: ReactNode
}

type IconButtonToggleProps =
  | MomentaryIconButtonProps
  | ControlledToggleIconButtonProps
  | UncontrolledToggleIconButtonProps

type IconButtonNativeProps = Omit<
  ComponentPropsWithRef<'button'>,
  'aria-pressed' | 'children'
>

/** Props for a native Material 3 Expressive icon-only button. */
export type IconButtonProps = IconButtonNativeProps & IconButtonOwnProps & IconButtonToggleProps

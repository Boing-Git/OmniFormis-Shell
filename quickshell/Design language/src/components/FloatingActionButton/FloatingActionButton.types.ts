import type { ComponentPropsWithRef, ReactNode } from 'react'

export type FloatingActionButtonSize = 'standard' | 'medium' | 'large'
export type FloatingActionButtonElevation = 'default' | 'lowered' | 'none'

interface FloatingActionButtonOwnProps {
  /** Decorative FAB artwork, normally an Icon. */
  readonly icon: ReactNode
  /** Current Material standard, medium, or large container size. */
  readonly size?: FloatingActionButtonSize
  /** Material shadow emphasis for momentary and extended FABs. */
  readonly elevation?: FloatingActionButtonElevation
}

interface MomentaryIconFloatingActionButtonProps {
  readonly toggle?: false
  readonly label?: never
  readonly expanded?: never
  readonly selected?: never
  readonly defaultSelected?: never
  readonly onSelectedChange?: never
  readonly selectedIcon?: never
}

interface ExtendedFloatingActionButtonProps {
  readonly toggle?: false
  /** Non-interactive text label that creates the extended FAB layout. */
  readonly label: ReactNode
  /** Whether the label is visually expanded. Its accessible name remains available. */
  readonly expanded?: boolean
  readonly selected?: never
  readonly defaultSelected?: never
  readonly onSelectedChange?: never
  readonly selectedIcon?: never
}

interface ControlledToggleFloatingActionButtonProps {
  readonly toggle: true
  readonly label?: never
  readonly expanded?: never
  readonly elevation?: never
  /** Controlled selected state. */
  readonly selected: boolean
  readonly defaultSelected?: never
  readonly onSelectedChange: (selected: boolean) => void
  /** Optional decorative artwork shown instead of icon while selected. */
  readonly selectedIcon?: ReactNode
}

interface UncontrolledToggleFloatingActionButtonProps {
  readonly toggle: true
  readonly label?: never
  readonly expanded?: never
  readonly elevation?: never
  readonly selected?: never
  /** Initial selected state when selection is uncontrolled. */
  readonly defaultSelected?: boolean
  readonly onSelectedChange?: (selected: boolean) => void
  /** Optional decorative artwork shown instead of icon while selected. */
  readonly selectedIcon?: ReactNode
}

type FloatingActionButtonModeProps =
  | MomentaryIconFloatingActionButtonProps
  | ExtendedFloatingActionButtonProps
  | ControlledToggleFloatingActionButtonProps
  | UncontrolledToggleFloatingActionButtonProps

type FloatingActionButtonNativeProps = Omit<
  ComponentPropsWithRef<'button'>,
  'aria-pressed' | 'children'
>

/** Props for a native Material 3 Expressive floating action button. */
export type FloatingActionButtonProps = FloatingActionButtonNativeProps &
  FloatingActionButtonOwnProps &
  FloatingActionButtonModeProps

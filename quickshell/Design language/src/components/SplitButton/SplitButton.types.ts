import type { ComponentPropsWithRef, MouseEventHandler, ReactNode } from 'react'

export type SplitButtonVariant = 'filled' | 'tonal' | 'elevated' | 'outlined'
export type SplitButtonSize = 'extra-small' | 'small' | 'medium' | 'large' | 'extra-large'

interface SplitButtonOwnProps {
  /** The leading (primary action) button's label. */
  readonly children: ReactNode
  /** Material emphasis variant, shared by both buttons. */
  readonly variant?: SplitButtonVariant
  /** Material 3 Expressive container and content size, shared by both buttons. */
  readonly size?: SplitButtonSize
  /** Decorative visual rendered before the leading button's label. */
  readonly leadingIcon?: ReactNode
  /** Click handler for the leading (primary action) button. */
  readonly onClick?: MouseEventHandler<HTMLButtonElement>
  /**
   * The trailing (icon-only) button's visual, typically a chevron toggling
   * an attached menu.
   */
  readonly trailingIcon: ReactNode
  /** Accessible name for the icon-only trailing button. */
  readonly trailingLabel: string
  /**
   * Controlled selected state for the trailing button — conventionally
   * "the attached menu is open." Morphs the trailing button to a full
   * circle while `true`. Wiring it to an actual menu (e.g. this project's
   * own `Menu`) is left to the consumer.
   */
  readonly selected?: boolean
  /** Initial selected state when selection is uncontrolled. */
  readonly defaultSelected?: boolean
  readonly onSelectedChange?: (selected: boolean) => void
  /** Disables both the leading and trailing buttons. */
  readonly disabled?: boolean
}

type SplitButtonNativeProps = Omit<
  ComponentPropsWithRef<'div'>,
  keyof SplitButtonOwnProps | 'role'
>

export type SplitButtonProps = SplitButtonOwnProps & SplitButtonNativeProps

import type { ComponentPropsWithRef, ReactNode } from 'react'

export type ButtonVariant = 'filled' | 'tonal' | 'elevated' | 'outlined' | 'text'
export type ButtonSize = 'extra-small' | 'small' | 'medium' | 'large' | 'extra-large'
export type ButtonWidth = 'fit' | 'full'
export type ButtonShape = 'round' | 'square'

interface ButtonOwnProps {
  /** Button label or other non-interactive label content. */
  readonly children: ReactNode
  /** Material emphasis variant. */
  readonly variant?: ButtonVariant
  /** Material 3 Expressive container and content size. */
  readonly size?: ButtonSize
  /** Intrinsic content width or the full width of the containing block. */
  readonly width?: ButtonWidth
  /** Round or size-aware square resting container shape. */
  readonly shape?: ButtonShape
  /** Decorative visual rendered before the label in logical reading order. */
  readonly leadingIcon?: ReactNode
  /** Decorative visual rendered after the label in logical reading order. */
  readonly trailingIcon?: ReactNode
}

/** Props for a native, form-capable Material 3 Expressive button. */
export type ButtonProps = ButtonOwnProps &
  Omit<ComponentPropsWithRef<'button'>, keyof ButtonOwnProps>

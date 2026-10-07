import type { ComponentPropsWithRef, ReactNode } from 'react'

interface SwitchOwnProps {
  /**
   * Decorative content drawn inside the thumb, expected to measure the
   * sourced 16px icon size. Its presence keeps the thumb at the selected
   * handle size even while unchecked, matching the pinned source's
   * `hasContent || checked` sizing rule.
   */
  readonly thumbIcon?: ReactNode
}

interface ControlledSwitchProps {
  /** Controlled checked state. */
  readonly checked: boolean
  readonly defaultChecked?: never
  readonly onCheckedChange: (checked: boolean) => void
}

interface UncontrolledSwitchProps {
  readonly checked?: never
  /** Initial checked state when the control is uncontrolled. */
  readonly defaultChecked?: boolean
  readonly onCheckedChange?: (checked: boolean) => void
}

type SwitchStateProps = ControlledSwitchProps | UncontrolledSwitchProps

type SwitchNativeProps = Omit<
  ComponentPropsWithRef<'input'>,
  'checked' | 'children' | 'defaultChecked' | 'role' | 'size' | 'type'
>

/**
 * Props for a native Material Switch, rendered as `input type="checkbox"
 * role="switch"`. `className` and `style` describe the switch root; every
 * other prop and the forwarded ref belong to the native input.
 */
export type SwitchProps = SwitchNativeProps & SwitchOwnProps & SwitchStateProps

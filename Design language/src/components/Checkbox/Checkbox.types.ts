import type { ComponentPropsWithRef } from 'react'

interface CheckboxOwnProps {
  /**
   * Mixed state. It renders the sourced indeterminate dash and `aria-checked="mixed"`
   * without owning a transition policy: browser activation resolves the control to its
   * native checked value, and the consumer clears this prop from its change handler.
   */
  readonly indeterminate?: boolean
}

interface ControlledCheckboxProps {
  /** Controlled checked state. */
  readonly checked: boolean
  readonly defaultChecked?: never
  readonly onCheckedChange: (checked: boolean) => void
}

interface UncontrolledCheckboxProps {
  readonly checked?: never
  /** Initial checked state when the control is uncontrolled. */
  readonly defaultChecked?: boolean
  readonly onCheckedChange?: (checked: boolean) => void
}

type CheckboxStateProps = ControlledCheckboxProps | UncontrolledCheckboxProps

type CheckboxNativeProps = Omit<
  ComponentPropsWithRef<'input'>,
  'checked' | 'children' | 'defaultChecked' | 'size' | 'type'
>

/**
 * Props for a native Material Checkbox. `className` and `style` describe the
 * checkbox root; every other prop and the forwarded ref belong to the native
 * `input type="checkbox"`.
 */
export type CheckboxProps = CheckboxNativeProps & CheckboxOwnProps & CheckboxStateProps

import type { ComponentPropsWithRef } from 'react'

interface RadioOwnProps {
  /**
   * The native grouping name. Required because a nameless radio cannot form a
   * group, and mutually exclusive, roving-focus grouping is this control's
   * required native behavior.
   */
  readonly name: string
}

interface ControlledRadioProps {
  /** Controlled checked state. */
  readonly checked: boolean
  readonly defaultChecked?: never
  readonly onCheckedChange: (checked: boolean) => void
}

interface UncontrolledRadioProps {
  readonly checked?: never
  /** Initial checked state when the control is uncontrolled. */
  readonly defaultChecked?: boolean
  readonly onCheckedChange?: (checked: boolean) => void
}

type RadioStateProps = ControlledRadioProps | UncontrolledRadioProps

type RadioNativeProps = Omit<
  ComponentPropsWithRef<'input'>,
  'checked' | 'children' | 'defaultChecked' | 'name' | 'size' | 'type'
>

/**
 * Props for a native Material Radio. `className` and `style` describe the
 * radio root; every other prop and the forwarded ref belong to the native
 * `input type="radio"`.
 */
export type RadioProps = RadioNativeProps & RadioOwnProps & RadioStateProps

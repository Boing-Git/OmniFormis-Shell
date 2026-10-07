import type { ComponentPropsWithRef, ReactNode } from 'react'

export type TextFieldVariant = 'filled' | 'outlined'

/**
 * Native text-like `input` types this component supports. Types with
 * browser-owned chrome incompatible with the sourced label/indicator
 * decoration (`checkbox`, `radio`, `file`, `range`, `color`, `date` and its
 * relatives) are intentionally excluded.
 */
export type TextFieldInputType = 'text' | 'email' | 'password' | 'search' | 'tel' | 'url' | 'number'

interface TextFieldOwnProps {
  /** Rendered inside a native `label` associated with the input via `htmlFor`. */
  readonly label: ReactNode
  /**
   * `filled` reproduces the pinned `TextField`'s inside-container label and
   * bottom indicator line. `outlined` reproduces `OutlinedTextField`'s
   * bordered container notched around the floating label.
   */
  readonly variant?: TextFieldVariant
  readonly leadingIcon?: ReactNode
  readonly trailingIcon?: ReactNode
  /** Rendered below the field; recolored and associated via `aria-describedby`. */
  readonly supportingText?: ReactNode
  /**
   * Recolors the label, indicator/outline, and supporting text, and sets
   * `aria-invalid`, reproducing the pinned source's generic
   * `defaultErrorSemantics` affordance. Does not alter `supportingText`
   * content; callers own the message.
   */
  readonly error?: boolean
  readonly type?: TextFieldInputType
}

type TextFieldNativeProps = Omit<ComponentPropsWithRef<'input'>, 'children' | 'size' | 'type'>

/**
 * Props for a native Material text field. `className` and `style` describe
 * the field root; every other prop and the forwarded ref belong to the
 * native `input`. Value state is left entirely to native controlled/
 * uncontrolled `input` behavior; this component owns no derived value state.
 */
export type TextFieldProps = TextFieldNativeProps & TextFieldOwnProps

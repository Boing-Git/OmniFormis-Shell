import type { ComponentPropsWithRef, ReactNode } from 'react'

export type TextAreaVariant = 'filled' | 'outlined'

interface TextAreaOwnProps {
  /** Rendered inside a native `label` associated with the control via `htmlFor`. */
  readonly label: ReactNode
  /**
   * `filled` reproduces the pinned `TextField`'s inside-container label and
   * bottom indicator line. `outlined` reproduces `OutlinedTextField`'s
   * bordered container notched around the floating label. The pinned source
   * has no distinct multiline composable — both reuse this exact decoration
   * for `singleLine=false`.
   */
  readonly variant?: TextAreaVariant
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
}

type TextAreaNativeProps = Omit<ComponentPropsWithRef<'textarea'>, 'children'>

/**
 * Props for a native Material multiline text field. `className` and `style`
 * describe the field root; every other prop and the forwarded ref belong to
 * the native `textarea`. Height follows the native `rows` attribute and the
 * browser's own vertical resize handle, clamped to the shared Material field
 * minimum; auto-growing height is out of scope.
 */
export type TextAreaProps = TextAreaNativeProps & TextAreaOwnProps

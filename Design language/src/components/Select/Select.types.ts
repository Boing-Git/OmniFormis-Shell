import type { ComponentPropsWithRef, ReactNode } from 'react'

export interface SelectOption {
  readonly value: string
  /**
   * Plain text, unlike `MenuItem.label` — this text also becomes the
   * trigger's own displayed input value, the same way a native
   * `<select>`'s `<option>` text is inherently plain text too.
   */
  readonly label: string
  readonly disabled?: boolean
}

export type SelectVariant = 'filled' | 'outlined'

interface SelectOwnProps {
  /** The choices shown in the popup listbox, in display order. */
  readonly options: readonly SelectOption[]
  /** Controlled selected value. Omit for uncontrolled `defaultValue`. */
  readonly value?: string
  /** Initial selected value when uncontrolled. Defaults to no selection. */
  readonly defaultValue?: string
  readonly onValueChange?: (value: string) => void
  /** Rendered inside a native `label` associated with the trigger via `htmlFor`. */
  readonly label: ReactNode
  readonly variant?: SelectVariant
  readonly leadingIcon?: ReactNode
  /** Rendered below the field; recolored and associated via `aria-describedby`. */
  readonly supportingText?: ReactNode
  readonly error?: boolean
  readonly disabled?: boolean
  /** Controlled listbox-open state. Omit for uncontrolled `defaultOpen`. */
  readonly open?: boolean
  /** Initial listbox-open state when uncontrolled. Defaults to `false`. */
  readonly defaultOpen?: boolean
  readonly onOpenChange?: (open: boolean) => void
}

type SelectNativeProps = Omit<
  ComponentPropsWithRef<'input'>,
  'children' | 'size' | 'type' | 'readOnly' | 'value' | 'defaultValue' | 'onChange' | keyof SelectOwnProps
>

/**
 * Props for a Material select. No native `<select>` element is used —
 * Material's opinionated option rows cannot be styled inside a native
 * `<select>`'s popup across this library's browser floor — so the visible
 * trigger is a read-only native `input` decorated by the same
 * `TextFieldChrome` foundation `TextField` uses, and `name` (when supplied)
 * renders a companion `<input type="hidden">` for real form participation.
 */
export type SelectProps = SelectNativeProps & SelectOwnProps

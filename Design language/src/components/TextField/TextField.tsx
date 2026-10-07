import { forwardRef, useId, type CSSProperties, type ForwardedRef, type ReactElement } from 'react'
import { TextFieldChrome } from '../../internal/TextFieldChrome'
import type { TextFieldProps } from './TextField.types'

interface TextFieldComponent {
  (props: TextFieldProps): ReactElement | null
  displayName?: string
}

function TextFieldRender(
  {
    label,
    variant = 'filled',
    leadingIcon,
    trailingIcon,
    supportingText,
    error = false,
    disabled = false,
    className,
    style,
    id: idProp,
    placeholder,
    type = 'text',
    'aria-invalid': ariaInvalidProp,
    'aria-describedby': ariaDescribedByProp,
    ...inputProps
  }: TextFieldProps,
  forwardedRef: ForwardedRef<HTMLInputElement>,
) {
  const generatedId = useId()
  const fieldId = idProp ?? generatedId
  const supportingTextId = supportingText != null ? `${fieldId}-supporting-text` : undefined

  // A non-empty native placeholder is required for `:placeholder-shown` to
  // ever match, which is what drives the floating label off true DOM state.
  // A caller-supplied placeholder passes through directly and is otherwise
  // hidden until focus by TextField.css, matching the pinned source showing
  // its own `placeholder` slot only once the label has floated.
  const resolvedPlaceholder = placeholder != null && placeholder.length > 0 ? placeholder : ' '
  const resolvedAriaInvalid = error ? true : ariaInvalidProp
  const resolvedAriaDescribedBy =
    [ariaDescribedByProp, supportingTextId].filter(Boolean).join(' ') || undefined

  return (
    <TextFieldChrome
      className={className}
      style={style as CSSProperties}
      variant={variant}
      label={label}
      leadingIcon={leadingIcon}
      trailingIcon={trailingIcon}
      supportingText={supportingText}
      supportingTextId={supportingTextId}
      error={error}
      disabled={disabled}
      fieldId={fieldId}
    >
      <input
        {...inputProps}
        ref={forwardedRef}
        id={fieldId}
        type={type}
        className="m3e-text-field__input"
        disabled={disabled}
        placeholder={resolvedPlaceholder}
        aria-invalid={resolvedAriaInvalid}
        aria-describedby={resolvedAriaDescribedBy}
      />
    </TextFieldChrome>
  )
}

const ForwardedTextField = forwardRef<HTMLInputElement, TextFieldProps>(TextFieldRender)
ForwardedTextField.displayName = 'TextField'

export const TextField = ForwardedTextField as TextFieldComponent

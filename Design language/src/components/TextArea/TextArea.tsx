import { forwardRef, useId, type CSSProperties, type ForwardedRef, type ReactElement } from 'react'
import { TextFieldChrome } from '../../internal/TextFieldChrome'
import type { TextAreaProps } from './TextArea.types'

interface TextAreaComponent {
  (props: TextAreaProps): ReactElement | null
  displayName?: string
}

function TextAreaRender(
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
    'aria-invalid': ariaInvalidProp,
    'aria-describedby': ariaDescribedByProp,
    ...textAreaProps
  }: TextAreaProps,
  forwardedRef: ForwardedRef<HTMLTextAreaElement>,
) {
  const generatedId = useId()
  const fieldId = idProp ?? generatedId
  const supportingTextId = supportingText != null ? `${fieldId}-supporting-text` : undefined

  // See TextField.tsx for why the native placeholder always resolves to a
  // non-empty string: it is what drives the floating label's
  // `:placeholder-shown` detection off true DOM state.
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
      multiline
    >
      <textarea
        {...textAreaProps}
        ref={forwardedRef}
        id={fieldId}
        className="m3e-text-field__input"
        disabled={disabled}
        placeholder={resolvedPlaceholder}
        aria-invalid={resolvedAriaInvalid}
        aria-describedby={resolvedAriaDescribedBy}
      />
    </TextFieldChrome>
  )
}

const ForwardedTextArea = forwardRef<HTMLTextAreaElement, TextAreaProps>(TextAreaRender)
ForwardedTextArea.displayName = 'TextArea'

export const TextArea = ForwardedTextArea as TextAreaComponent

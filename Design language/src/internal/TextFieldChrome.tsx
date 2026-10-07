import type { CSSProperties, ReactNode } from 'react'

export type TextFieldChromeVariant = 'filled' | 'outlined'

export interface TextFieldChromeProps {
  readonly variant: TextFieldChromeVariant
  readonly label: ReactNode
  readonly leadingIcon?: ReactNode
  readonly trailingIcon?: ReactNode
  readonly supportingText?: ReactNode
  readonly supportingTextId?: string
  readonly error?: boolean
  readonly disabled?: boolean
  readonly multiline?: boolean
  readonly fieldId: string
  readonly className?: string
  readonly style?: CSSProperties
  /** The native `input`/`textarea` this chrome decorates, rendered first so
   * every other part can read its `:focus`/`:placeholder-shown`/`:disabled`
   * state through a plain CSS sibling combinator. */
  readonly children: ReactNode
}

/**
 * Shared label, indicator/outline, icon, and supporting-text decoration for
 * `TextField` and `TextArea`. The pinned source has no distinct multiline
 * composable — `TextField`/`OutlinedTextField` reuse one decoration layer
 * regardless of line count — so this internal primitive is the direct web
 * equivalent of that shared Compose layer, not a bonus abstraction.
 * Horizontal chrome is exposed as one start/content/end layout: the native
 * control remains the first child for native-truth sibling selectors but is
 * placed only in the content region, while a transparent associated label
 * preserves whole-field click-to-focus behavior across the outer regions.
 *
 * `error` and `disabled` are mirrored onto this root as `data-m3e-*`
 * attributes because they are the only two states here with no DOM-native
 * signal reachable by a plain sibling combinator from the control: `error`
 * is a caller-supplied boolean with no HTML equivalent, and the supporting
 * text sits outside `.m3e-text-field__field`, one branch away from the
 * control itself. Both are safe as React-rendered attributes because
 * neither can change without this component re-rendering — unlike a
 * radio's checked state, nothing outside this instance can flip them.
 * Focus and has-value state are never mirrored this way; they are read
 * directly off the control's own `:focus`/`:placeholder-shown` pseudo
 * classes, the same native-truth precedent ADR 0012 established for Radio.
 */
export function TextFieldChrome({
  variant,
  label,
  leadingIcon,
  trailingIcon,
  supportingText,
  supportingTextId,
  error = false,
  disabled = false,
  multiline = false,
  fieldId,
  className,
  style,
  children,
}: TextFieldChromeProps) {
  const rootClassName = className ? `m3e-text-field ${className}` : 'm3e-text-field'

  return (
    <span
      className={rootClassName}
      style={style}
      data-m3e-variant={variant}
      data-m3e-error={error}
      data-m3e-disabled={disabled}
      data-m3e-multiline={multiline}
    >
      <span
        className="m3e-text-field__field"
        data-m3e-has-leading-icon={leadingIcon != null}
        data-m3e-has-trailing-icon={trailingIcon != null}
      >
        {children}
        <label className="m3e-text-field__label" htmlFor={fieldId}>
          {label}
        </label>
        {variant === 'outlined' ? (
          <span className="m3e-text-field__outline" aria-hidden="true">
            <span className="m3e-text-field__outline-start" />
            <span className="m3e-text-field__notch">
              <span>{label}</span>
            </span>
            <span className="m3e-text-field__outline-end" />
          </span>
        ) : (
          <span className="m3e-text-field__indicator" aria-hidden="true" />
        )}
        {leadingIcon != null ? (
          <span className="m3e-text-field__icon" data-m3e-position="leading" aria-hidden="true">
            {leadingIcon}
          </span>
        ) : null}
        {trailingIcon != null ? (
          <span className="m3e-text-field__icon" data-m3e-position="trailing" aria-hidden="true">
            {trailingIcon}
          </span>
        ) : null}
        <label
          className="m3e-text-field__hit-target"
          htmlFor={fieldId}
          aria-hidden="true"
        />
      </span>
      {supportingText != null ? (
        <span className="m3e-text-field__supporting-text" id={supportingTextId}>
          {supportingText}
        </span>
      ) : null}
    </span>
  )
}

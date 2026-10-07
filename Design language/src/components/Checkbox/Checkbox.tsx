import {
  forwardRef,
  useEffect,
  useRef,
  type ChangeEvent,
  type CSSProperties,
  type ForwardedRef,
  type InputHTMLAttributes,
  type ReactElement,
} from 'react'
import { composeEventHandlers } from '../../internal/composeEventHandlers'
import { composeRefs } from '../../internal/composeRefs'
import { useControllableState } from '../../internal/useControllableState'
import type { CheckboxProps } from './Checkbox.types'

interface CheckboxImplementationProps
  extends Omit<InputHTMLAttributes<HTMLInputElement>, 'children' | 'size' | 'type'> {
  readonly indeterminate?: boolean
  readonly onCheckedChange?: (checked: boolean) => void
}

interface CheckboxComponent {
  (props: CheckboxProps): ReactElement | null
  displayName?: string
}

function warn(message: string): void {
  if (typeof process !== 'undefined' && process.env.NODE_ENV !== 'production') {
    console.warn(`Checkbox: ${message}`)
  }
}

function warnForInvalidProps({
  checked,
  defaultChecked,
  onChange,
  onCheckedChange,
}: {
  readonly checked: boolean | undefined
  readonly defaultChecked: boolean | undefined
  readonly onChange: ((event: ChangeEvent<HTMLInputElement>) => void) | undefined
  readonly onCheckedChange: ((checked: boolean) => void) | undefined
}): void {
  if (checked !== undefined && defaultChecked !== undefined) {
    warn('use either checked or defaultChecked, not both.')
  }
  if (checked !== undefined && onCheckedChange === undefined && onChange === undefined) {
    warn('a controlled checked value requires onCheckedChange or onChange.')
  }
}

function CheckboxRender(
  {
    checked,
    defaultChecked,
    onCheckedChange,
    indeterminate = false,
    disabled = false,
    className,
    style,
    onChange,
    ...inputProps
  }: CheckboxImplementationProps,
  forwardedRef: ForwardedRef<HTMLInputElement>,
) {
  warnForInvalidProps({ checked, defaultChecked, onChange, onCheckedChange })

  const inputRef = useRef<HTMLInputElement | null>(null)
  const controlled = checked !== undefined
  const [resolvedChecked, setChecked] = useControllableState({
    value: checked,
    defaultValue: defaultChecked ?? false,
    onChange: onCheckedChange,
  })

  // The browser clears indeterminate on activation and never serializes it, so
  // the prop stays authoritative on every commit.
  useEffect(() => {
    const input = inputRef.current
    if (input) input.indeterminate = indeterminate
  }, [indeterminate, resolvedChecked])

  // Native form reset restores the input's default checkedness without a React
  // update, so uncontrolled visual state resynchronizes from the same event.
  useEffect(() => {
    const form = inputRef.current?.form
    if (controlled || !form) return undefined
    const handleReset = () => setChecked(defaultChecked ?? false)
    form.addEventListener('reset', handleReset)
    return () => form.removeEventListener('reset', handleReset)
  }, [controlled, defaultChecked, setChecked])

  const state = indeterminate ? 'indeterminate' : resolvedChecked ? 'checked' : 'unchecked'
  const mergedClassName = className ? `m3e-checkbox ${className}` : 'm3e-checkbox'
  const handleChange = composeEventHandlers<ChangeEvent<HTMLInputElement>>(
    onChange,
    (event) => setChecked(event.currentTarget.checked),
  )

  return (
    <span
      className={mergedClassName}
      style={style as CSSProperties}
      data-m3e-state={state}
      data-m3e-disabled={disabled}
    >
      <input
        {...inputProps}
        ref={composeRefs(forwardedRef, inputRef)}
        type="checkbox"
        className="m3e-checkbox__input"
        disabled={disabled}
        aria-checked={indeterminate ? 'mixed' : undefined}
        {...(controlled
          ? { checked: resolvedChecked }
          : { defaultChecked: defaultChecked ?? false })}
        onChange={handleChange}
      />
      <span className="m3e-checkbox__container" aria-hidden="true">
        <svg className="m3e-checkbox__mark" viewBox="0 0 18 18" focusable="false">
          <path className="m3e-checkbox__mark-path" />
        </svg>
      </span>
    </span>
  )
}

const ForwardedCheckbox = forwardRef<HTMLInputElement, CheckboxImplementationProps>(CheckboxRender)
ForwardedCheckbox.displayName = 'Checkbox'

export const Checkbox = ForwardedCheckbox as CheckboxComponent

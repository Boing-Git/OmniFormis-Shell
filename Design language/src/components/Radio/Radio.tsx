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
import type { RadioProps } from './Radio.types'

interface RadioImplementationProps
  extends Omit<InputHTMLAttributes<HTMLInputElement>, 'children' | 'size' | 'type'> {
  readonly name: string
  readonly onCheckedChange?: (checked: boolean) => void
}

interface RadioComponent {
  (props: RadioProps): ReactElement | null
  displayName?: string
}

function warn(message: string): void {
  if (typeof process !== 'undefined' && process.env.NODE_ENV !== 'production') {
    console.warn(`Radio: ${message}`)
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

function RadioRender(
  {
    checked,
    defaultChecked,
    onCheckedChange,
    disabled = false,
    className,
    style,
    onChange,
    ...inputProps
  }: RadioImplementationProps,
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

  // Native form reset restores the input's default checkedness without a
  // React update, so uncontrolled visual state resynchronizes from the same
  // event.
  useEffect(() => {
    const form = inputRef.current?.form
    if (controlled || !form) return undefined
    const handleReset = () => setChecked(defaultChecked ?? false)
    form.addEventListener('reset', handleReset)
    return () => form.removeEventListener('reset', handleReset)
  }, [controlled, defaultChecked, setChecked])

  const state = resolvedChecked ? 'checked' : 'unchecked'
  const mergedClassName = className ? `m3e-radio ${className}` : 'm3e-radio'
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
        type="radio"
        className="m3e-radio__input"
        disabled={disabled}
        {...(controlled
          ? { checked: resolvedChecked }
          : { defaultChecked: defaultChecked ?? false })}
        onChange={handleChange}
      />
      <span className="m3e-radio__container" aria-hidden="true">
        <span className="m3e-radio__dot" />
      </span>
    </span>
  )
}

const ForwardedRadio = forwardRef<HTMLInputElement, RadioImplementationProps>(RadioRender)
ForwardedRadio.displayName = 'Radio'

export const Radio = ForwardedRadio as RadioComponent

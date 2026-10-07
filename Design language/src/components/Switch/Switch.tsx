import {
  forwardRef,
  useEffect,
  useRef,
  type ChangeEvent,
  type CSSProperties,
  type ForwardedRef,
  type InputHTMLAttributes,
  type ReactElement,
  type ReactNode,
} from 'react'
import { composeEventHandlers } from '../../internal/composeEventHandlers'
import { composeRefs } from '../../internal/composeRefs'
import { useControllableState } from '../../internal/useControllableState'
import type { SwitchProps } from './Switch.types'

interface SwitchImplementationProps
  extends Omit<InputHTMLAttributes<HTMLInputElement>, 'children' | 'role' | 'size' | 'type'> {
  readonly thumbIcon?: ReactNode
  readonly onCheckedChange?: (checked: boolean) => void
}

interface SwitchComponent {
  (props: SwitchProps): ReactElement | null
  displayName?: string
}

function warn(message: string): void {
  if (typeof process !== 'undefined' && process.env.NODE_ENV !== 'production') {
    console.warn(`Switch: ${message}`)
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

function SwitchRender(
  {
    checked,
    defaultChecked,
    onCheckedChange,
    thumbIcon,
    disabled = false,
    className,
    style,
    onChange,
    ...inputProps
  }: SwitchImplementationProps,
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
  const mergedClassName = className ? `m3e-switch ${className}` : 'm3e-switch'
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
      data-m3e-has-thumb-icon={thumbIcon != null}
    >
      <input
        {...inputProps}
        ref={composeRefs(forwardedRef, inputRef)}
        type="checkbox"
        role="switch"
        className="m3e-switch__input"
        disabled={disabled}
        {...(controlled
          ? { checked: resolvedChecked }
          : { defaultChecked: defaultChecked ?? false })}
        onChange={handleChange}
      />
      <span className="m3e-switch__track" aria-hidden="true">
        <span className="m3e-switch__thumb">
          {thumbIcon != null ? <span className="m3e-switch__thumb-icon">{thumbIcon}</span> : null}
        </span>
      </span>
    </span>
  )
}

const ForwardedSwitch = forwardRef<HTMLInputElement, SwitchImplementationProps>(SwitchRender)
ForwardedSwitch.displayName = 'Switch'

export const Switch = ForwardedSwitch as SwitchComponent

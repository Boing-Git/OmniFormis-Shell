import {
  forwardRef,
  useEffect,
  useId,
  useRef,
  type ChangeEvent,
  type ForwardedRef,
  type ReactElement,
} from 'react'
import { useControllableState } from '../../internal/useControllableState'
import type { SegmentedButtonGroupProps, SegmentedButtonGroupSegment } from './SegmentedButtonGroup.types'

type GroupValue = string | readonly string[]

interface SegmentedButtonGroupComponent {
  (props: SegmentedButtonGroupProps): ReactElement | null
  displayName?: string
}

const EMPTY_VALUES: readonly string[] = []

// `androidx.compose.material3.internal.Icons.Filled.Check`: a static filled
// glyph, not the Checkbox stroke-draw polyline.
const CHECK_PATH = 'M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z'

function warn(message: string): void {
  if (typeof process !== 'undefined' && process.env.NODE_ENV !== 'production') {
    console.warn(`SegmentedButtonGroup: ${message}`)
  }
}

function warnForInvalidProps({
  value,
  defaultValue,
  onValueChange,
}: {
  readonly value: GroupValue | undefined
  readonly defaultValue: GroupValue | undefined
  readonly onValueChange: ((value: never) => void) | undefined
}): void {
  if (value !== undefined && defaultValue !== undefined) {
    warn('use either value or defaultValue, not both.')
  }
  if (value !== undefined && onValueChange === undefined) {
    warn('a controlled value requires onValueChange.')
  }
}

function segmentPosition(index: number, count: number): 'start' | 'middle' | 'end' | 'only' {
  if (count === 1) return 'only'
  if (index === 0) return 'start'
  if (index === count - 1) return 'end'
  return 'middle'
}

function SegmentedButtonGroupRender(
  props: SegmentedButtonGroupProps,
  forwardedRef: ForwardedRef<HTMLDivElement>,
): ReactElement {
  const {
    segments,
    multiple = false,
    disabled = false,
    name: nameProp,
    value,
    defaultValue,
    onValueChange,
    className,
    style,
    ...rootProps
  } = props as SegmentedButtonGroupProps & {
    readonly multiple?: boolean
    readonly value?: GroupValue
    readonly defaultValue?: GroupValue
    readonly onValueChange?: (value: never) => void
  }

  warnForInvalidProps({ value, defaultValue, onValueChange })

  const generatedName = useId()
  const name = nameProp ?? generatedName
  const firstInputRef = useRef<HTMLInputElement | null>(null)

  const resolvedDefaultValue: GroupValue = defaultValue ?? (multiple ? EMPTY_VALUES : '')
  const controlled = value !== undefined
  const [currentValue, setValue] = useControllableState<GroupValue>({
    value,
    defaultValue: resolvedDefaultValue,
    onChange: onValueChange as ((value: GroupValue) => void) | undefined,
  })

  // Native form reset restores each input's own `defaultChecked` without a
  // React update, so uncontrolled group state resynchronizes from the same
  // event, matching the Radio/Checkbox reset precedent.
  useEffect(() => {
    const form = firstInputRef.current?.form
    if (controlled || !form) return undefined
    const handleReset = () => setValue(resolvedDefaultValue)
    form.addEventListener('reset', handleReset)
    return () => form.removeEventListener('reset', handleReset)
  }, [controlled, resolvedDefaultValue, setValue])

  const isChecked = (segment: SegmentedButtonGroupSegment): boolean =>
    multiple
      ? (currentValue as readonly string[]).includes(segment.value)
      : currentValue === segment.value

  const isDefaultChecked = (segment: SegmentedButtonGroupSegment): boolean =>
    multiple
      ? (resolvedDefaultValue as readonly string[]).includes(segment.value)
      : resolvedDefaultValue === segment.value

  const handleChange = (segment: SegmentedButtonGroupSegment, event: ChangeEvent<HTMLInputElement>) => {
    if (multiple) {
      const current = currentValue as readonly string[]
      const next = event.currentTarget.checked
        ? [...current, segment.value]
        : current.filter((entry) => entry !== segment.value)
      setValue(next)
    } else if (event.currentTarget.checked) {
      setValue(segment.value)
    }
  }

  const mergedClassName = className
    ? `m3e-segmented-button-group ${className}`
    : 'm3e-segmented-button-group'
  const count = segments.length

  return (
    <div
      {...rootProps}
      ref={forwardedRef}
      className={mergedClassName}
      style={style}
      role={multiple ? 'group' : 'radiogroup'}
      data-m3e-disabled={disabled}
    >
      {segments.map((segment, index) => {
        const position = segmentPosition(index, count)
        const segmentDisabled = disabled || segment.disabled === true
        const hasIcon = segment.icon != null

        return (
          <label
            key={segment.value}
            className="m3e-segmented-button"
            data-m3e-position={position}
            data-m3e-disabled={segmentDisabled}
          >
            <input
              ref={index === 0 ? firstInputRef : undefined}
              type={multiple ? 'checkbox' : 'radio'}
              className="m3e-segmented-button__input"
              name={name}
              value={segment.value}
              disabled={segmentDisabled}
              {...(controlled
                ? { checked: isChecked(segment) }
                : { defaultChecked: isDefaultChecked(segment) })}
              onChange={(event) => handleChange(segment, event)}
            />
            <span className="m3e-segmented-button__icon" data-m3e-has-icon={hasIcon}>
              {hasIcon ? (
                <span className="m3e-segmented-button__icon-glyph">{segment.icon}</span>
              ) : null}
              <svg
                className="m3e-segmented-button__check"
                viewBox="0 0 24 24"
                aria-hidden="true"
                focusable="false"
              >
                <path d={CHECK_PATH} />
              </svg>
            </span>
            <span className="m3e-segmented-button__text">{segment.label}</span>
          </label>
        )
      })}
    </div>
  )
}

const ForwardedSegmentedButtonGroup = forwardRef<HTMLDivElement, SegmentedButtonGroupProps>(
  SegmentedButtonGroupRender,
)
ForwardedSegmentedButtonGroup.displayName = 'SegmentedButtonGroup'

export const SegmentedButtonGroup = ForwardedSegmentedButtonGroup as SegmentedButtonGroupComponent

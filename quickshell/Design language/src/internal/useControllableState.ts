import { useCallback, useState } from 'react'

export interface ControllableStateOptions<TValue> {
  readonly value: TValue | undefined
  readonly defaultValue: TValue
  readonly onChange?: (value: TValue) => void
}

/**
 * Keeps controlled and uncontrolled component state on one deterministic path.
 * A controlled value is never mirrored into local state.
 */
export function useControllableState<TValue>({
  value,
  defaultValue,
  onChange,
}: ControllableStateOptions<TValue>): readonly [TValue, (value: TValue) => void] {
  const [uncontrolledValue, setUncontrolledValue] = useState(defaultValue)
  const controlled = value !== undefined
  const currentValue = controlled ? value : uncontrolledValue

  const setValue = useCallback(
    (nextValue: TValue) => {
      if (Object.is(currentValue, nextValue)) return
      if (!controlled) setUncontrolledValue(nextValue)
      onChange?.(nextValue)
    },
    [controlled, currentValue, onChange],
  )

  return [currentValue, setValue] as const
}

import { forwardRef, type CSSProperties, type ForwardedRef, type ReactElement } from 'react'
import type { LinearProgressProps } from './LinearProgress.types'

interface LinearProgressComponent {
  (props: LinearProgressProps): ReactElement | null
  displayName?: string
}

function LinearProgressRender(
  { value, max = 1, className, style, ...divProps }: LinearProgressProps,
  forwardedRef: ForwardedRef<HTMLDivElement>,
) {
  const determinate = value != null
  const coercedValue = determinate ? Math.min(Math.max(value as number, 0), max) : 0
  const pct = max > 0 ? (coercedValue / max) * 100 : 0

  return (
    <div
      {...divProps}
      ref={forwardedRef}
      role="progressbar"
      aria-valuemin={0}
      aria-valuemax={max}
      aria-valuenow={determinate ? coercedValue : undefined}
      className={className ? `m3e-linear-progress ${className}` : 'm3e-linear-progress'}
      style={style as CSSProperties}
      data-m3e-determinate={determinate}
    >
      {determinate ? (
        <>
          <div
            className="m3e-linear-progress__track"
            style={{ insetInlineStart: `calc(${pct}% + var(--m3e-comp-linear-progress-track-gap))` }}
          />
          <div className="m3e-linear-progress__fill" style={{ inlineSize: `${pct}%` }} />
          <span className="m3e-linear-progress__stop" />
        </>
      ) : (
        <>
          <div className="m3e-linear-progress__track" />
          <div className="m3e-linear-progress__indeterminate-bar1" />
          <div className="m3e-linear-progress__indeterminate-bar2" />
        </>
      )}
    </div>
  )
}

const ForwardedLinearProgress = forwardRef<HTMLDivElement, LinearProgressProps>(LinearProgressRender)
ForwardedLinearProgress.displayName = 'LinearProgress'

export const LinearProgress = ForwardedLinearProgress as LinearProgressComponent

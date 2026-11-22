import { forwardRef, type CSSProperties, type ForwardedRef, type ReactElement } from 'react'
import type { CircularProgressProps } from './CircularProgress.types'

interface CircularProgressComponent {
  (props: CircularProgressProps): ReactElement | null
  displayName?: string
}

const DIAMETER = 40
const RADIUS = 18
const STROKE_WIDTH = 4
const TRACK_GAP_PX = 4
// Center = radius + half the stroke width, so the stroked circle's outer
// edge lands exactly on the viewBox boundary (diameter = 2 * center).
const CENTER = RADIUS + STROKE_WIDTH / 2
// Compose adds the active stroke width when round caps are in use so the
// requested 4px visible gap is measured between the cap edges, not between
// the centerline endpoints. Its angular conversion deliberately references
// the complete 40px canvas diameter, rather than the inset centerline radius.
const ROUND_CAP_ADJUSTED_GAP_PCT =
  ((TRACK_GAP_PX + STROKE_WIDTH) / (Math.PI * DIAMETER)) * 100

function CircularProgressRender(
  { value, max = 1, className, style, ...divProps }: CircularProgressProps,
  forwardedRef: ForwardedRef<HTMLDivElement>,
) {
  const determinate = value != null
  const coercedValue = determinate ? Math.min(Math.max(value as number, 0), max) : 0
  const progressFraction = max > 0 ? coercedValue / max : 0
  const sweepPct = progressFraction * 100
  const trackGapPct = Math.min(sweepPct, ROUND_CAP_ADJUSTED_GAP_PCT)
  const trackOnLenPct = Math.max(0, 100 - sweepPct - 2 * trackGapPct)
  const showIndicator = !determinate || sweepPct > 0
  const showTrack = determinate && trackOnLenPct > 0

  return (
    <div
      {...divProps}
      ref={forwardedRef}
      role="progressbar"
      aria-valuemin={0}
      aria-valuemax={max}
      aria-valuenow={determinate ? coercedValue : undefined}
      className={className ? `m3e-circular-progress ${className}` : 'm3e-circular-progress'}
      style={style as CSSProperties}
      data-m3e-determinate={determinate}
    >
      <svg
        className="m3e-circular-progress__svg"
        viewBox={`0 0 ${DIAMETER} ${DIAMETER}`}
        width={DIAMETER}
        height={DIAMETER}
        aria-hidden="true"
      >
        {/* circularIndeterminateTrackColor is Transparent in the pinned
            source (unlike the linear indicator's own indeterminate track,
            which stays visible) — no track element renders at all in
            indeterminate mode, rather than an explicit transparent one. */}
        {showTrack && (
          <circle
            className="m3e-circular-progress__track"
            cx={CENTER}
            cy={CENTER}
            r={RADIUS}
            pathLength={100}
            transform={`rotate(-90 ${CENTER} ${CENTER})`}
            style={{
              strokeDasharray: `${trackOnLenPct} ${100 - trackOnLenPct}`,
              strokeDashoffset: -(sweepPct + trackGapPct),
            }}
          />
        )}
        <g className="m3e-circular-progress__global-rotate">
          <g className="m3e-circular-progress__additional-rotate">
            {showIndicator && (
              <circle
                className="m3e-circular-progress__indicator m3e-circular-progress__sweep"
                cx={CENTER}
                cy={CENTER}
                r={RADIUS}
                pathLength={100}
                transform={determinate ? `rotate(-90 ${CENTER} ${CENTER})` : undefined}
                style={
                  determinate
                    ? {
                        strokeDasharray: `${sweepPct} ${100 - sweepPct}`,
                        strokeDashoffset: 0,
                      }
                    : undefined
                }
              />
            )}
          </g>
        </g>
      </svg>
    </div>
  )
}

const ForwardedCircularProgress = forwardRef<HTMLDivElement, CircularProgressProps>(
  CircularProgressRender,
)
ForwardedCircularProgress.displayName = 'CircularProgress'

export const CircularProgress = ForwardedCircularProgress as CircularProgressComponent

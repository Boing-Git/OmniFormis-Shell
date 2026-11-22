import { forwardRef, type CSSProperties, type ForwardedRef, type ReactElement } from 'react'
import type { WavyProgressProps } from './WavyProgress.types'
import {
  CIRCULAR_CIRCLE_PATH,
  CIRCULAR_WAVE_PATH,
  LINEAR_FLAT_PATH_DETERMINATE,
  LINEAR_WAVE_PATH_DETERMINATE,
  LINEAR_WAVE_PATH_INDETERMINATE,
  LINEAR_WAVE_VIEWBOX_HEIGHT,
  LINEAR_WAVE_VIEWBOX_WIDTH,
} from './wavePaths'

interface WavyProgressComponent {
  (props: WavyProgressProps): ReactElement | null
  displayName?: string
}

const CIRCULAR_DIAMETER = 48
const CIRCULAR_STROKE_WIDTH = 4
const CIRCULAR_TRACK_GAP_PX = 4
const CIRCULAR_CENTER = CIRCULAR_DIAMETER / 2
const CIRCULAR_CENTERLINE_RADIUS = CIRCULAR_CENTER - CIRCULAR_STROKE_WIDTH / 2
const CIRCULAR_CIRCUMFERENCE = 2 * Math.PI * CIRCULAR_CENTERLINE_RADIUS

function circularTrackSpacingPct(progressFraction: number): number {
  const progressLength = progressFraction * CIRCULAR_CIRCUMFERENCE
  // CircularWavyProgressModifiers reserves both round-cap half-widths plus
  // the requested track gap, shortening each term adaptively while the
  // active segment is still too small to contain the full spacing.
  const capInset = Math.min(progressLength, CIRCULAR_STROKE_WIDTH / 2)
  const gap = Math.min(progressLength, CIRCULAR_TRACK_GAP_PX)
  return ((capInset * 2 + gap) / CIRCULAR_CIRCUMFERENCE) * 100
}

// WavyProgressIndicatorDefaults.indicatorAmplitude: ramps the wave's
// amplitude to zero near the start and end of determinate progress.
function amplitudeFractionFor(progressFraction: number): number {
  if (progressFraction <= 0.1 || progressFraction >= 0.95) return 0
  return 1
}

function WavyProgressRender(
  { shape = 'linear', value, max = 1, className, style, ...divProps }: WavyProgressProps,
  forwardedRef: ForwardedRef<HTMLDivElement>,
) {
  const determinate = value != null
  const coercedValue = determinate ? Math.min(Math.max(value as number, 0), max) : 0
  const progressFraction = max > 0 ? coercedValue / max : 0
  const amplitudeFraction = amplitudeFractionFor(progressFraction)
  const renderedAmplitudeFraction = determinate ? amplitudeFraction : 1

  const rootProps = {
    ...divProps,
    ref: forwardedRef,
    role: 'progressbar' as const,
    'aria-valuemin': 0,
    'aria-valuemax': max,
    'aria-valuenow': determinate ? coercedValue : undefined,
    className: className ? `m3e-wavy-progress ${className}` : 'm3e-wavy-progress',
    style: style as CSSProperties,
    'data-m3e-shape': shape,
    'data-m3e-determinate': determinate,
    'data-m3e-amplitude': renderedAmplitudeFraction === 0 ? 'flat' : 'wave',
  }

  if (shape === 'circular') {
    const sweepPct = progressFraction * 100
    const trackSpacingPct = circularTrackSpacingPct(progressFraction)
    const trackOnLenPct = Math.max(0, 100 - sweepPct - 2 * trackSpacingPct)
    const showIndicator = !determinate || sweepPct > 0
    const showTrack = determinate && trackOnLenPct > 0
    return (
      <div {...rootProps}>
        <svg
          className="m3e-wavy-progress__circular-svg"
          viewBox={`0 0 ${CIRCULAR_DIAMETER} ${CIRCULAR_DIAMETER}`}
          width={CIRCULAR_DIAMETER}
          height={CIRCULAR_DIAMETER}
          aria-hidden="true"
        >
          {showTrack && (
            <path
              className="m3e-wavy-progress__track"
              d={CIRCULAR_CIRCLE_PATH}
              pathLength={100}
              style={{
                strokeDasharray: `${trackOnLenPct} ${100 - trackOnLenPct}`,
                strokeDashoffset: -(sweepPct + trackSpacingPct),
              }}
            />
          )}
          <g className="m3e-wavy-progress__global-rotate">
            <g className="m3e-wavy-progress__additional-rotate">
              {!determinate && (
                <path
                  className="m3e-wavy-progress__track m3e-wavy-progress__track-sweep"
                  d={CIRCULAR_CIRCLE_PATH}
                  pathLength={100}
                />
              )}
              {showIndicator && (
                <g className="m3e-wavy-progress__wave-rotate">
                  <path
                    className="m3e-wavy-progress__indicator m3e-wavy-progress__sweep m3e-wavy-progress__wave"
                    d={renderedAmplitudeFraction === 0 ? CIRCULAR_CIRCLE_PATH : CIRCULAR_WAVE_PATH}
                    pathLength={100}
                    vectorEffect="non-scaling-stroke"
                    style={
                      determinate
                        ? {
                            strokeDasharray: `${sweepPct} ${100 - sweepPct}`,
                            strokeDashoffset: 0,
                          }
                        : undefined
                    }
                  />
                </g>
              )}
            </g>
          </g>
        </svg>
      </div>
    )
  }

  const pct = progressFraction * 100

  const wave = (path: string) => (
    <svg
      className="m3e-wavy-progress__linear-wave-svg"
      viewBox={`0 0 ${LINEAR_WAVE_VIEWBOX_WIDTH} ${LINEAR_WAVE_VIEWBOX_HEIGHT}`}
      width={LINEAR_WAVE_VIEWBOX_WIDTH}
      preserveAspectRatio="none"
      aria-hidden="true"
    >
      <path d={path} vectorEffect="non-scaling-stroke" />
    </svg>
  )

  return (
    <div {...rootProps}>
      {determinate ? (
        <>
          <div
            className="m3e-wavy-progress__track"
            style={{
              insetInlineStart: `calc(${pct}% + var(--m3e-comp-wavy-progress-linear-track-gap))`,
            }}
          />
          <div className="m3e-wavy-progress__wave-clip" style={{ inlineSize: `${pct}%` }}>
            {wave(
              amplitudeFraction === 0 ? LINEAR_FLAT_PATH_DETERMINATE : LINEAR_WAVE_PATH_DETERMINATE,
            )}
          </div>
          <span className="m3e-wavy-progress__stop" />
        </>
      ) : (
        <>
          <div className="m3e-wavy-progress__track" />
          <div className="m3e-wavy-progress__indeterminate-bar1">
            <div className="m3e-wavy-progress__wave-clip">
              {wave(LINEAR_WAVE_PATH_INDETERMINATE)}
            </div>
          </div>
          <div className="m3e-wavy-progress__indeterminate-bar2">
            <div className="m3e-wavy-progress__wave-clip">
              {wave(LINEAR_WAVE_PATH_INDETERMINATE)}
            </div>
          </div>
        </>
      )}
    </div>
  )
}

const ForwardedWavyProgress = forwardRef<HTMLDivElement, WavyProgressProps>(WavyProgressRender)
ForwardedWavyProgress.displayName = 'WavyProgress'

export const WavyProgress = ForwardedWavyProgress as WavyProgressComponent

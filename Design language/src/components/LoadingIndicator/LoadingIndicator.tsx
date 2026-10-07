import { forwardRef, type CSSProperties, type ForwardedRef, type ReactElement } from 'react'
import type { LoadingIndicatorProps } from './LoadingIndicator.types'
import { determinateMorph } from './loadingIndicatorMorphs'

interface LoadingIndicatorComponent {
  (props: LoadingIndicatorProps): ReactElement | null
  displayName?: string
}

// morphSequence(circularSequence: true) over the 7-shape indeterminate list
// (SoftBurst, Cookie9Sided, Pentagon, Pill, Sunny, Cookie4Sided, Oval).
const INDETERMINATE_SEGMENT_COUNT = 7
const INDETERMINATE_SEGMENT_INDEXES = Array.from({ length: INDETERMINATE_SEGMENT_COUNT }, (_, i) => i)

function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t
}

// Reproduces Morph.forEachCubic's per-frame interpolation directly from the
// pre-matched (start, end) cubic pairs -- see loadingIndicatorMorphs.ts.
function determinatePathAt(progress: number): string {
  const first = determinateMorph[0]
  const startX = lerp(first[0][0], first[1][0], progress)
  const startY = lerp(first[0][1], first[1][1], progress)
  let d = `M${startX} ${startY}`
  for (const [c1, c2] of determinateMorph) {
    d += ` C${lerp(c1[2], c2[2], progress)} ${lerp(c1[3], c2[3], progress)},${lerp(c1[4], c2[4], progress)} ${lerp(c1[5], c2[5], progress)},${lerp(c1[6], c2[6], progress)} ${lerp(c1[7], c2[7], progress)}`
  }
  return `${d} Z`
}

function LoadingIndicatorRender(
  { value, max = 1, className, style, ...divProps }: LoadingIndicatorProps,
  forwardedRef: ForwardedRef<HTMLDivElement>,
) {
  const determinate = value != null
  const coercedValue = determinate ? Math.min(Math.max(value as number, 0), max) : 0
  const progressFraction = max > 0 ? coercedValue / max : 0

  const rootProps = {
    ...divProps,
    ref: forwardedRef,
    role: 'progressbar' as const,
    'aria-valuemin': 0,
    'aria-valuemax': max,
    'aria-valuenow': determinate ? coercedValue : undefined,
    className: className ? `m3e-loading-indicator ${className}` : 'm3e-loading-indicator',
    style: style as CSSProperties,
    'data-m3e-determinate': determinate,
  }

  return (
    <div {...rootProps}>
      <svg className="m3e-loading-indicator__svg" viewBox="0 0 100 100" aria-hidden="true">
        {determinate ? (
          <path
            className="m3e-loading-indicator__shape"
            d={determinatePathAt(progressFraction)}
            style={{ transform: `rotate(${-progressFraction * 180}deg)` }}
          />
        ) : (
          <g className="m3e-loading-indicator__global-rotate">
            {INDETERMINATE_SEGMENT_INDEXES.map((index) => (
              <path
                key={index}
                className={
                  index === 0
                    ? 'm3e-loading-indicator__shape m3e-loading-indicator__segment m3e-loading-indicator__segment-0 m3e-loading-indicator__reduced-motion-fallback'
                    : `m3e-loading-indicator__shape m3e-loading-indicator__segment m3e-loading-indicator__segment-${index}`
                }
              />
            ))}
          </g>
        )}
      </svg>
    </div>
  )
}

const ForwardedLoadingIndicator = forwardRef<HTMLDivElement, LoadingIndicatorProps>(LoadingIndicatorRender)
ForwardedLoadingIndicator.displayName = 'LoadingIndicator'

export const LoadingIndicator = ForwardedLoadingIndicator as LoadingIndicatorComponent

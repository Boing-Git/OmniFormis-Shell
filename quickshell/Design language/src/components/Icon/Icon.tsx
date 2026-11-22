import {
  forwardRef,
  type ComponentType,
  type CSSProperties,
  type ForwardedRef,
  type HTMLAttributes,
  type ReactNode,
} from 'react'
import type {
  IconProps,
  IconSourceProps,
  MaterialSymbolStyle,
} from './Icon.types'

interface IconCustomProperties extends CSSProperties {
  '--m3e-icon-size'?: string
  '--m3e-icon-symbol-fill'?: number
  '--m3e-icon-symbol-weight'?: number
  '--m3e-icon-symbol-grade'?: number
  '--m3e-icon-symbol-optical-size'?: number
  '--m3e-icon-symbol-roundness'?: number
}

interface IconImplementationProps extends Omit<HTMLAttributes<HTMLSpanElement>, 'children'> {
  readonly source: string | ComponentType<IconSourceProps>
  readonly decorative?: boolean
  readonly label?: string
  readonly size?: number
  readonly mirrored?: boolean
  readonly symbolStyle?: MaterialSymbolStyle
  readonly fill?: number
  readonly weight?: number
  readonly grade?: number
  readonly opticalSize?: number
  readonly roundness?: number
}

function warn(message: string): void {
  if (typeof process !== 'undefined' && process.env.NODE_ENV !== 'production') {
    console.warn(`Icon: ${message}`)
  }
}

function warnForRange(name: string, value: number | undefined, minimum: number, maximum: number) {
  if (value !== undefined && (!Number.isFinite(value) || value < minimum || value > maximum)) {
    warn(`${name} must be a finite number from ${minimum} through ${maximum}; received ${String(value)}.`)
  }
}

function warnForInvalidProps({
  source,
  decorative,
  label,
  size,
  fill,
  weight,
  grade,
  opticalSize,
  roundness,
}: IconImplementationProps): void {
  if (typeof source === 'string' && source.trim().length === 0) {
    warn('a Material Symbols source must not be empty.')
  }
  if (!decorative && (!label || label.trim().length === 0)) {
    warn('meaningful icons require a non-empty label when decorative={false}.')
  }
  if (size !== undefined && (!Number.isFinite(size) || size <= 0)) {
    warn(`size must be a positive finite CSS-pixel value; received ${String(size)}.`)
  }

  if (typeof source === 'string') {
    warnForRange('fill', fill, 0, 1)
    warnForRange('weight', weight, 100, 700)
    warnForRange('grade', grade, -50, 200)
    warnForRange('opticalSize', opticalSize, 20, 48)
    warnForRange('roundness', roundness, 0, 100)
  } else if (
    fill !== undefined ||
    weight !== undefined ||
    grade !== undefined ||
    opticalSize !== undefined ||
    roundness !== undefined
  ) {
    warn('Material Symbols axis props have no effect on an SVG source.')
  }
}

function createStyle(
  source: IconImplementationProps['source'],
  consumerStyle: CSSProperties | undefined,
  size: number | undefined,
  fill: number | undefined,
  weight: number | undefined,
  grade: number | undefined,
  opticalSize: number | undefined,
  roundness: number | undefined,
): CSSProperties | undefined {
  const internalStyle: IconCustomProperties = {}
  const hasValidSize = size !== undefined && Number.isFinite(size) && size > 0

  if (hasValidSize) internalStyle['--m3e-icon-size'] = `${size}px`
  if (typeof source === 'string') {
    if (fill !== undefined) internalStyle['--m3e-icon-symbol-fill'] = fill
    if (weight !== undefined) internalStyle['--m3e-icon-symbol-weight'] = weight
    if (grade !== undefined) internalStyle['--m3e-icon-symbol-grade'] = grade
    if (roundness !== undefined) internalStyle['--m3e-icon-symbol-roundness'] = roundness
    if (opticalSize !== undefined) {
      internalStyle['--m3e-icon-symbol-optical-size'] = opticalSize
    } else if (hasValidSize) {
      internalStyle['--m3e-icon-symbol-optical-size'] = Math.min(48, Math.max(20, size))
    }
  }

  return Object.keys(internalStyle).length > 0
    ? { ...consumerStyle, ...internalStyle }
    : consumerStyle
}

function IconRender(
  {
    source,
    decorative = true,
    label,
    size,
    mirrored = false,
    symbolStyle = 'outlined',
    fill,
    weight,
    grade,
    opticalSize,
    roundness,
    className,
    style,
    ...spanProps
  }: IconImplementationProps,
  forwardedRef: ForwardedRef<HTMLSpanElement>,
) {
  warnForInvalidProps({
    source,
    decorative,
    label,
    size,
    mirrored,
    symbolStyle,
    fill,
    weight,
    grade,
    opticalSize,
    roundness,
  })

  const mergedClassName = className ? `m3e-icon ${className}` : 'm3e-icon'
  const mergedStyle = createStyle(
    source,
    style,
    size,
    fill,
    weight,
    grade,
    opticalSize,
    roundness,
  )
  const sourceType = typeof source === 'string' ? 'symbol' : 'svg'
  const hasMeaningfulLabel = !decorative && Boolean(label?.trim())
  const accessibilityProps = hasMeaningfulLabel
    ? { role: 'img' as const, 'aria-label': label }
    : { 'aria-hidden': true as const }

  let visual: ReactNode
  if (typeof source === 'string') {
    visual = (
      <span className="m3e-icon__symbol" aria-hidden="true">
        {source}
      </span>
    )
  } else {
    const SvgSource = source
    visual = (
      <SvgSource
        className="m3e-icon__svg"
        aria-hidden={true}
        focusable="false"
      />
    )
  }

  return (
    <span
      {...spanProps}
      {...accessibilityProps}
      ref={forwardedRef}
      className={mergedClassName}
      style={mergedStyle}
      data-m3e-source={sourceType}
      data-m3e-mirrored={mirrored}
      data-m3e-symbol-style={sourceType === 'symbol' ? symbolStyle : undefined}
    >
      {visual}
    </span>
  )
}

export const Icon = forwardRef<HTMLSpanElement, IconProps>(IconRender)
Icon.displayName = 'Icon'

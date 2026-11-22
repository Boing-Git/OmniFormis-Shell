import {
  forwardRef,
  type ElementType,
  type ForwardedRef,
  type HTMLAttributes,
  type ReactElement,
} from 'react'
import type {
  SurfaceColor,
  SurfaceElement,
  SurfaceElevation,
  SurfaceProps,
  SurfaceShape,
} from './Surface.types'

interface SurfaceImplementationProps extends HTMLAttributes<HTMLElement> {
  readonly as?: SurfaceElement
  readonly color?: SurfaceColor
  readonly tonalElevation?: SurfaceElevation
  readonly shadowElevation?: SurfaceElevation
  readonly shape?: SurfaceShape
}

interface SurfaceComponent {
  <TElement extends SurfaceElement = 'div'>(
    props: SurfaceProps<TElement>,
  ): ReactElement | null
  displayName?: string
}

function warnForIneffectiveTonalElevation(
  color: SurfaceColor,
  tonalElevation: SurfaceElevation,
): void {
  if (
    typeof process !== 'undefined' &&
    process.env.NODE_ENV !== 'production' &&
    tonalElevation !== 0 &&
    color !== 'surface'
  ) {
    console.warn(
      `Surface: tonalElevation only affects color="surface". Received color="${color}" with tonalElevation={${tonalElevation}}; use color="surface" or remove tonalElevation.`,
    )
  }
}

function SurfaceRender(
  {
    as = 'div',
    color = 'surface',
    tonalElevation = 0,
    shadowElevation = 0,
    shape = 'none',
    className,
    ...elementProps
  }: SurfaceImplementationProps,
  forwardedRef: ForwardedRef<HTMLElement>,
) {
  const Element = as as ElementType
  const mergedClassName = className ? `m3e-surface ${className}` : 'm3e-surface'
  warnForIneffectiveTonalElevation(color, tonalElevation)

  return (
    <Element
      {...elementProps}
      ref={forwardedRef}
      className={mergedClassName}
      data-m3e-color={color}
      data-m3e-tonal-elevation={tonalElevation}
      data-m3e-shadow-elevation={shadowElevation}
      data-m3e-shape={shape}
    />
  )
}

const ForwardedSurface = forwardRef<HTMLElement, SurfaceImplementationProps>(SurfaceRender)
ForwardedSurface.displayName = 'Surface'

export const Surface = ForwardedSurface as SurfaceComponent

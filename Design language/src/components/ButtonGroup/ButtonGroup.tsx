import { forwardRef, type CSSProperties, type ForwardedRef, type ReactElement } from 'react'
import type { ButtonGroupProps } from './ButtonGroup.types'

interface ButtonGroupComponent {
  (props: ButtonGroupProps): ReactElement | null
  displayName?: string
}

function ButtonGroupRender(
  { children, className, style, role = 'group', ...divProps }: ButtonGroupProps,
  forwardedRef: ForwardedRef<HTMLDivElement>,
) {
  return (
    <div
      {...divProps}
      ref={forwardedRef}
      role={role}
      className={className ? `m3e-button-group ${className}` : 'm3e-button-group'}
      style={style as CSSProperties}
    >
      {children}
    </div>
  )
}

const ForwardedButtonGroup = forwardRef<HTMLDivElement, ButtonGroupProps>(ButtonGroupRender)
ForwardedButtonGroup.displayName = 'ButtonGroup'

export const ButtonGroup = ForwardedButtonGroup as ButtonGroupComponent

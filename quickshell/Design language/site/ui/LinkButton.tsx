import Link from 'next/link'
import type { ReactNode } from 'react'

/**
 * A navigation control styled as a Material button.
 *
 * `Button` renders a native `<button>` and deliberately offers no link mode —
 * its documentation says so, and points at "a separately designed link-button
 * adapter" instead of nesting an anchor inside a button. This is that adapter.
 * It is a real `<a>`, so middle-click, copy-link, and the browser's own
 * navigation all keep working.
 *
 * It is styled from the public `--m3e-comp-button-*` token layer rather than
 * the library's internal class names, so it tracks the theme exactly as a real
 * button does without depending on private CSS.
 */
export function LinkButton({
  href,
  children,
  variant = 'filled',
  size = 'medium',
  trailingIcon,
  external = false,
}: {
  href: string
  children: ReactNode
  variant?: 'filled' | 'tonal' | 'outlined' | 'text'
  size?: 'small' | 'medium'
  trailingIcon?: ReactNode
  external?: boolean
}) {
  const className = `link-button link-button--${variant} link-button--${size}`

  if (external) {
    return (
      <a className={className} href={href} target="_blank" rel="noreferrer">
        {children}
        {trailingIcon}
      </a>
    )
  }

  return (
    <Link className={className} href={href}>
      {children}
      {trailingIcon}
    </Link>
  )
}

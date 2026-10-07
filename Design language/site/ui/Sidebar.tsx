'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'

export interface SidebarGroup {
  label: string
  links: { label: string; href: string }[]
}

export function Sidebar({ groups }: { groups: SidebarGroup[] }) {
  const pathname = usePathname()

  return (
    <nav className="sidebar" aria-label="Documentation">
      {groups.map((group) => (
        <div className="sidebar__group" key={group.label}>
          <h2 className="sidebar__title">{group.label}</h2>
          <ul className="sidebar__list">
            {group.links.map((link) => (
              <li key={link.href}>
                <Link
                  href={link.href}
                  className="sidebar__link"
                  aria-current={pathname === link.href ? 'page' : undefined}
                >
                  {link.label}
                </Link>
              </li>
            ))}
          </ul>
        </div>
      ))}
    </nav>
  )
}

'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Dialog, Icon, IconButton } from '@language-lit/material3-expressive'
import type { NavigationGroup } from '../content/navigation'

/**
 * Navigation for viewports that cannot show the sidebar.
 *
 * It presents the same groups as the sidebar rather than a reduced set: below
 * 60rem the sidebar is hidden, so without this the component pages would be
 * reachable only through search.
 */
export function MobileNav({ groups }: { groups: NavigationGroup[] }) {
  const [open, setOpen] = useState(false)
  const pathname = usePathname()

  // Navigating away must close the drawer; the route change alone does not.
  useEffect(() => {
    setOpen(false)
  }, [pathname])

  return (
    <span className="bar__mobile-only">
      <IconButton
        aria-label="Open navigation"
        aria-expanded={open}
        variant="standard"
        onClick={() => setOpen(true)}
      >
        <Icon source="menu" />
      </IconButton>

      <Dialog open={open} onOpenChange={setOpen} title="Navigation">
        <nav aria-label="Documentation">
          {groups.map((group) => (
            <div className="sidebar__group" key={group.label}>
              <h3 className="sidebar__title">{group.label}</h3>
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
      </Dialog>
    </span>
  )
}

import type { ReactNode } from 'react'
import { buildNavigationGroups } from '../content/navigation'
import { Sidebar } from './Sidebar'

export async function DocsShell({ children }: { children: ReactNode }) {
  const groups = await buildNavigationGroups()
  return (
    <div className="shell">
      <Sidebar groups={groups} />
      <main className="shell__main">{children}</main>
    </div>
  )
}

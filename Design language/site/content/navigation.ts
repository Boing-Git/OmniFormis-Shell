import { getComponentsByKind } from './inventory'
import { docPages } from './docs'

export interface NavigationGroup {
  label: string
  links: { label: string; href: string }[]
}

/**
 * The site's full navigation tree, grouped the way the inventory groups
 * components. Shared by the desktop sidebar and the mobile drawer so the two
 * cannot present different destinations.
 */
export async function buildNavigationGroups(): Promise<NavigationGroup[]> {
  const byKind = await getComponentsByKind()
  return [
    {
      label: 'Guides',
      links: docPages.map((page) => ({
        label: page.title,
        href: `/docs/${page.slug}/`,
      })),
    },
    {
      label: 'Overview',
      links: [{ label: 'All components', href: '/components/' }],
    },
    ...byKind.map((group) => ({
      label: group.label,
      links: group.components.map((component) => ({
        label: component.name,
        href: `/components/${component.name}/`,
      })),
    })),
  ]
}

import { FloatingActionButton, Icon, NavigationRail, Surface, Text } from '@language-lit/material3-expressive'

export function NavigationRailExample() {
  return (
    <Surface
      as="section"
      aria-labelledby="navigation-rail-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="navigation-rail-example"
    >
      <Text as="h2" id="navigation-rail-example-title" variant="titleLarge" emphasis="emphasized">
        Navigation rail
      </Text>
      <Text as="p" variant="bodyMedium">
        The same item language as Navigation bar, oriented vertically, with
        an optional header slot.
      </Text>

      <div className="navigation-rail-example__frame">
        <NavigationRail
          aria-label="Example sections"
          header={<FloatingActionButton aria-label="Compose" icon={<Icon source="add" />} size="medium" />}
          items={[
            {
              value: 'home',
              label: 'Home',
              icon: <Icon source="home" />,
              selectedIcon: <Icon source="home" fill={1} />,
            },
            { value: 'favorites', label: 'Favorites', icon: <Icon source="favorite" /> },
            { value: 'trash', label: 'Trash', icon: <Icon source="delete" />, disabled: true },
            { value: 'docs', label: 'Docs', icon: <Icon source="description" />, href: '#' },
          ]}
        />
      </div>

      <Text as="p" variant="labelLarge">
        Without a header
      </Text>
      <div className="navigation-rail-example__frame">
        <NavigationRail
          aria-label="Example sections without header"
          items={[
            { value: 'home', label: 'Home', icon: <Icon source="home" /> },
            { value: 'favorites', label: 'Favorites', icon: <Icon source="favorite" /> },
            { value: 'trash', label: 'Trash', icon: <Icon source="delete" />, disabled: true },
          ]}
        />
      </div>
    </Surface>
  )
}

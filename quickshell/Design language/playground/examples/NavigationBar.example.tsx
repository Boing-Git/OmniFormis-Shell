import { Icon, NavigationBar, Surface, Text } from '@language-lit/material3-expressive'

export function NavigationBarExample() {
  return (
    <Surface
      as="section"
      aria-labelledby="navigation-bar-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="navigation-bar-example"
    >
      <Text as="h2" id="navigation-bar-example-title" variant="titleLarge" emphasis="emphasized">
        Navigation bar
      </Text>
      <Text as="p" variant="bodyMedium">
        Web-native `nav`/`aria-current` navigation with a sliding pill
        highlight per item.
      </Text>

      <NavigationBar
        aria-label="Example sections"
        className="navigation-bar-example__bar"
        defaultValue="profile"
        items={[
          {
            value: 'home',
            label: 'Home',
            icon: <Icon source="home" />,
            selectedIcon: <Icon source="home" fill={1} />,
          },
          {
            value: 'favorites',
            label: 'Favorites',
            icon: <Icon source="favorite" />,
            selectedIcon: <Icon source="favorite" fill={1} />,
          },
          { value: 'trash', label: 'Trash', icon: <Icon source="delete" />, disabled: true },
          // No `selectedIcon` — selected by default here to visually confirm
          // the fallback-to-`icon`-while-selected behavior.
          { value: 'profile', label: 'Profile', icon: <Icon source="person" /> },
          { value: 'docs', label: 'Docs', icon: <Icon source="description" />, href: '#' },
        ]}
      />
    </Surface>
  )
}

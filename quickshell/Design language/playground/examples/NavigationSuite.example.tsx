import {
  FloatingActionButton,
  Icon,
  NavigationSuite,
  Surface,
  Text,
} from '@language-lit/material3-expressive'

export function NavigationSuiteExample() {
  return (
    <Surface
      as="section"
      aria-labelledby="navigation-suite-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="navigation-suite-example"
    >
      <Text as="h2" id="navigation-suite-example-title" variant="titleLarge" emphasis="emphasized">
        Navigation suite
      </Text>
      <Text as="p" variant="bodyMedium">
        Adaptive: renders Navigation bar below 600px, Navigation rail from
        600–839px, and a permanent Navigation drawer at 840px and up. Resize
        the window to see it switch live.
      </Text>

      <div className="navigation-suite-example__frame">
        <NavigationSuite
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
            { value: 'settings', label: 'Settings', icon: <Icon source="settings" /> },
            { value: 'archive', label: 'Archive', icon: <Icon source="archive" />, disabled: true },
            { value: 'docs', label: 'Docs', icon: <Icon source="description" />, href: '#' },
          ]}
        />
      </div>
    </Surface>
  )
}

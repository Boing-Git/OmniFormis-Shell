import { Icon, Surface, Tabs, Text } from '@language-lit/material3-expressive'

export function TabsExample() {
  return (
    <Surface
      as="section"
      aria-labelledby="tabs-example-title"
      color="surface-container-low"
      shape="extra-large"
      className="tabs-example"
    >
      <Text as="h2" id="tabs-example-title" variant="titleLarge" emphasis="emphasized">
        Tabs
      </Text>
      <Text as="p" variant="bodyMedium">
        Roving-focus tabs with a sliding indicator, icon+label rows, and
        panels switched in place.
      </Text>

      <Tabs
        aria-label="Library sections"
        items={[
          {
            value: 'photos',
            label: 'Photos',
            icon: <Icon source="photo" />,
            panel: <Text as="p" variant="bodyMedium">Your photo library.</Text>,
          },
          {
            value: 'shared',
            label: 'Shared',
            icon: <Icon source="folder_shared" />,
            panel: <Text as="p" variant="bodyMedium">Albums shared with you.</Text>,
          },
          {
            value: 'trash',
            label: 'Trash',
            icon: <Icon source="delete" />,
            disabled: true,
            panel: <Text as="p" variant="bodyMedium">Recently deleted items.</Text>,
          },
        ]}
      />

      <Tabs
        aria-label="Secondary section"
        variant="secondary"
        defaultValue="overview"
        items={[
          { value: 'overview', label: 'Overview' },
          { value: 'activity', label: 'Activity' },
          { value: 'settings', label: 'Settings' },
          { value: 'archived', label: 'Archived', disabled: true },
        ]}
      />

      <Tabs
        aria-label="Scrollable section"
        scrollable
        items={[
          {
            value: 'home',
            label: 'Home',
            icon: <Icon source="home" />,
            panel: <Text as="p" variant="bodyMedium">Your home feed.</Text>,
          },
          {
            value: 'explore',
            label: 'Explore',
            icon: <Icon source="explore" />,
            panel: <Text as="p" variant="bodyMedium">Discover new content.</Text>,
          },
          {
            value: 'notifications',
            icon: <Icon source="notifications" />,
            panel: <Text as="p" variant="bodyMedium">Icon-only tab: no label, just an icon.</Text>,
          },
          {
            value: 'messages',
            label: 'Messages',
            icon: <Icon source="mail" />,
            panel: <Text as="p" variant="bodyMedium">Your conversations.</Text>,
          },
          {
            value: 'favorites',
            label: 'Favorites',
            icon: <Icon source="star" />,
            panel: <Text as="p" variant="bodyMedium">Items you starred.</Text>,
          },
          {
            value: 'downloads',
            label: 'Downloads',
            icon: <Icon source="download" />,
            href: '#downloads',
          },
          {
            value: 'archive',
            label: 'Archive',
            icon: <Icon source="archive" />,
            panel: <Text as="p" variant="bodyMedium">Archived items.</Text>,
          },
          {
            value: 'settings-2',
            label: 'Settings',
            icon: <Icon source="settings" />,
            panel: <Text as="p" variant="bodyMedium">App preferences.</Text>,
          },
        ]}
      />
    </Surface>
  )
}

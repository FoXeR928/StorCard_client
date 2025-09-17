import { Tabs } from 'expo-router';

export default function TabLayout() {
  return (
    <Tabs>
      <Tabs.Screen name="cards" />
      <Tabs.Screen name="settings" />
    </Tabs>
  );
}

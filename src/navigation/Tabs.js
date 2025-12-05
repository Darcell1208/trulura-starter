// src/navigation/Tabs.js
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Text, View } from 'react-native';

import HomeScreen from '../screens/HomeScreen';
import GlowScreen from '../screens/GlowScreen';
import SparkScreen from '../screens/SparkScreen';
import VentScreen from '../screens/VentScreen';
import CreatorScreen from '../screens/CreatorScreen';
import ProfileScreen from '../screens/ProfileScreen';

import { useMode, useTheme } from '../theme/ThemeProvider';

const Tab = createBottomTabNavigator();

// Simple fallback in case a screen is missing
function Placeholder({ label = 'Screen' }) {
  return (
    <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
      <Text>{label}</Text>
    </View>
  );
}

export default function Tabs() {
  const { palettes } = useTheme();
  const { setModeKey } = useMode();

  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarStyle: {
          backgroundColor: palettes.card,
          borderTopColor: 'transparent',
        },
        tabBarActiveTintColor: palettes.white,
        tabBarInactiveTintColor: palettes.subtle,
      }}
    >
      <Tab.Screen
        name="Home"
        component={HomeScreen || (() => <Placeholder label="Home" />)}
        listeners={{
          focus: () => setModeKey('Home'),
        }}
      />

      <Tab.Screen
        name="Glow"
        component={GlowScreen || (() => <Placeholder label="Glow" />)}
        listeners={{
          focus: () => setModeKey('Glow'),
        }}
      />

      <Tab.Screen
        name="Spark"
        component={SparkScreen || (() => <Placeholder label="Spark" />)}
        listeners={{
          focus: () => setModeKey('Spark'),
        }}
      />

      <Tab.Screen
        name="Vent"
        component={VentScreen || (() => <Placeholder label="Vent" />)}
        listeners={{
          focus: () => setModeKey('Vent'),
        }}
      />

      <Tab.Screen
        name="Creator"
        component={CreatorScreen || (() => <Placeholder label="Creator" />)}
        listeners={{
          // analytics / creator lane uses Explore colors
          focus: () => setModeKey('Explore'),
        }}
      />

      <Tab.Screen
        name="Profile"
        component={ProfileScreen || (() => <Placeholder label="Profile" />)}
        listeners={{
          // profile also uses Explore / teal lane for now
          focus: () => setModeKey('Explore'),
        }}
      />
    </Tab.Navigator>
  );
}

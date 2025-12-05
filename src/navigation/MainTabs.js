// src/navigation/MainTabs.js
import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';

import HomeScreen from '../screens/HomeScreen';
import SparkScreen from '../screens/SparkScreen';
import GlowScreen from '../screens/GlowScreen';
import ProfileScreen from '../screens/ProfileScreen';

import { truluraTheme } from '../theme/truluraTheme';

const Tab = createBottomTabNavigator();

export default function MainTabs() {
  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        headerShown: false,
        tabBarStyle: {
          backgroundColor: truluraTheme.colors.background,
          borderTopColor: 'rgba(148,163,184,0.35)',
        },
        tabBarActiveTintColor: truluraTheme.colors.accentStrong,
        tabBarInactiveTintColor: truluraTheme.colors.neutral,
        tabBarLabelStyle: {
          fontSize: 11,
          paddingBottom: 2,
        },
        tabBarIcon: ({ color, size }) => {
          let iconName = 'ellipse-outline';

          if (route.name === 'Home') iconName = 'home-outline';
          if (route.name === 'Spark') iconName = 'flame-outline';
          if (route.name === 'Glow') iconName = 'sparkles-outline';
          if (route.name === 'Profile') iconName = 'person-circle-outline';

          return <Ionicons name={iconName} size={size} color={color} />;
        },
      })}
    >
      <Tab.Screen name="Home" component={HomeScreen} />
      <Tab.Screen name="Spark" component={SparkScreen} />
      <Tab.Screen name="Glow" component={GlowScreen} />
      <Tab.Screen name="Profile" component={ProfileScreen} />
    </Tab.Navigator>
  );
}

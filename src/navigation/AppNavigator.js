// src/navigation/AppNavigator.js
import { createNativeStackNavigator } from '@react-navigation/native-stack';

import { useAuth } from '../context/AuthContext';

import ProfileSetupScreen from '../screens/ProfileSetupScreen';
import SignInScreen from '../screens/SignInScreen';
import SignUpScreen from '../screens/SignUpScreen';
import MainTabs from './MainTabs';

const Stack = createNativeStackNavigator();

export default function AppNavigator() {
  const { session, profile, loading } = useAuth();

  if (loading) {
    // you can show a splash loader here later
    return null;
  }

  const isLoggedIn = !!session;
  const hasDisplayName = !!profile?.display_name;

  // Not logged in → auth stack
  if (!isLoggedIn) {
    return (
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        <Stack.Screen name="SignIn" component={SignInScreen} />
        <Stack.Screen name="SignUp" component={SignUpScreen} />
      </Stack.Navigator>
    );
  }

  // Logged in → one stack that always contains ProfileSetup + MainTabs
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      {/* If profile incomplete, show ProfileSetup first */}
      {!hasDisplayName && (
        <Stack.Screen name="ProfileSetup" component={ProfileSetupScreen} />
      )}
      <Stack.Screen name="MainTabs" component={MainTabs} />
    </Stack.Navigator>
  );
}

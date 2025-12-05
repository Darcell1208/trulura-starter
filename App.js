// App.js
import { NavigationContainer } from '@react-navigation/native';
import { LogBox } from 'react-native';

import { AuthProvider } from './src/context/AuthContext';
import AppNavigator from './src/navigation/AppNavigator';

// Silence noisy RN Web warning from Navigation
LogBox.ignoreLogs(['props.pointerEvents is deprecated']);

export default function App() {
  return (
    <AuthProvider>
      <NavigationContainer>
        <AppNavigator />
      </NavigationContainer>
    </AuthProvider>
  );
}
